//
//  CompRegisterViewController.swift
//  SkromanIsra
//
//  Created by Admin on 01/12/25.
//

import UIKit
import PhotosUI
import SwiftKeychainWrapper
class CompRegisterViewController: UIViewController  {
    
    @IBOutlet weak var complaintView: UIView!
    
    @IBOutlet weak var complaintTypeText: UITextField!
    
    @IBOutlet weak var addImageLabel: UILabel!
    
    @IBOutlet weak var imageCollectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var imageViewCollectionView: UICollectionView!
    
    @IBOutlet weak var issueListLabel: UILabel!
    
    @IBOutlet weak var issueLabelHeight: NSLayoutConstraint!
    
    @IBOutlet weak var submitBtn: UIButton!
    
    @IBOutlet weak var complaintDescriptionText: UITextView!
    
    @IBOutlet weak var descriptionHeight: NSLayoutConstraint!
    
    @IBOutlet weak var addImageView: UIView!
    
    @IBOutlet weak var locationView: UIView!
    
    
    @IBOutlet weak var prefferdTimeView: UIView!
    
    @IBOutlet weak var fromDateLabel: UILabel!
    
    @IBOutlet weak var ToDatelabel: UILabel!
    
    var descriptionPlaceholder: UILabel!
    
    
    @IBOutlet weak var userAddressLabel: UILabel!
    
    var selectedImages: [UIImage] = []
    var selectedVideoURL: URL?
    
    var selectedHomeId: String = ""
    var selectedRoomDeviceButtonList: [SelectedRoomData] = []
    
    var selectedLatitude: Double = 0.0
    var selectedLongitude: Double = 0.0
    var selectedAddress: String = ""

    var societyId: String = ""
    var complaintCategory: String = ""
    
    private let complaintTypes: [String] = [
        "Device Repairing",
        "Lock Repairing",
        "New Device Installation",
        "New Lock Installation",
        "Device Replacement",
        "Lock Replacement",
        "Visit",
        "Demo",
        "Re-installation",
        "App config",
        "Alexa Config",
        "Other"
    ]
    
    private var complaintTypeDimView: UIView?
    private var complaintTypeDropdownContainer: UIView?
    private var complaintTypeTableView: UITableView?
    private var isComplaintTypeDropdownShown = false
    
    private var complaintTypeAnchorView: UIView { complaintTypeText }
    private var didUpdateIssueLabelHeight = false
    
    private weak var cachedScrollView: UIScrollView?
    private var keyboardObservers: [NSObjectProtocol] = []
    
    private var issueDetailsLabel: UILabel?
    
   
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    var totalMediaCount: Int {
        return selectedImages.count + (selectedVideoURL == nil ? 0 : 1)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.setTitleColor(.white, for: .highlighted)
        submitBtn.tintColor = .white
        submitBtn.adjustsImageWhenHighlighted = false
        imageCollectionViewHeight.constant = 0
       
        addImageView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        locationView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        complaintTypeText.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        prefferdTimeView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        complaintDescriptionText.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        imageViewCollectionView.delegate = self
          imageViewCollectionView.dataSource = self
        
        setupAddImageLabelTap()
        registerCell()
        
        print("Selected Home ID:", selectedHomeId)

           for item in selectedRoomDeviceButtonList {
               print("Room:", item.roomName)
               print("Device:", item.deviceName)
               print("Buttons:", item.buttonDetails.map { $0.buttonName })
           }
        
        var formattedLines: [String] = []

        for (index, item) in selectedRoomDeviceButtonList.enumerated() {
            
            let room = item.roomName
            let device = item.deviceName
            let buttons = item.buttonDetails.map { $0.buttonName }.joined(separator: ", ")
            
            let line = "Issue \(index + 1) : \(room) -> \(device) -> \(buttons)"
            formattedLines.append(line)
            
            print("line \(line)")
        }
        ensureIssueDetailsLabel()
        // Join with new lines
        let finalText = formattedLines.joined(separator: "\n")
        print("FINAL ISSUE TEXT:", finalText)

        issueDetailsLabel?.text = finalText.isEmpty ? "" : finalText
 
     
        issueListLabel.textColor = .white
        ensureIssueDetailsLabel()
       
        // Height will be updated after AutoLayout sets correct label width.
        didUpdateIssueLabelHeight = false
        DispatchQueue.main.async { [weak self] in
            self?.updateIssueLabelHeightIfPossible()
        }
        complaintDescriptionText.delegate = self
        complaintDescriptionText.isScrollEnabled = false
        complaintDescriptionText.textContainer.lineBreakMode = .byWordWrapping
        complaintDescriptionText.textContainer.maximumNumberOfLines = 0
        complaintDescriptionText.layer.cornerRadius = 12
        complaintDescriptionText.layer.masksToBounds = true
        
        complaintView.layer.cornerRadius = 10
        complaintView.layer.masksToBounds = true
        complaintView.borderColor = .systemGreen
        complaintView.borderWidth =  1
        complaintTypeText.delegate = self
        complaintTypeText.tintColor = .clear
        complaintTypeText.inputView = UIView() // prevent keyboard
        complaintTypeText.inputAccessoryView = UIView()
        complaintTypeText.layer.cornerRadius = 12
        complaintTypeText.layer.masksToBounds = true
        complaintTypeText.layer.borderWidth = 1
        complaintTypeText.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        complaintTypeText.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        complaintTypeText.leftViewMode = .always
        if complaintTypeText.placeholder?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            complaintTypeText.placeholder = "Select complaint type"
        }
        complaintTypeText.attributedPlaceholder = NSAttributedString(
            string: complaintTypeText.placeholder ?? "Select complaint type",
            attributes: [
                .foregroundColor: UIColor.lightGray.withAlphaComponent(0.85)
            ]
        )
        
        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTapToDismissKeyboard))
        dismissKeyboardTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissKeyboardTap)
        
        setupKeyboardAvoidance()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(openLocationPicker))
        locationView.addGestureRecognizer(tap)
        locationView.isUserInteractionEnabled = true
        let timeTap = UITapGestureRecognizer(target: self, action: #selector(openPreferredTimePopup))
        prefferdTimeView.addGestureRecognizer(timeTap)
        prefferdTimeView.isUserInteractionEnabled = true
        complaintDescriptionText.delegate = self

        // Placeholder Label
        descriptionPlaceholder = UILabel()
        descriptionPlaceholder.text = "Describe issue"
        descriptionPlaceholder.font = UIFont.systemFont(ofSize: 15)
        descriptionPlaceholder.textColor = UIColor.lightGray
        descriptionPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        complaintDescriptionText.addSubview(descriptionPlaceholder)

        // Add constraints
        NSLayoutConstraint.activate([
            descriptionPlaceholder.topAnchor.constraint(equalTo: complaintDescriptionText.topAnchor, constant: 8),
            descriptionPlaceholder.leadingAnchor.constraint(equalTo: complaintDescriptionText.leadingAnchor, constant: 5)
        ])

        setRoundedCorners(to: complaintView, radius: 20)
        setRoundedCorners(to: locationView, radius: 12)
        setRoundedCorners(to: prefferdTimeView, radius: 12)
        setRoundedCorners(to: addImageView, radius: 12)
    }
    
    @objc private func handleBackgroundTapToDismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isComplaintTypeDropdownShown {
            layoutComplaintTypeDropdown()
        }
        if !didUpdateIssueLabelHeight {
            updateIssueLabelHeightIfPossible()
        }
    }
    
     
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ensureIssueDetailsLabel()

        if let label = issueDetailsLabel,
           (label.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            label.text = " "
        }
        
        updateIssueLabelHeightIfPossible()
    }
    deinit {
        for obs in keyboardObservers {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func updateIssueLabelHeightIfPossible() {
        guard let detailsLabel = issueDetailsLabel else { return }
        let labelWidth = detailsLabel.bounds.width
        guard labelWidth > 0 else { return }

        // Use AutoLayout fitting for stackView/scrollView scenarios.
        let targetSize = CGSize(width: labelWidth, height: UIView.layoutFittingCompressedSize.height)
        let fittingSize = detailsLabel.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        // `issueLabelHeight` is connected to the title label height (35 in storyboard). Keep it.
        // The details label expands naturally in the stack view.
        _ = fittingSize
        didUpdateIssueLabelHeight = true
        view.layoutIfNeeded()
    }
    
    private func findContainingStackView(for view: UIView) -> UIStackView? {
        var current: UIView? = view.superview
        while let c = current {
            if let stack = c as? UIStackView {
                return stack
            }
            current = c.superview
        }
        return nil
    }
    
    private func ensureIssueDetailsLabel() {
        if issueDetailsLabel != nil { return }
        guard let stack = findContainingStackView(for: issueListLabel) else { return }
        
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        
        if let titleIndex = stack.arrangedSubviews.firstIndex(of: issueListLabel) {
            stack.insertArrangedSubview(label, at: min(titleIndex + 1, stack.arrangedSubviews.count))
        } else {
            stack.addArrangedSubview(label)
        }
        
        issueDetailsLabel = label
    }
    
    private func findFirstScrollView(in root: UIView) -> UIScrollView? {
        if let sv = root as? UIScrollView { return sv }
        for v in root.subviews {
            if let found = findFirstScrollView(in: v) { return found }
        }
        return nil
    }
    
    private func contentScrollView() -> UIScrollView? {
        if let cachedScrollView { return cachedScrollView }
        let found = findFirstScrollView(in: view)
        cachedScrollView = found
        return found
    }
    
    private func setupKeyboardAvoidance() {
        let center = NotificationCenter.default
        
        let willShow = center.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let self,
                let sv = self.contentScrollView(),
                let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { return }
            
            let keyboardInView = self.view.convert(frame, from: nil)
            let bottomInset = max(0, self.view.bounds.maxY - keyboardInView.minY) + 12
            
            sv.contentInset.bottom = bottomInset
            sv.verticalScrollIndicatorInsets.bottom = bottomInset
        }
        
        let willHide = center.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let sv = self.contentScrollView() else { return }
            sv.contentInset.bottom = 0
            sv.verticalScrollIndicatorInsets.bottom = 0
        }
        
        keyboardObservers = [willShow, willHide]
    }
    
    
    func setRoundedCorners(to view: UIView, radius: CGFloat) {
        view.layer.cornerRadius = radius
        view.layer.masksToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    @objc func openLocationPicker() {
        let vc = LocationPickerViewController()
        vc.onLocationSelected = { lat, long, address in
            self.selectedLatitude = lat
               self.selectedLongitude = long
               self.selectedAddress = address
            print("Latitude:", lat)
            print("Longitude:", long)
            print("Address:", address)

            // Show in your label or text field
            self.userAddressLabel.text = """
            Address: \(address)
            """
        }

        navigationController?.pushViewController(vc, animated: true)
    }


    @objc func openPreferredTimePopup() {

        let popup = PreferredTimePopup(frame: view.bounds)

        popup.onTimeSelected = { fromDate, toDate in
            print("From:", fromDate)
            print("To:", toDate)

            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy, HH:mm"

            let fromText = formatter.string(from: fromDate)
            let toText = formatter.string(from: toDate)

            self.fromDateLabel.text = "From: \(fromText)"
            self.ToDatelabel.text = "To: \(toText)"

        }

        view.addSubview(popup)
    }


    func addGradientappBorder(to view: UIView, cornerRadius: CGFloat, lineWidth: CGFloat) {
        // Remove old gradient layer if present
        view.layer.sublayers?.removeAll(where: { $0.name == "GradientBorder" })

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientBorder"

        // Set gradient colors (green → blue) with some transparency
        gradientLayer.colors = [
            UIColor.green.withAlphaComponent(0.5).cgColor,
            UIColor.blue.withAlphaComponent(0.5).cgColor
        ]

        // Set gradient direction: top-left to bottom-right
        gradientLayer.startPoint = CGPoint(x: 0, y: 0) // top-left
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)   // bottom-right

        gradientLayer.frame = view.bounds

        // Mask with shape path (rounded border only)
        let shapeLayer = CAShapeLayer()
        let insetRect = view.bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        shapeLayer.path = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius).cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor

        gradientLayer.mask = shapeLayer

        view.layer.addSublayer(gradientLayer)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func showComplaintTypeDropdown() {
        guard !isComplaintTypeDropdownShown else { return }
        isComplaintTypeDropdownShown = true
        
        // Dim background
        let dim = UIView(frame: view.bounds)
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dim.alpha = 0
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dim.isUserInteractionEnabled = true
        let dimTap = UITapGestureRecognizer(target: self, action: #selector(dismissComplaintTypeDropdown))
        dim.addGestureRecognizer(dimTap)
        view.addSubview(dim)
        complaintTypeDimView = dim
        
        // Dropdown container
        let container = UIView(frame: .zero)
        container.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        container.layer.cornerRadius = 14
        container.layer.masksToBounds = true
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        container.alpha = 0
        view.addSubview(container)
        complaintTypeDropdownContainer = container
        
        // Table
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.rowHeight = 46
        table.showsVerticalScrollIndicator = true
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "ComplaintTypeCell")
        container.addSubview(table)
        complaintTypeTableView = table
        
        layoutComplaintTypeDropdown()
        
        UIView.animate(withDuration: 0.2) {
            dim.alpha = 1
            container.alpha = 1
        }
    }
    
    private func layoutComplaintTypeDropdown() {
        guard
            let container = complaintTypeDropdownContainer,
            let table = complaintTypeTableView
        else { return }
        
        view.layoutIfNeeded()
        
        let anchorFrame = complaintTypeAnchorView.convert(complaintTypeAnchorView.bounds, to: view)
        let horizontalPadding: CGFloat = 16
        let spacing: CGFloat = 8
        
        let maxWidth = view.bounds.width - (horizontalPadding * 2)
        let width = min(maxWidth, max(anchorFrame.width, 240))
        
        let desiredHeight = CGFloat(complaintTypes.count) * table.rowHeight
        let maxHeight = min(view.bounds.height * 0.55, 420)
        let height = min(desiredHeight, maxHeight)
        
        var x = anchorFrame.minX
        x = max(horizontalPadding, min(x, view.bounds.width - horizontalPadding - width))
        
        var y = anchorFrame.maxY + spacing
        let bottomLimit = view.bounds.height - horizontalPadding
        if y + height > bottomLimit {
            // If not enough room below, show above the field.
            y = max(horizontalPadding, anchorFrame.minY - spacing - height)
        }
        
        container.frame = CGRect(x: x, y: y, width: width, height: height)
        table.frame = container.bounds
    }
    
    @objc private func dismissComplaintTypeDropdown() {
        guard isComplaintTypeDropdownShown else { return }
        isComplaintTypeDropdownShown = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.complaintTypeDimView?.alpha = 0
            self.complaintTypeDropdownContainer?.alpha = 0
        }, completion: { _ in
            self.complaintTypeTableView?.removeFromSuperview()
            self.complaintTypeDropdownContainer?.removeFromSuperview()
            self.complaintTypeDimView?.removeFromSuperview()
            self.complaintTypeTableView = nil
            self.complaintTypeDropdownContainer = nil
            self.complaintTypeDimView = nil
        })
    }
    
    func setupAddImageLabelTap() {
        addImageLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(addImageTapped))
        addImageLabel.addGestureRecognizer(tap)
    }

    @objc func addImageTapped() {
        let shouldShow = imageCollectionViewHeight.constant == 0

        imageCollectionViewHeight.constant = shouldShow ? 80
        : 0

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

  
    func showMediaSelectionOptions() {
        let alert = UIAlertController(title: "Add Media", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image"]  // only photos
        present(picker, animated: true)
    }
    

    func openGallery() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5  // max 4 images + 1 video
        config.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func expandCollectionViewIfNeeded() {
        if imageCollectionViewHeight.constant == 0 {
            imageCollectionViewHeight.constant = 100
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }

    func registerCell(){
        let uiNib =  UINib(nibName: "CompImageCollectionViewCell", bundle: nil)
        imageViewCollectionView.register(uiNib, forCellWithReuseIdentifier: "CompImageCollectionViewCell")
    }
    
    
    @IBAction func submitButton(_ sender: Any) {
        if !validateComplaintInputsForSubmit() { return }
        showTermsAndConditionsThenSubmit()
    }
    
    private func validateComplaintInputsForSubmit() -> Bool {
        if complaintTypeText.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            showAlert(title: "Failed", message: "Please select complaint type.")
            return false
        }

        if complaintDescriptionText.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            showAlert(title: "Failed", message: "Please enter complaint description.")
            return false
        }

        if selectedLatitude == 0 || selectedLongitude == 0 {
            showAlert(title: "Failed", message: "Please select a location.")
            return false
        }

        let fromTime = fromDateLabel.text?.replacingOccurrences(of: "From: ", with: "").trimmingCharacters(in: .whitespaces) ?? ""
        let toTime = ToDatelabel.text?.replacingOccurrences(of: "To: ", with: "").trimmingCharacters(in: .whitespaces) ?? ""

        if fromTime.isEmpty || toTime.isEmpty {
            showAlert(title: "Failed", message: "Please select preferred time.")
            return false
        }

        return true
    }
    
    private func showTermsAndConditionsThenSubmit() {
        view.endEditing(true)

        let vc = TermsAndConditionsViewController()
        vc.onAccepted = { [weak self] in
            self?.submitComplaint()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func submitComplaint() {

        
        // VALIDATION
        if complaintTypeText.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            showAlert(title: "Failed", message: "Please select complaint type.")
            return
        }

        if complaintDescriptionText.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            showAlert(title: "Failed", message: "Please enter complaint description.")
            return
        }

        if selectedLatitude == 0 || selectedLongitude == 0 {
            showAlert(title: "Failed", message: "Please select a location.")
            return
        }

        let fromTime = fromDateLabel.text?.replacingOccurrences(of: "From: ", with: "").trimmingCharacters(in: .whitespaces) ?? ""
        let toTime = ToDatelabel.text?.replacingOccurrences(of: "To: ", with: "").trimmingCharacters(in: .whitespaces) ?? ""

        if fromTime.isEmpty || toTime.isEmpty {
            showAlert(title: "Failed", message: "Please select preferred time.")
            return
        }

        let url = URL(string: MainApi.url("skroman/support/createTicket"))!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let issueText = issueDetailsLabel?.text ?? ""
        let userTypedDescription = complaintDescriptionText.text ?? ""

        let finalDescription =
        """
        \(issueText)

        User Description:
        \(userTypedDescription)
        """

        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        let homeId = selectedHomeId
        let complaintType = complaintTypeText.text ?? ""

//        let fromTime = fromDateLabel.text?.replacingOccurrences(of: "From: ", with: "") ?? ""
//        let toTime = ToDatelabel.text?.replacingOccurrences(of: "To: ", with: "") ?? ""

        let lat = selectedLatitude
        let lng = selectedLongitude

        var body = Data()

        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // REQUIRED FIELDS
        appendField("userId", userId)
        appendField("homeId", homeId)
        appendField("createdBy", "user")
        appendField("complaintType", complaintType)
        appendField("description", finalDescription)

        appendField("clientAvailability[from]", fromTime)
        appendField("clientAvailability[to]", toTime)

        appendField("location[lat]", "\(lat)")
        appendField("location[lng]", "\(lng)")
        appendField("societyId", societyId)
        appendField("complaintCategory", complaintCategory)

      
        for (index, img) in selectedImages.enumerated() {
            if let imgData = img.jpegData(compressionQuality: 0.7) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"ticketImages\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imgData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }

       
        if let videoURL = selectedVideoURL,
           let videoData = try? Data(contentsOf: videoURL) {

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"ticketVideos\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)

        }


        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        print("🚀 FINAL MULTIPART BODY:\n\(String(data: body, encoding: .utf8) ?? "NOT UTF8")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error:", error.localizedDescription)
                return
            }

            guard let data = data else { return }

            // PRINT RAW RESPONSE
            if let raw = String(data: data, encoding: .utf8) {
                print("🔥 RAW RESPONSE:\n", raw)
            }

            // JSON PARSING
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["msg"] as? String {

                    if message == "Ticket created successfully." {
                        self.showAlert(title: "Success", message: "Your complaint has been submitted successfully.")
                    } else {
                        self.showAlert(title: "Error", message: message)
                    }
                }
            } catch {
                print("JSON ERROR:", error)
            }

        }.resume()

    }
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                // After successful complaint creation, return to Main Home screen.
                if title.lowercased() == "success" {
                    self.navigateToMainHome()
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    private func navigateToMainHome() {
        // If MainHomeViewController exists in current navigation stack, pop to it.
        if let nav = navigationController {
            if let existing = nav.viewControllers.first(where: { $0 is MainHomeViewController }) {
                nav.popToViewController(existing, animated: true)
                return
            }
        }
        
        // Otherwise, instantiate and make it the root (fallback for unexpected stacks).
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let home = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as? MainHomeViewController else {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        
        if let nav = navigationController {
            nav.setViewControllers([home], animated: true)
            return
        }
        
        // Scene-based root replacement
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UINavigationController(rootViewController: home)
            window.makeKeyAndVisible()
        } else {
            present(home, animated: true)
        }
    }

}

extension CompRegisterViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === complaintTypeText {
            view.endEditing(true)
            showComplaintTypeDropdown()
            return false
        }
        return true
    }
}

extension CompRegisterViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        complaintTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ComplaintTypeCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = complaintTypes[indexPath.row]
        config.textProperties.color = .white
        config.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        cell.contentConfiguration = config
        cell.backgroundColor = .clear
        cell.selectionStyle = .default
        
        let bg = UIView()
        bg.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        cell.selectedBackgroundView = bg
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        complaintTypeText.text = complaintTypes[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        dismissComplaintTypeDropdown()
    }
}

extension CompRegisterViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        for result in results {

            // MARK: Handle Video
            if result.itemProvider.hasItemConformingToTypeIdentifier("public.movie") {

                result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { tempURL, error in
                    guard let tempURL = tempURL else { return }

                    // Create permanent file URL
                    let fileName = "video-\(UUID().uuidString).mp4"
                    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let permanentURL = documents.appendingPathComponent(fileName)

                    do {
                        // Remove if exists
                        if FileManager.default.fileExists(atPath: permanentURL.path) {
                            try FileManager.default.removeItem(at: permanentURL)
                        }

                        
                        try FileManager.default.copyItem(at: tempURL, to: permanentURL)
                        print("🎥 Video copied to:", permanentURL)

                        DispatchQueue.main.async {
                            self.selectedVideoURL = permanentURL
                            self.imageViewCollectionView.reloadData()
                            self.expandCollectionViewIfNeeded()
                        }

                    } catch {
                        print("❌ Error copying video:", error)
                    }
                }
            }

            // MARK: Handle Images
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                
                if selectedImages.count >= 4 { continue } // max 4 images

                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    guard let image = object as? UIImage else { return }

                    DispatchQueue.main.async {
                        self.selectedImages.append(image)
                        self.imageViewCollectionView.reloadData()
                        self.expandCollectionViewIfNeeded()
                    }
                }
            }
        }
    }
}

extension CompRegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        picker.dismiss(animated: true)

        // Check if it's an image from Camera
        if let image = info[.originalImage] as? UIImage {

            if selectedImages.count < 4 {   // allow max 4 images
                selectedImages.append(image)
            }

            imageViewCollectionView.reloadData()
            expandCollectionViewIfNeeded()
        }

        // For camera video (if you ever allow it)
        if let videoURL = info[.mediaURL] as? URL {
            if selectedVideoURL == nil {     // allow only 1 video
                selectedVideoURL = videoURL
            }

            imageViewCollectionView.reloadData()
            expandCollectionViewIfNeeded()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
    
}

extension CompRegisterViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if totalMediaCount >= 5 {
            return 5
        }

        return totalMediaCount + 1  // media + add button
    }


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let totalMedia = selectedImages.count + (selectedVideoURL == nil ? 0 : 1)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CompImageCollectionViewCell", for: indexPath) as! CompImageCollectionViewCell

        if indexPath.row < selectedImages.count {
            cell.selectedImage.image = selectedImages[indexPath.row]
        }
        else if indexPath.row == selectedImages.count && selectedVideoURL != nil {
            cell.selectedImage.image = UIImage(systemName: "video.fill")
        }
        else {
            cell.selectedImage.image = UIImage(systemName: "plus.circle") // add button
        }

        return cell
    }
    func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {

           return CGSize(width: 80, height: 80)
       }

       func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           minimumLineSpacingForSectionAt section: Int) -> CGFloat {

           return 8
       }

       func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

           return 8
       }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showMediaSelectionOptions()
    }

    
}


extension CompRegisterViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {

        // Calculate height needed
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)

        // Update height constraint
        descriptionHeight.constant = estimatedSize.height

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        descriptionPlaceholder.isHidden = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        descriptionPlaceholder.isHidden = !textView.text.isEmpty
    }
}

