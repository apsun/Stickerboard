import UIKit

/**
 * Controls the banner style (i.e. background color).
 */
enum BannerStyle {
    case normal
    case error
}

/**
 * View controller that displays a notification banner at the top
 * of its view.
 */
class BannerViewController: UIViewController {
    private var bannerBackgroundView: UIView!
    private var bannerPaddingView: UIView!
    private var bannerLabel: UILabel!
    private var bannerHiddenConstraint: NSLayoutConstraint!
    private var bannerVisibleConstraint: NSLayoutConstraint!

    /**
     * If non-nil, banners will automatically hide after this amount of time.
     */
    var bannerTimeout: TimeInterval? = 3

    /**
     * Returns the amount of vertical space the banner will take up on screen
     * when it is shown.
     */
    var bannerHeight: CGFloat {
        self.view.layoutIfNeeded()
        return self.bannerPaddingView.bounds.height
    }

    override func loadView() {
        self.view = UIView()
    }

    override func viewDidLoad() {
        self.view.clipsToBounds = true
        self.view.isUserInteractionEnabled = false

        // The banner background view provides an "infinite height" background
        // color container for the banner. This allows us to use spring animations
        // that overshoot the target position without leaving a gap.
        self.bannerBackgroundView = UIView()
        self.bannerBackgroundView
            .autoLayoutInView(self.view)
            .fillX(self.view.safeAreaLayoutGuide)
            .height(640)  // ought to be enough for anybody ;-)
            .activate()

        // The padding view is used to add some insets to the label. It's anchored
        // at the bottom of the background view.
        self.bannerPaddingView = UIView()
        self.bannerPaddingView
            .autoLayoutInView(self.bannerBackgroundView)
            .fillX(self.bannerBackgroundView.safeAreaLayoutGuide)
            .bottom(self.bannerBackgroundView.safeAreaLayoutGuide.bottomAnchor)
            .activate()
        self.bannerPaddingView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        // This is the banner text view. It fills the padding view (minus the insets).
        self.bannerLabel = UILabel()
        self.bannerLabel
            .autoLayoutInView(self.bannerPaddingView)
            .fill(self.bannerPaddingView.layoutMarginsGuide)
            .activate()
        self.bannerLabel.lineBreakMode = .byTruncatingMiddle
        self.bannerLabel.textAlignment = .center
        self.setBannerText("")

        // Create the banner position constraints. We don't use the constant:
        // form because we want to adapt to screen/text size changes automatically.
        // Instead we just swap between these two constraints.
        self.bannerHiddenConstraint = self.bannerPaddingView.bottomAnchor.constraint(
            equalTo: self.view.topAnchor
        )
        self.bannerVisibleConstraint = self.bannerPaddingView.topAnchor.constraint(
            equalTo: self.view.topAnchor
        )
        self.bannerHiddenConstraint.isActive = true
    }

    /**
     * Returns an appropriate background color for the banner.
     */
    private func backgroundColorForStyle(_ style: BannerStyle) -> UIColor {
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
    private func setBannerText(_ text: String) {
        if text == "" {
            self.bannerLabel.text = " "
        } else {
            self.bannerLabel.text = text
        }
    }

    /**
     * Shows a banner with the given text, replacing the existing banner
     * if it is currently being shown.
     */
    func showBanner(text: String, style: BannerStyle) {
        let bannerColor = self.backgroundColorForStyle(style)
        let textColor = UIColor.label.contrastingBackground(bannerColor)

        self.bannerBackgroundView.backgroundColor = bannerColor
        self.bannerLabel.textColor = textColor
        self.setBannerText(text)

        self.bannerVisibleConstraint.isActive = false
        self.bannerHiddenConstraint.isActive = true
        self.view.layoutIfNeeded()

        // Reset automatic hide timeout
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(self.hideBanner),
            object: nil
        )

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                self.bannerHiddenConstraint.isActive = false
                self.bannerVisibleConstraint.isActive = true
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                if let timeout = self.bannerTimeout {
                    self.perform(#selector(self.hideBanner), with: nil, afterDelay: timeout)
                }
            }
        )
    }

    /**
     * Hides the banner if it is currently being shown.
     */
    @objc
    func hideBanner() {
        self.view.layoutIfNeeded()

        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(self.hideBanner),
            object: nil
        )

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                self.bannerVisibleConstraint.isActive = false
                self.bannerHiddenConstraint.isActive = true
                self.view.layoutIfNeeded()
            }
        )
    }
}
