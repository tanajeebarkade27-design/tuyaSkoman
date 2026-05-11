//
//  AddSocietyStatusVC.swift
//  SkromanIsra
//
//  Created by Admin on 05/02/26.
//

import UIKit

class AddSocietyStatusVC: UIViewController {
    var joinRequestData: JoinRequestData?
    
    @IBOutlet weak var statusTableView: UITableView!
    
    
    @IBOutlet weak var backButton: UIButton!
    
    
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
         print("joinRequestData\(joinRequestData)")
        setupTable()
        prepareDisplayData()
        setupTable()
            prepareDisplayData()
        statusTableView.rowHeight = UITableView.automaticDimension
        statusTableView.estimatedRowHeight = 160

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
   
    func setupTable() {
        statusTableView.dataSource = self
        statusTableView.delegate = self
        let uiNib = UINib(nibName: "StatusViewCell", bundle: nil)
        statusTableView.register(uiNib, forCellReuseIdentifier: "StatusViewCell")
    }

    func prepareDisplayData() {

        guard let data = joinRequestData else { return }

      
        statusTableView.reloadData()
    }

  
    @IBAction func backButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as! MainHomeViewController
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
}

extension AddSocietyStatusVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return joinRequestData == nil ? 0 : 1
    }
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "StatusViewCell",
            for: indexPath
        ) as! StatusViewCell

        guard let data = joinRequestData else { return cell }

        cell.flatNumber.text = "Flat: \(data.flatNo)"
        cell.winglabel.text = "Wing: \(data.wingId)"
        cell.mobileNumber.text = "Mobile: \(data.mobile)"
        cell.submitDate.text = "Area: \(data.areaSquareFeet)"
        cell.backgroundColor =  .clear
        let status = data.status.uppercased()
        cell.statuslabel.text = "Status: \(status)"

       
        cell.statuslabel.layer.borderWidth = 1
        cell.statuslabel.layer.cornerRadius = 6
        cell.statuslabel.clipsToBounds = true

        if status == "PENDING" {

            cell.statuslabel.textColor = .systemGreen
            cell.statuslabel.layer.borderColor = UIColor.systemGreen.cgColor

        } else if status == "REJECTED" {

            cell.statuslabel.textColor = .systemYellow
            cell.statuslabel.layer.borderColor = UIColor.systemYellow.cgColor

        } else {

       
            cell.statuslabel.textColor = .systemBlue
            cell.statuslabel.layer.borderColor = UIColor.systemBlue.cgColor
        }

        return cell
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return 170
        
    }
    
}
