import UIKit

/**
 * This is a dirty workaround for the fact that making a view with a
 * transparent background causes it to ignore touch inputs. Without this,
 * the collection view will fail to scroll if you drag it by the background.
 */
public class TouchableTransparentView: UIView {
    override open class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }

    required init?(coder: NSCoder) {
        abort()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let gradientLayer = self.layer as! CAGradientLayer
        gradientLayer.colors = [CGColor(gray: 0, alpha: 0)]
    }
}
