import UIKit

class KeyboardViewController: UIInputViewController, StickerCollectionViewDelegate {
    var nextKeyboardButton: UIButton!
    var stickerView: UIView!
    var stickerCollectionViewController: StickerCollectionViewController!
    var needFullAccessView: UILabel!

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
        // self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        // self.view.addSubview(self.nextKeyboardButton)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Unless we explicitly set a height for the keyboard view, it will
        // randomly change sizes for no apparent reason.
        self.view.heightAnchor.constraint(equalToConstant: 216).isActive = true

        if !self.hasFullAccess {
            self.needFullAccessView = UILabel()
            self.view.addSubview(self.needFullAccessView)
            self.needFullAccessView.numberOfLines = 0
            self.needFullAccessView.lineBreakMode = .byClipping
            self.needFullAccessView.adjustsFontSizeToFitWidth = true
            self.needFullAccessView.text = "Please enable full access in the iOS keyboard settings in order to use this app\n\n→ Settings\n→ Stickerboard\n→ Keyboards\n→ Allow Full Access"
            self.needFullAccessView.textAlignment = .center
            self.needFullAccessView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.needFullAccessView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20),
                self.needFullAccessView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
                self.needFullAccessView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
                self.needFullAccessView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            ])
            return
        }

        self.stickerView = TouchableTransparentView()
        self.view.addSubview(self.stickerView)
        self.stickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
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

        // Hack to make the next keyboard button go to the previously selected
        // keyboard instead of the next one (iOS seems go to the next one only
        // if you didn't input anything with the keyboard)
        self.textDocumentProxy.insertText("")
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
    }
}
