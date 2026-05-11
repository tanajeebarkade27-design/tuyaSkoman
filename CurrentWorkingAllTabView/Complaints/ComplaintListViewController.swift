//
//  ComplaintListViewController.swift
//  SkromanIsra
//
//  Created by Admin on 27/11/25.
//

import UIKit
import SwiftKeychainWrapper

class ComplaintListViewController: UIViewController {
    
    
    @IBOutlet weak var backgroundView: UIImageView!
    
    @IBOutlet weak var ComplaintListTableView: UITableView!
    var tickets: [ComplaintTicket] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchComplaintList()
        registerCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    

    @IBAction func backButton(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
    }
    
    func fetchComplaintList() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        let urlString = MainApi.url("skroman/support/user-tickets/\(userId)")
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
             print("complaint data\(data)")
            
            do {
                let decoded = try JSONDecoder().decode(ComplaintResponse.self, from: data)
                self.tickets = decoded.ticket
                
                print("Tickets:", self.tickets)

                
                DispatchQueue.main.async {
                    self.ComplaintListTableView.reloadData()
                }
                
            } catch {
                print("Decode Error:", error)
            }
            
        }.resume()
    }

    
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"   // Output: 10:12 AM
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }
    
    private func preferredTimeString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    private func openUpdateAvailabilityPopup(for ticket: ComplaintTicket) {
        let popup = PreferredTimePopup(frame: view.bounds)
        popup.onTimeSelected = { [weak self] fromDate, toDate in
            guard let self else { return }
            let from = self.preferredTimeString(from: fromDate)
            let to = self.preferredTimeString(from: toDate)
            self.updateAvailabilityTime(ticket: ticket, from: from, to: to)
        }
        view.addSubview(popup)
    }
    
    private func updateAvailabilityTime(ticket: ComplaintTicket, from: String, to: String) {
        let ticketId = (ticket.ticketId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ticketId.isEmpty else {
            showAlert(title: "Failed", message: "Ticket id missing.")
            return
        }
        
        guard let url = URL(string: MainApi.url("skroman/support/complaint/updateAvailabilityTime/\(ticketId)")) else {
            showAlert(title: "Failed", message: "Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "from": from,
            "to": to
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            showAlert(title: "Failed", message: "Not updated")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            
            if let error {
                print("❌ Error:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.showAlert(title: "Failed", message: "Not updated")
                }
                return
            }
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseString = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No response"
            print("📥 Status Code:", statusCode)
            print("📥 Response Body:\n\(responseString)")
            
            DispatchQueue.main.async {
                if (200...299).contains(statusCode) {
                    self.showAlert(title: "Success", message: "Availability time updated.")
                    self.fetchComplaintList()
                } else {
                    self.showAlert(title: "Failed", message: responseString)
                }
            }
        }.resume()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func registerCell(){
        let uiNib = UINib(nibName: "ComplaintListTableViewCell", bundle: nil)
        ComplaintListTableView.register(uiNib, forCellReuseIdentifier: "ComplaintListTableViewCell")
        ComplaintListTableView.dataSource =  self
        ComplaintListTableView.delegate =  self
    }
    
   

}

extension ComplaintListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ComplaintListTableViewCell",
            for: indexPath
        ) as! ComplaintListTableViewCell
        
        let item = tickets[indexPath.row]
        
        // Pass data to cell
        cell.complaintTypeLabel.text = item.complaintType ?? "-"
        cell.descriptionLabel.text = item.description ?? "-"
        cell.raisedDateLabel.text = "-"
        cell.tiameLabel.text = "-"

        // Match ComplaintViewController behavior
        if let raisedDate = item.createdAt?.toDate() {
            cell.raisedDateLabel.text = formatDate(raisedDate)
            cell.tiameLabel.text = formatTime(raisedDate)
        }
        
        let rawStatus = (item.status ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        cell.statuslabel.text = rawStatus.isEmpty ? "" : "  \(rawStatus)  "

        if rawStatus == "Completed" {
            cell.statuslabel.backgroundColor = UIColor.systemGreen
            cell.statuslabel.textColor = .white
        } else if rawStatus == "Pending" {
            cell.statuslabel.backgroundColor = UIColor.systemOrange
            cell.statuslabel.textColor = .white
        } else if rawStatus == "InProgress" {
            cell.statuslabel.backgroundColor = UIColor.systemBlue
            cell.statuslabel.textColor = .white
        } else {
            cell.statuslabel.backgroundColor = .clear
            cell.statuslabel.textColor = .black
        }
        
        cell.updateTimeButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.updateTimeButton.tag = indexPath.row
        cell.updateTimeButton.addTarget(self, action: #selector(updateTimeTapped(_:)), for: .touchUpInside)

        return cell
    }
    
    @objc private func updateTimeTapped(_ sender: UIButton) {
        let row = sender.tag
        guard row >= 0, row < tickets.count else { return }
        let ticket = tickets[row]
        openUpdateAvailabilityPopup(for: ticket)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTicket = tickets[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ComplaintMsgViewController") as? ComplaintMsgViewController {
            vc.ticketId = selectedTicket.ticketId
            vc.ticket = selectedTicket
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    
    
}




 

// MARK: - Main Response
struct ComplaintResponse: Decodable {
    let msg: String
    let ticket: [ComplaintTicket]
}

// MARK: - Ticket Model
struct ComplaintTicket: Decodable {
    let id: String
    let complaintRaisedTime: String?
    let complaintResolvedTime: String?
    let complaintType: String?
    let createdAt: String?
    let createdBy: String?
    let description: String?
    let homeId: String?
    let homeName: String?
    let images: [String]?
    let memberId: String?
    let removedEmployees: [RemovedEmployee]?
    let societyId: String?
    let status: String?
    let ticketId: String?
    let updatedAt: String?
    let updatedBy: String?
    let updatedByType: String?
    let user: ComplaintUser?
    let userId: String?
    let videos: [String]?
    let clientAvailability: ClientAvailability?
    let ticketOtp: Int?
    let messages: [TicketMessage]?
    let complaintCategory: String?
    let devices: [DeviceTrack]?
    let amount: Double?
    let gstAmount: Double?
    let gstRate: Double?
    let totalPayableAmount: Double?
    let paymentStatus: String?
    let availableCoupons: [AvailableCoupon]?
    let amountAfterDiscount: Double?
    let discountAmount: Double?
    let paybleAmount: Double?
    let paymentGatewayOrderId: String?
    let paymentGatewayPaymentId: String?
    let paymentSource: String?
    let paymentTransactionId: String?
    let paymentUpdatedAt: String?
    let tasks: [TicketTask]?
    let rating: TicketRating?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case complaintRaisedTime
        case complaintResolvedTime
        case complaintType
        case createdAt
        case createdBy
        case description
        case homeId
        case homeName
        case images
        case memberId
        case removedEmployees
        case societyId
        case status
        case ticketId
        case updatedAt
        case updatedBy
        case updatedByType
        case user
        case userId
        case videos
        case clientAvailability
        case messages
        case ticketOtp
        case complaintCategory
        case devices
        case amount
        case gstAmount
        case gstRate
        case totalPayableAmount
        case paymentStatus
        case availableCoupons
        case amountAfterDiscount
        case discountAmount
        case paybleAmount
        case paymentGatewayOrderId
        case paymentGatewayPaymentId
        case paymentSource
        case paymentTransactionId
        case paymentUpdatedAt
        case tasks
        case rating
    }
}

// MARK: - Tasks (for assigned employees)
struct TicketTask: Decodable {
    let taskId: String?
    let employees: [TaskEmployee]?
}

struct TaskEmployee: Decodable {
    let memberId: String?
    let name: String?
    let role: String?
}

// MARK: - Rating
struct TicketRating: Decodable {
    let stars: Int?
    let comment: String?
    let ratedFor: [String]?
    let ratedAt: String?
}

struct AvailableCoupon: Decodable {
    let code: String?
    let title: String?
    let description: String?
    let appliedTicketId: String?
    let discountType: String?
    let discountValue: Double?
    let maxDiscountAmount: Double?
    let validFrom: String?
    let validTill: String?
}




struct SendMessageResponse: Decodable {
    let msg: String?
    let message: TicketMessage?
}

struct TicketMessage: Decodable {
    let id: String?
    let senderId: String?
    let senderType: String?
    let message: String?
    let messageImage: [String]?
    let sentAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case senderId
        case senderType
        case message
        case messageImage
        case sentAt
    }
}

// MARK: - Client Availability
struct ClientAvailability: Decodable {
    let from: String?
    let to: String?
}

// MARK: - Removed Employee
struct RemovedEmployee: Decodable {
    let assignedAt: String?
    let assignedBy: String?
    let email: String?
    let employeeId: String?
    let name: String?
    let reason: String?
    let removedAt: String?
    let removedBy: RemovedBy?
    let role: String?
    let workMode: String?
}

struct RemovedBy: Decodable {
    let id: String?
    let name: String?
    let role: String?
}

// MARK: - User
struct ComplaintUser: Decodable {
    let id: String
    let address1: String?
    let address2: String?
    let city: String?
    let emailId: String?
    let familyMember: [FamilyMember]?
    let imageUser: String?
    let loginType: String?
    let mobileNumber: String?
    let state: String?
    let updatedAt: String?
    let userId: String?
    let userName: String?
    let verifyAlexa: Bool?          // <-- stays Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case address1
        case address2
        case city
        case emailId
        case familyMember
        case imageUser
        case loginType
        case mobileNumber
        case state
        case updatedAt
        case userId
        case userName
        case verifyAlexa
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        address1 = try container.decodeIfPresent(String.self, forKey: .address1)
        address2 = try container.decodeIfPresent(String.self, forKey: .address2)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        emailId = try container.decodeIfPresent(String.self, forKey: .emailId)
        familyMember = try container.decodeIfPresent([FamilyMember].self, forKey: .familyMember)
        imageUser = try container.decodeIfPresent(String.self, forKey: .imageUser)
        loginType = try container.decodeIfPresent(String.self, forKey: .loginType)

        // mobileNumber (Int or String)
        if let intValue = try? container.decode(Int.self, forKey: .mobileNumber) {
            mobileNumber = String(intValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .mobileNumber) {
            mobileNumber = stringValue
        } else {
            mobileNumber = nil
        }

        state = try container.decodeIfPresent(String.self, forKey: .state)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        userName = try container.decodeIfPresent(String.self, forKey: .userName)

        // 🔥 FIX verifyAlexa (Bool or String)
        if let boolValue = try? container.decode(Bool.self, forKey: .verifyAlexa) {
            verifyAlexa = boolValue
        } else if let stringValue = try? container.decode(String.self, forKey: .verifyAlexa) {
            verifyAlexa = (stringValue == "true" || stringValue == "1")
        } else {
            verifyAlexa = nil
        }
    }
}


// MARK: - Family Member
struct FamilyMember: Decodable {
    let emailId: String?
    let familyUserId: String?
}


struct DeviceTrack: Decodable {
    let deviceId: String?
    let trackingId: String?
    let currentStage: String?
    let repairFlow: [RepairFlow]?
}

struct RepairFlow: Decodable {
    let stage: String?
    let status: String?
    let description: String?
    let images: [DeviceImage]?
    let createdAt: String?
}

struct DeviceImage: Decodable {
    let url: String?
    let visibleToUser: Bool?
}
