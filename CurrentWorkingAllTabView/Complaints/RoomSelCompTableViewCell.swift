//
//  RoomSelCompTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 28/11/25.
//

import UIKit

class RoomSelCompTableViewCell: UITableViewCell {
    
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var cellBackground: UIView!
    @IBOutlet weak var imageBackgroundView: UIView!
    
    @IBOutlet weak var roomIamgeView: UIImageView!
    
    @IBOutlet weak var deviceCollectionView: UICollectionView!
    
    @IBOutlet weak var isRoomSelcted: UIButton!
    

    weak var parentVC: HomeSelCompViewController?
    var onDeviceCellTapped: (([ButtonDetails]) -> Void)?
    

    var onSelectRoom: (() -> Void)?
    var roomDevices: [Device] = [] {
        didSet {
            deviceCollectionView.reloadData()
             
           
        }
    }

       override func awakeFromNib() {
           super.awakeFromNib()
           imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
           backgroundColor = .clear
           contentView.backgroundColor = .clear
           isRoomSelcted.addTarget(self, action: #selector(roomButtonTapped), for: .touchUpInside)
           deviceCollectionView.delegate = self
              deviceCollectionView.dataSource = self

              let nib = UINib(nibName: "DeviceSelCompCollectionViewCell", bundle: nil)
           deviceCollectionView.register(nib, forCellWithReuseIdentifier: "DeviceSelCompCollectionViewCell")
       }

    @objc func roomButtonTapped() {
            onSelectRoom?()
        }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        imageBackgroundView.cornerRadius =  20
        
        cellBackground.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
        cellBackground.cornerRadius =  20
        cellBackground.clipsToBounds =  true
    }
    
    func updateRoomSelectionAfterDeviceToggle() {
        guard let parentVC = parentVC else { return }
        
        // Find this room inside its home
        for sectionIndex in 0..<parentVC.homes.count {
            for roomIndex in 0..<parentVC.homes[sectionIndex].rooms.count {
                
                let room = parentVC.homes[sectionIndex].rooms[roomIndex]
                
                if room.roomId == roomDevices.first?.roomId {
                    
                    let devices = room.devices
                    
                    // All devices selected?
                    let allSelected = devices.allSatisfy { parentVC.selectedDevices[$0.uniqueId] ?? false }
                    
                    // Update room state
                    parentVC.homes[sectionIndex].rooms[roomIndex].isSelected = allSelected
                    
                    // Update home state
                    let allRoomsSelected = parentVC.homes[sectionIndex].rooms.allSatisfy { $0.isSelected }
                    parentVC.homes[sectionIndex].isSelected = allRoomsSelected
                    
                    return
                }
            }
        }
    }
    
    func fetchDeviceStateByUniqueId(uniqueId: String) -> [ButtonDetails] {
        return SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: uniqueId)
    }
    
    private func toggleSelection(for device: Device) {
        guard let parentVC else { return }
        
        let homeIndex = parentVC.homes.firstIndex(where: { home in
            home.rooms.contains { $0.roomId == device.roomId }
        })
        
        if let homeIndex {
            // If no active home → set active home
            if parentVC.activeHomeIndex == nil {
                parentVC.activeHomeIndex = homeIndex
            }
            
            if parentVC.activeHomeIndex != homeIndex {
                print("❌ Cannot select device from another home")
                return
            }
        }
        
        // Toggle
        let old = parentVC.selectedDevices[device.uniqueId] ?? false
        parentVC.selectedDevices[device.uniqueId] = !old
        
        updateRoomSelectionAfterDeviceToggle()
        parentVC.HomeTableView.reloadData()
    }



}
extension RoomSelCompTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Device count for this room:", roomDevices.count)   // DEBUG
        return roomDevices.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DeviceSelCompCollectionViewCell",
            for: indexPath
        ) as! DeviceSelCompCollectionViewCell
       

        let device = roomDevices[indexPath.item]

        print("Setting device name:", device.uniqueId)

        cell.deviceNameLabel.text = device.uniqueId
        

       
        let selected = (parentVC?.selectedDevices[device.uniqueId] ?? false)
        let imageName = selected ? "okImage" : "unselect1"

        cell.onDeviceSelect = { [weak self] in
            guard let self = self else { return }
            self.toggleSelection(for: device)
        }

            if let img = UIImage(named: imageName)?.resized(to: CGSize(width: 20, height: 20)) {
                cell.IsDeviceSelect.setImage(img, for: .normal)
                
            }
        
        
        
        


        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let device = roomDevices[indexPath.item]
        let uniqueId = device.uniqueId
        
        // Most users tap the cell itself. Treat cell-tap as selection toggle too.
        toggleSelection(for: device)

        let buttonDetails = fetchDeviceStateByUniqueId(uniqueId: uniqueId)

        print("Sending button details to parent VC")

       
        onDeviceCellTapped?(buttonDetails)
    }




    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 160, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    

     
}
