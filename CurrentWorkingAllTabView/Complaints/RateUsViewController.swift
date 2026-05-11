import UIKit

final class RateUsViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var onSubmit: ((_ rating: Int, _ description: String) -> Void)?
    var ticketId: String?
    
    struct EmployeeOption {
        let id: String
        let name: String
    }
    
    var employeeOptions: [EmployeeOption] = [] {
        didSet {
            if isViewLoaded {
                configureEmployeesList()
            }
        }
    }
    private var selectedEmployeeIds = Set<String>()
    
    // Prefill (when rating already exists)
    var initialStars: Int?
    var initialComment: String?
    var initialSelectedEmployeeIds: [String]?
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let dimView = UIView()
    private let cardView = UIView()
    
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    private var starButtons: [UIButton] = []
    private let starsStack = UIStackView()
    
    private let descriptionTextView = UITextView()
    private let placeholderLabel = UILabel()
    
    private let submitButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .medium)
    
    private let employeesTitleLabel = UILabel()
    private let employeesTableView = UITableView(frame: .zero, style: .plain)
    private var employeesTableHeightConstraint: NSLayoutConstraint?
    
    private var selectedRating: Int = 0 {
        didSet { updateStars() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        
        // Extra dim on top of blur (keeps background from distracting)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        
        // Tap outside should dismiss keyboard only (not close popup)
        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        dismissKeyboardTap.cancelsTouchesInView = false
        dimView.addGestureRecognizer(dismissKeyboardTap)
        
        cardView.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        cardView.layer.cornerRadius = 18
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)
        
        titleLabel.text = "Rate Us"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        cardView.addSubview(closeButton)
        
        starsStack.axis = .horizontal
        starsStack.alignment = .center
        starsStack.distribution = .fillEqually
        starsStack.spacing = 8
        starsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(starsStack)
        
        starButtons = (1...5).map { idx in
            let b = UIButton(type: .system)
            b.tag = idx
            b.tintColor = .systemYellow
            b.setImage(UIImage(systemName: "star"), for: .normal)
            b.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            return b
        }
        starButtons.forEach { starsStack.addArrangedSubview($0) }
        
        descriptionTextView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        descriptionTextView.textColor = .white
        descriptionTextView.font = UIFont.systemFont(ofSize: 15)
        descriptionTextView.layer.cornerRadius = 12
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        descriptionTextView.delegate = self
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(descriptionTextView)
        
        placeholderLabel.text = "Write description..."
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.font = UIFont.systemFont(ofSize: 15)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.addSubview(placeholderLabel)
        
        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = .systemGreen
        submitButton.layer.cornerRadius = 12
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        cardView.addSubview(submitButton)

        activity.hidesWhenStopped = true
        activity.color = .white
        activity.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addSubview(activity)
        
        employeesTitleLabel.text = "Select Employee"
        employeesTitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        employeesTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        employeesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(employeesTitleLabel)
        
        employeesTableView.backgroundColor = .clear
        employeesTableView.separatorStyle = .none
        employeesTableView.dataSource = self
        employeesTableView.delegate = self
        employeesTableView.rowHeight = 42
        employeesTableView.alwaysBounceVertical = false
        employeesTableView.showsVerticalScrollIndicator = true
        employeesTableView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(employeesTableView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            starsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            starsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            starsStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            starsStack.heightAnchor.constraint(equalToConstant: 34),
            
            descriptionTextView.topAnchor.constraint(equalTo: starsStack.bottomAnchor, constant: 14),
            descriptionTextView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            descriptionTextView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 110),
            
            placeholderLabel.topAnchor.constraint(equalTo: descriptionTextView.topAnchor, constant: 10),
            placeholderLabel.leadingAnchor.constraint(equalTo: descriptionTextView.leadingAnchor, constant: 14),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: descriptionTextView.trailingAnchor, constant: -14),
            
            employeesTitleLabel.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 12),
            employeesTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            employeesTitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            employeesTableView.topAnchor.constraint(equalTo: employeesTitleLabel.bottomAnchor, constant: 8),
            employeesTableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            employeesTableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            submitButton.topAnchor.constraint(equalTo: employeesTableView.bottomAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            submitButton.widthAnchor.constraint(equalToConstant: 120),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            submitButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            activity.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor)
        ])
        
        employeesTableHeightConstraint = employeesTableView.heightAnchor.constraint(equalToConstant: 0)
        employeesTableHeightConstraint?.isActive = true
        configureEmployeesList()
        applyInitialValuesIfNeeded()
        
        updateStars()
    }
    
    private func applyInitialValuesIfNeeded() {
        if let stars = initialStars, stars > 0 {
            selectedRating = min(5, max(0, stars))
        }
        if let comment = initialComment, !comment.isEmpty {
            descriptionTextView.text = comment
            placeholderLabel.isHidden = true
        }
        if let ids = initialSelectedEmployeeIds {
            selectedEmployeeIds = Set(ids)
            employeesTableView.reloadData()
        }
    }
    
    private func configureEmployeesList() {
        if employeeOptions.isEmpty {
            employeesTitleLabel.isHidden = true
            employeesTableView.isHidden = true
            employeesTableHeightConstraint?.constant = 0
        } else {
            employeesTitleLabel.isHidden = false
            employeesTableView.isHidden = false
            let height = min(CGFloat(employeeOptions.count) * employeesTableView.rowHeight, 170)
            employeesTableHeightConstraint?.constant = height
            employeesTableView.reloadData()
        }
        view.layoutIfNeeded()
    }
    
    private func updateStars() {
        for b in starButtons {
            let filled = b.tag <= selectedRating
            b.setImage(UIImage(systemName: filled ? "star.fill" : "star"), for: .normal)
        }
    }
    
    @objc private func starTapped(_ sender: UIButton) {
        selectedRating = sender.tag
    }
    
    @objc private func submitTapped() {
        let tid = (ticketId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if tid.isEmpty {
            showAlert(title: "Failed", message: "Ticket id missing.")
            return
        }
        if selectedRating <= 0 {
            showAlert(title: "Failed", message: "Please select rating.")
            return
        }
        if employeeOptions.isEmpty == false, selectedEmployeeIds.isEmpty {
            showAlert(title: "Failed", message: "Please select employee.")
            return
        }
        
        let text = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            showAlert(title: "Failed", message: "Please enter description.")
            return
        }
        setSubmitting(true)
        
        let selectedEmployees = Array(selectedEmployeeIds)
        submitRating(ticketId: tid, stars: selectedRating, comment: text, assignedEmployees: selectedEmployees) { [weak self] ok, msg in
            guard let self else { return }
            DispatchQueue.main.async {
                self.setSubmitting(false)
                if ok {
                    self.onSubmit?(self.selectedRating, text)
                    let alert = UIAlertController(title: "Thank you!", message: "Thanks for rating.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismiss(animated: true)
                    })
                    self.present(alert, animated: true)
                } else {
                    self.showAlert(title: "Failed", message: msg ?? "Something went wrong.")
                }
            }
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func backgroundTapped() {
        view.endEditing(true)
    }
    
    private func setSubmitting(_ submitting: Bool) {
        submitButton.isEnabled = !submitting
        submitButton.alpha = submitting ? 0.75 : 1.0
        closeButton.isEnabled = !submitting
        if submitting {
            activity.startAnimating()
            submitButton.setTitle("", for: .normal)
        } else {
            activity.stopAnimating()
            submitButton.setTitle("Submit", for: .normal)
        }
    }
    
    private func submitRating(
        ticketId: String,
        stars: Int,
        comment: String,
        assignedEmployees: [String],
        completion: @escaping (_ ok: Bool, _ message: String?) -> Void
    ) {
        guard let url = URL(string: MainApi.url("skroman/support/rate/\(ticketId)")) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "stars": stars,
            "comment": comment,
            "assignedEmployees": assignedEmployees
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(false, "Failed to encode request.")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(false, error.localizedDescription)
                return
            }
            
            if let http = response as? HTTPURLResponse {
                print("⭐️ Rate API status:", http.statusCode)
            }
            if let data, let body = String(data: data, encoding: .utf8) {
                print("⭐️ Rate API response:", body)
            }
            
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = data.flatMap { String(data: $0, encoding: .utf8) }
                completion(false, body ?? "HTTP \(http.statusCode)")
                return
            }
            
            completion(true, nil)
        }.resume()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Employees table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        employeeOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "EmployeeCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) ?? UITableViewCell(style: .default, reuseIdentifier: cellId)
        let item = employeeOptions[indexPath.row]
        
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cell.selectionStyle = .none
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        
        cell.textLabel?.text = item.name
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        let checked = selectedEmployeeIds.contains(item.id)
        cell.accessoryType = .none
        cell.tintColor = .systemGreen
        cell.imageView?.tintColor = .systemGreen
        cell.imageView?.image = UIImage(systemName: checked ? "checkmark.square.fill" : "square")
        cell.imageView?.contentMode = .scaleAspectFit
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = employeeOptions[indexPath.row]
        if selectedEmployeeIds.contains(item.id) {
            selectedEmployeeIds.remove(item.id)
        } else {
            selectedEmployeeIds.insert(item.id)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

