import UIKit

/**
 * Builder object to help generate auto layout constraints.
 */
class AutoLayoutBuilder {
    private var constraints: [NSLayoutConstraint] = []
    private let view: UIView

    init(_ view: UIView) {
        self.view = view
    }

    /**
     * Adds an arbitrary pre-generated constraint to the view.
     */
    func constraint(_ constraint: NSLayoutConstraint) -> AutoLayoutBuilder {
        self.constraints.append(constraint)
        return self
    }

    /**
     * Anchors the leading edge of this view to the given point.
     */
    func left(_ left: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> AutoLayoutBuilder {
        return self.constraint(self.view.leadingAnchor.constraint(equalTo: left, constant: constant))
    }

    /**
     * Anchors the top edge of this view to the given point.
     */
    func top(_ top: NSLayoutYAxisAnchor, constant: CGFloat = 0) -> AutoLayoutBuilder {
        return self.constraint(self.view.topAnchor.constraint(equalTo: top, constant: constant))
    }

    /**
     * Anchors the trailing edge of this view to the given point.
     */
    func right(_ right: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> AutoLayoutBuilder {
        return self.constraint(self.view.trailingAnchor.constraint(equalTo: right, constant: constant))
    }

    /**
     * Anchors the bottom edge of this view to the given point.
     */
    func bottom(_ bottom: NSLayoutYAxisAnchor, constant: CGFloat = 0) -> AutoLayoutBuilder {
        return self.constraint(self.view.bottomAnchor.constraint(equalTo: bottom, constant: constant))
    }

    /**
     * Sets a fixed width for this view.
     */
    func width(_ constant: CGFloat) -> AutoLayoutBuilder {
        return self.constraint(self.view.widthAnchor.constraint(equalToConstant: constant))
    }

    /**
     * Sets a fixed height for this view.
     */
    func height(_ constant: CGFloat) -> AutoLayoutBuilder {
        return self.constraint(self.view.heightAnchor.constraint(equalToConstant: constant))
    }

    /**
     * Aligns the horizontal center of this view to the given point.
     */
    func centerX(_ centerX: NSLayoutXAxisAnchor) -> AutoLayoutBuilder {
        return self.constraint(self.view.centerXAnchor.constraint(equalTo: centerX))
    }

    /**
     * Aligns the vertical center of this view to the given point.
     */
    func centerY(_ centerY: NSLayoutYAxisAnchor) -> AutoLayoutBuilder {
        return self.constraint(self.view.centerYAnchor.constraint(equalTo: centerY))
    }

    /**
     * Anchors the top edge of this view below the specified view.
     */
    func below(_ view: UIView) -> AutoLayoutBuilder {
        return self.constraint(
            self.view.topAnchor.constraint(
                equalToSystemSpacingBelow: view.bottomAnchor,
                multiplier: 1.0
            )
        )
    }

    /**
     * Anchors the leading edge of this view after the specified view.
     */
    func after(_ view: UIView) -> AutoLayoutBuilder {
        return self.constraint(
            self.view.leadingAnchor.constraint(
                equalToSystemSpacingAfter: view.trailingAnchor,
                multiplier: 1.0
            )
        )
    }

    /**
     * Anchors the leading and trailing edges of this view to the corresponding
     * anchor points in the layout guide.
     */
    func fillX(_ guide: UILayoutGuide) -> AutoLayoutBuilder {
        return self.left(guide.leadingAnchor).right(guide.trailingAnchor)
    }

    /**
     * Anchors the top and bottom edges of this view to the corresponding
     * anchor points in the layout guide.
     */
    func fillY(_ guide: UILayoutGuide) -> AutoLayoutBuilder {
        return self.top(guide.topAnchor).bottom(guide.bottomAnchor)
    }

    /**
     * Anchors the top and bottom edges of this view to the corresponding
     * anchor points in the view. Note that this does not respect margins/safe areas.
     */
    func fillY(_ view: UIView) -> AutoLayoutBuilder {
        return self.top(view.topAnchor).bottom(view.bottomAnchor)
    }

    /**
     * Anchors all edges of this view to the corresponding anchor points in
     * the layout guide.
     */
    func fill(_ guide: UILayoutGuide) -> AutoLayoutBuilder {
        return self.fillX(guide).fillY(guide)
    }

    /**
     * Anchors all edges of this view to the corresponding anchor points in
     * the view. Note that this does not respect margins/safe areas.
     */
    func fill(_ view: UIView) -> AutoLayoutBuilder {
        return self
            .top(view.topAnchor)
            .bottom(view.bottomAnchor)
            .left(view.leadingAnchor)
            .right(view.trailingAnchor)
    }

    /**
     * Call this to activate all constraints created by this builder.
     */
    func activate() {
        NSLayoutConstraint.activate(self.constraints)
    }
}

/**
 * Adds a convenience method to create an auto layout builder for the current view.
 */
extension UIView {
    /**
     * Disables autoresizing mask constraints for this view, then returns an auto
     * layout builder object.
     */
    private func autoLayout() -> AutoLayoutBuilder {
        self.translatesAutoresizingMaskIntoConstraints = false
        return AutoLayoutBuilder(self)
    }

    /**
     * Adds this view to the given parent view, disables autoresizing mask
     * constraints for this view, then returns an auto layout builder object.
     */
    func autoLayoutInView(_ view: UIView) -> AutoLayoutBuilder {
        view.addSubview(self)
        return self.autoLayout()
    }

    /**
     * Adds this view to the given parent view behind the specified sibling view,
     * disables autoresizing mask constraints for this view, then returns an auto
     * layout builder object.
     */
    func autoLayoutInView(_ view: UIView, below: UIView) -> AutoLayoutBuilder {
        view.insertSubview(self, belowSubview: below)
        return self.autoLayout()
    }

    /**
     * Adds this view to the given parent view in front of the specified sibling view,
     * disables autoresizing mask constraints for this view, then returns an auto
     * layout builder object.
     */
    func autoLayoutInView(_ view: UIView, above: UIView) -> AutoLayoutBuilder {
        view.insertSubview(self, aboveSubview: above)
        return self.autoLayout()
    }
}
