import UIKit

class MainViewController : UIViewController {
    var testTextField: UITextField!
    var theButton: UIButton!

    override func loadView() {
        print("loadView")
        
        self.view = UIView()
        self.view.backgroundColor = .systemBackground

        self.testTextField = UITextField()
        self.view.addSubview(self.testTextField)
        self.testTextField.translatesAutoresizingMaskIntoConstraints = false
        self.testTextField.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.testTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.testTextField.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -16).isActive = true

        self.theButton = UIButton(type: .system)
        self.view.addSubview(self.theButton)
        self.theButton.translatesAutoresizingMaskIntoConstraints = false
        self.theButton.topAnchor.constraint(equalTo: self.testTextField.bottomAnchor).isActive = true
        self.theButton.centerXAnchor.constraint(equalTo: self.testTextField.centerXAnchor).isActive = true
    }

    override func viewDidLoad() {
        print("viewDidLoad")

        self.testTextField.borderStyle = .roundedRect

        self.theButton.addTarget(self, action: #selector(onButtonClicked), for: .touchUpInside)
        self.theButton.setTitle("Click me", for: .normal)

        self.title = "Stickerboard"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(onNavItemClicked))
    }

    @objc
    func onNavItemClicked() {
        let alert = UIAlertController(title: "Hello world", message: "This is a test", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Okily dokily", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Delet dis", style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: "Nevermind", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @objc
    func onButtonClicked() {
        self.show(MainViewController(), sender: self)
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
