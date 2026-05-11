//
//  SocietyViewController.swift
//  SkromanIsra
//
//  Created by Admin on 22/01/26.
//

import UIKit
import SwiftKeychainWrapper
import DropDown
class SocietyViewController: UIViewController {
    
    
    @IBOutlet weak var societyTabCollectionView: UICollectionView!
    
    
    @IBOutlet weak var upcomingBookingsViewList: UIView!
    
    @IBOutlet weak var upcomingVisterView: UIView!
    
    
    
    @IBOutlet weak var dashbordScrollView: UIScrollView!
    
    @IBOutlet weak var latestNoticeDate: UILabel!
    
    
    @IBOutlet weak var noticeDataLabel: UILabel!
    
    @IBOutlet weak var noticeAudianceType: UILabel!
    
    @IBOutlet weak var latestNoticeBody: UILabel!
    
    @IBOutlet weak var noticeView: UIView!
    
    
    @IBOutlet weak var unreadNoticeCount: UILabel!
    
    
    private let visitorStack = UIStackView()
    private let viewAllButton = UIButton(type: .system)
    
    private let bookingStack = UIStackView()
    private let viewAllBookButton = UIButton(type: .system)
    private var isBookingExpanded = false
    private var bookingCollapsedHeight: NSLayoutConstraint!

    var isVisitorExpanded = false
    private var visitorCollapsedHeight: NSLayoutConstraint!
    private var upcomingBookingCount = 0
    private var currentSocietyId: String = ""
    private var   currentFlatNo : String = ""
    private var  currentWingId: String =  ""
    private var  residentMemberId: String =  ""
    var visitorTapMap: [Int: VisitorItem] = [:]
    var visitorTapIndex = 0

    var recentBookings: [BookingItem] = []
   
    var homeId :String?
    var recentVisitors: [VisitorItem] = []

    @IBOutlet weak var latestNoticeView: UIView!
    
    let items: [SocietyTabItem] = [
        SocietyTabItem(title: "Book\nAmenity", imageName: "book_amenity"),
        SocietyTabItem(title: "Add\nVisitor", imageName: "add_visitor"),
        SocietyTabItem(title: "Pay\nDues", imageName: "pay_dues"),
        SocietyTabItem(title: "Raise\nComplaint", imageName: "raise_complaint")
    ]


    override func viewDidLoad() {
        super.viewDidLoad()
      
        registerCell()
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        //fetchJoinRequestStatus(userId: userId)
        print ("userId \(userId)")
//     
        
        
        let bookingTap = UITapGestureRecognizer(target: self, action: #selector(upcomingBookingTapped))
        upcomingBookingsViewList.isUserInteractionEnabled = true
        upcomingBookingsViewList.addGestureRecognizer(bookingTap)

        let visitorTap = UITapGestureRecognizer(target: self, action: #selector(upcomingVisitorTapped))
        upcomingVisterView.isUserInteractionEnabled = true
        upcomingVisterView.addGestureRecognizer(visitorTap)
        
        upcomingBookingsViewList.cornerRadius =  12
        upcomingVisterView.cornerRadius =  12
        upcomingVisterView.clipsToBounds =  true
        upcomingBookingsViewList.clipsToBounds = true
        upcomingBookingsViewList.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        upcomingVisterView.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        
        latestNoticeView.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        latestNoticeView.borderColor =  .white
        latestNoticeView.borderWidth = 0.5
        
        
        latestNoticeView.cornerRadius =  12
        latestNoticeView.clipsToBounds =  true
        setupVisitorExpandableView()
        setupBookingExpandableView()

    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        fetchJoinRequestStatus(userId: userId)
        
    }
    func setupVisitorExpandableView() {

        visitorStack.axis = .vertical
        visitorStack.spacing = 8
        visitorStack.alignment = .fill
        visitorStack.distribution = .fill
        visitorStack.isHidden = true


        upcomingVisterView.addSubview(visitorStack)

        visitorStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            visitorStack.leadingAnchor.constraint(equalTo: upcomingVisterView.leadingAnchor, constant: 12),
            visitorStack.trailingAnchor.constraint(equalTo: upcomingVisterView.trailingAnchor, constant: -12),
            visitorStack.topAnchor.constraint(equalTo: upcomingVisterView.topAnchor, constant: 50),
            visitorStack.bottomAnchor.constraint(equalTo: upcomingVisterView.bottomAnchor, constant: -12)
        ])
        visitorCollapsedHeight = upcomingVisterView.heightAnchor.constraint(equalToConstant: 50)
        visitorCollapsedHeight.isActive = true

        viewAllButton.setTitle("View All →", for: .normal)
        viewAllButton.tintColor = .green
        viewAllButton.addTarget(self, action: #selector(viewAllVisitorsTapped), for: .touchUpInside)
    }
    
    
    func setupBookingExpandableView() {

        bookingStack.axis = .vertical
        bookingStack.spacing = 8
        bookingStack.alignment = .fill
        bookingStack.distribution = .fill
        bookingStack.isHidden = true

        upcomingBookingsViewList.addSubview(bookingStack)
        bookingStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bookingStack.leadingAnchor.constraint(equalTo: upcomingBookingsViewList.leadingAnchor, constant: 12),
            bookingStack.trailingAnchor.constraint(equalTo: upcomingBookingsViewList.trailingAnchor, constant: -12),
            bookingStack.topAnchor.constraint(equalTo: upcomingBookingsViewList.topAnchor, constant: 50),
            bookingStack.bottomAnchor.constraint(equalTo: upcomingBookingsViewList.bottomAnchor, constant: -12)
           
        ])
        viewAllBookButton.setTitle("View All →", for: .normal)
        viewAllBookButton.addTarget(self, action: #selector(viewAllVisitorsTapped), for: .touchUpInside)
        viewAllBookButton.addTarget(self, action: #selector(upcomingBookingTapped), for: .touchUpInside)
        viewAllButton.tintColor = .green
        bookingCollapsedHeight = upcomingBookingsViewList.heightAnchor.constraint(equalToConstant: 50)
        bookingCollapsedHeight.isActive = true
    }

    
    func registerCell(){
        let unib =  UINib(nibName: "SocietyCollectionViewCell", bundle: nil)
        societyTabCollectionView.register(unib, forCellWithReuseIdentifier: "SocietyCollectionViewCell")
        societyTabCollectionView.dataSource = self
        societyTabCollectionView.delegate = self
    }
    
    @objc func upcomingBookingTapped() {
        toggleBookingView()
    }


    @objc func upcomingVisitorTapped() {
        toggleVisitorView()
    }
    
    
    func toggleVisitorView() {

        isVisitorExpanded.toggle()

        if isVisitorExpanded {

            visitorCollapsedHeight.isActive = false
            populateVisitorStack()
            visitorStack.isHidden = false

        } else {

            visitorCollapsedHeight.isActive = true
            visitorStack.isHidden = true
        }

        UIView.animate(withDuration: 0.02) {
            self.view.layoutIfNeeded()
        }
    }
    
    func toggleBookingView() {

        isBookingExpanded.toggle()

        if isBookingExpanded {

            bookingCollapsedHeight.isActive = false
            populateBookingStack()
            bookingStack.isHidden = false

        } else {

            bookingCollapsedHeight.isActive = true
            bookingStack.isHidden = true
        }

        UIView.animate(withDuration: 0.02) {
            self.view.layoutIfNeeded()
        }
    }

  
   


    func fetchJoinRequestStatus(userId: String) {

        let urlString = MainApi.url("skroman/society-management/resident/join-request/userId/\(userId)")

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in

            if let error = error {
                print("API Error:", error)
                return
            }

            guard let data = data else { return }

            let rawResponse = String(data: data, encoding: .utf8) ?? ""
            print("RAW API Response:", rawResponse)

            DispatchQueue.main.async {

                let storyboard = UIStoryboard(name: "Main", bundle: nil)

             
                if rawResponse.contains("No join requests found for this user") {

                    let vc = storyboard.instantiateViewController(withIdentifier: "AddSocietyViewController") as! AddSocietyViewController
                    self.navigationController?.pushViewController(vc, animated: true)
                    return
                }

                
                do {
                    let response = try JSONDecoder().decode(JoinRequestAPIResponse.self, from: data)

                    guard let joinData = response.data.first else {
                        let vc = storyboard.instantiateViewController(withIdentifier: "AddSocietyViewController") as! AddSocietyViewController
                        self.navigationController?.pushViewController(vc, animated: true)
                        return
                    }

                    // Status NOT approved
                    if joinData.status != "APPROVED" {

                        let vc = storyboard.instantiateViewController(withIdentifier: "AddSocietyStatusVC") as! AddSocietyStatusVC
                        vc.joinRequestData = joinData
                        self.navigationController?.pushViewController(vc, animated: true)
                        return
                    }

                    
                    print("Approved → calling dashboard API")

                    self.currentWingId =  joinData.wingId
                    self.currentFlatNo =  joinData.flatNo
                    self.residentMemberId =  joinData.userId
                    self.homeId =  joinData.homeId
                    
                    self.fetchResidentDashboard(
                        userId: joinData.userId,
                        societyId: joinData.societyId,
                        flatNo: joinData.flatNo, wingId: joinData.wingId)


                } catch {
                    print("Decoding Error:", error)
                }
            }

        }.resume()
    }
    
    
    
    func fetchResidentDashboard(userId: String, societyId: String, flatNo: String, wingId: String) {

        let combinedFlatNo =  "\(wingId)-\(flatNo)"
        
        let urlString =
        MainApi.url("skroman/residentApprovalRoutes/api/dashboard/resident?residentMemberId=\(userId)&societyId=\(societyId)&flatNo=\(combinedFlatNo)")
        
        print("urlString dashboard\(urlString)")

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

                    self.upcomingBookingCount = dashboard.summary.upcomingBookings
                    self.currentSocietyId = dashboard.societyId
                  
                    let preApproved = dashboard.visitors.preApprovedActive
                    self.recentVisitors = Array(preApproved.prefix(2))

                    let upcoming = dashboard.bookings.upcoming
                    self.recentBookings = Array(upcoming.prefix(2))
                    if self.isBookingExpanded {
                        self.populateBookingStack()
                    }
                    
                    
                    if dashboard.notices.isEmpty {
                        self.noticeView.isHidden = true
                        return
                    } else {
                        self.noticeView.isHidden = false
                    }

                    if dashboard.unreadCount > 0 {
                        self.unreadNoticeCount.text = String(dashboard.unreadCount)
                        self.unreadNoticeCount.isHidden = false
                    } else {
                        self.unreadNoticeCount.isHidden = true
                    }
                    if let firstVisitor = self.recentVisitors.first {
                        print("First Visitor Name:", firstVisitor.person.name ?? "")
                    }
                    
                    let latestNotice = dashboard.notices
                        .sorted { $0.publishAt > $1.publishAt }
                        .first
                    if let notice = latestNotice {

                        self.noticeView.isHidden = false   // 👈 SHOW view

                        self.latestNoticeBody.text = notice.title
                        self.noticeDataLabel.text = notice.body
                        self.noticeDataLabel.numberOfLines = 3
                        self.noticeDataLabel.lineBreakMode = .byTruncatingTail

                        self.latestNoticeDate.text = self.formatNoticeDate(notice.publishAt)

                        if notice.audienceType.uppercased() == "SOCIETY" {
                            self.noticeAudianceType.textColor = .white
                            self.noticeAudianceType.backgroundColor = .systemBlue
                        } else if notice.audienceType.uppercased() == "FLAT" {
                            self.noticeAudianceType.textColor = .black
                            self.noticeAudianceType.backgroundColor = .systemYellow
                        }

                        self.noticeAudianceType.text = notice.audienceType

                    } else {
                        // 👇 IMPORTANT: hide when empty
                        self.noticeView.isHidden = true
                    }
                }


            } catch {
                print("Dashboard Decoding Error:", error)
            }

        }.resume()
    }

    func formatNoticeDate(_ dateString: String) -> String {

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        if let date = inputFormatter.date(from: dateString) {

            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d MMM yyyy"

            return outputFormatter.string(from: date)
        }

        return ""
    }
    func populateBookingStack() {

        bookingStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if recentBookings.isEmpty {

            let label = UILabel()
            label.text = "No upcoming bookings"
            label.textColor = .lightGray
            label.textAlignment = .center
            label.heightAnchor.constraint(equalToConstant: 40).isActive = true

            bookingStack.addArrangedSubview(label)
            return
        }

        for booking in recentBookings {
            bookingStack.addArrangedSubview(makeBookingCard(booking))
        }

        bookingStack.addArrangedSubview(viewAllBookButton)
    }
    
    func populateVisitorStack() {

        visitorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let firstTwo = Array(recentVisitors.prefix(2))

        for visitor in firstTwo {
            visitorStack.addArrangedSubview(makeVisitorRow(visitor))
        }

        visitorStack.addArrangedSubview(viewAllButton)
    }



    func makeBookingCard(_ booking: BookingItem) -> UIView {

        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        card.layer.cornerRadius = 12

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])

        let amenity = UILabel()
        amenity.text = "Amenity: \(booking.amenityId ?? "")"
        amenity.textColor = .white
        amenity.font = .boldSystemFont(ofSize: 14)

        let date = UILabel()
        date.text = "Date: \(booking.date ?? "")"
        date.textColor = .white
        date.font = .systemFont(ofSize: 12)

        let status = UILabel()
        status.text = booking.status ?? ""
        status.textColor = .green
        status.font = .systemFont(ofSize: 12)

        stack.addArrangedSubview(amenity)
        stack.addArrangedSubview(date)
        stack.addArrangedSubview(status)

        return card
    }
    
    
    
    @objc func viewAllVisitorsTapped() {
        print("View All Visitors tapped")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "VisterListViewController") as! VisterListViewController
        vc.societyId = currentSocietyId
           vc.flatNo = currentFlatNo
        vc.wingId = currentWingId
        vc.residentMemberId =  residentMemberId
        
        navigationController?.pushViewController(vc, animated: true)
   
    }

    func makeVisitorRow(_ visitor: VisitorItem) -> UIView {

        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        card.layer.cornerRadius = 12

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Store visitor with index
           let index = visitorTapIndex
           visitorTapMap[index] = visitor
           card.tag = index
           visitorTapIndex += 1
        let cardTap = UITapGestureRecognizer(target: self, action: #selector(visitorCardTapped(_:)))
           card.addGestureRecognizer(cardTap)

        card.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])

        // ---------- TOP ROW ----------

        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 10

        // User Image
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.widthAnchor.constraint(equalToConstant: 40).isActive = true
        img.heightAnchor.constraint(equalToConstant: 40).isActive = true
        img.layer.cornerRadius = 20
        img.clipsToBounds = true
        img.image = UIImage(named: "profile") 

        // Text Stack (Name, Mobile, Type)
        let nameLabel = UILabel()
        nameLabel.text = visitor.person.name ?? ""
        nameLabel.textColor = .white
        nameLabel.font = .boldSystemFont(ofSize: 14)

        let mobileLabel = UILabel()
        mobileLabel.text = visitor.person.mobile ?? ""
        mobileLabel.textColor = .white
        mobileLabel.font = .systemFont(ofSize: 12)

        let typeLabel = UILabel()
        typeLabel.text = visitor.visitorType ?? "Guest"
        typeLabel.textColor = .white
        typeLabel.font = .systemFont(ofSize: 12)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, mobileLabel, typeLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        // Status Container (for padding)
        let statusContainer = UIView()
        statusContainer.layer.borderWidth = 1
        statusContainer.layer.borderColor = UIColor.systemGreen.cgColor
        statusContainer.layer.cornerRadius = 8
        statusContainer.clipsToBounds = true
        statusContainer.borderColor =  .green
        statusContainer.borderWidth = 1
        // Status Label
        let statusLabel = UILabel()
        statusLabel.text = visitor.status ?? "PRE-APPROVED"
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        statusContainer.addSubview(statusLabel)

        // Add padding using constraints
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: statusContainer.topAnchor, constant: 4),
            statusLabel.bottomAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: -4),
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -8)
        ])

        let spacer = UIView()

        topRow.addArrangedSubview(img)
        topRow.addArrangedSubview(textStack)
        topRow.addArrangedSubview(spacer)
        topRow.addArrangedSubview(statusLabel)

        // ---------- Divider ----------

        let divider = UIView()
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        // ---------- QR Row ----------

        let qrRow = UIStackView()
        qrRow.axis = .horizontal
        qrRow.spacing = 8
        qrRow.alignment = .center
        qrRow.isUserInteractionEnabled = true
       
       


        let qrImage = UIImageView(image: UIImage(systemName: "qrcode"))
        qrImage.tintColor = .white
        qrImage.widthAnchor.constraint(equalToConstant: 18).isActive = true
        qrImage.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let qrLabel = UILabel()
        qrLabel.text = "Share QR access code"
        qrLabel.textColor = .white
        qrLabel.font = .systemFont(ofSize: 12)

        qrRow.addArrangedSubview(qrImage)
        qrRow.addArrangedSubview(qrLabel)

        // ---------- Assemble ----------

        mainStack.addArrangedSubview(topRow)
        mainStack.addArrangedSubview(divider)
        mainStack.addArrangedSubview(qrRow)

        return card
    }

    @objc func visitorCardTapped(_ sender: UITapGestureRecognizer) {

        guard let view = sender.view else { return }

        let index = view.tag

        guard let visitor = visitorTapMap[index] else { return }

        print("Tapped visitor:", visitor.person.name ?? "")

        getOrGenerateQR(visitor: visitor)
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
                       // self.showSimpleAlert(msg: result.message ?? "QR not valid")
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
        present(vc, animated: true)
    }
    
    
    @objc func shareQR() {

        let message = "Here is your visitor QR access code."
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let whatsappURL = URL(string: "whatsapp://send?text=\(encoded)")
        let whatsappBusinessURL = URL(string: "whatsapp-business://send?text=\(encoded)")

        let alert = UIAlertController(title: "Share via", message: nil, preferredStyle: .actionSheet)

        if let wa = whatsappURL, UIApplication.shared.canOpenURL(wa) {
            alert.addAction(UIAlertAction(title: "WhatsApp", style: .default) { _ in
                UIApplication.shared.open(wa)
            })
        }

        if let wab = whatsappBusinessURL, UIApplication.shared.canOpenURL(wab) {
            alert.addAction(UIAlertAction(title: "WhatsApp Business", style: .default) { _ in
                UIApplication.shared.open(wab)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }


    @IBAction func viewAllNotice(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AllNoticeViewController") as! AllNoticeViewController
        vc.societyId = currentSocietyId
           vc.flatNo = currentFlatNo
        vc.wingId = currentWingId
        navigationController?.pushViewController(vc, animated: true)
    }
    
    

}



extension SocietyViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SocietyCollectionViewCell",
            for: indexPath
        ) as! SocietyCollectionViewCell

        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = (collectionView.frame.width - 20) / 2
        return CGSize(width: width, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let selectedItem = items[indexPath.item]
        print("Tapped: \(selectedItem.title)")

        if selectedItem.title.contains("Book\nAmenity") {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AmenityViewController") as! AmenityViewController
            vc.societyId = currentSocietyId
            navigationController?.pushViewController(vc, animated: true)

        } else if selectedItem.title.contains("Add\nVisitor") {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "VisterListViewController") as! VisterListViewController
            vc.societyId = currentSocietyId
            vc.flatNo = currentFlatNo
            vc.wingId = currentWingId
            vc.residentMemberId = residentMemberId
            navigationController?.pushViewController(vc, animated: true)

        } else if selectedItem.title.contains("Raise\nComplaint") {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ComplaintViewController") as! ComplaintViewController
            
            vc.selectedHomeId = homeId ?? ""
            vc.societyId = currentSocietyId
            vc.complaintCategory = "SOCIETY_COMPLAINT"
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
   
}

extension UILabel {
    func padding(left: CGFloat, right: CGFloat, top: CGFloat, bottom: CGFloat) {
        let inset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        drawText(in: bounds.inset(by: inset))
    }
}


struct SocietyTabItem {
    let title: String
    let imageName: String
}
struct JoinRequestAPIResponse: Decodable {
    let success: Bool?
    let count: Int
    let data: [JoinRequestData]
}

struct JoinRequestData: Decodable {
    let requestId: String
    let userId: String
    let societyId: String
    let homeId: String
    let wingId: String
    let floor: String
    let flatNo: String
    let flatType: String
    let residentType: String
    let mobile: String
    let areaSquareFeet: String
    let parkingSlot: String
    let status: String
}



 
 

// MARK: - Root Response

struct ResidentDashboardResponse: Decodable {
    let residentMemberId: String
    let societyId: String
    let flatNo: String
    let filtersApplied: FiltersApplied
    let summary: DashboardSummary
    let bookings: DashboardBookings
    let visitors: DashboardVisitors
    let notices: [Notice]
       let unreadCount: Int
}

// MARK: - Filters

struct FiltersApplied: Decodable {
    let bookingFromDate: String?
    let bookingToDate: String?
    let visitorFromDate: String?
    let visitorToDate: String?
}

// MARK: - Summary

struct DashboardSummary: Decodable {
    let totalBookings: Int
    let upcomingBookings: Int
    let activePreApprovedVisitors: Int
    let totalVisitorHistory: Int
}

// MARK: - Bookings

struct DashboardBookings: Decodable {
    let upcoming: [BookingItem]
    let all: [BookingItem]
}

struct BookingItem: Decodable {
    let bookingId: String?
    let amenityId: String?
    let sectionId: String?
    let date: String?
    let status: String?
    let createdAt: String?
}

// MARK: - Visitors

struct DashboardVisitors: Decodable {
    let preApprovedActive: [VisitorItem]
    let allHistory: [VisitorItem]
}

// MARK: - Visitor Item

struct VisitorItem: Decodable {
    let visitorId: String?
    let visitorType: String?
    let person: VisitorPerson
    let status: String?
    let preApproved: Bool?
    let qr: VisitorQR?
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - Visitor Person

struct VisitorPerson: Decodable {
    let name: String?
    let mobile: String?
    let photo: String?
}

// MARK: - QR

struct VisitorQR: Decodable {
    let code: String?
    let createdAt: String?
    let expiresAt: String?
    let used: Bool?
    let cancelledAt: String?
}
 

struct NoticeResponse: Codable {
    let notices: [Notice]
    let unreadCount: Int
}

struct Notice: Codable {
    let id: String
    let noticeId: String
    let societyId: String
    let title: String
    let body: String
    let audienceType: String
    let targetFlatIds: [String]
    let targetResidentIds: [String]
    let status: String
    let publishAt: String
    let expireAt: String
    let isPinned: Bool
    let createdBy: String
    let createdAt: String
    let updatedAt: String
    let isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case noticeId
        case societyId
        case title
        case body
        case audienceType
        case targetFlatIds
        case targetResidentIds
        case status
        case publishAt
        case expireAt
        case isPinned
        case createdBy
        case createdAt
        case updatedAt
        case isRead
    }
}
