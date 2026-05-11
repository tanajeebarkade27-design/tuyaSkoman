//
//  ComplaintListViewController.swift
//  SkromanIsra
//
//  Created by Admin on 27/11/25.
//

import UIKit
import SwiftKeychainWrapper
class ComplaintViewController: UIViewController {
    
    var societyId: String = ""
    var complaintCategory: String = ""
    var selectedHomeId : String?
    @IBOutlet weak var backgroundView: UIView!
    
    
    @IBOutlet weak var backgroundImage: UIImageView!
    var tickets: [ComplaintTicket] = []
    
   
    @IBOutlet weak var registerBtn: UIButton!
    
    @IBOutlet weak var complaintTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchComplaintList()
        registerCell()
       print ("complaintCategory\(complaintCategory)")
         
        
        registerBtn.setTitleColor(.white, for: .normal)
           registerBtn.setTitleColor(.white, for: .highlighted)
           registerBtn.tintColor = .white
           registerBtn.adjustsImageWhenHighlighted = false
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
    
    
    @IBAction func registerCompalint(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if complaintCategory.uppercased() == "SOCIETY_COMPLAINT" {
            
            // 👉 Society Complaint Screen
            if let vc = storyboard.instantiateViewController(withIdentifier: "CompRegisterViewController") as? CompRegisterViewController {
                
                vc.societyId = self.societyId
                vc.complaintCategory = self.complaintCategory
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
        } else {
            
            // 👉 Home Complaint Screen
            if let vc = storyboard.instantiateViewController(withIdentifier: "HomeSelCompViewController") as? HomeSelCompViewController {
                
//                vc.selectedHomeId = self.selectedHomeId
//                vc.complaintCategory = self.complaintCategory
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    
    
    @IBAction func listButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ComplaintListViewController") as? ComplaintListViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    
    
    @IBAction func emailConnectTapped(_ sender: UIButton) {
        openSupportEmailInGmail()
    }
    
    @IBAction func whatsAppConnect(_ sender: Any) {
        let phone = "919699206295" // support number with country code, no '+'
        let message = ""
        let encMsg = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Try WhatsApp app first
        if let appURL = URL(string: "whatsapp://send?phone=\(phone)&text=\(encMsg)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
            return
        }

        // Fallback to web
        if let webURL = URL(string: "https://wa.me/\(phone)?text=\(encMsg)") {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }

    @IBAction func emailConnect(_ sender: Any) {
        openSupportEmailInGmail()
    }
    
    private func openSupportEmailInGmail() {
        let to = "support@skromanglobal.com"
        let subject = "I have an issue"
        let body = ""
        
        func enc(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
        }
        
        // Prefer Gmail app compose.
        let gmailPrimary = URL(string: "googlegmail:///co?to=\(enc(to))&subject=\(enc(subject))&body=\(enc(body))")
        let gmailAlternate = URL(string: "googlegmail://co?to=\(enc(to))&subject=\(enc(subject))&body=\(enc(body))")
        let mailtoURL = URL(string: "mailto:\(enc(to))?subject=\(enc(subject))&body=\(enc(body))")
        
        if let gmailPrimary, UIApplication.shared.canOpenURL(gmailPrimary) {
            UIApplication.shared.open(gmailPrimary, options: [:], completionHandler: nil)
        } else if let gmailAlternate, UIApplication.shared.canOpenURL(gmailAlternate) {
            UIApplication.shared.open(gmailAlternate, options: [:], completionHandler: nil)
        } else if let mailtoURL, UIApplication.shared.canOpenURL(mailtoURL) {
            UIApplication.shared.open(mailtoURL, options: [:], completionHandler: nil)
        } else {
            showAlert(title: "Failed", message: "Gmail is not installed.")
        }
    }
    
    
    @IBAction func TC(_ sender: Any) {
        let vc = TermsAndConditionsViewController()
        vc.isReadOnly = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func fetchComplaintList() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""

        var components = URLComponents(string: MainApi.url("skroman/support/user-tickets/\(userId)"))
        components?.queryItems = [
            URLQueryItem(name: "complaintCategory", value: complaintCategory),
            URLQueryItem(name: "societyId", value: societyId)
        ]

        guard let url = components?.url else {
            print("Invalid URL")
            return
        }

        print("Final URL:", url.absoluteString)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("API Error:", error.localizedDescription)
                return
            }

            guard let data = data else { return }

            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code:", httpResponse.statusCode)
                print("Headers:", httpResponse.allHeaderFields)
                print("==========================\n")
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("\n===== RESPONSE BODY =====")
                print(jsonString)
            }

            do {
                let decoded = try JSONDecoder().decode(ComplaintResponse.self, from: data)
                self.tickets = Array(decoded.ticket.prefix(5))

                DispatchQueue.main.async {
                    self.complaintTableView.reloadData()
                }

            } catch {
                print("Decode Error:", error)
            }

        }.resume()
    }

    
    func registerCell(){
        let uiNib = UINib(nibName: "ComplaintTableViewCell", bundle: nil)
        complaintTableView.register(uiNib, forCellReuseIdentifier: "ComplaintTableViewCell")
        complaintTableView.dataSource =  self
        complaintTableView.delegate =  self
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
        formatter.dateFormat = "hh:mm a"
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
            
            // 🔍 Debug logs
            print("🌐 URL:", url.absoluteString)
            print("📤 METHOD:", request.httpMethod ?? "")
            print("📤 HEADERS:", request.allHTTPHeaderFields ?? [:])
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 BODY:\n\(jsonString)")
            }
            
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
            print("📥 Status Code:", statusCode)
            
            let responseString = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No response"
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

  
}

extension ComplaintViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ComplaintTableViewCell",
            for: indexPath
        ) as! ComplaintTableViewCell
        
        let item = tickets[indexPath.row]
        
        // Pass data to cell
        cell.ComplaintTypeLabel.text = item.complaintType ?? "-"
        cell.complaintDescription.text = item.description ?? "-"
        cell.complaintdatelabel.text = item.complaintRaisedTime ?? "-"
        
        if let raisedDate = item.createdAt?.toDate() {
            cell.complaintdatelabel.text = formatDate(raisedDate)
            cell.timeLabel.text = formatTime(raisedDate)
        }
        
        let rawStatus = (item.status ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        cell.complaintStatusLabel.text = rawStatus.isEmpty ? "" : "  \(rawStatus)  "

        if rawStatus == "Completed" {
            cell.complaintStatusLabel.backgroundColor = UIColor.systemGreen
            cell.complaintStatusLabel.textColor = .white
        } else if rawStatus == "Pending" {
            cell.complaintStatusLabel.backgroundColor = UIColor.systemOrange
            cell.complaintStatusLabel.textColor = .white
        } else if rawStatus == "InProgress" {
            cell.complaintStatusLabel.backgroundColor = UIColor.systemBlue
            cell.complaintStatusLabel.textColor = .white
        } else {
            cell.complaintStatusLabel.backgroundColor = .clear
            cell.complaintStatusLabel.textColor = .black
        }
        
        cell.updateTimeBtn.removeTarget(nil, action: nil, for: .allEvents)
        cell.updateTimeBtn.tag = indexPath.row
        cell.updateTimeBtn.addTarget(self, action: #selector(updateTimeTapped(_:)), for: .touchUpInside)

        
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
extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
}


