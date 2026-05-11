//
//  DetailNoticeVC.swift
//  SkromanIsra
//
//  Created by Admin on 07/03/26.
//

import UIKit
import SwiftKeychainWrapper

class DetailNoticeVC: UIViewController {
    
    var noticeId: String?
    var societyId: String = ""
    var flatNo: String = ""

    @IBOutlet weak var createdDate: UILabel!
    @IBOutlet weak var publishDate: UILabel!
    @IBOutlet weak var noticeTitle: UILabel!
    @IBOutlet weak var noticeBody: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        markNoticeAsRead()
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

   
    func markNoticeAsRead() {

        guard let noticeId = noticeId else { return }

        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""

        let urlString = MainApi.url("skroman/residentApprovalRoutes/api/resident/notices/\(noticeId)/read")

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "residentMemberId": userId,
            "societyId": societyId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("JSON Error:", error)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ API Error:", error)
                return
            }

            guard let data = data else { return }

            if let responseString = String(data: data, encoding: .utf8) {
                print("✅ API Response:", responseString)
            }

        }.resume()
    }

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    @IBAction func backbtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
