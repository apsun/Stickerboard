import UIKit

/**
 * Creates StickerPickerViewController instances from StickerPack objects.
 */
class StickerPageViewControllerDataSource
    : NSObject
    , ArrayPageViewControllerDataSource
{
    private let stickerPacks: [StickerPack]
    private weak var stickerPickerDelegate: StickerPickerViewDelegate?

    init(stickerPacks: [StickerPack], stickerPickerDelegate: StickerPickerViewDelegate) {
        self.stickerPacks = stickerPacks
        self.stickerPickerDelegate = stickerPickerDelegate
    }

    func create(index: Int) -> UIViewController {
        let pack = self.stickerPacks[index]
        let controller = StickerPickerViewController()
        controller.stickerPack = pack
        controller.delegate = self.stickerPickerDelegate
        return controller
    }

    func indexOf(viewController: UIViewController) -> Int {
        let pack = (viewController as! StickerPickerViewController).stickerPack!
        return self.stickerPacks.firstIndex { $0.url == pack.url }!
    }

    func count() -> Int {
        return self.stickerPacks.count
    }
}
