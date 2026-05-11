//
//  ConfigureRoomSecensTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 20/08/25.
//

import UIKit
import Alamofire

protocol ConfigureRoomSecensTableViewCellDelegate: AnyObject {
    func sendSceneRedundantPayload(for device: Device, redundantL: String, redundantF: String)
}


class ConfigureRoomSecensTableViewCell: UITableViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    @IBOutlet weak var SeeButtons: UIButton!
    
    @IBOutlet weak var sceneButtonCollectionView: UICollectionView!
    var selectedSwitchIndices: Set<Int> = [] 

   
    var device: Device?
    weak var delegate: ConfigureRoomSecensTableViewCellDelegate?
    var receivedDeviceStates: [DeviceStateArray] = [] {
        didSet {
            sceneButtonCollectionView.reloadData()
            print("📦 Updated device states for cell: \(receivedDeviceStates)")
        }
    }
    var deviceSeries: String? {
           return receivedDeviceStates.first?.series
       }
   

    var switches: [SwitchItem] = [] {
           didSet {
               sceneButtonCollectionView.reloadData()
           }
       }
   
    override func awakeFromNib() {
        super.awakeFromNib()
       
     print ("device at scene\(device)")
       
        cellbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        cellbackgroundView.cornerRadius =  10
        cellbackgroundView.clipsToBounds =  true
        registerFile()
        
        
    }

    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 10
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: inset/2, left: 0, bottom: inset/2, right: 0))
    }

    
    func registerFile(){
        let uinib =  UINib(nibName: "ConfigureRoomButtonCollectionViewCell", bundle: nil)
        sceneButtonCollectionView.register(uinib, forCellWithReuseIdentifier: "ConfigureRoomButtonCollectionViewCell")
       
        sceneButtonCollectionView.dataSource =  self
        sceneButtonCollectionView.delegate =  self
        
    }
    

    
    func configureCell(with device: Device) {
        deviceNameLabel.text = device.deviceName ?? device.uniqueId
        
       
        if let state = receivedDeviceStates.first {
            print("📊 Device \(device.uniqueId) state data: \(state)")
        }

        // If you need to do something with switches
        if !switches.isEmpty {
            print("💡 Switches count: \(switches.count)")
        }

        sceneButtonCollectionView.reloadData()
    }


}

 
    extension ConfigureRoomSecensTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        
        // ✅ Only non-master switches are shown
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            let nonMasterSwitches = switches.filter { $0.type != .master }
            print("💡 Total visible switches (excluding master): \(nonMasterSwitches.count)")
            return nonMasterSwitches.count
        }
        
        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ConfigureRoomButtonCollectionViewCell",
                for: indexPath
            ) as! ConfigureRoomButtonCollectionViewCell
            
            // ✅ Use only non-master switches
            let nonMasterSwitches = switches.filter { $0.type != .master }
            let switchItem = nonMasterSwitches[indexPath.item]
            
            // Device series (for V9)
            cell.deviceSeries = receivedDeviceStates.first?.series
            
             
            cell.configure(with: switchItem)
            
            // Selection logic for V9 devices
            if selectedSwitchIndices.contains(indexPath.item),
               cell.deviceSeries == "AVR_V9_NORMAL" {
                cell.iselectedImageview.isHidden = false
            } else {
                cell.iselectedImageview.isHidden = true
            }
            
            return cell
        }

        func collectionView(_ collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout,
                            sizeForItemAt indexPath: IndexPath) -> CGSize {
            let numberOfColumns: CGFloat = 3
            let spacing: CGFloat = 10
            let totalSpacing = (numberOfColumns - 1) * spacing
            let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
            return CGSize(width: itemWidth, height: itemWidth)
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard deviceSeries == "AVR_V9_NORMAL",
                  let device = device else { return }
            
            let nonMasterSwitches = switches.filter { $0.type != .master }
            let switchItem = nonMasterSwitches[indexPath.item]
            
            // ✅ Toggle selection
            if selectedSwitchIndices.contains(indexPath.item) {
                selectedSwitchIndices.remove(indexPath.item)
            } else {
                selectedSwitchIndices.insert(indexPath.item)
            }
            
            // ✅ Reload only tapped cell
            collectionView.reloadItems(at: [indexPath])
          
           
        }

    }

   
extension ConfigureRoomSecensTableViewCell {
    func buildRedundantStrings() -> (redundantL: String, redundantF: String) {
        let nonMasterSwitches = switches.filter { $0.type != .master }
        var redundantL = ""
        var redundantF = ""

        for (index, sItem) in nonMasterSwitches.enumerated() {
            if sItem.type == .light {
                redundantL.append(selectedSwitchIndices.contains(index) ? "1" : "0")
            } else if sItem.type == .fan {
                redundantF.append(selectedSwitchIndices.contains(index) ? "1" : "0")
            }
        }

        return (redundantL, redundantF)
    }
}


    




