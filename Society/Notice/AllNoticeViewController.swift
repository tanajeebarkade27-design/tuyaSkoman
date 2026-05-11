//
//  AllNoticeViewController.swift
//  SkromanIsra
//
//  Created by Admin on 07/03/26.
//

import UIKit
import SwiftKeychainWrapper

class AllNoticeViewController: UIViewController {
    
    var societyId: String = ""
    var flatNo: String = ""
   
    var wingId: String =  ""
    var noticeList: [Notice] = []
    
    @IBOutlet weak var noticeTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
      
        noticeTableView.delegate = self
        noticeTableView.dataSource = self
        registerXib()
        fetchNotices()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    func fetchNotices() {
        
        let combinedFlatNo = "\(wingId)-\(flatNo)"
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        let urlString =
        MainApi.url("skroman/residentApprovalRoutes/api/resident/notices?residentMemberId=\(userId)&societyId=\(societyId)&flatNo=\(combinedFlatNo)&page=1&limit=20")
        
        print("Notice API:", urlString)
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let error = error {
                print("Notice API Error:", error)
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
           
            if let rawResponse = String(data: data, encoding: .utf8) {
              
                print(rawResponse)
            }
            
            do {
                let response = try JSONDecoder().decode(AllNoticeResponse.self, from: data)

                DispatchQueue.main.async {

                    self.noticeList = response.items
                    self.noticeTableView.reloadData()

                    print("Total notices:", response.items.count)

                }

            } catch {
                print("❌ Decoding Error:", error)
            }
            
        }.resume()
    }
    
    
    func formatNoticeDate(_ dateString: String) -> String {

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd MMM "
            return outputFormatter.string(from: date)
        }

        return dateString
    }
    
    func registerXib(){
        let uiNib =  UINib(nibName: "AllNoticeTableViewCell", bundle: nil)
        noticeTableView.register(uiNib, forCellReuseIdentifier: "AllNoticeTableViewCell")
    }
    
    @IBAction func backbtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    

}



extension AllNoticeViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noticeList.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "AllNoticeTableViewCell",
            for: indexPath
        ) as! AllNoticeTableViewCell

        let notice = noticeList[indexPath.row]

        cell.noticeTitle.text = notice.title
        cell.noticeBody.text = notice.body
        cell.noticeBody.numberOfLines = 3
      
        cell.noticeDate.text = formatNoticeDate(notice.publishAt)
        cell.audianceType.text = notice.audienceType

        // Audience badge color
        if notice.audienceType.uppercased() == "SOCIETY" {
            cell.audianceType.backgroundColor = .systemBlue
            cell.audianceType.textColor = .white
        } else {
            cell.audianceType.backgroundColor = .systemYellow
            cell.audianceType.textColor = .black
        }

        cell.audianceType.layer.cornerRadius = 6
        cell.audianceType.clipsToBounds = true

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        let notice = noticeList[indexPath.row]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DetailNoticeVC") as! DetailNoticeVC

        vc.noticeId = notice.id
        vc.societyId = notice.societyId
        vc.flatNo = flatNo

        navigationController?.pushViewController(vc, animated: true)
    }
}

struct AllNoticeResponse: Codable {
    let success: Bool
    let page: Int
    let limit: Int
    let items: [Notice]
}
