import UIKit

class MainViewController : UIViewController, StickerPickerViewDelegate {
    var stickerView: TouchableTransparentView!
    var stickerPickerViewController: StickerPickerViewController!
    var testTextField: UITextField!
    var importButton: UIButton!

    override func loadView() {
        print("loadView")

        self.view = UIView()
        self.view.backgroundColor = .systemBackground

        self.stickerView = TouchableTransparentView()
        self.view.addSubview(self.stickerView)
        self.stickerView.translatesAutoresizingMaskIntoConstraints = false
        self.stickerView
            .autoLayout()
            .fillX(self.view.safeAreaLayoutGuide)
            .top(self.view.safeAreaLayoutGuide.topAnchor)
            .height(261)
            .activate()

        self.stickerPickerViewController = StickerPickerViewController(delegate: self)
        self.addChild(self.stickerPickerViewController)
        self.stickerView.addSubview(self.stickerPickerViewController.view)
        self.stickerPickerViewController.view
            .autoLayout()
            .fill(self.stickerView.safeAreaLayoutGuide)
            .activate()
        self.stickerPickerViewController.didMove(toParent: self)

        self.testTextField = UITextField()
        self.testTextField.allowsEditingTextAttributes = true
        self.view.addSubview(self.testTextField)
        self.testTextField
            .autoLayout()
            .fillX(self.view.layoutMarginsGuide)
            .below(self.stickerPickerViewController.view)
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
    }

    @objc
    func importStickersButtonClicked() {
        try! StickerFileManager.main.importFromDocuments()
        let pack = try! StickerFileManager.main.singleStickerPack()
        self.stickerPickerViewController.stickerPack = pack
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
