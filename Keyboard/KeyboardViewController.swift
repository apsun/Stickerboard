import UIKit
import UniformTypeIdentifiers
import Common

class KeyboardViewController
    : UIInputViewController
    , StickerPickerViewDelegate
{
    private var touchableView: TouchableTransparentView!
    private var bannerViewController: BannerViewController!
    private var stickerPackPageViewController: ArrayPageViewController!
    private var stickerPackDataSource: StickerPageViewControllerDataSource?
    private var controlView: UIView!
    private var nextKeyboardButton: KeyboardButton?
    private var stickerPackPageControl: UIPageControl!
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        // As seen in: https://stackoverflow.com/questions/39694039
        // Basically, it seems that the parent view resizes its height to fit
        // the keyboard contents, which means that constraining our own height
        // to equal the parent height will cause a chicken and egg problem.
        // Thus, we need to set an explicit keyboard height ourselves.
        //
        // Since we're disabling autoresizing mask constraints, we need to also
        // set the width to equal the parent, which we won't know in viewDidLoad.
        // Hence, we delay adding the constraints to viewDidAppear.
        self.view.translatesAutoresizingMaskIntoConstraints = false

        self.touchableView = TouchableTransparentView()
        self.touchableView
            .autoLayoutInView(self.view)
            .fill(self.view.safeAreaLayoutGuide)
            .activate()

        self.bannerViewController = BannerViewController()
        self.addChild(self.bannerViewController)
        self.bannerViewController.view
            .autoLayoutInView(self.touchableView)
            .fill(self.touchableView.safeAreaLayoutGuide)
            .activate()
        self.bannerViewController.didMove(toParent: self)

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

        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.systemFill
        appearance.currentPageIndicatorTintColor = UIColor.accent

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

        // TODO: This could probably be made more elegant... maybe use UIStackView?
        var leftAnchor = self.controlView.layoutMarginsGuide.leadingAnchor
        if let nextKeyboardButton = self.nextKeyboardButton {
            leftAnchor = nextKeyboardButton.trailingAnchor
        }

        self.stickerPackPageControl = UIPageControl()
        self.stickerPackPageControl
            .autoLayoutInView(self.controlView)
            .left(leftAnchor)
            .right(self.controlView.layoutMarginsGuide.trailingAnchor)
            .centerY(self.controlView.layoutMarginsGuide.centerYAnchor)
            .activate()
        self.stickerPackPageViewController.pageControl = self.stickerPackPageControl

        // Ensure banners display over everything else
        self.touchableView.bringSubviewToFront(self.bannerViewController.view)

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
            self.stickerPackPageViewController.emptyText = F(
                "failed_load_stickers",
                err.localizedDescription
            )
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let parent = self.view.superview!
        self.widthConstraint = self.view.widthAnchor.constraint(equalTo: parent.widthAnchor)
        self.heightConstraint = self.view.heightAnchor.constraint(equalToConstant: 261)

        NSLayoutConstraint.activate([
            self.widthConstraint!,
            self.heightConstraint!,
        ])
    }

    override func viewWillDisappear(_ animated: Bool) {
        NSLayoutConstraint.deactivate([
            self.widthConstraint!,
            self.heightConstraint!,
        ])

        self.widthConstraint = nil
        self.heightConstraint = nil

        super.viewWillDisappear(animated)
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
            self.bannerViewController.showBanner(
                text: F("copied_to_clipboard", stickerFile.name),
                style: .normal
            )
        case .failure(let error):
            logger.error(
                "Failed to copy \(stickerFile.name): \(error.localizedDescription)"
            )
            self.bannerViewController.showBanner(
                text: F("failed_copy_to_clipboard", stickerFile.name),
                style: .error
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
            self.bannerViewController.showBanner(
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
}
