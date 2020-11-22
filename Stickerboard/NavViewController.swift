//
//  NavViewController.swift
//  Stickerboard
//
//  Created by Andrew Sun on 11/21/20.
//

import Foundation
import UIKit

class NavViewController : UINavigationController {
    override func viewDidLoad() {
        print("viewDidLoad")

        self.setViewControllers([MainViewController()], animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear")
    }

    override func viewWillLayoutSubviews() {
        print("viewWillLayoutSubviews")
    }

    override func viewDidLayoutSubviews() {
        print("viewDidLayoutSubviews")
    }
}
