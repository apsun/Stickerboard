import UIKit

class KeyboardViewController: UIInputViewController, StickerCollectionViewDelegate {
    var nextKeyboardButton: UIButton!
    var stickerView: UIView!
    var stickerCollectionViewController: StickerCollectionViewController!
    var needFullAccessView: UILabel!
    var heightConstraint: NSLayoutConstraint?
    var widthConstraint: NSLayoutConstraint?

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

        self.stickerView = TouchableTransparentView()
        self.view.addSubview(self.stickerView)
        self.stickerView
            .autoLayout()
            .fill(self.view.safeAreaLayoutGuide)
            .activate()

        self.stickerCollectionViewController = StickerCollectionViewController(delegate: self)
        self.addChild(self.stickerCollectionViewController)
        self.stickerView.addSubview(self.stickerCollectionViewController.view)
        self.stickerCollectionViewController.view
            .autoLayout()
            .fill(self.stickerView.safeAreaLayoutGuide)
            .activate()
        self.stickerCollectionViewController.didMove(toParent: self)
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

    func stickerCollectionView(
        _ sender: StickerCollectionViewController,
        didSelect stickerURL: URL
    ) {
        UIPasteboard.general.image = UIImage(contentsOfFile: stickerURL.path)

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
