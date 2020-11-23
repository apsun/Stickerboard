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
    private let stickers = [
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
        UIImage(named: "TestSticker1")!,
    ]

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    convenience init(delegate: StickerCollectionViewDelegate) {
        self.init()
        self.delegate = delegate
    }

    required init?(coder: NSCoder) {
        abort()
    }
    
    override var collectionViewLayout: UICollectionViewFlowLayout {
        get {
            return super.collectionViewLayout as! UICollectionViewFlowLayout
        }
    }

    override func viewDidLoad() {
        self.collectionView.register(
            StickerCell.self,
            forCellWithReuseIdentifier: self.reuseIdentifier
        )
        self.collectionView.backgroundColor = .clear
        self.collectionView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
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
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: self.reuseIdentifier,
            for: indexPath
        ) as! StickerCell
        cell.setImage(image: self.stickers[indexPath.item])
        if lastSelectedStickerIndex == indexPath {
            cell.setOverlay(animate: false)
        } else {
            cell.resetOverlay(animate: false)
        }
        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let image = self.stickers[indexPath.item]

        // Hide overlay on previous cell
        if let prevSelectedIndex = self.lastSelectedStickerIndex {
            let prevCell = self.collectionView.cellForItem(at: prevSelectedIndex) as? StickerCell
            prevCell?.resetOverlay(animate: true)
            print("CLEAR OTHER AT \(prevSelectedIndex)")
        }

        // Time out overlay on current cell after 3 seconds
        self.overlayAutoHideWork?.cancel()
        self.overlayAutoHideWork = DispatchWorkItem(block: {
            self.lastSelectedStickerIndex = nil
            let currCell = self.collectionView.cellForItem(at: indexPath) as? StickerCell
            currCell?.resetOverlay(animate: true)
            print("AUTO TIMEOUT AT \(indexPath)")
        })
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + 3,
            execute: self.overlayAutoHideWork!
        )

        // Show overlay on current cell
        let cell = self.collectionView.cellForItem(at: indexPath) as! StickerCell
        cell.setOverlay(animate: true)
        self.lastSelectedStickerIndex = indexPath
        print("SHOW AT \(indexPath)")

        self.delegate?.stickerCollectionView(self, didSelect: image)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 80)
    }
}
