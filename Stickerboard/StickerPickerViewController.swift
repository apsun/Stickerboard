import UIKit

protocol StickerPickerViewDelegate : class {
    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack
    )
}

fileprivate class StickerPickerCell : UICollectionViewCell {
    static let reuseIdentifier = "StickerPickerCell"

    let imageView: UIImageView
    let overlayView: UILabel
    var overlayTopConstraint: NSLayoutConstraint!
    var imageParams: ImageLoaderParams?

    override init(frame: CGRect) {
        self.imageView = UIImageView()
        self.overlayView = UILabel()
        super.init(frame: frame)

        self.addSubview(self.imageView)
        self.imageView.autoLayout().fill(self.contentView.safeAreaLayoutGuide).activate()

        self.addSubview(self.overlayView)
        self.overlayView.backgroundColor = .accent
        self.overlayView.textColor = .accentedLabel
        self.overlayView.textAlignment = .center
        self.overlayView.text = "Copied!"
        self.overlayTopConstraint = self.overlayView.topAnchor.constraint(
            equalTo: self.contentView.bottomAnchor
        )
        self.overlayView
            .autoLayout()
            .fillX(self.contentView.safeAreaLayoutGuide)
            .constraint(self.overlayTopConstraint)
            .activate()

        self.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        abort()
    }

    func setImage(params: ImageLoaderParams, image: UIImage) {
        self.imageParams = params
        self.imageView.image = image
    }

    func beginSetImage(params: ImageLoaderParams) {
        self.imageParams = params
        self.imageView.image = nil
    }

    func commitSetImage(params: ImageLoaderParams, image: UIImage) {
        if params == self.imageParams {
            self.imageView.image = image
        }
    }

    func showOverlay(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.showOverlay(animated: false)
            })
        } else {
            self.overlayTopConstraint.constant = -self.overlayView.intrinsicContentSize.height
            self.layoutIfNeeded()
        }
    }

    func hideOverlay(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.hideOverlay(animated: false)
            })
        } else {
            self.overlayTopConstraint.constant = 0
            self.layoutIfNeeded()
        }
    }
}

class StickerPickerViewController
    : UICollectionViewController
    , UICollectionViewDelegateFlowLayout
    , UICollectionViewDataSourcePrefetching
{
    private let imageLoader = ImageLoader()
    private var lastSelectedStickerIndex: IndexPath?
    private var overlayAutoHideTask: DispatchWorkItem?
    weak var delegate: StickerPickerViewDelegate?
    
    var stickerPack: StickerPack? {
        didSet {
            if let index = self.lastSelectedStickerIndex {
                self.collectionView(self.collectionView, didDeselectItemAt: index)
            }
            self.collectionView.reloadData()
        }
    }

    init() {
        let layout = UICollectionViewCompositionalLayout { (
            sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment
        ) -> NSCollectionLayoutSection? in
            let width = layoutEnvironment.container.effectiveContentSize.width
            let columns = max(Int(width / 88), 1)
            let insets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = insets

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(1.0 / CGFloat(columns))
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: columns
            )

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = insets
            return section
        }
        super.init(collectionViewLayout: layout)
    }

    convenience init(delegate: StickerPickerViewDelegate) {
        self.init()
        self.delegate = delegate
    }

    required init?(coder: NSCoder) {
        abort()
    }

    override func viewDidLoad() {
        self.collectionView.register(
            StickerPickerCell.self,
            forCellWithReuseIdentifier: StickerPickerCell.reuseIdentifier
        )
        self.collectionView.backgroundColor = .clear
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return self.stickerPack?.files.count ?? 0
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: StickerPickerCell.reuseIdentifier,
            for: indexPath
        )
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let cell = cell as! StickerPickerCell
        let imageURL = self.stickerPack!.files[indexPath.item].url
        let params = ImageLoaderParams(
            imageURL: imageURL,
            pointSize: cell.bounds.size,
            scale: UIScreen.main.scale
        )

        cell.beginSetImage(params: params)
        self.imageLoader.loadAsync(
            params: params,
            callback: { (image: UIImage) in
                cell.commitSetImage(params: params, image: image)
            }
        )

        if self.lastSelectedStickerIndex == indexPath {
            cell.showOverlay(animated: false)
        } else {
            cell.hideOverlay(animated: false)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            let imageURL = self.stickerPack!.files[indexPath.item].url
            let size = self.collectionViewLayout.layoutAttributesForItem(at: indexPath)!.size
            let params = ImageLoaderParams(
                imageURL: imageURL,
                pointSize: size,
                scale: UIScreen.main.scale
            )
            self.imageLoader.loadAsync(params: params)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            let imageURL = self.stickerPack!.files[indexPath.item].url
            let size = self.collectionViewLayout.layoutAttributesForItem(at: indexPath)!.size
            let params = ImageLoaderParams(
                imageURL: imageURL,
                pointSize: size,
                scale: UIScreen.main.scale
            )
            self.imageLoader.cancelLoad(params: params)
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        self.overlayAutoHideTask?.cancel()
        self.overlayAutoHideTask = DispatchWorkItem {
            self.collectionView.deselectItem(at: indexPath, animated: true)
            self.collectionView(self.collectionView, didDeselectItemAt: indexPath)
        }
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + 3,
            execute: self.overlayAutoHideTask!
        )

        let cell = self.collectionView.cellForItem(at: indexPath) as! StickerPickerCell
        cell.showOverlay(animated: true)
        self.lastSelectedStickerIndex = indexPath

        let pack = self.stickerPack!
        let file = pack.files[indexPath.item]
        self.delegate?.stickerPickerView(self, didSelect: file, inPack: pack)
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didDeselectItemAt indexPath: IndexPath
    ) {
        let cell = self.collectionView.cellForItem(at: indexPath) as? StickerPickerCell
        cell?.hideOverlay(animated: true)
        self.lastSelectedStickerIndex = nil
    }
}
