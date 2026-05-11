//
//  ComplaintMsgViewController.swift
//  SkromanIsra
//
//  Created by Admin on 09/12/25.
//

import UIKit
 import SwiftKeychainWrapper
 

class ComplaintMsgViewController: UIViewController {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    
    @IBOutlet weak var msgView: UIView!
    
    @IBOutlet weak var msgTextFiled: UITextField!
    
    
    
    @IBOutlet weak var tracknumber: UILabel!
    
    
    @IBOutlet weak var messageTableView: UITableView!
    
    
    @IBOutlet weak var complStatusLabel: UILabel!
    
    
    @IBOutlet weak var complTitle: UILabel!
    
    @IBOutlet weak var complDate: UILabel!
    
    @IBOutlet weak var timelabel: UILabel!
    
    @IBOutlet weak var otpLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var compView: UIView!
    
    @IBOutlet weak var complViewheight: NSLayoutConstraint!
    
    @IBOutlet weak var complViewExpand: UIButton!
    
    var selectedMsgImage: UIImage? = nil
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var previewContainerView: UIView!

    @IBOutlet weak var deleteSelectedImage: UIButton!
    
    @IBOutlet weak var addImageButton: UIButton!
    var ticketId: String?
    var isExpanded = false

    var allMessages: [TicketMessage] = []

    var paymentViewRef: UIView?
    /// Storyboard: `messageTableView.top` = `compView.bottom` + constant — adjust when payment banner is shown so chat sits below it.
    private var messageTableViewTopToCompConstraint: NSLayoutConstraint?
    private let gapCompViewToPayment: CGFloat = 10
    private let gapPaymentToTable: CGFloat = 15
    /// Matches `showPaymentDetailsLabelIfNeeded` top inset below complaint card.
    private let gapCompViewToPaymentDetails: CGFloat = 14
    /// Extra space below “Payment Details” so chat rows don’t overlap the label.
    private let gapPaymentDetailsToTable: CGFloat = 18
    var ticket: ComplaintTicket?
    private var devicesForStack: [DeviceTrack] = []
    @IBOutlet weak var msgViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var deviceStackView: UIStackView!
    var payButtonRef: UIButton?
    
    private var keyboardObservers: [NSObjectProtocol] = []
    
    @IBOutlet weak var rateUsBtn: UIButton!
    
 
    @IBOutlet weak var paymentDetails: UILabel!
    var totalLabelRef: UILabel?
    var gstLabelRef: UILabel?
    var amountLabelRef: UILabel?
    var paymentDetailsLabelRef: UILabel?
    
    private lazy var inrFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
    
    private func formatINR(_ value: Double) -> String {
        let number = NSNumber(value: value)
        let formatted = inrFormatter.string(from: number) ?? "\(value)"
        return "₹\(formatted)"
    }

    private let refreshControl = UIRefreshControl()
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Default hidden until assignment check completes.
        rateUsBtn.isHidden = true
        
        // Make typed text clearly visible
        msgTextFiled.textColor = .white
        msgTextFiled.tintColor = .white
        if let placeholder = msgTextFiled.placeholder, !placeholder.isEmpty {
            msgTextFiled.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor.lightGray]
            )
        }
        msgView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        msgView.layer.cornerRadius = 12
        msgView.clipsToBounds = true
        
        rateUsBtn.addTarget(self, action: #selector(rateUsTapped), for: .touchUpInside)
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.text = ticket?.description ?? "-"
        self.view.layoutIfNeeded()
        compView.cornerRadius =  15
        compView.clipsToBounds =  true
        compView.backgroundColor =  UIColor.white.withAlphaComponent(0.10)
        let otp = ticket?.ticketOtp ?? 00
        otpLabel.text = "OTP \(otp) "
         
        if ticket?.status == "Completed" {
            complStatusLabel.backgroundColor = UIColor.systemGreen
             complStatusLabel.textColor = .white
        } else if ticket?.status == "Pending" {
            complStatusLabel.backgroundColor = UIColor.systemOrange
             complStatusLabel.textColor = .white
        } else if ticket?.status == "InProgress" {
          complStatusLabel.backgroundColor = UIColor.systemBlue
            complStatusLabel.textColor = .white
        } else {
            complStatusLabel.backgroundColor = .clear
            complStatusLabel.textColor = .black
        }
        complStatusLabel.text = ticket?.status
        complTitle.text = ticket?.complaintType
        descriptionLabel.text =  ticket?.description
      tracknumber.text =  "Trcak No\(ticket?.ticketId ?? "")"
       
        if let raisedDate = ticket?.createdAt?.toDate() {
            complDate.text = formatDate(raisedDate)
            timelabel.text = formatTime(raisedDate)
        }
        
        
        guard let ticket = ticket else { return }

        allMessages = ticket.messages ?? []

        print("User messages:", allMessages.filter { $0.senderType == "user" }.count)
        print("Employee messages:", allMessages.filter { $0.senderType != "user" }.count)
        messageTableView.register(UINib(nibName: "UserMessageCell", bundle: nil), forCellReuseIdentifier: "UserMessageCell")
        messageTableView.register(UINib(nibName: "AdminMessageCell", bundle: nil), forCellReuseIdentifier: "AdminMessageCell")


        messageTableView.dataSource =  self
        messageTableView.delegate =  self
        // Dynamic chat cells (XIB constraints fixed)
        messageTableView.estimatedRowHeight = 80
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTableView.keyboardDismissMode = .interactive
        messageTableView.reloadData()

        // Pull to refresh (scroll down)
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        messageTableView.refreshControl = refreshControl
        
        // Toggle complaint details card
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(toggleCompView))
        compView.addGestureRecognizer(tap1)
        compView.isUserInteractionEnabled = true
        
        // Tap anywhere to dismiss keyboard (chat behavior)
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardTap))
        dismissTap.cancelsTouchesInView = false
        dismissTap.delegate = self
        view.addGestureRecognizer(dismissTap)
        
        setupKeyboardHandling()
        
        
        previewContainerView.isHidden = true
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.clipsToBounds = true
        msgViewHeight.constant = 50
        
        // Devices section (shown only when ticket has devices)
        setupDevicesSection()
        
        setupDynamicPaymentView()
        updateCompViewHeight(animated: false)
        captureMessageTableViewTopConstraintIfNeeded()
        updateMessageTableViewOffsetForPaymentBanner()

        // Show RateUs only if ticket has employees assigned
        updateRateUsVisibility()
    }

    @objc private func handlePullToRefresh() {
        fetchLatestTicketAndReload()
    }

    private func fetchLatestTicketAndReload() {
        let userId = (KeychainWrapper.standard.string(forKey: "userId") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let id = (ticketId ?? ticket?.ticketId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty, !id.isEmpty else {
            refreshControl.endRefreshing()
            return
        }

        guard let url = URL(string: MainApi.url("skroman/support/user-tickets/\(userId)")) else {
            refreshControl.endRefreshing()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }
            DispatchQueue.main.async { self.refreshControl.endRefreshing() }

            if let error {
                print("❌ Refresh error:", error.localizedDescription)
                return
            }
            guard let data else { return }

            do {
                let decoded = try JSONDecoder().decode(ComplaintResponse.self, from: data)
                guard let updated = decoded.ticket.first(where: { ($0.ticketId ?? "") == id }) else {
                    print("⚠️ Ticket not found on refresh:", id)
                    return
                }

                DispatchQueue.main.async {
                    self.ticket = updated
                    self.ticketId = updated.ticketId
                    self.allMessages = updated.messages ?? []

                    // Refresh top card labels
                    self.complStatusLabel.text = updated.status
                    self.complTitle.text = updated.complaintType
                    self.descriptionLabel.text = updated.description
                    self.tracknumber.text = "Trcak No\(updated.ticketId ?? "")"
                    if let raisedDate = updated.createdAt?.toDate() {
                        self.complDate.text = self.formatDate(raisedDate)
                        self.timelabel.text = self.formatTime(raisedDate)
                    }

                    // Refresh dynamic sections
                    self.setupDevicesSection()
                    self.setupDynamicPaymentView()
                    self.updateCompViewHeight(animated: false)
                    self.updateRateUsVisibility()

                    self.messageTableView.reloadData()
                    self.scrollToBottomSafely(animated: false)
                }
            } catch {
                print("❌ Refresh decode error:", error)
            }
        }.resume()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMessageTableViewOffsetForPaymentBanner()
    }

    private func captureMessageTableViewTopConstraintIfNeeded() {
        guard messageTableViewTopToCompConstraint == nil,
              let container = messageTableView.superview else { return }

        for c in container.constraints {
            let table = messageTableView!
            let topToBottom =
                c.firstAttribute == .top && c.secondAttribute == .bottom &&
                (c.firstItem as? UIView) == table &&
                (c.secondItem as? UIView) == compView
            let bottomToTop =
                c.firstAttribute == .bottom && c.secondAttribute == .top &&
                (c.firstItem as? UIView) == compView &&
                (c.secondItem as? UIView) == table
            if topToBottom || bottomToTop {
                messageTableViewTopToCompConstraint = c
                return
            }
        }
    }

    /// Keeps chat below the payment pending banner and/or “Payment Details” row (same idea as pending panel).
    private func updateMessageTableViewOffsetForPaymentBanner() {
        captureMessageTableViewTopConstraintIfNeeded()
        guard let c = messageTableViewTopToCompConstraint else { return }

        if let payment = paymentViewRef, payment.superview != nil, payment.isDescendant(of: view) {
            payment.layoutIfNeeded()
            let paymentHeight = payment.bounds.height
            c.constant = gapCompViewToPayment + paymentHeight + gapPaymentToTable
        } else if let detailsLabel = paymentDetailsLabelRef,
                  detailsLabel.superview != nil,
                  detailsLabel.isDescendant(of: view) {
            detailsLabel.superview?.layoutIfNeeded()
            let targetWidth = max(0, view.bounds.width - gapCompViewToPaymentDetails - 18)
            let fitting = detailsLabel.systemLayoutSizeFitting(
                CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            let labelHeight = max(fitting.height, detailsLabel.bounds.height, detailsLabel.intrinsicContentSize.height)
            c.constant = gapCompViewToPaymentDetails + labelHeight + gapPaymentDetailsToTable
        } else {
            c.constant = gapPaymentToTable
        }
    }

    private func setupDevicesSection() {
        // Clear any previous rows
        deviceStackView.arrangedSubviews.forEach { view in
            deviceStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        // Prefer backend-provided devices (contains trackingId/flow). If not present,
        // fall back to extracting device IDs from ticket description + chat messages.
        let backendDevices = (ticket?.devices ?? []).compactMap { d -> DeviceTrack? in
            let id = (d.deviceId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return id.isEmpty ? nil : d
        }

        if !backendDevices.isEmpty {
            devicesForStack = backendDevices
        } else {
            var ids = Set<String>()

            // 1) From ticket description
            extractDevices(from: ticket?.description).forEach { ids.insert($0) }

            // 2) From all messages text
            for msg in allMessages {
                extractDevices(from: msg.message).forEach { ids.insert($0) }
            }

            let sorted = ids.sorted()
            devicesForStack = sorted.map { DeviceTrack(deviceId: $0, trackingId: nil, currentStage: nil, repairFlow: nil) }
        }

        guard !devicesForStack.isEmpty else {
            deviceStackView.isHidden = true
            return
        }

        deviceStackView.isHidden = false
        deviceStackView.axis = .vertical
        deviceStackView.spacing = 8
        deviceStackView.alignment = .fill
        deviceStackView.distribution = .fill

        // Header
        let header = UILabel()
        header.text = "Devices"
        header.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        header.textColor = .white
        deviceStackView.addArrangedSubview(header)

        for (index, device) in devicesForStack.enumerated() {
            let title = (device.deviceId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }

            let button = UIButton(type: .system)
            button.tag = index
            button.contentHorizontalAlignment = .leading
            button.setTitle("• \(title)", for: .normal)
            button.setTitleColor(.systemYellow, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            button.addTarget(self, action: #selector(trackDeviceTapped(_:)), for: .touchUpInside)
            deviceStackView.addArrangedSubview(button)
        }

        // If all deviceIds were empty, hide the section.
        let hasAnyDeviceRow = deviceStackView.arrangedSubviews.count > 1
        deviceStackView.isHidden = !hasAnyDeviceRow
        
        // Ensure immediate layout for newly added rows.
        deviceStackView.setNeedsLayout()
        deviceStackView.layoutIfNeeded()

        // Ensure comp view expands enough to show devices.
        updateCompViewHeight(animated: false)
    }
    
    private func updateRateUsVisibility() {
        let hasAssignments = !assignedEmployeeOptions().isEmpty
        rateUsBtn.isHidden = !hasAssignments
        rateUsBtn.isEnabled = hasAssignments
    }
    
    private func assignedEmployeeOptions() -> [RateUsViewController.EmployeeOption] {
        guard let tasks = ticket?.tasks else { return [] }
        
        var options: [RateUsViewController.EmployeeOption] = []
        for task in tasks {
            for employee in (task.employees ?? []) {
                let id = (employee.memberId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !id.isEmpty else { continue }
                let name = (employee.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                options.append(.init(id: id, name: name.isEmpty ? "Employee" : name))
            }
        }
        
        var seen = Set<String>()
        return options.filter { seen.insert($0.id).inserted }
    }
    
    @objc private func rateUsTapped() {
        let employeeOptions = assignedEmployeeOptions()
        guard !employeeOptions.isEmpty else {
            updateRateUsVisibility()
            return
        }
        
        let vc = RateUsViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.ticketId = ticket?.ticketId
        
        // Show assigned employees from tasks.
        vc.employeeOptions = employeeOptions
        
        // Prefill existing rating (if already rated)
        if let rating = ticket?.rating {
            vc.initialStars = rating.stars
            vc.initialComment = rating.comment
            vc.initialSelectedEmployeeIds = rating.ratedFor
        }
        vc.onSubmit = { rating, desc in
            print("⭐️ RateUs submitted rating=\(rating), desc=\(desc)")
            // TODO: wire to backend if needed
        }
        present(vc, animated: true)
    }
    
    deinit {
        for obs in keyboardObservers {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    @objc private func dismissKeyboardTap() {
        view.endEditing(true)
    }
    
    private func setupKeyboardHandling() {
        let center = NotificationCenter.default
        
        let willShow = center.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let self,
                let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { return }
            
            let keyboardInView = self.view.convert(frame, from: nil)
            let bottomInset = max(0, self.view.bounds.maxY - keyboardInView.minY) + 8
            
            self.messageTableView.contentInset.bottom = bottomInset
            self.messageTableView.verticalScrollIndicatorInsets.bottom = bottomInset
            self.scrollToBottomSafely(animated: true)
            
            // Keep input visible (old behavior)
            UIView.animate(withDuration: 0.25) {
                self.msgView.transform = CGAffineTransform(translationX: 0, y: -bottomInset + 30)
            }
        }
        
        let willHide = center.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.messageTableView.contentInset.bottom = 0
            self.messageTableView.verticalScrollIndicatorInsets.bottom = 0
            UIView.animate(withDuration: 0.25) {
                self.msgView.transform = .identity
            }
        }
        
        keyboardObservers = [willShow, willHide]
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
      
    }
    
    // Devices stack view removed from this screen.
    
    
    
    @objc func expandCompView() {

        descriptionLabel.numberOfLines = 0
        updateCompViewHeight(animated: true)
    }

    @objc func collapseCompView() {

        descriptionLabel.numberOfLines = 2
        updateCompViewHeight(animated: true)
    }

    @objc func toggleCompView() {

        isExpanded.toggle()

        if isExpanded {
            descriptionLabel.numberOfLines = 0
        } else {
            descriptionLabel.numberOfLines = 2
        }
        updateCompViewHeight(animated: true)
    }
    
    private func updateCompViewHeight(animated: Bool) {
        view.layoutIfNeeded()
        
        // Calculate required height for the whole `compView` (includes devices stack view).
        let width = compView.bounds.width
        guard width > 0 else { return }
        
        let maxHeight: CGFloat = 520
        let minHeight: CGFloat = 150
        
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let fitting = compView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        complViewheight.constant = min(maxHeight, max(minHeight, fitting.height))
        
        let animations = {
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: animations)
        } else {
            animations()
        }
    }
    @objc func trackDeviceTapped(_ sender: UIButton) {

        guard devicesForStack.indices.contains(sender.tag) else { return }
        let selectedDevice = devicesForStack[sender.tag]
        
        // If tracking details are not available from backend, don't navigate to an empty screen.
        let hasTracking = !(selectedDevice.trackingId ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasFlow = (selectedDevice.repairFlow?.isEmpty == false)
        if !hasTracking && !hasFlow {
            let alert = UIAlertController(
                title: "Tracking not available",
                message: "Tracking details are not available for this device yet.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "DeviceTrackingViewController") as? DeviceTrackingViewController else {
            return
        }

        vc.device = selectedDevice
        
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }
    
    func extractDevices(from description: String?) -> [String] {
        guard let desc = description else { return [] }

        let pattern = #"SKSL_[A-Za-z0-9]+"#

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let results = regex.matches(in: desc, range: NSRange(desc.startIndex..., in: desc))

            let devices = results.compactMap { match -> String? in
                if let range = Range(match.range, in: desc) {
                    return String(desc[range])
                }
                return nil
            }

            return Array(Set(devices)) // remove duplicates
        } catch {
            print("Regex error:", error)
            return []
        }
    }
  
    @IBAction func backbutton(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"   // Output: 10:12 AM
        return formatter.string(from: date)
    }


   

    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = false
            present(picker, animated: true)
        }
    }

    func openGallery() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    @IBAction func addImageButton(_ sender: Any) {
        
        let alert = UIAlertController(title: "Select Image", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
        
    }
    
    
    @IBAction func sendBtnTapped(_ sender: Any) {

        let text = msgTextFiled.text ?? ""

        if text.isEmpty && selectedMsgImage == nil { return }

        if let img = selectedMsgImage {
           
            sendMessageWithImage(text: text, image: img)
        } else {
           
            sendMessageWithoutImage(text: text)
        }
    }

    

    func scrollToBottom() {
        let index = IndexPath(row: allMessages.count - 1, section: 0)
        messageTableView.scrollToRow(at: index, at: .bottom, animated: true)
    }
    
    private func scrollToBottomSafely(animated: Bool) {
        guard allMessages.count > 0 else { return }
        let index = IndexPath(row: allMessages.count - 1, section: 0)
        if messageTableView.numberOfRows(inSection: 0) > index.row {
            messageTableView.scrollToRow(at: index, at: .bottom, animated: animated)
        }
    }
    func sendMessageWithoutImage(text: String) {

        guard let ticketId = ticket?.ticketId else { return }
        print ("ticketId is \(ticketId)")
      
        let urlString = MainApi.url("skroman/support/complaint/image/messages/\(ticketId)")
        guard let url = URL(string: urlString) else { return }
         print("url\(urlString)")

        let senderId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        let senderType = "user"

        let body: [String: Any] = [
            "senderId": senderId,
            "senderType": senderType,
            "message": text,
            "messageImage": []
        ]
print ("body parameter\(body)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ Error:", error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else { return }
            print("📡 Status Code:", httpResponse.statusCode)

            guard let data = data else { return }

            // 🔴 Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔴 RAW RESPONSE:\n", responseString)
            }

           
            do {
                let response = try JSONDecoder().decode(SendMessageResponse.self, from: data)
                
                print("✅ API Message:", response.msg ?? "")
                
                if let newMessage = response.message {
                    DispatchQueue.main.async {
                        self.allMessages.append(newMessage)
                        self.reloadChatUI()
                    }
                }
                
            } catch {
                print("❌ Decode error:", error)
            }

        }.resume()
    }

    func sendMessageWithImage(text: String, image: UIImage) {

        guard let ticketId = ticket?.ticketId else { return }

        let urlString = MainApi.url("skroman/support/complaint/image/messages/\(ticketId)")
        guard let url = URL(string: urlString) else { return }

        let senderId = KeychainWrapper.standard.string(forKey: "userId") ?? ""

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

      
        func appendText(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendText(name: "senderId", value: senderId)
        appendText(name: "senderType", value: "user")
        appendText(name: "message", value: text)

        // ✅ IMAGE PART (correct key: messageImage)
        if let imgData = image.jpegData(compressionQuality: 0.7) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"messageImage\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imgData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ Upload error:", error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else { return }
            print("📡 Status Code:", httpResponse.statusCode)

            guard let data = data else { return }

            // 🔴 Debug response
            if let str = String(data: data, encoding: .utf8) {
                print("🔴 RESPONSE:\n", str)
            }
            do {
                let response = try JSONDecoder().decode(SendMessageResponse.self, from: data)

                print("✅ API Msg:", response.msg ?? "")

                if let newMessage = response.message {
                    DispatchQueue.main.async {
                        self.allMessages.append(newMessage)
                        self.reloadChatUI()
                    }
                }

            } catch {
                print("❌ Decode error:", error)
            }

        }.resume()
    }

    func reloadChatUI() {
        self.messageTableView.reloadData()
        self.scrollToBottomSafely(animated: true)

        msgTextFiled.text = ""
        selectedMsgImage = nil
        previewContainerView.isHidden = true
        previewImageView.image = nil
    }


    
    @IBAction func deleteSelectedImage(_ sender: Any) {

      
        selectedMsgImage = nil

       
        previewContainerView.isHidden = true
        previewImageView.image = nil

      
        msgViewHeight.constant = 60   // ← set your original height
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    func createPaymentView() -> UIView {

        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Payment pending"
        titleLabel.font = UIFont.boldSystemFont(ofSize:14)
        titleLabel.textColor = .systemYellow

        // Amount Label
        let amountLabel = UILabel()
        amountLabel.font = UIFont.systemFont(ofSize: 14)
        amountLabel.textColor = .white
        
        // GST Label
        let gstLabel = UILabel()
        gstLabel.font = UIFont.systemFont(ofSize: 14)
        gstLabel.textColor = .white
        
        // Total Payable (bold)
        let totalPayableLabel = UILabel()
        totalPayableLabel.font = UIFont.boldSystemFont(ofSize: 16)
        totalPayableLabel.textColor = .white
        

        // Button
        let payButton = UIButton(type: .system)
        payButton.setTitle("Pay Now", for: UIControl.State.normal)
        payButton.setTitleColor(.white, for: UIControl.State.normal)
        payButton.backgroundColor = .systemGreen
        payButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        payButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        payButton.layer.cornerRadius = 17.5 // capsule for 35pt height
        payButton.clipsToBounds = true
        payButton.addTarget(self, action: #selector(payNowTapped(_:)), for: .touchUpInside)

        // Save references ✅
        self.amountLabelRef = amountLabel
        self.gstLabelRef = gstLabel
        self.totalLabelRef = totalPayableLabel
        self.payButtonRef = payButton

        // Bottom row (GST + Button)
        let bottomStack = UIStackView(arrangedSubviews: [gstLabel, payButton])
        bottomStack.axis = .horizontal
        bottomStack.distribution = .equalSpacing
        bottomStack.alignment = .center

        // Main stack
        let mainStack = UIStackView(arrangedSubviews: [titleLabel, amountLabel, totalPayableLabel, bottomStack])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        return container
    }
    func setupDynamicPaymentView() {

        guard let ticket = ticket else { return }

        // Show payment view if we have any payable amount
        let payable = ticket.totalPayableAmount ?? ticket.amount ?? 0
        guard payable > 0 else {
            paymentViewRef?.removeFromSuperview()
            paymentViewRef = nil
            hidePaymentDetailsLabelIfNeeded()
            return
        }
        
        let paidStatuses: Set<String> = ["PAID", "SUCCESS", "COMPLETED"]
        let isPaid = paidStatuses.contains((ticket.paymentStatus ?? "").uppercased())
        
        if isPaid {
            paymentViewRef?.removeFromSuperview()
            paymentViewRef = nil
            updateMessageTableViewOffsetForPaymentBanner()
            showPaymentDetailsLabelIfNeeded()
            return
        } else {
            hidePaymentDetailsLabelIfNeeded()
        }

        // Avoid adding multiple times
        let paymentView: UIView
        if let existing = paymentViewRef {
            paymentView = existing
        } else {
            paymentView = createPaymentView()
            self.view.addSubview(paymentView)
            paymentViewRef = paymentView
            
            NSLayoutConstraint.activate([
                paymentView.topAnchor.constraint(equalTo: compView.bottomAnchor, constant: gapCompViewToPayment),
                paymentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                paymentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
            ])
        }

        // ✅ Fill data
        let amount = ticket.amount ?? 0
        let backendGst = ticket.gstAmount ?? 0
        let gst18 = (amount * 0.18)
        let gstToShow = backendGst > 0 ? backendGst : gst18
        let total = ticket.totalPayableAmount ?? (amount + gstToShow)
        
        amountLabelRef?.text = "Amount: \(formatINR(amount))"
        gstLabelRef?.text = "GST (18%): \(formatINR(gstToShow))"
        totalLabelRef?.text = "Total Payable: \(formatINR(total))"

        // ✅ Handle payment status
        if ticket.paymentStatus == "PAID" {
            payButtonRef?.setTitle("Paid", for: UIControl.State.normal)
            payButtonRef?.isEnabled = false
            payButtonRef?.backgroundColor = .gray
        } else {
            payButtonRef?.setTitle("Pay Now", for: .normal)
            payButtonRef?.isEnabled = true
            payButtonRef?.backgroundColor = .systemGreen
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateMessageTableViewOffsetForPaymentBanner()
    }

    private func showPaymentDetailsLabelIfNeeded() {
        if paymentDetailsLabelRef != nil { return }
        
        let label = UILabel()
        label.text = "Payment Details"
        label.textColor = .systemGreen
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(paymentDetailsTapped))
        label.addGestureRecognizer(tap)
        
        view.addSubview(label)
        paymentDetailsLabelRef = label
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: compView.bottomAnchor, constant: gapCompViewToPaymentDetails),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18)
        ])

        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateMessageTableViewOffsetForPaymentBanner()
    }
    
    private func hidePaymentDetailsLabelIfNeeded() {
        paymentDetailsLabelRef?.removeFromSuperview()
        paymentDetailsLabelRef = nil
        updateMessageTableViewOffsetForPaymentBanner()
    }
    
    @objc private func paymentDetailsTapped() {
        guard let ticket else { return }
        
        let popup = PaymentSuccessPopup()
        let details = PaymentSuccessPopup.Details(
            transactionId: ticket.paymentTransactionId ?? "-",
            totalAmount: ticket.amount ?? 0,
            couponOffAmount: ticket.discountAmount ?? 0,
            gstAmount: ticket.gstAmount ?? 0,
            finalAmount: ticket.paybleAmount ?? ticket.totalPayableAmount ?? 0
        )
        popup.configure(with: details)
        popup.present(in: view)
    }
    
    @objc func payNowTapped(_ sender: UIButton) {
        let vc = PaymentComplaintVc()
        vc.ticket = ticket
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
extension ComplaintMsgViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let msg = allMessages[indexPath.row]
        
        if msg.senderType == "user" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserMessageCell", for: indexPath) as! UserMessageCell
            let imageURL: URL? = {
                guard let images = msg.messageImage, let firstImage = images.first else { return nil }
                return URL(string: firstImage)
            }()
            cell.configure(message: msg.message, imageURL: imageURL)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdminMessageCell", for: indexPath) as! AdminMessageCell

            cell.messageLabel.text = msg.message

//            cell.profileImageView.image = UIImage(named: "admin_placeholder")

            return cell
        }

    }
    
    // Use automatic dimension for chat sizing.
    
  
   

  
    
}

extension ComplaintMsgViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {

        // Allow taps inside controls (text field, buttons) without dismissing.
        if touch.view?.isDescendant(of: msgView) == true { return false }
        if touch.view?.isDescendant(of: messageTableView) == true { return false }
        if touch.view?.isDescendant(of: compView) == true { return false }
        if let pv = paymentViewRef, touch.view?.isDescendant(of: pv) == true { return false }
        if let dl = paymentDetailsLabelRef, touch.view?.isDescendant(of: dl) == true { return false }
        return true
    }
}


 
extension ComplaintMsgViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        picker.dismiss(animated: true)

        if let img = info[.originalImage] as? UIImage {

            selectedMsgImage = img

            previewImageView.contentMode = .scaleAspectFit
            previewImageView.clipsToBounds = true
            msgViewHeight.constant =  150
            previewContainerView.isHidden = false
            previewImageView.image = img
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
