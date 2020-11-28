import UIKit

class AutoLayoutBuilder {
    private var constraints: [NSLayoutConstraint] = []
    private let view: UIView

    init(_ view: UIView) {
        self.view = view
    }

    func constraint(_ constraint: NSLayoutConstraint) -> AutoLayoutBuilder {
        self.constraints.append(constraint)
        return self
    }

    func left(_ left: NSLayoutXAxisAnchor) -> AutoLayoutBuilder {
        return self.constraint(self.view.leadingAnchor.constraint(equalTo: left))
    }

    func top(_ top: NSLayoutYAxisAnchor) -> AutoLayoutBuilder {
        return self.constraint(self.view.topAnchor.constraint(equalTo: top))
    }

    func right(_ right: NSLayoutXAxisAnchor) -> AutoLayoutBuilder {
        return self.constraint(self.view.trailingAnchor.constraint(equalTo: right))
    }

    func bottom(_ bottom: NSLayoutYAxisAnchor) -> AutoLayoutBuilder {
        return self.constraint(self.view.bottomAnchor.constraint(equalTo: bottom))
    }

    func width(_ constant: CGFloat) -> AutoLayoutBuilder {
        return self.constraint(self.view.widthAnchor.constraint(equalToConstant: constant))
    }

    func height(_ constant: CGFloat) -> AutoLayoutBuilder {
        return self.constraint(self.view.heightAnchor.constraint(equalToConstant: constant))
    }

    func below(_ view: UIView) -> AutoLayoutBuilder {
        return self.constraint(
            self.view.topAnchor.constraint(
                equalToSystemSpacingBelow: view.bottomAnchor,
                multiplier: 1.0
            )
        )
    }

    func after(_ view: UIView) -> AutoLayoutBuilder {
        return self.constraint(
            self.view.leadingAnchor.constraint(
                equalToSystemSpacingAfter: view.trailingAnchor,
                multiplier: 1.0
            )
        )
    }

    func fillX(_ guide: UILayoutGuide) -> AutoLayoutBuilder {
        return self.left(guide.leadingAnchor).right(guide.trailingAnchor)
    }

    func fillY(_ guide: UILayoutGuide) -> AutoLayoutBuilder {
        return self.top(guide.topAnchor).bottom(guide.bottomAnchor)
    }

    func fill(_ guide: UILayoutGuide) -> AutoLayoutBuilder {
        return self.fillX(guide).fillY(guide)
    }

    func activate() {
        NSLayoutConstraint.activate(self.constraints)
    }
}

extension UIView {
    func autoLayout() -> AutoLayoutBuilder {
        self.translatesAutoresizingMaskIntoConstraints = false
        return AutoLayoutBuilder(self)
    }
}
