import UIKit

class KeyboardViewController: UIInputViewController {
    var nextKeyboardButton: UIButton!

    override func loadView() {
        super.loadView()
        let globe = UIImage(systemName: "globe")!
        self.nextKeyboardButton = UIButton(type: .system)
        self.nextKeyboardButton.setImage(globe, for: .normal)
        self.nextKeyboardButton.tintColor = .label
        self.nextKeyboardButton.backgroundColor = .systemFill
        self.nextKeyboardButton.layer.cornerRadius = 5
        self.nextKeyboardButton.layer.masksToBounds = false
        self.nextKeyboardButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        self.inputView!.addSubview(self.nextKeyboardButton)
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
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }
}
