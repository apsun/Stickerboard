import UIKit

/**
 * Provides a callback for when the user selects a sticker.
 */
protocol StickerPickerViewDelegate: class {
    func stickerPickerView(
        _ sender: StickerPickerViewController,
        didSelect stickerFile: StickerFile,
        inPack stickerPack: StickerPack,
        longPress: Bool
    )
}

/**
 * A cell containing an image view.
 */
fileprivate class StickerPickerCell: UICollectionViewCell {
    static let reuseIdentifier = NSStringFromClass(StickerPickerCell.self)
    private static let loadingImage: UIImage? = nil
    private static let errorImage = UIImage(
        systemName: "exclamationmark.triangle.fill",
        withConfiguration: UIImage.SymbolConfiguration(pointSize: 36)
    )

    private var imageView: UIImageView!
    private var imageParams: AsyncImageLoaderParams?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.imageView = UIImageView()
        self.imageView
            .autoLayoutInView(self.contentView)
            .fill(self.contentView.safeAreaLayoutGuide)
            .activate()
        self.imageView.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        abort()
    }

    /**
     * Returns a parameters object for the image loader given the specified
     * URL and the current size of the cell.
     */
    private func makeImageParams(url: URL?) -> AsyncImageLoaderParams? {
        guard let url = url else { return nil }
        return AsyncImageLoaderParams(
            imageURL: url,
            pointSize: self.bounds.size,
            scale: self.traitCollection.displayScale,
            mode: .fill
        )
    }

    /**
     * Configures the cell to load and eventually display the specified image.
     */
    private func beginSetImage(params: AsyncImageLoaderParams?) {
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

        AsyncImageLoader.main.loadAsync(params: params) { result in
            self.commitSetImage(params: params, result: result)
        }
    }

    /**
     * Called when an image has successfully loaded/failed to load. Updates
     * the cell with the image (or displays an error thumbnail if the load failed).
     */
    private func commitSetImage(params: AsyncImageLoaderParams, result: Result<UIImage, Error>) {
        guard params == self.imageParams else { return }

        switch result {
        case .success(let image):
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.image = image
        case .failure(_):
            self.imageView.contentMode = .center
            self.imageView.image = StickerPickerCell.errorImage
        }
    }

    /**
     * Called when the size of the image changes; triggers a request to load
     * a new version of the current image with the appropriate size.
     */
    override func layoutSubviews() {
        super.layoutSubviews()

        let params = self.makeImageParams(url: self.imageParams?.imageURL)
        self.beginSetImage(params: params)
    }

    /**
     * Asynchronously loads the specified image in this cell.
     */
    func setImageAsync(url: URL?) {
        let params = self.makeImageParams(url: url)
        self.beginSetImage(params: params)
    }
}

/**
 * Displays a vertically scrolling list of sticker images that the user
 * can select.
 */
class StickerPickerViewController
    : UICollectionViewController
    , UICollectionViewDelegateFlowLayout
    , UICollectionViewDataSourcePrefetching
{
    /**
     * Callback for when a sticker is selected by the user.
     */
    weak var delegate: StickerPickerViewDelegate?

    /**
     * The sticker pack (i.e. image list) displayed by this sticker picker.
     */
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

        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(self.didLongPressCollectionView)
        )
        self.collectionView.addGestureRecognizer(longPress)
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
            let params = AsyncImageLoaderParams(
                imageURL: imageURL,
                pointSize: size,
                scale: self.traitCollection.displayScale,
                mode: .fill
            )
            AsyncImageLoader.main.loadAsync(params: params)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            let imageURL = self.stickerPack!.files[indexPath.item].url
            let size = self.collectionViewLayout.layoutAttributesForItem(at: indexPath)!.size
            let params = AsyncImageLoaderParams(
                imageURL: imageURL,
                pointSize: size,
                scale: self.traitCollection.displayScale,
                mode: .fill
            )
            AsyncImageLoader.main.cancelLoad(params: params)
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let pack = self.stickerPack!
        let file = pack.files[indexPath.item]
        self.delegate?.stickerPickerView(self, didSelect: file, inPack: pack, longPress: false)
    }

    @objc
    private func didLongPressCollectionView(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != .began {
            return
        }

        let point = recognizer.location(in: self.collectionView)
        guard let indexPath = self.collectionView.indexPathForItem(at: point) else { return }

        let pack = self.stickerPack!
        let file = pack.files[indexPath.item]
        self.delegate?.stickerPickerView(self, didSelect: file, inPack: pack, longPress: true)
    }
}
