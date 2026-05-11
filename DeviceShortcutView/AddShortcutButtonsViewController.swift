//
//  ShortcutButtonsViewController.swift
//  SkromanIsra
//
//  Created by Admin on 03/05/25.
//

import UIKit
enum ShortcutMode {
    case dimming, fan
}

class AddShortcutButtonsViewController: UIViewController {
    var rooms: [Room] = []
    var devices: [Device] = []
    var mode: ShortcutMode = .dimming
    
    var receivedDeviceStates: [DeviceStateArray] = []
    
    var filteredTargets: [(device: DeviceStateArray, index: Int, currentState: String)] = []
    var selectedIndexes: Set<Int> = []
    
    @IBOutlet var mainView: UIView!
    var buttonDetails: [ButtonDetails] = []
    
    @IBOutlet weak var deviceCollectionView: UICollectionView!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var buttonsCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyGradientBackground()
       fetchAllButtonDetailsForDevices()
        registerXib()
        backButton.setTitle("", for: .normal)
        print("devices at \(devices)")
         print("receivedDeviceStates at sh\(receivedDeviceStates)")
        print("buttonDetails at  sh\(buttonDetails)")
        reloadTargets()
        switch mode {
            case .dimming:
                title = "Dimming Shortcuts"
               print("Dimming Shortcuts")
            case .fan:
                title = "Fan Shortcuts"
           print( "fan Shortcuts")
            }
    }
    
    
   

    
    func registerXib(){
        
        let deviceNib = UINib(nibName: "ShortcutDeviceButtonCollectionViewCell", bundle: nil)
        deviceCollectionView.register(deviceNib, forCellWithReuseIdentifier: "ShortcutDeviceButtonCollectionViewCell")
        deviceCollectionView.dataSource = self
        deviceCollectionView.delegate = self
    }
    
    @IBAction func saveButton(_ sender: Any) {
        for case let cell as ShortcutDeviceButtonCollectionViewCell in deviceCollectionView.visibleCells {
               cell.submitSelectedButtons()
           }
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    func reloadTargets() {
        filteredTargets.removeAll()

        for device in receivedDeviceStates {
            switch mode {
            case .dimming:
                let maskChars  = Array(device.cNm)
                let stateChars = Array(device.lightState)

                for (i, maskChar) in maskChars.enumerated() {
                    guard i < stateChars.count else { continue }
                    if maskChar == "L" {
                        filteredTargets.append((
                            device:       device,
                            index:        i,
                            currentState: String(stateChars[i])
                        ))
                    }
                }

            case .fan:
                let fanCount = device.cF.count / 3
                for fanIndex in 0..<fanCount {
                    let start = fanIndex * 3
                    let end = min(start + 3, device.fanState.count)
                    guard end > start else { continue }
                    
                    let startIndex = device.fanState.index(device.fanState.startIndex, offsetBy: start)
                    let endIndex = device.fanState.index(device.fanState.startIndex, offsetBy: end)
                    let stateChunk = device.fanState[startIndex..<endIndex]
                    
                    filteredTargets.append((
                        device:       device,
                        index:        fanIndex,
                        currentState: String(stateChunk)
                    ))
                }

            }
        }

        // Debug
        print("🔍 Filtered \(mode) targets:")
        for (dev, idx, state) in filteredTargets {
            print(" • \(mode) @ \(dev.uniqueID)[\(idx)] = \(state)")
        }

        DispatchQueue.main.async {
            self.deviceCollectionView.reloadData()  // reload the outer view
        }
    }

    

    
    func fetchAllButtonDetailsForDevices() {
        var allFetchedButtonDetails: [ButtonDetails] = []

        for device in receivedDeviceStates {
            let uniqueId = device.uniqueID
            let details =  SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: uniqueId)
            allFetchedButtonDetails.append(contentsOf: details)
        }

        self.buttonDetails = allFetchedButtonDetails
        print("Loaded button details: \(buttonDetails.count)")
    }


    
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = mainView.bounds

        mainScreen.colors = [
            UIColor(red: 163/255, green: 159/255, blue: 98/255, alpha: 1).cgColor,   // Gold
            UIColor(red: 141/255, green: 176/255, blue: 144/255, alpha: 1).cgColor,  // Green
            UIColor(red: 104/255, green: 155/255, blue: 181/255, alpha: 1).cgColor   // Blue
        ]

        mainScreen.locations = [0.0, 0.3, 0.8]  // Expands green & blue areas
        mainScreen.startPoint = CGPoint(x: 0.5, y: 0)   // Top center
        mainScreen.endPoint = CGPoint(x: 0.5, y: 1)     // Bottom center

     
        mainView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        mainView.layer.insertSublayer(mainScreen, at: 0)
    }

    

}


extension AddShortcutButtonsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(
          withReuseIdentifier: "ShortcutDeviceButtonCollectionViewCell",
          for: ip
        ) as! ShortcutDeviceButtonCollectionViewCell

        cell.mode    = mode
        cell.devices = devices
        cell.configure(with: devices[ip.item], allTargets: filteredTargets)
        return cell
    }



    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - 5
        return CGSize(width: width, height:300)
    }
}

