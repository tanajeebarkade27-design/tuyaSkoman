import UIKit
import Lottie

class ShowPopupView: UIView {
    private let animationView: LottieAnimationView = {
        let animView = LottieAnimationView()
        animView.loopMode = .playOnce
        animView.contentMode = .scaleAspectFit
        return animView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()
    
    init(animationName: String, title: String, subtitle: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: 350, height: 150))
        setupView()
        configurePopup(animationName: animationName, title: title, subtitle: subtitle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .black
        layer.cornerRadius = 15
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 10
        

        addSubview(animationView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        animationView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            animationView.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            animationView.widthAnchor.constraint(equalToConstant: 60),
            animationView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }
    
    private func configurePopup(animationName: String, title: String, subtitle: String) {
        animationView.animation = LottieAnimation.named(animationName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        animationView.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.dismissPopup()
        }
    }
    
    private func dismissPopup() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - Popup Presenter with Background Image
class showPopupPresenter {
    static func showPopup1(on parentView: UIView, animationName: String, title: String, subtitle: String) {
        print ("new  popup")
        // 0. Create a full-screen container
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: parentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])

        // 1. Add background image to container
        let backgroundImageView = UIImageView(image: UIImage(named: "Screen Background")) // Replace with your image
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(backgroundImageView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // 2. Add popup to container
        let popup = ShowPopupView(animationName: animationName, title: title, subtitle: subtitle)
        popup.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        popup.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(popup)
        
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 300),
            popup.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // 3. Animate popup
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.6,
                       options: .curveEaseInOut,
                       animations: {
            popup.alpha = 1
            popup.transform = .identity
        })
        
        // 4. Optional: Remove container after popup dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIView.animate(withDuration: 0.3, animations: {
                containerView.alpha = 0
            }) { _ in
                containerView.removeFromSuperview()
            }
        }
    }
}
