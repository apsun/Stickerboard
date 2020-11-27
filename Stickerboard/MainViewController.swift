import UIKit

class MainViewController : UIViewController, StickerCollectionViewDelegate {
    var testTextField: UITextField!
    var stickerView: TouchableTransparentView!
    var stickerCollectionViewController: StickerCollectionViewController!
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

        self.stickerCollectionViewController = StickerCollectionViewController(delegate: self)
        self.addChild(self.stickerCollectionViewController)
        self.stickerView.addSubview(self.stickerCollectionViewController.view)
        self.stickerCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.stickerCollectionViewController.view.widthAnchor.constraint(
                equalTo: self.stickerView.widthAnchor
            ),
            self.stickerCollectionViewController.view.heightAnchor.constraint(
                equalTo: self.stickerView.heightAnchor
            ),
        ])
        self.stickerCollectionViewController.didMove(toParent: self)

        self.testTextField = UITextField()
        self.testTextField.allowsEditingTextAttributes = true
        self.testTextField.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.testTextField)
        NSLayoutConstraint.activate([
            self.testTextField.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 8),
            self.testTextField.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -8),
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
        try! StickerDirectoryManager.main.importFromDocuments()
    }

    func stickerCollectionView(
        _ sender: StickerCollectionViewController,
        didSelect stickerURL: URL
    ) {
        UIPasteboard.general.image = UIImage(contentsOfFile: stickerURL.path)
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
