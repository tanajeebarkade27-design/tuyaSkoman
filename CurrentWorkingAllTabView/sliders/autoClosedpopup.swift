import UIKit

class AutoClosePopup: UIView {

    private let container = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)

    private var timer: Timer?
    private var autoCloseTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        startAnimatingProgress()
        startAutoCloseTimer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        startAnimatingProgress()
        startAutoCloseTimer()
    }

    private func setupUI() {

        backgroundColor = UIColor.black.withAlphaComponent(0.4)

        container.backgroundColor = UIColor.black
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false
        container.borderColor = .systemGray2
        container.borderWidth = 0.5
        addSubview(container)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textColor = .lightGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        progressView.progressTintColor = .systemGreen
        progressView.trackTintColor = UIColor.systemGray5
        progressView.progress = 0
        progressView.transform = CGAffineTransform(scaleX: 1, y: 1.5)

        let stack = UIStackView(arrangedSubviews: [
            iconImageView,
            progressView,
            titleLabel,
            messageLabel
        ])

        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([

            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 25),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -25),

            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50),

            progressView.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])

        // Popup animation
        container.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        container.alpha = 0

        UIView.animate(withDuration: 0.25) {
            self.container.transform = .identity
            self.container.alpha = 1
        }
    }

    func configure(icon: String, title: String, message: String) {
        iconImageView.image = UIImage(named: icon)
        titleLabel.text = title
        messageLabel.text = message
    }

    // MARK: Progress Animation
    private func startAnimatingProgress() {

        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            self.progressView.progress += 0.01

            if self.progressView.progress >= 1 {
                self.progressView.progress = 0
            }
        }
    }

    // MARK: Auto Close
    private func startAutoCloseTimer() {

        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.dismissPopup()
        }
    }

    func dismissPopup() {

        timer?.invalidate()
        autoCloseTimer?.invalidate()

        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
