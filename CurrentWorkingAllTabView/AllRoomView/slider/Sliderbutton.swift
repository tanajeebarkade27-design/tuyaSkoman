import UIKit

class SliderButton: UIButton {

    private let thumbView = UIView()
    private let powerImageView = UIImageView()
    private let statusLabel = UILabel()

    private var thumbLeadingConstraint: NSLayoutConstraint!
    private var thumbTrailingConstraint: NSLayoutConstraint!
    private var statusLabelLeadingConstraint: NSLayoutConstraint?
    private var statusLabelTrailingConstraint: NSLayoutConstraint?

    private(set) var isOn = false
    var onToggle: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .black
        layer.cornerRadius = 15
        translatesAutoresizingMaskIntoConstraints = false

        
        let thumbSize: CGFloat = 20 // Updated from 25
        let thumbPadding: CGFloat = 4

        thumbView.backgroundColor = .white
        thumbView.layer.cornerRadius = thumbSize / 2
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(thumbView)

        NSLayoutConstraint.activate([
            thumbView.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumbView.widthAnchor.constraint(equalToConstant: thumbSize),
            thumbView.heightAnchor.constraint(equalToConstant: thumbSize)
        ])


        thumbLeadingConstraint = thumbView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: thumbPadding)
        thumbTrailingConstraint = thumbView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -thumbPadding)
        // Initial state: off
        thumbLeadingConstraint.isActive = true

        // Power icon
        powerImageView.image = UIImage(systemName: "power")
        powerImageView.tintColor = .orange
        powerImageView.contentMode = .scaleAspectFit
        powerImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbView.addSubview(powerImageView)

        NSLayoutConstraint.activate([
            powerImageView.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor),
            powerImageView.centerYAnchor.constraint(equalTo: thumbView.centerYAnchor),
            powerImageView.widthAnchor.constraint(equalToConstant: 12),
            powerImageView.heightAnchor.constraint(equalToConstant: 12)
        ])

        // Status label
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textColor = .white
       
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        statusLabelTrailingConstraint = statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        statusLabelLeadingConstraint = statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        // Initial: show on the right (thumb is on the left)
        statusLabelTrailingConstraint?.isActive = true

        // Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleState))
        thumbView.addGestureRecognizer(tapGesture)
        thumbView.isUserInteractionEnabled = true

        addTarget(self, action: #selector(toggleState), for: .touchUpInside)
    }

    @objc private func toggleState() {
        isOn.toggle()
        onToggle?(isOn)
        updateStyle(animated: true)
    }

    func setState(_ on: Bool) {
        isOn = on
        updateStyle(animated: false)
    }

    private func updateStyle(animated: Bool) {
        let updates = {
            if self.isOn {
                // Thumb right
                self.thumbLeadingConstraint.isActive = false
                self.thumbTrailingConstraint.isActive = true
                // Label on left
                self.statusLabelTrailingConstraint?.isActive = false
                self.statusLabelLeadingConstraint?.isActive = true
                self.powerImageView.tintColor = .green
                // Update label
                self.statusLabel.text = "ON"

                // Glow effect
                self.thumbView.layer.borderWidth = 2
                self.thumbView.layer.borderColor = UIColor.systemGreen.cgColor
                self.thumbView.layer.shadowColor = UIColor.systemGreen.cgColor
                self.thumbView.layer.shadowRadius = 4
                self.thumbView.layer.shadowOpacity = 0.8
                self.thumbView.layer.shadowOffset = .zero
            } else {
                // Thumb left
                self.thumbTrailingConstraint.isActive = false
                self.thumbLeadingConstraint.isActive = true
                // Label on right
                self.statusLabelLeadingConstraint?.isActive = false
                self.statusLabelTrailingConstraint?.isActive = true
                self.powerImageView.tintColor = .orange
                // Update label
                self.statusLabel.text = "OFF"

                // Remove glow
                self.thumbView.layer.borderWidth = 0
                self.thumbView.layer.shadowOpacity = 0
            }

            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: updates)
        } else {
            updates()
        }
    }

}
