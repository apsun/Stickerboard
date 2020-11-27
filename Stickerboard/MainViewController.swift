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
        NSLayoutConstraint.activate([
            self.stickerView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.stickerView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            self.stickerView.heightAnchor.constraint(equalToConstant: 400),
        ])

        self.stickerPickerViewController = StickerPickerViewController(delegate: self)
        self.addChild(self.stickerPickerViewController)
        self.stickerView.addSubview(self.stickerPickerViewController.view)
        self.stickerPickerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.stickerPickerViewController.view.widthAnchor.constraint(
                equalTo: self.stickerView.widthAnchor
            ),
            self.stickerPickerViewController.view.heightAnchor.constraint(
                equalTo: self.stickerView.heightAnchor
            ),
        ])
        self.stickerPickerViewController.didMove(toParent: self)

        self.testTextField = UITextField()
        self.testTextField.allowsEditingTextAttributes = true
        self.testTextField.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.testTextField)
        NSLayoutConstraint.activate([
            self.testTextField.leftAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leftAnchor),
            self.testTextField.rightAnchor.constraint(equalTo: self.view.layoutMarginsGuide.rightAnchor),
            self.testTextField.topAnchor.constraint(
                equalTo: self.stickerView.bottomAnchor,
                constant: 8
            )
        ])

        self.importButton = UIButton(type: .system)
        self.importButton.setTitle("Import stickers", for: .normal)
        self.importButton.addTarget(self, action: #selector(importStickersButtonClicked), for: .touchUpInside)
        self.importButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.importButton)
        NSLayoutConstraint.activate([
            self.importButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 8),
            self.importButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -8),
            self.importButton.topAnchor.constraint(
                equalTo: self.testTextField.bottomAnchor,
                constant: 8
            )
        ])
    }

    @objc
    func importStickersButtonClicked() {
        try! StickerFileManager.main.importFromDocuments()
        let packs = try! StickerFileManager.main.stickerPacks()
        self.stickerPickerViewController.stickerPack = packs[0]
    }

    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack
    ) {
        UIPasteboard.general.image = UIImage(contentsOfFile: stickerFile.url.path)
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
