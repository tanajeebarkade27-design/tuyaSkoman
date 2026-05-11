import UIKit
import AWSCore
import AWSIoT
import Alamofire

class ScheduleViewController: UIViewController {
    @IBOutlet weak var schdeuleView: UIView!
    
    @IBOutlet weak var scheduleBackgroundview: UIView!
    @IBOutlet weak var closedButton: UIButton!
    @IBOutlet weak var scheduleNumberCollectionView: UICollectionView!
    
    @IBOutlet var backgroundView: UIView!
    let numbers = Array(1...10)
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceScene: [DeviceScene] = []
    var deviceUinqueId: String?
    var buttonItems: [String] = []
    var deviceSchdeule:[Schedule] =  []
    var selectedIndex: Int?
    var deviceUid: String?
    var selectedDevice: Device?
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        schdeuleView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        schdeuleView.cornerRadius = 15
        closedButton.setTitle("", for: .normal)
       
           closedButton.setTitleColor(.black, for: .normal)
           
           if let image = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
               closedButton.setImage(image, for: .normal)
           }
        scheduleNumberCollectionView.dataSource = self
        scheduleNumberCollectionView.delegate = self
        registerXib()
         print("devicestate at  she\(devicestate)")
         print("buttonItems att\(buttonItems)")
         print ("decvice Scene\(deviceScene)")
        print ("device schdedule\(deviceSchdeule)")
        
        let layout = UICollectionViewFlowLayout()
               layout.minimumInteritemSpacing = 10
               layout.minimumLineSpacing = 10     
               scheduleNumberCollectionView.collectionViewLayout = layout
        
        print("🚀 ScheduleViewController loaded")

           print("🧪 selectedDevice is nil? \(selectedDevice == nil)")
           print("🧪 devices count: \(devices.count)")
        print("🧪 devices deviceUid: \(selectedDevice?.deviceUid)")
        

           if let selected = selectedDevice {
               deviceUid = selected.deviceUid
               print("✅ Selected device UID: \(deviceUid!)")
           } else if let firstScene = devices.first {
               deviceUid = firstScene.deviceUid
               print("✅ First device UID: \(deviceUid!)")
           } else {
               deviceUid = nil
               print("⚠️ No device found to fetch schedule.")
           }

           print("📌 Final deviceUid: \(deviceUid ?? "nil")")
        fetchSchedule(deviceUid: deviceUid ?? "")
        
        
        let buttons: [UIButton] = [ nextButton]
        for button in buttons {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
        }
    }
    
    @IBAction func closedButton(_ sender: Any) {
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
   
    
    func fetchSchedule(deviceUid: String) {
        print("✅ fetchSchedule called for deviceUid: \(deviceUid)")
        deviceSchdeule.removeAll()

        let schedules = SkromanIsraDatabaseHelper.shared.fetchSchedulesByDeviceUid(deviceUid: deviceUid)
        print ("schedules\(schedules)")

        deviceSchdeule = schedules.sorted(by: { $0.scheduleNumber < $1.scheduleNumber })

        print("📦 Retrieved \(deviceSchdeule.count) schedules for deviceUid: \(deviceUid)")
        
        for schedule in deviceSchdeule {
            print("🧾 Schedule \(schedule.scheduleNumber) | UID: \(schedule.deviceUid ?? "nil")")
            
            
        }

        scheduleNumberCollectionView.reloadData()
    }

    
    
    @IBAction func viewSchdeule(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ViewScheduleViewController") as! ViewScheduleViewController
        vc.devicestate = self.devicestate
        vc.selectedDevice = selectedDevice
        vc.deviceScene = self.deviceScene
       
     
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    @IBAction func nextButton(_ sender: Any) {
        guard let selectedIndex = selectedIndex else {
            print("No schedule number selected")
            showPopup()
            return
        }
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "ShowScheduleViewController") as! ShowScheduleViewController
        vc.devicestate = self.devicestate
        vc.selectedDevice = self.selectedDevice
        vc.deviceScene = self.deviceScene
        vc.schduleNumber = String(numbers[selectedIndex])  
        vc.buttonItems1 = self.buttonItems
        navigationController?.pushViewController(vc, animated: true)
    }

    
    @objc func showPopup() {
           
           showPopupPresenter.showPopup1(on: self.view,
                                        animationName: "alert",
                                        title: "Opps!",
                                        subtitle: "please select schdeule Number ")
           
          
       }
    
    
    func registerXib() {
        let uinib = UINib(nibName: "ScheduleNumberCollectionViewCell", bundle: nil)
        scheduleNumberCollectionView.register(uinib, forCellWithReuseIdentifier: "ScheduleNumberCollectionViewCell")
    }
    
    
}

extension ScheduleViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numbers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = scheduleNumberCollectionView.dequeueReusableCell(withReuseIdentifier: "ScheduleNumberCollectionViewCell", for: indexPath) as! ScheduleNumberCollectionViewCell
        
        cell.scheduleNollabel.text = "\(numbers[indexPath.item])"
        
        let number = numbers[indexPath.item]
        let scheduledNumbers = Set(deviceSchdeule.map { $0.scheduleNumber })

         
        if scheduledNumbers.contains("\(number)") {
            cell.isScheduleImage.image = UIImage(named: "isSelected")
            cell.isScheduleImage.isHidden = false
        } else {
            cell.isScheduleImage.isHidden = true
        }

        
        // Change appearance if selected
        if indexPath.item == selectedIndex {
           cell.backgroundSchedule.backgroundColor = UIColor.systemBlue
            cell.layer.cornerRadius = 10
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.gray.cgColor
            cell.scheduleNollabel.textColor = UIColor.white
        } else {
            cell.backgroundSchedule.backgroundColor = UIColor.white
            cell.scheduleNollabel.textColor = UIColor.black
            cell.layer.cornerRadius = 10
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.gray.cgColor
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        collectionView.reloadData()
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 30
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let itemsPerRow: CGFloat = 3
        let sectionInset: CGFloat = 20 // left + right insets from layout (adjust as needed)
        let spacing: CGFloat = 10      // space between cells (adjust as needed)

        // Calculate available width for all items in a row
        let totalSpacing = (2 * sectionInset) + ((itemsPerRow - 1) * spacing)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let cellWidth = availableWidth / itemsPerRow

        return CGSize(width: cellWidth, height: 35)
    }

}
