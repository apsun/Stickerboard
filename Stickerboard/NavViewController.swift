import UIKit

class NavViewController: UINavigationController {
    override func viewDidLoad() {
        self.setViewControllers([MainViewController()], animated: false)
    }
}
