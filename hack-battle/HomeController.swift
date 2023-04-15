import Foundation
import UIKit

class HomeController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func navigateToViewController(_ sender: Any) {
        performSegue(withIdentifier: "toViewController", sender: self)
    }
    @IBAction func navigateToRecyclingController(_ sender: Any) {
        performSegue(withIdentifier: "toRecyclingController", sender: self)
    }
    @IBAction func navigateToGarbageController(_ sender: Any) {
        performSegue(withIdentifier: "toGarbageController", sender: self)
    }
    @IBAction func navigateToCompostController(_ sender: Any) {
        performSegue(withIdentifier: "toCompostController", sender: self)
    }
    @IBAction func navigateToQuizController(_ sender: Any) {
        performSegue(withIdentifier: "toQuizController", sender: self)
    }
    @IBAction func clearUserDefaults(_ sender: Any) {
        let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
    }
}
