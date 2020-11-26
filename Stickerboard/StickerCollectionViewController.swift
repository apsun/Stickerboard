import UIKit

protocol StickerCollectionViewDelegate : class {
    func stickerCollectionView(
        _ sender: StickerCollectionViewController,
        didSelect sticker: UIImage
    )
}

class StickerCollectionViewController
    : UICollectionViewController
    , UICollectionViewDelegateFlowLayout
{
    weak var delegate: StickerCollectionViewDelegate?
    private var lastSelectedStickerIndex: IndexPath?
    private var overlayAutoHideWork: DispatchWorkItem?
    private let reuseIdentifier = "StickerCell"
    private let stickerManager: StickerManager
    private let stickers: [UIImage]

    init() {
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
        self.stickerManager = StickerManager(fileManager: FileManager.default)
        let stickerURLs = try! self.stickerManager.loadStickers()
        var stickers = [UIImage]()
        for stickerURL in stickerURLs {
            stickers.append(UIImage(contentsOfFile: stickerURL.path)!)
        }
        self.stickers = stickers
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
            forCellWithReuseIdentifier: self.reuseIdentifier
        )
        self.collectionView.backgroundColor = .clear
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return self.stickers.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: self.reuseIdentifier,
            for: indexPath
        )
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let cell = cell as! StickerCell
        cell.setImage(image: self.stickers[indexPath.item])
        if self.lastSelectedStickerIndex == indexPath {
            cell.setOverlay(animated: false)
        } else {
            cell.resetOverlay(animated: false)
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        self.overlayAutoHideWork?.cancel()
        self.overlayAutoHideWork = DispatchWorkItem(block: {
            self.collectionView.deselectItem(at: indexPath, animated: true)
            self.collectionView(self.collectionView, didDeselectItemAt: indexPath)
        })
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + 3,
            execute: self.overlayAutoHideWork!
        )

        let cell = self.collectionView.cellForItem(at: indexPath) as! StickerCell
        cell.setOverlay(animated: true)
        self.lastSelectedStickerIndex = indexPath

        let image = self.stickers[indexPath.item]
        self.delegate?.stickerCollectionView(self, didSelect: image)
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
