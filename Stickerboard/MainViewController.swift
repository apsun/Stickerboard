import UIKit

class MainViewController
    : UIViewController
    , StickerPickerViewDelegate
{
    var touchableView: TouchableTransparentView!
    var stickerTabViewController: UIPageViewController!
    var testTextField: UITextField!
    var importButton: UIButton!
    var stickerTabDataSource: StickerPageViewControllerDataSource!
    var bannerContainer: BannerContainerViewController!

    override func loadView() {
        print("loadView")

        self.view = UIView()
    }

    override func viewDidLoad() {
        print("viewDidLoad")

        self.view.backgroundColor = .systemBackground
        self.title = "Stickerboard"

        self.touchableView = TouchableTransparentView()
        self.view.addSubview(self.touchableView)
        self.touchableView
            .autoLayout()
            .fillX(self.view.safeAreaLayoutGuide)
            .top(self.view.safeAreaLayoutGuide.topAnchor)
            .height(261)
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

        self.testTextField = UITextField()
        self.testTextField.borderStyle = .roundedRect
        self.testTextField.allowsEditingTextAttributes = true
        self.view.addSubview(self.testTextField)
        self.testTextField
            .autoLayout()
            .fillX(self.view.layoutMarginsGuide)
            .below(self.bannerContainer.view)
            .activate()

        self.importButton = UIButton(type: .system)
        self.importButton.setTitle("Import stickers", for: .normal)
        self.importButton.addTarget(self, action: #selector(importStickersButtonClicked), for: .touchUpInside)
        self.view.addSubview(self.importButton)
        self.importButton
            .autoLayout()
            .fillX(self.view.layoutMarginsGuide)
            .below(self.testTextField)
            .activate()

        let stickerPacks = try! StickerFileManager.main.stickerPacks()
        self.stickerTabDataSource = StickerPageViewControllerDataSource(
            stickerPacks: stickerPacks,
            stickerDelegate: self
        )
        self.stickerTabViewController.dataSource = self.stickerTabDataSource
        self.stickerTabViewController.setViewControllers(
            [self.stickerTabDataSource.initialViewController()],
            direction: .forward,
            animated: false
        )
    }

    @objc
    func importStickersButtonClicked() {
        do {
            try StickerFileManager.main.importFromDocuments()
        } catch {
            self.bannerContainer.showBanner(
                text: "Failed to import stickers",
                style: .error
            )
            return
        }
        self.bannerContainer.showBanner(text: "Successfully imported stickers")
        let stickerPacks = try! StickerFileManager.main.stickerPacks()
        self.stickerTabDataSource = StickerPageViewControllerDataSource(
            stickerPacks: stickerPacks,
            stickerDelegate: self
        )
        self.stickerTabViewController.dataSource = self.stickerTabDataSource
        self.stickerTabViewController.setViewControllers(
            [self.stickerTabDataSource.initialViewController()],
            direction: .reverse,
            animated: true
        )
    }

    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack
    ) {
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
