//
//  ViewScheduleViewController.swift
//  SkromanIsra
//
//  Created by Admin on 13/03/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class ViewScheduleViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var viewSchdeuler: UIView!
    
    @IBOutlet weak var deviceCollectionView: UICollectionView!
    
    @IBOutlet weak var schdeuleCollectionView: UICollectionView!
    @IBOutlet weak var dayView: UIView!
    
    @IBOutlet weak var scheduleView: UIView!
    @IBOutlet weak var weekDayView: UIView!
    @IBOutlet weak var deviceView: UIView!
    @IBOutlet weak var dayViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var datepicker: UIDatePicker!
    @IBOutlet weak var daycollectionView: UICollectionView!
    @IBOutlet weak var timeView: UIView!
    
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var scheduleButton: UIButton!
    var selectedWeekSchedule: String?
    var selectedSchedule: SkromanIsra.Schedule?
    var selectedScheduleIndex: Int?
    var deviceUid: String?
    var deviceSchdeule:[Schedule] =  []
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceScene: [DeviceScene] = []
    var deviceUinqueId: String?
    var buttonItems: [String] = []
    var daysArray = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    var selectedDevice: Device?
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.setTitle("", for: .normal)
        
        backButton.setTitleColor(.black, for: .normal) // Set text color
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
            backButton.setImage(image, for: .normal)
        }
        scheduleButton.setTitle("", for: .normal)
        if let firstScene = devices.first {
            deviceUid = firstScene.deviceUid
        } else {
            deviceUid = nil
        }
        
        deviceUid = selectedDevice?.deviceUid
        print(" device  data \(selectedDevice)")
       print("deviceUid is at sc\(deviceUid)")
        fetchSchedule()
       
        viewSchdeuler.cornerRadius = 15
        schdeuleCollectionView.dataSource =  self
        schdeuleCollectionView.delegate =  self
        daycollectionView.dataSource =  self
        daycollectionView.delegate =  self
        deviceCollectionView.dataSource =  self
        deviceCollectionView.delegate =  self
        registerXib()

       
        
        devicecornerView()
       // scheduleView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        scheduleView.cornerRadius = 15
        
        datepicker.overrideUserInterfaceStyle = .dark
        datepicker.setValue(UIColor.white, forKeyPath: "textColor")
        datepicker.tintColor = .white
        datepicker.backgroundColor = .clear

        timePicker.overrideUserInterfaceStyle = .dark
        timePicker.setValue(UIColor.white, forKeyPath: "textColor")
        timePicker.tintColor = .white
        timePicker.backgroundColor = .clear


        
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func devicecornerView() {
        let views = [viewSchdeuler]
        
        for view in views {
            view?.cornerRadius = 10
            view?.clipsToBounds = true
            view?.borderWidth = 1
            view?.borderColor = .gray
        }
    }

   
    func fetchSchedule() {
        deviceSchdeule.removeAll()
        deviceSchdeule = []
        let schedule = SkromanIsraDatabaseHelper.shared.fetchSchedulesByDeviceUid(deviceUid: deviceUid ?? "")
        
        let sortedSchedule = schedule.sorted { $0.scheduleNumber < $1.scheduleNumber } // Sorting in Swift

      
        deviceSchdeule = sortedSchedule
        
        schdeuleCollectionView.reloadData()
        print("Sorted Schedule: \(deviceSchdeule)")
    }

    
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func scheduleButton(_ sender: Any) {
        
    }
    
    
  
    
    @IBAction func deleteSchdeule(_ sender: Any) {
        guard let selectedSchedule = selectedSchedule else {
            print("No schedule selected")
            return
        }

        let alert = UIAlertController(title: "Delete Schedule",
                                      message: "Are you sure you want to delete this schedule?",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
         
            self.Delete_Schedule_Api_Func(sheduleId: selectedSchedule.scheduleId)
        }))

        present(alert, animated: true, completion: nil)
    }
    

    func registerXib() {
        let uinib = UINib(nibName: "ScheduleNoCollectionViewCell", bundle: nil)
        schdeuleCollectionView.register(uinib, forCellWithReuseIdentifier: "ScheduleNoCollectionViewCell")
        let uinib1 = UINib(nibName: "ScheduleDaysCollectionViewCell", bundle: nil)
        daycollectionView.register(uinib1, forCellWithReuseIdentifier: "ScheduleDaysCollectionViewCell")
        let unNib2 = UINib(nibName: "ScheduleDeviceCollectionViewCell", bundle: nil)
        deviceCollectionView.register(unNib2, forCellWithReuseIdentifier: "ScheduleDeviceCollectionViewCell")
        
    }
    
    
    
    
    func Delete_Schedule_Api_Func(sheduleId: String)
    {
        
        
        let Delete_Schedule_Params: Image_Parameters =
        [
            "sheduleId" : sheduleId
        ]
        
        print("Delete_Schedule_Params \(Delete_Schedule_Params)")
        
        AF.request("http://3.7.18.55:3000/skroman/timesheduledelete", method: .post, parameters: Delete_Schedule_Params, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    print(jsonOne!)
                    
                    
                    if let parse_json = jsonOne!["msg"] as? String {
                        
                        if parse_json == "shedule delete successfully." {
                            
                         
                            self.showPopupDelete()
                        }
                        
                    }
                    
                    
                }
                catch {
                    }
                
                
            case .failure(let err):
                
                print(err.localizedDescription)
                
            }
            
        }.resume()
    }
    @objc func showPopupDelete() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "schedule",
                                     title: "Deleted",
                                     subtitle: "Selected Schedule is Delete ")
        
       
    }
    

}

extension ViewScheduleViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == schdeuleCollectionView {
            return deviceSchdeule.count
        } else if collectionView == daycollectionView {
            return daysArray.count
        } else if collectionView == deviceCollectionView {
            guard let selectedSchedule = selectedSchedule else { return 0 }
            
            var filteredButtons: [String] = []
            
            if let configButtons = selectedSchedule.configButtons {
                let allowedButtons = ["L", "O", "C", "D", "Y", "Q"]
                filteredButtons = configButtons.compactMap { allowedButtons.contains(String($0)) ? String($0) : nil }
            }
            
            if selectedSchedule.fanDest == "1" {
                filteredButtons.append("F")  // Add fan cell
            }
            
            filteredButtons.append("M") // Add master switch cell

            return filteredButtons.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == schdeuleCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScheduleNoCollectionViewCell", for: indexPath) as! ScheduleNoCollectionViewCell
            let schedule = deviceSchdeule[indexPath.row]
            cell.schdeuleNumberLabel.text = "No:\(schedule.scheduleNumber)"
            print("schedule.scheduleNumber\(schedule.scheduleNumber)")
            cell.cellbackgroundview.backgroundColor = (indexPath.row == selectedScheduleIndex) ? UIColor.systemMint : UIColor.clear
            return cell
        } else if collectionView == daycollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScheduleDaysCollectionViewCell", for: indexPath) as! ScheduleDaysCollectionViewCell
            
            var isSelected = false
            if let weekSchedule = selectedWeekSchedule, indexPath.row < weekSchedule.count {
                let index = weekSchedule.index(weekSchedule.startIndex, offsetBy: indexPath.row)
                isSelected = weekSchedule[index] == "1"
            }
            cell.configure(day: daysArray[indexPath.row], isSelected: isSelected)
            return cell
        } else if collectionView == deviceCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScheduleDeviceCollectionViewCell", for: indexPath) as! ScheduleDeviceCollectionViewCell
            
            guard let selectedSchedule = selectedSchedule else { return cell }
            
            var filteredButtons: [String] = []
            if let configButtons = selectedSchedule.configButtons {
                let allowedButtons = ["L", "O", "C", "D", "Y", "Q"]
                filteredButtons = configButtons.compactMap { allowedButtons.contains(String($0)) ? String($0) : nil }
            }
            
            if selectedSchedule.fanDest == "1" {
                filteredButtons.append("F")
            }
            filteredButtons.append("M")
            
            let item = filteredButtons[indexPath.row]
            
            // ✅ Set image
            switch item {
            case "L": cell.deviceImage.image = UIImage(named: "bulb")
            case "O": cell.deviceImage.image = UIImage(named: "curtains_open")
            case "C": cell.deviceImage.image = UIImage(named: "curtains_close")
            case "Q": cell.deviceImage.image = UIImage(named: "curtains_open")
            case "Y": cell.deviceImage.image = UIImage(named: "curtains_close")
            case "F": cell.deviceImage.image = UIImage(named: "ceiling-fan")
            case "M": cell.deviceImage.image = UIImage(named: "AppIcon1")
            case "D": cell.deviceImage.image = UIImage(named: "lock-2")
            default: cell.deviceImage.image = nil
            }
            
            // ✅ Define colors
           
            let activeBorderColor = UIColor(hex: "#44DB34")
            let inactiveBorderColor = UIColor(hex: "#D3D3D3")
            
            // Default to inactive
            var borderColor = inactiveBorderColor
            
            // ✅ Check active states
            if item == "L", selectedSchedule.LState.count > indexPath.row {
                let index = selectedSchedule.LState.index(selectedSchedule.LState.startIndex, offsetBy: indexPath.row)
                if selectedSchedule.LState[index] == "1" {
                    borderColor = activeBorderColor
                }
            }
            
            if item == "F", selectedSchedule.FState == "1" {
                borderColor = activeBorderColor
            }
            
            if item == "M", selectedSchedule.master == "1" {
                borderColor = activeBorderColor
            }
            
            // ✅ Apply border color change
            cell.backroundCell.layer.borderColor = borderColor.cgColor
            cell.backroundCell.layer.borderWidth = 2.0
            cell.backroundCell.backgroundColor = .clear
            
            return cell
        }

        
        
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == schdeuleCollectionView {
            selectedScheduleIndex = indexPath.row
            selectedSchedule = deviceSchdeule[indexPath.row]
            selectedWeekSchedule = selectedSchedule?.weekSchedule

            deviceCollectionView.reloadData()
            daycollectionView.reloadData()
            schdeuleCollectionView.reloadData()

         
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            if let date = timeFormatter.date(from: selectedSchedule?.time ?? "") {
                timePicker.date = date
            } else {
                print("Invalid time format: \(selectedSchedule?.time ?? "")")
            }
            
            // Date Picker
            if selectedSchedule?.date == "00/00/00" {
                dateView.isHidden = true
            } else {
                dateView.isHidden = false
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yy"
                if let date = dateFormatter.date(from: selectedSchedule?.date ?? "") {
                    datepicker.date = date
                } else {
                    print("Invalid date format: \(selectedSchedule?.date ?? "")")
                }
            }

       
            timePicker.isUserInteractionEnabled = false
            datepicker.isUserInteractionEnabled = false
        }
    }


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == deviceCollectionView {
            let numberOfColumns: CGFloat = 3
            let spacing: CGFloat = 20
            let totalSpacing = (numberOfColumns - 1) * spacing
            let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
            return CGSize(width: itemWidth, height: itemWidth)
        } else {
            return CGSize(width: 100, height: 40)
        }
    }
}
