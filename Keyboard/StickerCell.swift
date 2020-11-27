import UIKit

class StickerCell : UICollectionViewCell {
    var imageParams: StickerImageParams?
    var imageView: UIImageView
    var overlayView: UILabel
    var overlayTopConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        self.imageView = UIImageView()
        self.overlayView = UILabel()
        super.init(frame: frame)

        self.addSubview(self.imageView)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.imageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.imageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
        ])

        self.addSubview(self.overlayView)
        self.overlayView.backgroundColor = .accent
        self.overlayView.textColor = .accentedLabel
        self.overlayView.textAlignment = .center
        self.overlayView.text = "Copied!"
        self.overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.overlayTopConstraint = self.overlayView.topAnchor.constraint(
            equalTo: self.contentView.bottomAnchor
        )
        NSLayoutConstraint.activate([
            self.overlayView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.overlayView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.overlayTopConstraint
        ])

        self.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        abort()
    }

    func setImage(params: StickerImageParams, image: UIImage) {
        self.imageParams = params
        self.imageView.image = image
    }

    func beginSetImage(params: StickerImageParams) {
        self.imageParams = params
        self.imageView.image = nil
    }

    func commitSetImage(params: StickerImageParams, image: UIImage) {
        if params == self.imageParams {
            self.imageView.image = image
        }
    }

    func setOverlay(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.setOverlay(animated: false)
            })
        } else {
            self.overlayTopConstraint.constant = -self.overlayView.intrinsicContentSize.height
            self.layoutIfNeeded()
        }
    }

    func resetOverlay(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.resetOverlay(animated: false)
            })
        } else {
            self.overlayTopConstraint.constant = 0
            self.layoutIfNeeded()
        }
    }
}
