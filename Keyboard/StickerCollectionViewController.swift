import UIKit

protocol StickerCollectionViewDelegate : class {
    func stickerCollectionView(
        _ sender: StickerCollectionViewController,
        didSelect stickerURL: URL
    )
}

class StickerCollectionViewController
    : UICollectionViewController
    , UICollectionViewDelegateFlowLayout
    , UICollectionViewDataSourcePrefetching
{
    private static let reuseIdentifier = "StickerCell"
    private let stickerURLs: [URL]
    private let stickerLoader: StickerImageLoader
    private var lastSelectedStickerIndex: IndexPath?
    private var overlayAutoHideTask: DispatchWorkItem?
    private weak var delegate: StickerCollectionViewDelegate?

    init() {
        self.stickerURLs = try! StickerDirectoryManager.main.importedStickerURLs()
        self.stickerLoader = StickerImageLoader()
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (
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
        })
        super.init(collectionViewLayout: layout)
    }

    convenience init(delegate: StickerCollectionViewDelegate) {
        self.init()
        self.delegate = delegate
    }

    required init?(coder: NSCoder) {
        abort()
    }

    override func viewDidLoad() {
        self.collectionView.register(
            StickerCell.self,
            forCellWithReuseIdentifier: StickerCollectionViewController.reuseIdentifier
        )
        self.collectionView.backgroundColor = .clear
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return self.stickerURLs.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: StickerCollectionViewController.reuseIdentifier,
            for: indexPath
        )
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let cell = cell as! StickerCell
        let imageURL = self.stickerURLs[indexPath.item]
        let params = StickerImageParams(
            imageURL: imageURL,
            pointSize: cell.bounds.size,
            scale: UIScreen.main.scale
        )

        cell.beginSetImage(params: params)
        self.stickerLoader.loadAsync(
            params: params,
            callback: { (image: UIImage) in
                cell.commitSetImage(params: params, image: image)
            }
        )

        if self.lastSelectedStickerIndex == indexPath {
            cell.setOverlay(animated: false)
        } else {
            cell.resetOverlay(animated: false)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            let imageURL = self.stickerURLs[indexPath.item]
            let size = self.collectionViewLayout.layoutAttributesForItem(at: indexPath)!.size
            let params = StickerImageParams(
                imageURL: imageURL,
                pointSize: size,
                scale: UIScreen.main.scale
            )
            self.stickerLoader.loadAsync(params: params)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            let imageURL = self.stickerURLs[indexPath.item]
            let size = self.collectionViewLayout.layoutAttributesForItem(at: indexPath)!.size
            let params = StickerImageParams(
                imageURL: imageURL,
                pointSize: size,
                scale: UIScreen.main.scale
            )
            self.stickerLoader.cancelLoad(params: params)
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        self.overlayAutoHideTask?.cancel()
        self.overlayAutoHideTask = DispatchWorkItem(block: {
            self.collectionView.deselectItem(at: indexPath, animated: true)
            self.collectionView(self.collectionView, didDeselectItemAt: indexPath)
        })
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + 3,
            execute: self.overlayAutoHideTask!
        )

        let cell = self.collectionView.cellForItem(at: indexPath) as! StickerCell
        cell.setOverlay(animated: true)
        self.lastSelectedStickerIndex = indexPath

        let url = self.stickerURLs[indexPath.item]
        self.delegate?.stickerCollectionView(self, didSelect: url)
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didDeselectItemAt indexPath: IndexPath
    ) {
        let cell = self.collectionView.cellForItem(at: indexPath) as? StickerCell
        cell?.resetOverlay(animated: true)
        self.lastSelectedStickerIndex = nil
    }
}
