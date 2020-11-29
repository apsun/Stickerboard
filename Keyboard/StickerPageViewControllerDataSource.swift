import UIKit

class StickerPageViewControllerDataSource
    : NSObject
    , UIPageViewControllerDataSource
{
    private let stickerPacks: [StickerPack]
    private weak var stickerDelegate: StickerPickerViewDelegate?

    init(stickerPacks: [StickerPack], stickerDelegate: StickerPickerViewDelegate) {
        self.stickerPacks = stickerPacks
        self.stickerDelegate = stickerDelegate
    }

    private func viewController(forIndex index: Int) -> UIViewController {
        let pack = self.stickerPacks[index]
        let controller = StickerPickerViewController()
        controller.stickerPack = pack
        controller.delegate = self.stickerDelegate
        return controller
    }

    func initialViewController() -> UIViewController {
        return viewController(forIndex: 0)
    }

    private func indexOf(viewController: UIViewController) -> Int {
        let pack = (viewController as! StickerPickerViewController).stickerPack!
        return self.stickerPacks.firstIndex { $0.url == pack.url }!
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.stickerPacks.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let viewController = pageViewController.viewControllers![0]
        return self.indexOf(viewController: viewController)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        let packIndex = self.indexOf(viewController: viewController)
        if packIndex == 0 {
            return nil
        }
        return self.viewController(forIndex: packIndex - 1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        let packIndex = self.indexOf(viewController: viewController)
        if packIndex == self.stickerPacks.count - 1 {
            return nil
        }
        return self.viewController(forIndex: packIndex + 1)
    }
}
