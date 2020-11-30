import UIKit

class MainViewController
    : UIViewController
    , StickerPickerViewDelegate
{
    private var touchableView: TouchableTransparentView!
    private var bannerViewController: BannerViewController!
    private var stickerTabViewController: UIPageViewController!
    private var stickerTabDataSource: StickerPageViewControllerDataSource?
    private var testTextField: UITextField!
    private var importButton: UIButton!

    override func loadView() {
        print("loadView")

        self.view = UIView()
    }

    override func viewDidLoad() {
        print("viewDidLoad")

        self.view.backgroundColor = .systemBackground
        self.title = "Stickerboard"

        self.touchableView = TouchableTransparentView()
        self.touchableView
            .autoLayoutInView(self.view)
            .fillX(self.view.safeAreaLayoutGuide)
            .top(self.view.safeAreaLayoutGuide.topAnchor)
            .height(261)
            .activate()

        self.bannerViewController = BannerViewController()
        self.addChild(self.bannerViewController)
        self.bannerViewController.view
            .autoLayoutInView(self.touchableView)
            .fill(self.touchableView.safeAreaLayoutGuide)
            .activate()
        self.bannerViewController.didMove(toParent: self)

        self.stickerTabViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        self.addChild(self.stickerTabViewController)
        self.stickerTabViewController.view
            .autoLayoutInView(self.touchableView)
            .fill(self.touchableView.safeAreaLayoutGuide)
            .activate()
        self.stickerTabViewController.didMove(toParent: self)
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.systemFill
        appearance.currentPageIndicatorTintColor = UIColor.accent

        self.testTextField = UITextField()
        self.testTextField
            .autoLayoutInView(self.view)
            .fillX(self.view.layoutMarginsGuide)
            .below(self.bannerViewController.view)
            .activate()
        self.testTextField.borderStyle = .roundedRect
        self.testTextField.allowsEditingTextAttributes = true

        self.importButton = UIButton(type: .system)
        self.importButton
            .autoLayoutInView(self.view)
            .fillX(self.view.layoutMarginsGuide)
            .below(self.testTextField)
            .activate()
        self.importButton.setTitle("Import stickers", for: .normal)
        self.importButton.addTarget(self, action: #selector(importStickersButtonClicked), for: .touchUpInside)

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

        self.touchableView.bringSubviewToFront(self.bannerViewController.view)
    }

    @objc
    func importStickersButtonClicked() {
        do {
            try StickerFileManager.main.importFromDocuments()
        } catch {
            self.bannerViewController.showBanner(
                text: "Failed to import stickers",
                style: .error
            )
            return
        }
        self.bannerViewController.showBanner(text: "Successfully imported stickers")
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

    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack
    ) {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.selectionChanged()

        let data: Data
        do {
            data = try Data(contentsOf: stickerFile.url)
        } catch {
            self.bannerViewController.showBanner(
                text: "Failed to load '\(stickerFile.name)'",
                style: .error
            )
            return
        }
        UIPasteboard.general.setData(data, forPasteboardType: stickerFile.utiType.identifier)
        self.bannerViewController.showBanner(text: "Copied '\(stickerFile.name)' to the clipboard")
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear")
    }

    override func viewWillLayoutSubviews() {
        print("viewWillLayoutSubviews")
    }

    override func viewDidLayoutSubviews() {
        print("viewDidLayoutSubviews")
    }
}
