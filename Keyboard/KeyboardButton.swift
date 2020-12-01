import UIKit

/**
 * UIButton with a drop shadow in the style of the iOS system keyboard.
 */
class KeyboardButton: UIButton {
    /**
     * Adds a drop shadow to the bottom of the button.
     */
    private func applyDropShadow(
        size: CGFloat,
        color: UIColor,
        opacity: Float
    ) {
        let layer = self.layer
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = .zero
        layer.shadowRadius = 0
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.contentsScale = UIScreen.main.scale

        // Add a shadow in the shape of the button, translated by the size.
        // This is enough if the button is opaque, but if the button is
        // transparent the shadow will be visible behind the button...
        let path = UIBezierPath(
            roundedRect: self.bounds.offsetBy(dx: 0, dy: size),
            cornerRadius: layer.cornerRadius
        )

        // ... so here we undo the portion of the shadow behind the
        // button by tracing the path in reverse, insetting by the shadow
        // size so that we only affect the portion behind the button.
        path.append(
            UIBezierPath(
                roundedRect: self.bounds.inset(
                    by: UIEdgeInsets(top: size, left: 0, bottom: 0, right: 0)
                ),
                cornerRadius: layer.cornerRadius
            ).reversing()
        )

        layer.shadowPath = path.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.applyDropShadow(size: 1, color: .black, opacity: 0.3)
    }
}
