import UIKit
import UniformTypeIdentifiers
import Common

class KeyboardViewController
    : UIInputViewController
    , StickerPickerViewDelegate
{
    private var touchableView: TouchableTransparentView!
    private var bannerView: BannerView!
    private var controlView: UIView!
    private var nextKeyboardButton: KeyboardButton?
    private var stickerPackPageControl: UIPageControl!
    private var stickerPackPageViewController: ArrayPageViewController!
    private var stickerPackDataSource: StickerPageViewControllerDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        // As seen in: https://stackoverflow.com/questions/39694039
        // Basically, it seems that the parent view resizes its height to fit
        // the keyboard contents, which means that constraining our own height
        // to equal the parent height will cause a chicken and egg problem.
        // Thus, we need to set an explicit keyboard height ourselves.
        //
        // We don't set translatesAutoresizingMaskIntoConstraints = false here
        // since we need the system to manage the keyboard's width. Doing it
        // ourselves results in janky layout issues. Yes, we are intentionally
        // ignoring constraint conflicts.
        self.view.heightAnchor.constraint(equalToConstant: 261).isActive = true

        self.touchableView = TouchableTransparentView()
        self.touchableView
            .autoLayoutInView(self.view)
            .fill(self.view.safeAreaLayoutGuide)
            .activate()

        self.bannerView = BannerView()
        self.bannerView
            .autoLayoutInView(self.touchableView)
            .fill(self.touchableView.safeAreaLayoutGuide)
            .activate()

        self.controlView = UIView()
        self.controlView
            .autoLayoutInView(self.touchableView)
            .fillX(self.touchableView.safeAreaLayoutGuide)
            .bottom(self.touchableView.safeAreaLayoutGuide.bottomAnchor)
            .height(40)
            .activate()
        self.controlView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 4, leading: 4, bottom: 4, trailing: 4
        )

        if self.needsInputModeSwitchKey {
            self.nextKeyboardButton = KeyboardButton(type: .system)
            self.nextKeyboardButton!
                .autoLayoutInView(self.controlView)
                .left(self.controlView.layoutMarginsGuide.leadingAnchor)
                .fillY(self.controlView.layoutMarginsGuide)
                .width(64)
                .activate()

            let globe = UIImage(
                systemName: "globe",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16)
            )!
            self.nextKeyboardButton!.setImage(globe, for: .normal)
            self.nextKeyboardButton!.tintColor = .label
            self.nextKeyboardButton!.backgroundColor = .systemFill
            self.nextKeyboardButton!.layer.cornerRadius = 5
            self.nextKeyboardButton!.addTarget(
                self,
                action: #selector(self.handleInputModeList(from:with:)),
                for: .allTouchEvents
            )
        }

        self.stickerPackPageControl = UIPageControl()
        self.stickerPackPageControl
            .autoLayoutInView(self.controlView)
            .leftAtLeast(self.controlView.layoutMarginsGuide.leadingAnchor)
            .leftAtLeast(self.nextKeyboardButton?.trailingAnchor)
            .rightAtMost(self.controlView.layoutMarginsGuide.trailingAnchor)
            .centerX(self.controlView.layoutMarginsGuide.centerXAnchor, priority: .defaultHigh)
            .centerY(self.controlView.layoutMarginsGuide.centerYAnchor)
            .activate()
        self.stickerPackPageControl.pageIndicatorTintColor = .systemFill
        self.stickerPackPageControl.currentPageIndicatorTintColor = .accent

        self.stickerPackPageViewController = ArrayPageViewController()
        self.addChild(stickerPackPageViewController)
        self.stickerPackPageViewController.view
            .autoLayoutInView(self.touchableView)
            .fillX(self.touchableView.safeAreaLayoutGuide)
            .top(self.touchableView.safeAreaLayoutGuide.topAnchor)
            .bottom(self.controlView.topAnchor)
            .activate()
        self.stickerPackPageViewController.didMove(toParent: self)
        self.stickerPackPageViewController.animatePageTransitions = false
        self.stickerPackPageViewController.pageControl = self.stickerPackPageControl

        // Ensure banners display over everything else
        self.touchableView.bringSubviewToFront(self.bannerView)

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try StickerFileManager.main.stickerPacks() }
            DispatchQueue.main.async {
                self.didLoadStickerPacks(result: result)
            }
        }
    }

    private func didLoadStickerPacks(result: Result<[StickerPack], Error>) {
        switch result {
        case .success(let stickerPacks):
            let dataSource = StickerPageViewControllerDataSource(
                stickerPacks: stickerPacks,
                stickerPickerDelegate: self
            )
            self.stickerPackDataSource = dataSource
            self.stickerPackPageViewController.dataSource = dataSource
            self.stickerPackPageViewController.emptyText = L("no_stickers")
        case .failure(let err):
            logger.error("Failed to load stickers: \(err.localizedDescription)")
            let dataSource = StickerPageViewControllerDataSource(
                stickerPacks: [],
                stickerPickerDelegate: self
            )
            self.stickerPackDataSource = dataSource
            self.stickerPackPageViewController.dataSource = dataSource
            self.stickerPackPageViewController.emptyText = F(
                "failed_load_stickers",
                err.localizedDescription
            )
        }
    }

    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack,
        longPress: Bool
    ) {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.selectionChanged()

        // Hack to make the next keyboard button go to the previously selected
        // keyboard instead of the next one (iOS seems go to the next one only
        // if you didn't input anything with the keyboard)
        self.textDocumentProxy.insertText("")

        if !self.hasFullAccess {
            self.bannerView.show(
                text: L("full_access_required"),
                style: .error
            )
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result {
                try self.loadStickerData(stickerFile: stickerFile, forceOriginal: longPress)
            }
            DispatchQueue.main.async {
                self.didLoadStickerData(stickerFile: stickerFile, result: result)
            }
        }
    }

    private func loadStickerData(
        stickerFile: StickerFile,
        forceOriginal: Bool
    ) throws -> (Data, UTType) {
        // We return the original sticker under the following conditions:
        //
        // 1. User absolutely wants the original (by long tapping)
        // 2. Image is animated (we don't support resizing those)
        // 3. Resize image option is disabled and the image format is widely supported
        //
        // This path is faster since it doesn't involve decoding the image;
        // we just push bits around.
        let isAnimatedFormat = ImageLoader.animatedImageFormats.contains(stickerFile.utiType)
        let isSafeFormat = ImageLoader.safeImageFormats.contains(stickerFile.utiType)
        let wantsResize = PreferenceManager.shared.resizeStickers()
        if forceOriginal || isAnimatedFormat || (isSafeFormat && !wantsResize) {
            let data = try Data(contentsOf: stickerFile.url)
            return (data, stickerFile.utiType)
        }

        // Otherwise, either the image needs resizing, or it's in an "unsafe"
        // format (like HEIC). Go through the image loader and turn it into a
        // PNG. Note that we limit to 512x512 here even if the user did not want
        // resizing, because performance quickly degrades with larger images.
        let data = try ImageLoader.loadImageAsPNG(
            url: stickerFile.url,
            resizeParams: ImageResizeParams(
                pointSize: CGSize(width: 512, height: 512),
                scale: 1.0,
                mode: .fit
            )
        )
        return (data, .png)
    }

    private func didLoadStickerData(
        stickerFile: StickerFile,
        result: Result<(Data, UTType), Error>
    ) {
        switch result {
        case .success(let (data, type)):
            UIPasteboard.general.setData(
                data,
                forPasteboardType: type.identifier
            )

            if PreferenceManager.shared.autoSwitchKeyboard() {
                self.advanceToNextInputMode()
            } else {
                self.bannerView.show(
                    text: F("copied_to_clipboard", stickerFile.name),
                    style: .normal
                )
            }
        case .failure(let error):
            logger.error(
                "Failed to copy \(stickerFile.name): \(error.localizedDescription)"
            )
            self.bannerView.show(
                text: F("failed_copy_to_clipboard", stickerFile.name),
                style: .error
            )
        }
    }
}
