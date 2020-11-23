import UIKit

class KeyboardViewController: UIInputViewController, StickerCollectionViewDelegate {
    var nextKeyboardButton: UIButton!
    var stickerView: UIView!
    var stickerCollectionViewController: StickerCollectionViewController!

    override func loadView() {
        super.loadView()
        // let globe = UIImage(systemName: "globe")!
        // self.nextKeyboardButton = UIButton(type: .system)
        // self.nextKeyboardButton.setImage(globe, for: .normal)
        // self.nextKeyboardButton.tintColor = .label
        // self.nextKeyboardButton.backgroundColor = .systemFill
        // self.nextKeyboardButton.layer.cornerRadius = 5
        // self.nextKeyboardButton.layer.masksToBounds = false
        // self.nextKeyboardButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right:  8)
        // self.nextKeyboardButton.sizeToFit()
        // self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        // self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)),  for: //.allTouchEvents)
        // self.inputView!.addSubview(self.nextKeyboardButton)

        self.stickerView = TouchableTransparentView()
        self.view.addSubview(self.stickerView)
        self.stickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.stickerView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.stickerView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            self.stickerView.heightAnchor.constraint(equalTo: self.view.heightAnchor),
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
    }

    func stickerCollectionView(
        _ sender: StickerCollectionViewController,
        didSelect sticker: UIImage
    ) {
        UIPasteboard.general.image = sticker
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
    }
}
