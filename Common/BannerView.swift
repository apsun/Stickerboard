import UIKit

/**
 * A drop-down banner view that displays an ephemeral message.
 */
public class BannerView: UIView {
    /**
     * Controls the banner style (i.e. background color).
     */
    public enum Style {
        case normal
        case error
    }

    private var backgroundView: UIView!
    private var paddingView: UIView!
    private var label: UILabel!
    private var hiddenConstraint: NSLayoutConstraint!
    private var visibleConstraint: NSLayoutConstraint!

    /**
     * If non-nil, banners will automatically hide after this amount of time.
     */
    public var timeout: TimeInterval? = 3

    /**
     * Controls the bottom corner radius of the banner.
     */
    public var cornerRadius: CGFloat {
        get {
            return self.backgroundView.layer.cornerRadius
        }
        set {
            self.backgroundView.layer.cornerRadius = newValue
        }
    }

    required init?(coder: NSCoder) {
        abort()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.clipsToBounds = true
        self.isUserInteractionEnabled = false

        // The banner background view provides an "infinite height" background
        // color container for the banner. This allows us to use spring animations
        // that overshoot the target position without leaving a gap.
        self.backgroundView = UIView()
        self.backgroundView
            .autoLayoutInView(self)
            .fillX(self.safeAreaLayoutGuide)
            .height(640)  // ought to be enough for anybody ;-)
            .activate()

        // The padding view is used to add some insets to the label. It's anchored
        // at the bottom of the background view.
        self.paddingView = UIView()
        self.paddingView
            .autoLayoutInView(self.backgroundView)
            .fillX(self.backgroundView.safeAreaLayoutGuide)
            .bottom(self.backgroundView.safeAreaLayoutGuide.bottomAnchor)
            .activate()
        self.paddingView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        // This is the banner text view. It fills the padding view (minus the insets).
        self.label = UILabel()
        self.label
            .autoLayoutInView(self.paddingView)
            .fill(self.paddingView.layoutMarginsGuide)
            .activate()
        self.label.lineBreakMode = .byTruncatingMiddle
        self.label.textAlignment = .center
        self.setText("")

        // Create the banner position constraints. We don't use the constant:
        // form because we want to adapt to screen/text size changes automatically.
        // Instead we just swap between these two constraints.
        self.hiddenConstraint = self.paddingView.bottomAnchor.constraint(
            equalTo: self.topAnchor
        )
        self.visibleConstraint = self.paddingView.topAnchor.constraint(
            equalTo: self.topAnchor
        )
        self.hiddenConstraint.isActive = true
    }

    /**
     * Returns an appropriate background color for the banner.
     */
    private func backgroundColorForStyle(_ style: Style) -> UIColor {
        switch style {
        case .normal:
            return .accent
        case .error:
            return .systemRed
        }
    }

    /**
     * Sets the banner text. Note that we do not allow an empty string
     * as that would collapse the whole view. At the minimum we show a
     * single space which takes up some height.
     */
    private func setText(_ text: String) {
        if text == "" {
            self.label.text = " "
        } else {
            self.label.text = text
        }
    }

    /**
     * Shows a banner with the given text, replacing the existing banner
     * if it is currently being shown.
     */
    public func show(text: String, style: Style) {
        let bannerColor = self.backgroundColorForStyle(style)
        let textColor = UIColor.label.contrastingBackground(bannerColor)

        self.backgroundView.backgroundColor = bannerColor
        self.label.textColor = textColor
        self.setText(text)

        self.visibleConstraint.isActive = false
        self.hiddenConstraint.isActive = true
        self.layoutIfNeeded()

        // Reset automatic hide timeout
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(self.hide),
            object: nil
        )

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                self.hiddenConstraint.isActive = false
                self.visibleConstraint.isActive = true
                self.layoutIfNeeded()
            },
            completion: { _ in
                if let timeout = self.timeout {
                    self.perform(#selector(self.hide), with: nil, afterDelay: timeout)
                }
            }
        )
    }

    /**
     * Hides the banner if it is currently being shown.
     */
    @objc
    public func hide() {
        self.layoutIfNeeded()

        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(self.hide),
            object: nil
        )

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                self.visibleConstraint.isActive = false
                self.hiddenConstraint.isActive = true
                self.layoutIfNeeded()
            },
            completion: { _ in
                self.backgroundView.backgroundColor = .none
                self.label.textColor = .none
                self.setText("")
            }
        )
    }
}
