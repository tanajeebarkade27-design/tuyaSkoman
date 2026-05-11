import Foundation
import UIKit

class CustomPopupView: UIView {

    var onClose: (() -> Void)? // Callback for close button
    var onConfigure: ((String) -> Void)? // Callback for configure button
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Scene Name:"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .left  // Align text to the left
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✖️", for: .normal)
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()
    
    private let titleSeparator: UIView = {  // Separator below scene name
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()

    private let sceneTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter scene name"
        return textField
    }()
    
  
    
    private let configureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Configure", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(configureTapped), for: .touchUpInside)
        return button
    }()
    
    init(sceneName: String) {
        super.init(frame: CGRect.zero)
        self.sceneTextField.text = sceneName
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 8
        
        // Add subviews
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(titleSeparator)
        addSubview(sceneTextField)
      
        addSubview(configureButton)
        
        // Layout using Auto Layout
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        titleSeparator.translatesAutoresizingMaskIntoConstraints = false
        sceneTextField.translatesAutoresizingMaskIntoConstraints = false
     
        configureButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20), // Align to the left
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),
            
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            
            titleSeparator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            titleSeparator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleSeparator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleSeparator.heightAnchor.constraint(equalToConstant: 1),
            
            sceneTextField.topAnchor.constraint(equalTo: titleSeparator.bottomAnchor, constant: 10),
            sceneTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            sceneTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            sceneTextField.heightAnchor.constraint(equalToConstant: 40),
            
            configureButton.topAnchor.constraint(equalTo: sceneTextField.bottomAnchor, constant: 20),
            configureButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            configureButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            configureButton.heightAnchor.constraint(equalToConstant: 44),
            configureButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func closeTapped() {
        onClose?()
    }
    
    @objc private func configureTapped() {
        let newName = sceneTextField.text ?? ""
        onConfigure?(newName)
    }
}
