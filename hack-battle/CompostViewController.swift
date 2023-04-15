import UIKit

class CompostViewController: UIViewController {
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStackView()
        loadCompostItems()
    }
    
    private func setupStackView() {
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150)
        ])
    }
    
    private func loadCompostItems() {
        let compostItems = getSavedResponses(for: "compost")
        
        for item in compostItems {
            let itemView = UIView()
            itemView.backgroundColor = .white
            itemView.layer.cornerRadius = 8
            itemView.layer.masksToBounds = true
            itemView.widthAnchor.constraint(equalToConstant: view.frame.width - 64).isActive = true
            itemView.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            let itemLabel = UILabel()
            itemLabel.text = item
            itemLabel.textAlignment = .left
            itemLabel.textColor = .black
            itemView.addSubview(itemLabel)
            
            itemLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                itemLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 24),
                itemLabel.topAnchor.constraint(equalTo: itemView.topAnchor),
                itemLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor),
                itemLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -16)
            ])
            
            stackView.addArrangedSubview(itemView)
        }
    }

    
    func getSavedResponses(for category: String) -> [String] {
        let defaults = UserDefaults.standard
        let key = "savedResponses_\(category)"
        let savedResponses = defaults.array(forKey: key) as? [String] ?? [String]()
        
        return savedResponses
    }
}
