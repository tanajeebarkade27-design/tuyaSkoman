//
//  VisterListViewController.swift
//  SkromanIsra
//
//  Created by Admin on 23/01/26.
//

import UIKit
import SwiftKeychainWrapper

class VisterListViewController: UIViewController {

    @IBOutlet weak var visterTypeCollectionview: UICollectionView!
    
    @IBOutlet weak var visterList: UITableView!
    
    var societyId: String = ""
    var flatNo: String = ""
    var userId: String = ""
    var wingId: String =  ""
    var residentMemberId: String =  ""
    var popupBackgroundView: UIView!
    var popupContainer: UIView!

    var nameField = UITextField()
    var mobileField = UITextField()
    var tillDatePicker = UIDatePicker()
    var visitorTypeButton = UIButton()

    var selectedVisitorType = "Guest"
    let addvisitorTypes = ["Guest", "Delivery", "Maid", "Relative", "Maintenance"]

   
    private let addVisitorButton = UIButton(type: .system)


    var visitorTypes: [VisitorType] = [
        VisitorType(title: "Pre Approved"),
        VisitorType(title: "Upcoming"),
        VisitorType(title: "Completed"),
        
        VisitorType(title: "Rejected")
    ]
    
    var allVisitors: [VisitorItem] = []
    var filteredVisitors: [VisitorItem] = []
    var selectedIndex = 0

    var preApprovedVisitors: [VisitorItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupCollectionView()
        registerCell()
        DispatchQueue.main.async {
            let firstIndex = IndexPath(item: 0, section: 0)
            self.visterTypeCollectionview.selectItem(at: firstIndex, animated: false, scrollPosition: [])
        }
        setupAddVisitorButton()
    }

    func setupCollectionView() {
        visterTypeCollectionview.dataSource = self
        visterTypeCollectionview.delegate = self
    }
    
     
    func setupBackground() {
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)

        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    @IBAction func backbtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        
        fetchResidentDashboard(societyId: societyId,
                               flatNo: flatNo, wingId: wingId)
        
      
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func setupAddVisitorButton() {
        addVisitorButton.translatesAutoresizingMaskIntoConstraints = false
        addVisitorButton.backgroundColor = .green
        addVisitorButton.setTitle("+", for: .normal)
        addVisitorButton.setTitleColor(.white, for: .normal)
        addVisitorButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        addVisitorButton.layer.cornerRadius = 28
        addVisitorButton.clipsToBounds = true
        addVisitorButton.layer.shadowColor = UIColor.black.cgColor
        addVisitorButton.layer.shadowOpacity = 0.3
        addVisitorButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        addVisitorButton.layer.shadowRadius = 4
        view.addSubview(addVisitorButton)
        NSLayoutConstraint.activate([
            addVisitorButton.widthAnchor.constraint(equalToConstant: 56),
            addVisitorButton.heightAnchor.constraint(equalToConstant: 56),

            addVisitorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addVisitorButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        addVisitorButton.addTarget(self, action: #selector(addVisitorTapped), for: .touchUpInside)
    }

    @objc func addVisitorTapped() {
        showAddVisitorPopup()
    }

    func showAddVisitorPopup() {
        popupBackgroundView = UIView(frame: view.bounds)
        popupBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(popupBackgroundView)

        popupContainer = UIView()
        popupContainer.backgroundColor = .white
        popupContainer.layer.cornerRadius = 16
        popupContainer.translatesAutoresizingMaskIntoConstraints = false
        popupBackgroundView.addSubview(popupContainer)

        NSLayoutConstraint.activate([
            popupContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            popupContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        let title = UILabel()
        title.text = "Add Visitor"
        title.font = .boldSystemFont(ofSize: 20)

        configureField(nameField, "Visitor Name")
        configureField(mobileField, "Mobile Number")
        mobileField.keyboardType = .numberPad

        tillDatePicker.datePickerMode = .dateAndTime
        tillDatePicker.minimumDate = Date()

        visitorTypeButton.setTitle("Select Visiter Type", for: .normal)
        visitorTypeButton.setTitleColor(.black, for: .normal)
        visitorTypeButton.layer.borderWidth = 1
        visitorTypeButton.layer.cornerRadius = 8
        visitorTypeButton.layer.borderColor = UIColor.systemGray4.cgColor
        visitorTypeButton.addTarget(self, action: #selector(showVisitorTypePicker), for: .touchUpInside)

        let addButton = UIButton()
        addButton.setTitle("Add Visitor", for: .normal)
        addButton.backgroundColor = .systemGreen
        addButton.layer.cornerRadius = 10
        addButton.addTarget(self, action: #selector(submitVisitor), for: .touchUpInside)
        let validTillLabel = UILabel()
        validTillLabel.text = "Valid Till"
        validTillLabel.font = .systemFont(ofSize: 16, weight: .medium)
        validTillLabel.textColor = .black

        let stack = UIStackView(arrangedSubviews: [
            title,
            nameField,
            mobileField,
            validTillLabel,
            tillDatePicker,
            visitorTypeButton,
            addButton
        ])

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        popupContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: popupContainer.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: popupContainer.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: popupContainer.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: popupContainer.trailingAnchor, constant: -16),

            visitorTypeButton.heightAnchor.constraint(equalToConstant: 40),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        popupBackgroundView.addGestureRecognizer(tapGesture)
    }
    @objc func dismissPopup() {
        popupBackgroundView.removeFromSuperview()
    }
    func configureField(_ tf: UITextField, _ placeholder: String) {
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    @objc func showVisitorTypePicker() {

        let sheet = UIAlertController(title: "Visitor Type", message: nil, preferredStyle: .actionSheet)

        addvisitorTypes.forEach { type in
            sheet.addAction(UIAlertAction(title: type, style: .default) { _ in
                self.selectedVisitorType = type
                self.visitorTypeButton.setTitle(type, for: .normal)
            })
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(sheet, animated: true)
    }

    @objc func submitVisitor() {

        let name = nameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let mobile = mobileField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        if name.isEmpty || mobile.isEmpty {
            //showAlert(title: "Error", message: "Please enter visitor name and mobile")
            return
        }

      
        let flatNo =  "\(wingId)-\(flatNo)"

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoDate = formatter.string(from: tillDatePicker.date)
        print("data at api\(isoDate)")

        preApproveVisitor(
            name: name,
            mobile: mobile,
            flatNo: flatNo,
            type: selectedVisitorType,
            expiresAt: isoDate
        )

        popupBackgroundView.removeFromSuperview()
    }

    func preApproveVisitor(name: String,
                           mobile: String,
                           flatNo: String,
                           type: String,
                           expiresAt: String) {

        let urlString = MainApi.url("skroman/residentApprovalRoutes/resident/visitors/preapprove")

        guard let url = URL(string: urlString) else { return }

        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "residentMemberId": residentMemberId,
            "visitorType": type,
            "personName": name,
            "mobileNo": mobile,
            "expiresAt": expiresAt,
            "flatNo": flatNo
           
        ]

        print(" add visiter body\(body)")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ Preapprove error:", error)
                return
            }

            if let data = data {
                let raw = String(data: data, encoding: .utf8) ?? ""
                print("📨 Preapprove response:", raw)
            }

            DispatchQueue.main.async {

              

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.navigationController?.popViewController(animated: true)
                }
            }

        }.resume()
    }
   
    func fetchResidentDashboard( societyId: String, flatNo: String , wingId: String) {
        
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        let combinedFlatNo =   "\(wingId)-\(flatNo)"
        
        let urlString =
        MainApi.url("skroman/residentApprovalRoutes/api/dashboard/resident?residentMemberId=\(userId)&societyId=\(societyId)&flatNo=\(combinedFlatNo)")
        
        print ("urlString dashboard \(urlString)")

        guard let url = URL(string: urlString) else {
            print("Invalid dashboard URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                print("Dashboard API Error:", error)
                return
            }

            guard let data = data else { return }

            let raw = String(data: data, encoding: .utf8) ?? ""
            print(" DASHBOARD RAW RESPONSE:")
            print(raw)

            do {
                let dashboard = try JSONDecoder().decode(ResidentDashboardResponse.self, from: data)

                DispatchQueue.main.async {

                    print("Dashboard decoded:", dashboard)

                    self.preApprovedVisitors = dashboard.visitors.preApprovedActive
                    self.allVisitors = dashboard.visitors.allHistory
                    
                    print ("allVisitors at  dashboard\(self.allVisitors)")

                    self.applyFilter(index: 0)
                }



            } catch {
                print("Dashboard Decoding Error:", error)
            }

        }.resume()
    }
    
    
    func applyFilter(index: Int) {

        selectedIndex = index

        switch index {

        case 0: // Preapproved (ACTIVE)
            filteredVisitors = preApprovedVisitors

        case 1: // Pending
            filteredVisitors = allVisitors.filter { $0.status == "PENDING" }

        case 2: // Approved / Entered
            filteredVisitors = allVisitors.filter {
                $0.status == "ENTERED" || $0.status == "APPROVED"
            }

        case 3: // Rejected
            filteredVisitors = allVisitors.filter { $0.status == "REJECTED" }

        default:
            filteredVisitors = []
        }

        print("Filtered count:", filteredVisitors.count)
        visterList.reloadData()
    }

    
    func registerCell(){
        let uiNib =  UINib(nibName: "preApprovedViewCell", bundle: nil)
        visterList.register(uiNib, forCellReuseIdentifier: "preApprovedViewCell")
        let uiNib1 =  UINib(nibName: "UpcomingViewCell", bundle: nil)
        visterList.register(uiNib1, forCellReuseIdentifier: "UpcomingViewCell")
        let uiNib2 =  UINib(nibName: "CompletedViewCell", bundle: nil)
        visterList.register(uiNib2, forCellReuseIdentifier: "CompletedViewCell")
        
        let uiNib3 =  UINib(nibName: "cancelViewCell", bundle: nil)
        visterList.register(uiNib3, forCellReuseIdentifier: "cancelViewCell")
        
        
        visterList.dataSource =  self
        visterList.delegate =  self
    }
    
    
    func getOrGenerateQR(visitor: VisitorItem) {

        guard let visitorId = visitor.visitorId else { return }

        let qrCode = visitor.qr?.code ?? ""

        let urlString = MainApi.url("skroman/residentApprovalRoutes/api/visitors/getOrRegenerateVisitorQr")

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "visitorId": visitorId,
            "qrCode": qrCode
        ]
        print("body qr api \(body)")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in

            guard let data = data else { return }

            print(String(data: data, encoding: .utf8) ?? "")

            do {
                let result = try JSONDecoder().decode(QRPopupResponse.self, from: data)
                print("result\(result)")
                DispatchQueue.main.async {

                    if result.success,
                       let qrData = result.data {

                        self.showQRPopup(qrData: qrData)


                    } else {
                        self.showSimpleAlert(msg: result.message ?? "QR not valid")
                    }
                }

            } catch {
                print("QR Decode Error:", error)
            }

        }.resume()
    }

    func showQRPopup(qrData: QRPopupData) {

        let vc = QRPopupViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.qrData = qrData

        present(vc, animated: true) {
            vc.updateExpiryLabel()   // ✅ force update after present
        }
    }
    
     

   
    func formatDate(_ iso: String?) -> String {

        guard let iso = iso else { return "" }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: iso) else { return "" }

        let output = DateFormatter()
        output.dateFormat = "dd MMM yyyy, hh:mm a"
        output.timeZone = TimeZone(secondsFromGMT: 0)

        return output.string(from: date)
    }

    func showSimpleAlert(msg: String) {
        let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


}


extension VisterListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout , PreApprovedCellDelegate{

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visitorTypes.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "visiterTypeCell",
            for: indexPath
        ) as! visiterTypeCell

        cell.titleLabel.text = visitorTypes[indexPath.item].title
        cell.isSelected = indexPath.item == selectedIndex

        return cell
    }


    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = (collectionView.frame.width - 30) / 4
        return CGSize(width: width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        applyFilter(index: indexPath.item)
//visterTypeCollectionview.reloadData()
    }
    
    

}



extension VisterListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredVisitors.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }


    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let visitor = filteredVisitors[indexPath.section]


        // Pre Approved
        if selectedIndex == 0 {

            let cell = tableView.dequeueReusableCell(
                withIdentifier: "preApprovedViewCell",
                for: indexPath
            ) as! preApprovedViewCell
            cell.delegate = self
            cell.visiterNamelabel.text = visitor.person.name
            cell.visitercontact.text = visitor.person.mobile
            cell.visiterType.text = visitor.visitorType
            cell.userProfileIamge.image = UIImage(named: "profile")

            if let photoString = visitor.person.photo,
               let url = URL(string: photoString) {

                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.userProfileIamge.image = image
                        }
                    }
                }.resume()
            }

            return cell
        }
        else if selectedIndex == 1 {

            let cell = tableView.dequeueReusableCell(
                withIdentifier: "UpcomingViewCell",
                for: indexPath
            ) as! UpcomingViewCell

            cell.visitername.text = visitor.person.name
            cell.visiterContact.text = visitor.person.mobile
            cell.visiterType.text = visitor.visitorType
           
            
            if let photoString = visitor.person.photo,
               let url = URL(string: photoString) {

                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.profileimage.image = image
                        }
                    }
                }.resume()
            }
            
            cell.visitor = visitor
            cell.delegate = self

            return cell
        }

        else if selectedIndex == 2 {

            let cell = tableView.dequeueReusableCell(
                withIdentifier: "CompletedViewCell",
                for: indexPath
            ) as! CompletedViewCell

            cell.visitername.text = visitor.person.name
            cell.visterContcat.text = visitor.person.mobile
            cell.visterType.text = visitor.visitorType
            cell.userProfileImage.image = UIImage(named: "profile")
            
            if let photoString = visitor.person.photo,
               let url = URL(string: photoString) {

                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.userProfileImage.image = image
                        }
                    }
                }.resume()
            }
            return cell
        }
        else if selectedIndex == 3 {

            let cell = tableView.dequeueReusableCell(
                withIdentifier: "cancelViewCell",
                for: indexPath
            ) as! cancelViewCell

            cell.visitername.text = visitor.person.name
            cell.visterContcat.text = visitor.person.mobile
            cell.visterType.text = visitor.visitorType
            cell.userProfileImage.image = UIImage(named: "profile")
            
            if let photoString = visitor.person.photo,
               let url = URL(string: photoString) {

                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.userProfileImage.image = image
                        }
                    }
                }.resume()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  140
    }
    
    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard selectedIndex == 0 else { return } // ONLY Pre Approved

        let visitor = filteredVisitors[indexPath.section]

        guard let visitorId = visitor.visitorId else { return }

        getOrGenerateQR(visitor: visitor)

    }
    func didTapEdit(cell: preApprovedViewCell) {

        guard let indexPath = visterList.indexPath(for: cell) else { return }

        let visitor = filteredVisitors[indexPath.section]

        showEditVisitorPopup(visitor: visitor)
    }
    
    func showEditVisitorPopup(visitor: VisitorItem) {

        let alert = UIAlertController(
            title: "Edit Visitor",
            message: "\n\n\n\n\n\n\n\n\n",
            preferredStyle: .alert
        )

        let nameField = UITextField()
        nameField.placeholder = "Visitor Name"
        nameField.text = visitor.person.name
        nameField.borderStyle = .roundedRect

        let contactField = UITextField()
        contactField.placeholder = "Contact Number"
        contactField.keyboardType = .phonePad
        contactField.text = visitor.person.mobile
        contactField.borderStyle = .roundedRect

        let datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.datePickerMode = .dateAndTime
        datePicker.timeZone = TimeZone(secondsFromGMT: 0)
      
        if let expiryDate = isoStringToDate(visitor.qr?.expiresAt) {
            datePicker.date = expiryDate
        }

        alert.view.addSubview(nameField)
        alert.view.addSubview(contactField)
        alert.view.addSubview(datePicker)

        nameField.translatesAutoresizingMaskIntoConstraints = false
        contactField.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            nameField.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 60),
            nameField.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 34),

            contactField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 10),
            contactField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            contactField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            contactField.heightAnchor.constraint(equalToConstant: 34),

            datePicker.topAnchor.constraint(equalTo: contactField.bottomAnchor, constant: 10),
            datePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: 120)
        ])
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in

            let updatedName = nameField.text ?? ""
            let updatedMobile = contactField.text ?? ""
            let selectedDate = datePicker.date

            self.updateVisitorAPI(
                visitorId: visitor.visitorId ?? "",
                personName: updatedName,
                mobileNo: updatedMobile,
                expiresAt: selectedDate
            )
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    func updateVisitorAPI(visitorId: String,
                          personName: String,
                          mobileNo: String,
                          expiresAt: Date) {

        let residentId = self.residentMemberId

        if residentId.isEmpty {
            print("❌ residentMemberId empty")
            return
        }

        let urlString = MainApi.url("skroman/residentApprovalRoutes/resident/visitors/\(visitorId)/modify")

        guard let url = URL(string: urlString) else { return }

        let formatter = ISO8601DateFormatter()
        let expiryString = formatter.string(from: expiresAt)

        let params: [String: Any] = [
            "residentMemberId": residentId,
            "personName": personName,
            "mobileNo": mobileNo,
            "expiresAt": expiryString
        ]

        print("📤 PATCH BODY:", params)

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ PATCH Error:", error)
                return
            }

            if let http = response as? HTTPURLResponse {
                print("📡 Status:", http.statusCode)
            }

            if let data = data {
                print("🌐 Response:", String(data: data, encoding: .utf8) ?? "")
            }

            DispatchQueue.main.async {
                // reload dashboard / visitors
            }

        }.resume()
    }
    func isoStringToDate(_ iso: String?) -> Date? {

        guard let iso = iso else { return nil }

        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        input.locale = Locale(identifier: "en_US_POSIX")
        input.timeZone = TimeZone(secondsFromGMT: 0)   // just to parse

        guard let date = input.date(from: iso) else { return nil }

        // ADD +1 hour manually (14 → 15)
        return Calendar.current.date(byAdding: .hour, value: 0, to: date)
    }
  
}


extension VisterListViewController: UpcomingViewCellDelegate {

    func didTapApprove(visitor: VisitorItem) {
        guard let id = visitor.visitorId else { return }
        approveVisitor(visitorId: id)
    }

    func didTapReject(visitor: VisitorItem) {

        let alert = UIAlertController(
            title: "Reject Visitor",
            message: "Are you sure you want to reject this visitor?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { _ in
            if let id = visitor.visitorId {
                self.rejectVisitor(visitorId: id)
            }
        }))

        present(alert, animated: true)
    }

    
    func approveVisitor(visitorId: String) {

        let urlString = MainApi.url("skroman/residentApprovalRoutes/resident/visitors/\(visitorId)/approve")

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ Approve Error:", error)
                return
            }

            var message = "Visitor approved"

            if let data = data,
               let raw = String(data: data, encoding: .utf8) {

                print("📨 Approve Raw Response:", raw)

                if raw.contains("Visitor approved") {
                    message = "Visitor approved"
                }
            }

            DispatchQueue.main.async {

                // Success popup
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))

                self.present(alert, animated: true)

                // Reload dashboard + table
                self.fetchResidentDashboard(societyId: self.societyId,
                                            flatNo: self.flatNo, wingId: self.wingId)
            }

        }.resume()
    }


    func rejectVisitor(visitorId: String) {

        let urlString = MainApi.url("skroman/residentApprovalRoutes/resident/visitors/\(visitorId)/reject")

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ Reject Error:", error)
                return
            }

            var message = "Visitor rejected"

            if let data = data,
               let raw = String(data: data, encoding: .utf8) {
                print("📨 Reject Raw Response:", raw)

                // Extract message manually (simple way)
                if raw.contains("Visitor rejected") {
                    message = "Visitor rejected"
                }
            }

            DispatchQueue.main.async {

                // Show popup
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))

                self.present(alert, animated: true)

               
                self.fetchResidentDashboard(societyId: self.societyId,
                                            flatNo: self.flatNo, wingId: self.wingId)
            }

        }.resume()
    }


}


struct VisitorType {
    let title: String
}

 
struct QRPopupResponse: Decodable {
    let success: Bool
    let message: String?
    let data: QRPopupData?
}

struct QRPopupData: Decodable {
    let visitorId: String?
    let residentMemberId: String?
    let visitorType: String?
    let personName: String?
    let mobileNo: String?
    let flatNo: String?
    let expiresAt: String?
    let qrCode: String?
}
