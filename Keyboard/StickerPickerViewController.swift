import UIKit

protocol StickerPickerViewDelegate: class {
    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack
    )
}

fileprivate class StickerPickerCell: UICollectionViewCell {
    static let reuseIdentifier = NSStringFromClass(StickerPickerCell.self)
    private static let loadingImage: UIImage? = nil
    private static let errorImage = UIImage(
        systemName: "exclamationmark.triangle.fill",
        withConfiguration: UIImage.SymbolConfiguration(pointSize: 36)
    )

    private var imageView: UIImageView!
    private var imageParams: ImageLoaderParams?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.imageView = UIImageView()
        self.imageView
            .autoLayoutInView(self)
            .fill(self.contentView.safeAreaLayoutGuide)
            .activate()
        self.imageView.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        abort()
    }

    private func makeImageParams(url: URL?) -> ImageLoaderParams? {
        guard let url = url else { return nil }
        return ImageLoaderParams(
            imageURL: url,
            pointSize: self.bounds.size,
            scale: UIScreen.main.scale
        )
    }

    private func beginSetImage(params: ImageLoaderParams?) {
        let oldParams = self.imageParams
        if params == oldParams {
            return
        }

        self.imageParams = params
        guard let params = params else {
            self.imageView.image = nil
            return
        }

        // If the image is the same as before (just with a different size),
        // keep it in place while we load the new one. Otherwise, display a
        // placeholder thumbnail.
        if params.imageURL != oldParams?.imageURL {
            self.imageView.image = StickerPickerCell.loadingImage
            self.imageView.contentMode = .center
        }

        ImageLoader.main.loadAsync(params: params) { image in
            self.commitSetImage(params: params, image: image)
        }
    }

    private func commitSetImage(params: ImageLoaderParams, image: UIImage?) {
        guard params == self.imageParams else { return }

        if let image = image {
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.image = image
        } else {
            self.imageView.contentMode = .center
            self.imageView.image = StickerPickerCell.errorImage
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let params = self.makeImageParams(url: self.imageParams?.imageURL)
        self.beginSetImage(params: params)
    }

    func setImageAsync(url: URL?) {
        let params = self.makeImageParams(url: url)
        self.beginSetImage(params: params)
    }
}

class StickerPickerViewController
    : UICollectionViewController
    , UICollectionViewDelegateFlowLayout
    , UICollectionViewDataSourcePrefetching
{
    weak var delegate: StickerPickerViewDelegate?
    var stickerPack: StickerPack? {
        didSet {
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
        cell.setImageAsync(url: imageURL)
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
            ImageLoader.main.loadAsync(params: params)
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
            ImageLoader.main.cancelLoad(params: params)
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let pack = self.stickerPack!
        let file = pack.files[indexPath.item]
        self.delegate?.stickerPickerView(self, didSelect: file, inPack: pack)
    }
}
