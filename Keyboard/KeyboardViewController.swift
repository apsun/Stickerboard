import UIKit
import UniformTypeIdentifiers

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

        // Start loading the actual data
        if self.hasFullAccess {
            DispatchQueue.global(qos: .userInitiated).async {
                let result = Result { try StickerFileManager.main.stickerPacks() }
                DispatchQueue.main.async {
                    self.stickerPacksDidLoad(result: result)
                }
            }
        } else {
            self.stickerPackPageViewController.emptyText = """
                Please enable full access in the iOS keyboard settings in order to use this app

                → Settings
                → Stickerboard
                → Keyboards
                """
        }
    }

    private func stickerPacksDidLoad(result: Result<[StickerPack], Error>) {
        switch result {
        case .success(let stickerPacks):
            let dataSource = StickerPageViewControllerDataSource(
                stickerPacks: stickerPacks,
                stickerPickerDelegate: self
            )
            self.stickerPackDataSource = dataSource
            self.stickerPackPageViewController.dataSource = dataSource
            self.stickerPackPageViewController.emptyText = """
                It looks like you have no stickers!

                To get started, add your stickers to the Stickerboard documents folder, then hit the import button.
                """
        case .failure(let err):
            self.stickerPackPageViewController.emptyText = """
                Something went wrong loading your stickers! Please file a bug report and include the following message:

                \(err.localizedDescription)
                """
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

    private func loadStickerData(stickerFile: StickerFile, forceOriginal: Bool) throws -> Data {
        if !forceOriginal && PreferenceManager.shared.signalMode() {
            if [UTType.png, UTType.jpeg].contains(stickerFile.utiType) {
                let image = try ImageLoader.loadImageWithAlpha(
                    url: stickerFile.url,
                    width: 512,
                    height: 512,
                    scale: 1.0,
                    mode: .fit
                )
                guard let png = image.pngData() else {
                    throw RuntimeError("Failed to convert image to PNG")
                }
                return png
            }
        }
        return try Data(contentsOf: stickerFile.url)
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

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result {
                try self.loadStickerData(stickerFile: stickerFile, forceOriginal: longPress)
            }
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    UIPasteboard.general.setData(
                        data,
                        forPasteboardType: stickerFile.utiType.identifier
                    )
                    self.bannerViewController.showBanner(
                        text: "Copied '\(stickerFile.name)' to the clipboard",
                        style: .normal
                    )
                case .failure(_):
                    self.bannerViewController.showBanner(
                        text: "Failed to load '\(stickerFile.name)'",
                        style: .error
                    )
                }
            }
        }
    }
}
