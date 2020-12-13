import UIKit

/**
 * Creates StickerPickerViewController instances from StickerPack objects.
 */
public class StickerPageViewControllerDataSource
    : NSObject
    , ArrayPageViewControllerDataSource
{
    private let stickerPacks: [StickerPack]
    private weak var stickerPickerDelegate: StickerPickerViewDelegate?

    public init(stickerPacks: [StickerPack], stickerPickerDelegate: StickerPickerViewDelegate) {
        self.stickerPacks = stickerPacks
        self.stickerPickerDelegate = stickerPickerDelegate
    }

    public func create(index: Int) -> UIViewController {
        let pack = self.stickerPacks[index]
        let controller = StickerPickerViewController()
        controller.stickerPack = pack
        controller.delegate = self.stickerPickerDelegate
        return controller
    }

    public func indexOf(viewController: UIViewController) -> Int {
        let pack = (viewController as! StickerPickerViewController).stickerPack!
        return self.stickerPacks.firstIndex { $0.url == pack.url }!
    }

    public func count() -> Int {
        return self.stickerPacks.count
    }

    public func initialPage() -> Int? {
        guard let pageUrl = PreferenceManager.standard.lastStickerPageUrl() else { return nil }
        return self.stickerPacks.firstIndex {
            $0.url.path == pageUrl
        }
    }

    public func didShowPage(index: Int) {
        PreferenceManager.standard.setLastStickerPageUrl(self.stickerPacks[index].url.path)
    }
}
