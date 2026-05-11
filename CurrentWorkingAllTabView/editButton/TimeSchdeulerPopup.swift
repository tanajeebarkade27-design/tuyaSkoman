import UIKit
import AWSCore
import AWSIoT
class SetTimerPopupView: UIView, UIGestureRecognizerDelegate {
    var buttonDetail: ButtonDetails? 
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let popupView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let warningLabel = UILabel()
    private let statusLabel = UILabel()
    private let toggleSwitch = UISwitch()

    private let timePicker = UIDatePicker()
    private let dropdownButton = UIButton(type: .system)
    private let submitButton = UIButton(type: .system) // ✅ Submit button
    private let statusStack = UIStackView()
    
    private var timePickerHeightConstraint: NSLayoutConstraint!
    
    var onSubmit: ((Date, Bool) -> Void)? // Callback for submit (selected time + switch state)
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Blur background
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Full-screen blur behind the popup
        blurView.alpha = 1.0
        addSubview(blurView)
        
        // Popup container
        popupView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        popupView.layer.cornerRadius = 16
        popupView.layer.masksToBounds = true
        popupView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(popupView)
        
        // Title
        titleLabel.text = "Set Timer"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "You can schedule a timer for Today."
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(subtitleLabel)
        
        // Warning
        warningLabel.text = "Setting a new timer will override the existing schedule."
        warningLabel.font = UIFont.italicSystemFont(ofSize: 14)
        warningLabel.textColor = UIColor.systemYellow
        warningLabel.textAlignment = .center
        warningLabel.numberOfLines = 0
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(warningLabel)
        
        // Switch + label
        statusLabel.text = "Switch Status:"
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textColor = .white
        
        statusStack.axis = .horizontal
        statusStack.alignment = .center
        statusStack.distribution = .equalSpacing
        statusStack.addArrangedSubview(statusLabel)
        statusStack.addArrangedSubview(toggleSwitch)
        statusStack.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(statusStack)
        
        // Dropdown button
        dropdownButton.setTitle("Select Time ▼", for: .normal)
        dropdownButton.setTitleColor(.white, for: .normal)
        dropdownButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        dropdownButton.translatesAutoresizingMaskIntoConstraints = false
        dropdownButton.addTarget(self, action: #selector(toggleTimePicker), for: .touchUpInside)
        popupView.addSubview(dropdownButton)
        
        // Time picker
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.locale = Locale(identifier: "en_GB") // 24-hour
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(timePicker)
        timePicker.isHidden = true
        timePicker.tintColor = .white
        if #available(iOS 13.4, *) {
            // Wheels are readable on dark background.
            timePicker.setValue(UIColor.white, forKey: "textColor")
        }
        
        // Submit button
        submitButton.setTitle("Submit", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        submitButton.setTitleColor(.black, for: .normal)
        submitButton.backgroundColor = .white
        submitButton.layer.cornerRadius = 15
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        popupView.addSubview(submitButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor),
            popupView.widthAnchor.constraint(equalToConstant: 320),
            
            titleLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -20),
            
            warningLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            warningLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -20),
            
            statusStack.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 20),
            statusStack.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 20),
            statusStack.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -20),
            
            dropdownButton.topAnchor.constraint(equalTo: statusStack.bottomAnchor, constant: 20),
            dropdownButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
            timePicker.topAnchor.constraint(equalTo: dropdownButton.bottomAnchor, constant: 10),
            timePicker.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
            timePicker.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
            
            submitButton.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 20),
            submitButton.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 40),
            submitButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -40),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            submitButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -20)
        ])

        // Smooth expand/collapse without "jump" in height.
        timePickerHeightConstraint = timePicker.heightAnchor.constraint(equalToConstant: 0)
        timePickerHeightConstraint.isActive = true
        
        // Tap to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        blurView.addGestureRecognizer(tap)
    }
    
    // MARK: - Show & Dismiss
    func show(on parent: UIView) {
        self.frame = parent.bounds
        self.alpha = 0
        parent.addSubview(self)
        
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1.0
        }
    }
    
    @objc func dismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    var isSwitchOn: Bool {
           get { toggleSwitch.isOn }
           set { toggleSwitch.isOn = newValue }
       }
    // MARK: - Toggle time picker
    @objc private func toggleTimePicker() {
        let willShow = timePicker.isHidden
        timePicker.isHidden = false
        timePickerHeightConstraint.constant = willShow ? 216 : 0

        let arrow = willShow ? "▲" : "▼"
        dropdownButton.setTitle("Select Time \(arrow)", for: .normal)

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        } completion: { _ in
            if !willShow {
                self.timePicker.isHidden = true
            }
        }
    }
    
    // MARK: - Submit action
    @objc private func submitTapped() {
        onSubmit?(timePicker.date, toggleSwitch.isOn)
        dismiss()
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't dismiss when interacting inside the popup.
        if let v = touch.view, v.isDescendant(of: popupView) { return false }
        return true
    }
   

    // Your existing publish function
    
}
