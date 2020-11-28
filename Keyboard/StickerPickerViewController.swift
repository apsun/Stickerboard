import UIKit

protocol StickerPickerViewDelegate : class {
    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack
    )
}

fileprivate class StickerPickerCell: UICollectionViewCell {
    static let reuseIdentifier = NSStringFromClass(StickerPickerCell.self)

    let imageView: UIImageView
    var imageParams: ImageLoaderParams?

    override init(frame: CGRect) {
        self.imageView = UIImageView()
        super.init(frame: frame)

        self.addSubview(self.imageView)
        self.imageView.autoLayout().fill(self.contentView.safeAreaLayoutGuide).activate()
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
}

class StickerPickerViewController
    : UICollectionViewController
    , UICollectionViewDelegateFlowLayout
    , UICollectionViewDataSourcePrefetching
{
    private let imageLoader = ImageLoader()
    weak var delegate: StickerPickerViewDelegate?
    let stickerPack: StickerPack

    init(stickerPack: StickerPack) {
        self.stickerPack = stickerPack

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
        return self.stickerPack.files.count
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
        let imageURL = self.stickerPack.files[indexPath.item].url
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
    }

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            let imageURL = self.stickerPack.files[indexPath.item].url
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
            let imageURL = self.stickerPack.files[indexPath.item].url
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
        let pack = self.stickerPack
        let file = pack.files[indexPath.item]
        self.delegate?.stickerPickerView(self, didSelect: file, inPack: pack)
    }
}
