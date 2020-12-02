import UIKit

class MainViewController: UIViewController {
    private var bannerViewController: BannerViewController!
    private var testTextField: UITextField!
    private var importButton: UIButton!

    override func loadView() {
        self.view = UIView()
    }

    override func viewDidLoad() {
        self.view.backgroundColor = .systemBackground
        self.title = "Stickerboard"

        self.bannerViewController = BannerViewController()
        self.addChild(self.bannerViewController)
        self.bannerViewController.view
            .autoLayoutInView(self.view)
            .fill(self.view.safeAreaLayoutGuide)
            .activate()
        self.bannerViewController.didMove(toParent: self)

        self.testTextField = UITextField()
        self.testTextField
            .autoLayoutInView(self.view)
            .top(self.view.safeAreaLayoutGuide.topAnchor, constant: 20)
            .left(self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
            .right(self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
            .activate()
        self.testTextField.borderStyle = .roundedRect
        self.testTextField.allowsEditingTextAttributes = true

        self.importButton = UIButton(type: .system)
        self.importButton
            .autoLayoutInView(self.view)
            .below(self.testTextField)
            .left(self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
            .right(self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
            .activate()
        self.importButton.setTitle("Import stickers", for: .normal)
        self.importButton.addTarget(
            self,
            action: #selector(importStickersButtonClicked),
            for: .touchUpInside
        )

        self.view.bringSubviewToFront(self.bannerViewController.view)
    }

    @objc
    private func importStickersButtonClicked() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try StickerFileManager.main.importFromDocuments() }
            DispatchQueue.main.async {
                switch result {
                case .success(let count):
                    self.bannerViewController.showBanner(
                        text: "Successfully imported \(count) sticker(s)",
                        style: .normal
                    )
                case .failure(_):
                    self.bannerViewController.showBanner(
                        text: "Failed to import stickers!",
                        style: .error
                    )
                }
            }
        }
    }
}
