import UIKit

class KeyboardViewController
    : UIInputViewController
    , StickerPickerViewDelegate
{
    var touchableView: TouchableTransparentView!
    var nextKeyboardButton: UIButton!
    var bannerContainer: BannerContainerViewController!
    var stickerTabViewController: UIPageViewController!
    var stickerTabDataSource: StickerPageViewControllerDataSource?
    var needFullAccessView: UILabel!
    var heightConstraint: NSLayoutConstraint?
    var widthConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.translatesAutoresizingMaskIntoConstraints = false

        if !self.hasFullAccess {
            self.needFullAccessView = UILabel()
            self.view.addSubview(self.needFullAccessView)
            self.needFullAccessView.numberOfLines = 0
            self.needFullAccessView.lineBreakMode = .byClipping
            self.needFullAccessView.adjustsFontSizeToFitWidth = true
            self.needFullAccessView.text = """
                Please enable full access in the iOS keyboard settings in order to use this app

                → Settings
                → General
                → Keyboards
                → Stickerboard
                → Allow Full Access
                """
            self.needFullAccessView.textAlignment = .center
            self.needFullAccessView.autoLayout().fill(self.view.safeAreaLayoutGuide).activate()
            return
        }

        self.touchableView = TouchableTransparentView()
        self.view.addSubview(self.touchableView)
        self.touchableView
            .autoLayout()
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
        self.touchableView.addSubview(self.bannerContainer.view)
        self.bannerContainer.didMove(toParent: self)
        self.bannerContainer.setContentViewController(self.stickerTabViewController)
        self.bannerContainer.view
            .autoLayout()
            .fill(self.touchableView.safeAreaLayoutGuide)
            .activate()

        self.nextKeyboardButton = UIButton(type: .system)
        self.nextKeyboardButton.setImage(UIImage(systemName: "globe")!, for: .normal)
        self.nextKeyboardButton.tintColor = .label
        self.nextKeyboardButton.backgroundColor = .systemFill
        self.nextKeyboardButton.layer.cornerRadius = 5
        self.nextKeyboardButton.layer.masksToBounds = false
        self.nextKeyboardButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right:  8)
        self.bannerContainer.view.addSubview(self.nextKeyboardButton)
        self.nextKeyboardButton
           .autoLayout()
           .left(self.bannerContainer.view.safeAreaLayoutGuide.leadingAnchor)
           .bottom(self.bannerContainer.view.safeAreaLayoutGuide.bottomAnchor)
           .activate()
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

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

    override func updateViewConstraints() {
        // As seen in: https://stackoverflow.com/questions/39694039
        // Basically, it seems that the parent view resizes its height to fit
        // the keyboard contents, which means that constraining our own height
        // to equal the parent height will cause a chicken and egg problem.
        // Thus, we need to set an explicit keyboard height ourselves.
        //
        // Since we're disabling autoresizing mask constraints, we need to also
        // set the width to equal the parent, which we won't know in viewDidLoad.
        // Hence we're adding the constraints here, where the superview is known.
        if self.heightConstraint == nil {
            self.heightConstraint = self.view.heightAnchor.constraint(equalToConstant: 261)
            self.heightConstraint!.isActive = true
        }
        if self.widthConstraint == nil {
            self.widthConstraint = self.view.widthAnchor.constraint(
                equalTo: self.view.superview!.widthAnchor
            )
            self.widthConstraint!.isActive = true
        }
        super.updateViewConstraints()
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
