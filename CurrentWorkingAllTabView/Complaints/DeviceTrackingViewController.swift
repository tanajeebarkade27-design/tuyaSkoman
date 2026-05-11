//
//  DeviceTrackingViewController.swift
//  SkromanIsra
//
//  Created by Admin on 21/03/26.
//

import UIKit

class DeviceTrackingViewController: UIViewController {

    var device: DeviceTrack?
    
    
    @IBOutlet weak var trackTableView: UITableView!
    
    @IBOutlet weak var trackId: UILabel!
    
    @IBOutlet weak var deviceNumber: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("device data \(device)")
        print("Tracking ID:", device?.trackingId ?? "")
        print("Current Stage:", device?.currentStage ?? "")
        
        let tracking = (device?.trackingId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if tracking.isEmpty {
            trackId.text = "Tracking ID: Not available"
        } else {
            trackId.text = "Tracking ID: \(tracking)"
        }
        
        deviceNumber.text = "Device No: \(device?.deviceId ?? "")"
        
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        let uiNib = UINib(nibName: "TrackingCell", bundle: nil)
        trackTableView.register(uiNib, forCellReuseIdentifier: "TrackingCell")
        trackTableView.rowHeight = UITableView.automaticDimension
            trackTableView.estimatedRowHeight = 120
        trackTableView.dataSource = self
        trackTableView.delegate = self
        trackTableView.borderColor =  .systemGreen
        trackTableView.borderWidth =  1
        trackTableView.cornerRadius =  12
        trackTableView.clipsToBounds =  true
        
        // If no flow data available, show an empty state instead of blank table.
        if (device?.repairFlow?.isEmpty ?? true) {
            trackTableView.isHidden = true
            
            let empty = UILabel()
            empty.text = "Tracking details are not available yet."
            empty.textColor = UIColor.white.withAlphaComponent(0.85)
            empty.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            empty.numberOfLines = 0
            empty.textAlignment = .center
            empty.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(empty)
            
            NSLayoutConstraint.activate([
                empty.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                empty.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                empty.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
                empty.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
            ])
        } else {
            trackTableView.isHidden = false
            trackTableView.reloadData()
        }
        
    }
    
    
    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func getProgress() -> Float {

        guard let flows = device?.repairFlow else { return 0 }

        let completed = flows.filter { $0.status == "COMPLETED" }.count

        return Float(completed) / Float(flows.count)
    }
    func formatStage(_ stage: String?) -> String {
        guard let stage = stage else { return "" }

        return stage
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    func formatDateTime(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "-" }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy, hh:mm a"
            return formatter.string(from: date)
        }

        return "-"
    }
}


extension DeviceTrackingViewController: UITableViewDataSource , UITableViewDelegate{

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return device?.repairFlow?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackingCell", for: indexPath) as! TrackingCell

        guard let flow = device?.repairFlow?[indexPath.row] else {
            return cell
        }

        // ✅ Status
        let status = flow.status ?? "UNKNOWN"
        cell.statusLabel.text = status

        switch status {
        case "COMPLETED":
            cell.statusLabel.textColor = .systemGreen
            cell.statusView.backgroundColor = .systemGreen
            cell.statusView1.backgroundColor = .systemGreen

        case "PENDING":
            cell.statusLabel.textColor = .systemOrange
            cell.statusView.backgroundColor = .gray
            cell.statusView1.backgroundColor = .gray

        case "IN_PROGRESS":
            cell.statusLabel.textColor = .systemBlue
            cell.statusView.backgroundColor = .gray
            cell.statusView1.backgroundColor = .gray

        default:
            cell.statusLabel.textColor = .white
        }

        // ✅ Stage + Description + Date
        cell.stageLabel.text = formatStage(flow.stage)
        cell.descriptionLabel.text = flow.description ?? "-"
        cell.createdAt.text = formatDateTime(flow.createdAt)

        // ✅ Image with visibleToUser check (ONLY ONCE)
        if let imageObj = flow.images?.first,
           imageObj.visibleToUser == true,
           let urlString = imageObj.url,
           let url = URL(string: urlString) {

            cell.customImageView.isHidden = false
            cell.imageHeightConstraint.constant = 80
            cell.customImageView.load(url: url)

        } else {
            cell.customImageView.isHidden = true
            cell.imageHeightConstraint.constant = 0
        }

        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
     return 160
        
        
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.image = UIImage(data: data)
                }
            }
        }
    }
}
