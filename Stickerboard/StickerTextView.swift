import UIKit

/**
 * UITextView that allows image insertion; also tries to show the
 * sticker keyboard instead of the default user selected keyboard.
 */
class StickerTextView: UITextView {
    override var textInputMode: UITextInputMode? {
        for tim in UITextInputMode.activeInputModes {
            if tim.primaryLanguage == "mis" {
                return tim
            }
        }
        return super.textInputMode
    }

    required init?(coder: NSCoder) {
        abort()
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.allowsEditingTextAttributes = true
    }
}
