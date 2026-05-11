import UIKit

class PreferredTimePopup: UIView {

    var onTimeSelected: ((Date, Date) -> Void)?

    private let container = UIView()
    private let fromLabel = UILabel()
    private let toLabel = UILabel()
    private let fromPicker = UIDatePicker()
    private let toPicker = UIDatePicker()
    private let okButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {

        backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Container View
        container.backgroundColor = .white
        container.layer.cornerRadius = 18
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 330),
            container.heightAnchor.constraint(equalToConstant: 250)
        ])

        // ===== FROM LABEL =====
        fromLabel.text = "From:"
        fromLabel.font = UIFont.boldSystemFont(ofSize: 16)
        fromLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(fromLabel)

        // ===== FROM PICKER =====
        fromPicker.datePickerMode = .dateAndTime
        fromPicker.translatesAutoresizingMaskIntoConstraints = false
        fromPicker.minimumDate = Date()        // 🔥 Rule 1: Cannot pick past date
        fromPicker.addTarget(self, action: #selector(fromChanged), for: .valueChanged)
        container.addSubview(fromPicker)

        // ===== TO LABEL =====
        toLabel.text = "To:"
        toLabel.font = UIFont.boldSystemFont(ofSize: 16)
        toLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(toLabel)

        // ===== TO PICKER =====
        toPicker.datePickerMode = .dateAndTime
        toPicker.translatesAutoresizingMaskIntoConstraints = false
        toPicker.minimumDate = fromPicker.date.addingTimeInterval(3600)  // 🔥 Rule 2 default: 1 hour later
        toPicker.addTarget(self, action: #selector(toChanged), for: .valueChanged)
        container.addSubview(toPicker)

        // ===== OK BUTTON =====
        okButton.setTitle("OK", for: .normal)
        okButton.backgroundColor = UIColor.systemBlue
        okButton.setTitleColor(.white, for: .normal)
        okButton.layer.cornerRadius = 10
        okButton.addTarget(self, action: #selector(okTapped), for: .touchUpInside)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(okButton)

        // ===== CANCEL BUTTON =====
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = UIColor.lightGray
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 10
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(cancelButton)

        // ===== AUTO LAYOUT =====
        NSLayoutConstraint.activate([

            fromLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            fromLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            fromLabel.widthAnchor.constraint(equalToConstant: 60),

            fromPicker.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor),
            fromPicker.leadingAnchor.constraint(equalTo: fromLabel.trailingAnchor, constant: 10),
            fromPicker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),

            toLabel.topAnchor.constraint(equalTo: fromPicker.bottomAnchor, constant: 25),
            toLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            toLabel.widthAnchor.constraint(equalToConstant: 60),

            toPicker.centerYAnchor.constraint(equalTo: toLabel.centerYAnchor),
            toPicker.leadingAnchor.constraint(equalTo: toLabel.trailingAnchor, constant: 10),
            toPicker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),

            cancelButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 25),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 45),

            okButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            okButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -25),
            okButton.widthAnchor.constraint(equalToConstant: 120),
            okButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }

    // MARK: - RULE HANDLING

    
    @objc private func fromChanged() {

        // Update To picker minimum to at least 1 hour later
        toPicker.minimumDate = fromPicker.date.addingTimeInterval(3600)

        // If user-selected "To" is invalid, auto-correct it
        if toPicker.date < toPicker.minimumDate! {
            toPicker.setDate(toPicker.minimumDate!, animated: true)
        }
    }

    
    @objc private func toChanged() {
        let minTo = fromPicker.date.addingTimeInterval(3600)

        if toPicker.date < minTo {
            toPicker.setDate(minTo, animated: true)
        }
    }

    // MARK: - BUTTON ACTIONS

    @objc private func okTapped() {
        onTimeSelected?(fromPicker.date, toPicker.date)
        removeFromSuperview()
    }

    @objc private func cancelTapped() {
        removeFromSuperview()
    }
}
