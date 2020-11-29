import UIKit

class KeyboardViewController
    : UIInputViewController
    , StickerPickerViewDelegate
{
    private var touchableView: TouchableTransparentView!
    private var nextKeyboardButton: KeyboardButton!
    private var bannerContainer: BannerContainerViewController!
    private var stickerTabViewController: UIPageViewController!
    private var stickerTabDataSource: StickerPageViewControllerDataSource?
    private var needFullAccessView: UILabel!
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

        if !self.hasFullAccess {
            self.needFullAccessView = UILabel()
            self.needFullAccessView
                .autoLayoutInView(self.view)
                .fill(self.view.safeAreaLayoutGuide)
                .activate()
            self.needFullAccessView.numberOfLines = 0
            self.needFullAccessView.lineBreakMode = .byClipping
            self.needFullAccessView.adjustsFontSizeToFitWidth = true
            self.needFullAccessView.textAlignment = .center
            self.needFullAccessView.text = """
                Please enable full access in the iOS keyboard settings in order to use this app

                → Settings
                → General
                → Keyboards
                → Stickerboard
                → Allow Full Access
                """
            return
        }

        self.touchableView = TouchableTransparentView()
        self.touchableView
            .autoLayoutInView(self.view)
            .fill(self.view.safeAreaLayoutGuide)
            .activate()

        self.stickerTabViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.systemFill
        appearance.currentPageIndicatorTintColor = UIColor.accent

        self.bannerContainer = BannerContainerViewController()
        self.addChild(self.bannerContainer)
        self.bannerContainer.view
            .autoLayoutInView(self.touchableView)
            .fill(self.touchableView.safeAreaLayoutGuide)
            .activate()
        self.bannerContainer.didMove(toParent: self)
        self.bannerContainer.setContentViewController(self.stickerTabViewController)

        self.nextKeyboardButton = KeyboardButton(type: .system)
        self.nextKeyboardButton
            .autoLayoutInView(self.bannerContainer.view)
            .left(self.bannerContainer.view.safeAreaLayoutGuide.leadingAnchor, constant: 4)
            .bottom(self.bannerContainer.view.safeAreaLayoutGuide.bottomAnchor, constant: -4)
            .height(32)
            .width(64)
            .activate()

        let globe = UIImage(
            systemName: "globe",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16)
        )!
        self.nextKeyboardButton.setImage(globe, for: .normal)
        self.nextKeyboardButton.tintColor = .label
        self.nextKeyboardButton.backgroundColor = .systemFill
        self.nextKeyboardButton.layer.cornerRadius = 5
        self.nextKeyboardButton.addTarget(
            self,
            action: #selector(handleInputModeList(from:with:)),
            for: .allTouchEvents
        )

        let stickerPacks = try! StickerFileManager.main.stickerPacks()
        if stickerPacks.isEmpty {
            self.stickerTabDataSource = nil
            self.stickerTabViewController.dataSource = nil
        } else {
            let dataSource = StickerPageViewControllerDataSource(
                stickerPacks: stickerPacks,
                stickerDelegate: self
            )
            self.stickerTabDataSource = dataSource
            self.stickerTabViewController.dataSource = dataSource
            self.stickerTabViewController.setViewControllers(
                [dataSource.initialViewController()],
                direction: .forward,
                animated: false
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

    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack
    ) {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.selectionChanged()

        // Hack to make the next keyboard button go to the previously selected
        // keyboard instead of the next one (iOS seems go to the next one only
        // if you didn't input anything with the keyboard)
        self.textDocumentProxy.insertText("")

        let data: Data
        do {
            data = try Data(contentsOf: stickerFile.url)
        } catch {
            self.bannerContainer.showBanner(
                text: "Failed to load '\(stickerFile.name)'",
                style: .error
            )
            return
        }
        UIPasteboard.general.setData(data, forPasteboardType: stickerFile.utiType.identifier)
        self.bannerContainer.showBanner(text: "Copied '\(stickerFile.name)' to the clipboard")
    }
}
