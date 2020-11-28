import UIKit

class MainViewController
    : UIViewController
    , StickerPickerViewDelegate
    , UIPageViewControllerDelegate
{
    var stickerView: TouchableTransparentView!
    var stickerTabViewController: UIPageViewController!
    var stickerPackNameLabel: UILabel!
    var testTextField: UITextField!
    var importButton: UIButton!
    var stickerTabDataSource: StickerPageViewControllerDataSource!

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if !completed {
            return
        }
        let viewController = pageViewController.viewControllers![0] as! StickerPickerViewController
        self.stickerPackNameLabel.text = viewController.stickerPack.name
    }

    override func loadView() {
        print("loadView")

        self.view = UIView()
        self.view.backgroundColor = .systemBackground

        self.stickerView = TouchableTransparentView()
        self.view.addSubview(self.stickerView)
        self.stickerView
            .autoLayout()
            .fillX(self.view.safeAreaLayoutGuide)
            .top(self.view.safeAreaLayoutGuide.topAnchor)
            .height(261)
            .activate()

        self.stickerTabViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        self.addChild(self.stickerTabViewController)
        self.stickerView.addSubview(self.stickerTabViewController.view)
        self.stickerTabViewController.view
            .autoLayout()
            .fill(self.stickerView.safeAreaLayoutGuide)
            .activate()
        self.stickerTabViewController.didMove(toParent: self)
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.systemFill
        appearance.currentPageIndicatorTintColor = UIColor.accent

        self.stickerPackNameLabel = UILabel()
        self.view.addSubview(self.stickerPackNameLabel)
        self.stickerPackNameLabel
            .autoLayout()
            .fillX(self.view.layoutMarginsGuide)
            .below(self.stickerTabViewController.view)
            .activate()

        self.testTextField = UITextField()
        self.testTextField.allowsEditingTextAttributes = true
        self.view.addSubview(self.testTextField)
        self.testTextField
            .autoLayout()
            .fillX(self.view.layoutMarginsGuide)
            .below(self.stickerPackNameLabel)
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
        self.stickerTabViewController.delegate = self
        self.stickerTabViewController.dataSource = self.stickerTabDataSource
        self.stickerTabViewController.setViewControllers(
            [self.stickerTabDataSource.initialViewController()],
            direction: .forward,
            animated: false
        )
    }

    @objc
    func importStickersButtonClicked() {
        try! StickerFileManager.main.importFromDocuments()
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
        let data = try! Data(contentsOf: stickerFile.url)
        UIPasteboard.general.setData(data, forPasteboardType: stickerFile.utiType.identifier)
    }

    override func viewDidLoad() {
        print("viewDidLoad")

        self.title = "Stickerboard"
        self.testTextField.borderStyle = .roundedRect
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
