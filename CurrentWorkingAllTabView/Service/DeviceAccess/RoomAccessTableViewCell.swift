//
//  RoomAccessTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 15/11/25.
//

import UIKit

class RoomAccessTableViewCell: UITableViewCell {
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var cellBackground: UIView!
    @IBOutlet weak var imageBackgroundView: UIView!
    
    @IBOutlet weak var roomIamgeView: UIImageView!
    
    @IBOutlet weak var deviceCollectionView: UICollectionView!
    
    @IBOutlet weak var isRoomSelcted: UIButton!
    weak var parentVC: DeviceAccessViewController?

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

              let nib = UINib(nibName: "AccessDeviceCollectionViewCell", bundle: nil)
              deviceCollectionView.register(nib, forCellWithReuseIdentifier: "AccessDeviceCollectionViewCell")
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
                    
                    // Any device selected?
                    let anySelected = devices.contains { parentVC.selectedDevices[$0.uniqueId] ?? false }
                    
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

}
extension RoomAccessTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Device count for this room:", roomDevices.count)   // DEBUG
        return roomDevices.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "AccessDeviceCollectionViewCell",
            for: indexPath
        ) as! AccessDeviceCollectionViewCell
       

        let device = roomDevices[indexPath.item]

        print("Setting device name:", device.uniqueId)

        cell.deviceNameLabel.text = device.uniqueId

       
        let selected = (parentVC?.selectedDevices[device.uniqueId] ?? false)
        let imageName = selected ? "okImage" : "unselect1"


        if let img = UIImage(named: imageName)?.resized(to: CGSize(width: 20, height: 20)) {
            cell.IsDeviceSelect.setImage(img, for: .normal)
        }



        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 140, height: 55)
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let parentVC = parentVC else { return }

        let device = roomDevices[indexPath.item]
        let uniqueId = device.uniqueId
        let currentState = parentVC.selectedDevices[uniqueId] ?? false
        parentVC.selectedDevices[uniqueId] = !currentState
 
        collectionView.reloadItems(at: [indexPath])

        updateRoomSelectionAfterDeviceToggle()

   
        parentVC.homeListTableView.reloadData()
    }

     
}

