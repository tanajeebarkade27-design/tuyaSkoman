import UIKit
import Lottie

// MARK: - Custom Popup View
class DynamicPopupView: UIView {
    
    private let animationView: LottieAnimationView = {
        let animView = LottieAnimationView()
        animView.loopMode = .playOnce
        animView.contentMode = .scaleAspectFit
        animView.backgroundBehavior = .pauseAndRestore
        return animView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .darkGray
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    init(animationName: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        setupView()
        configurePopup(animationName: animationName, title: title, subtitle: subtitle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup UI
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 15
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 5
        translatesAutoresizingMaskIntoConstraints = false
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 18, leading: 18, bottom: 16, trailing: 18)

        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [animationView, titleLabel, subtitleLabel, closeButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            
            animationView.heightAnchor.constraint(equalToConstant: 84),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
    }

    private func configurePopup(animationName: String, title: String, subtitle: String) {
        animationView.animation = LottieAnimation.named(animationName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        if animationView.animation != nil {
            animationView.play()
        }
    }

    // MARK: Dismiss Logic
    @objc private func dismissPopup() {
        self.superview?.subviews.forEach {
            if $0 is DynamicPopupView || $0.tag == 998 || $0.tag == 999 {
                $0.removeFromSuperview()
            }
        }
    }
}


// MARK: - Popup Presenter
class PopupPresenter {

    static func showPopup(on parentView: UIView, animationName: String, title: String, subtitle: String) {
        // Remove existing popup if any (avoid stacking)
        dismissPopup(from: parentView)
        
        // 1. Background Image View
        let backgroundImageView = UIImageView()
        backgroundImageView.image = UIImage(named: "Screen Background")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.5
        backgroundImageView.tag = 999
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: parentView.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])

        // 2. Dimming Layer
        let dimmingView = UIView()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        dimmingView.tag = 998
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(dimmingView)

        NSLayoutConstraint.activate([
            dimmingView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            dimmingView.topAnchor.constraint(equalTo: parentView.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        
        // Tap outside to dismiss
        dimmingView.isUserInteractionEnabled = true
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(_dismissFromTap(_:))))

        // 3. Popup View
        let popup = DynamicPopupView(animationName: animationName, title: title, subtitle: subtitle)
        parentView.addSubview(popup)
        
        // Layout: self-sizing, safe-area aware
        let safe = parentView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: safe.centerYAnchor),
            
            popup.leadingAnchor.constraint(greaterThanOrEqualTo: safe.leadingAnchor, constant: 20),
            popup.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -20),
            popup.topAnchor.constraint(greaterThanOrEqualTo: safe.topAnchor, constant: 20),
            popup.bottomAnchor.constraint(lessThanOrEqualTo: safe.bottomAnchor, constant: -20),
            
            popup.widthAnchor.constraint(lessThanOrEqualTo: safe.widthAnchor, multiplier: 0.86),
            popup.widthAnchor.constraint(lessThanOrEqualToConstant: 340)
        ])

        // 4. Initial Animation State
        popup.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        // 5. Animate Popup In
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.6,
                       options: .curveEaseInOut,
                       animations: {
            popup.alpha = 1
            popup.transform = .identity
        }, completion: nil)
    }

    static func dismissPopup(from parentView: UIView) {
        parentView.subviews.forEach {
            if $0 is DynamicPopupView || $0.tag == 998 || $0.tag == 999 {
                $0.removeFromSuperview()
            }
        }
    }
    
    @objc private static func _dismissFromTap(_ recognizer: UITapGestureRecognizer) {
        guard let parent = recognizer.view?.superview else { return }
        dismissPopup(from: parent)
    }
}
