//
//  ViewRoomSceneTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 20/08/25.
//

import UIKit

class ViewRoomSceneTableViewCell: UITableViewCell {
    @IBOutlet weak var cellBackgrounView: UIView!
    @IBOutlet weak var deviecNameLabel: UILabel!
    @IBOutlet weak var roomSceneCollectionView: UICollectionView!
    
    private var scenes: [DeviceScene] = []
    var buttonItems: [(name: String, type: String, status: String, redundant: String)] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        registerFile()
        cellBackgrounView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        cellBackgrounView.cornerRadius =  10
        cellBackgrounView.clipsToBounds =  true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 10
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: inset/2, left: 0, bottom: inset/2, right: 0))
    }

    func configure(with device: Device, scenes: [DeviceScene]) {
        deviecNameLabel.text = device.deviceName
        self.scenes = scenes
        print("📌 Scenes received for device \(device.deviceName): \(scenes)")
        
        if let firstScene = scenes.first {   // ✅ handle first matching scene only
            updateDeviceStates(from: firstScene)
        } else {
            buttonItems.removeAll()
        }
        
        roomSceneCollectionView.reloadData()
    }
    
    private func registerFile() {
        let uinib =  UINib(nibName: "ViewRoomSceneCollectionViewCell", bundle: nil)
        roomSceneCollectionView.register(uinib, forCellWithReuseIdentifier: "ViewRoomSceneCollectionViewCell")
        roomSceneCollectionView.dataSource = self
        roomSceneCollectionView.delegate = self
    }
    
    private func updateDeviceStates(from scene: DeviceScene) {
        let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
        var updatedButtonItems: [(name: String, type: String, status: String, redundant: String)] = []

        let lightStatusArray = Array(scene.LState)
        let configButtonsArray = Array(scene.configButtons ?? "")
        let lightRedundantArray = Array(scene.LRedundant ?? "")
        
        // Lights
        for (index, button) in configButtonsArray.enumerated() {
            guard index < lightStatusArray.count else { continue }

            let status = String(lightStatusArray[index])
            let redundant = index < lightRedundantArray.count ? String(lightRedundantArray[index]) : "0"
            let filteredName = String(button).filter { !unwantedChars.contains($0) }

            if !filteredName.isEmpty {
                updatedButtonItems.append((name: filteredName, type: String(button), status: status, redundant: redundant))
            }
        }

        // Fan
        if scene.fanDest == "1" {
            let fanStatus = scene.FState.isEmpty ? "0" : scene.FState
            let fanRedundant = scene.FRedundant ?? "0"
            updatedButtonItems.append((name: "Fan", type: "F", status: fanStatus, redundant: fanRedundant))
        }

        self.buttonItems = updatedButtonItems
    }

}

extension ViewRoomSceneTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttonItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ViewRoomSceneCollectionViewCell",
            for: indexPath
        ) as! ViewRoomSceneCollectionViewCell
        
        let item = buttonItems[indexPath.item]
        print("⚙️ Configuring item \(indexPath.item): \(item)")
        
        // MARK: - Label
        cell.deviceNamelabel.text = "\(item.name)\(indexPath.item + 1)"
        
        // MARK: - Image + slider visibility
        switch item.type {
        case "L":
            cell.deviceImageView.image = UIImage(named: "Group-2")
            cell.fanSlider.isHidden = true
            
        case "O", "Q": // Curtain open
            cell.deviceImageView.image = UIImage(named: "curtains_open")
            cell.fanSlider.isHidden = true
            
        case "C", "Y": // Curtain close
            cell.deviceImageView.image = UIImage(named: "curtains_close")
            cell.fanSlider.isHidden = true
            
        case "F": // Fan
            cell.deviceImageView.image = UIImage(named: "Fan1")
            cell.fanSlider.isHidden = false
            
        case "D": // Door lock
            cell.deviceImageView.image = UIImage(named: "lock-2")
            cell.fanSlider.isHidden = true
            
        default:
            cell.deviceImageView.image = UIImage(named: "appicon")
            cell.fanSlider.isHidden = true
        }
        
        // MARK: - Border color (ON/OFF state)
        cell.cellbackgroundview.layer.borderColor = (item.status == "1" ? UIColor.systemYellow.cgColor : UIColor.white.cgColor)
        cell.cellbackgroundview.layer.borderWidth = 1
        cell.cellbackgroundview.layer.cornerRadius = 8
        cell.cellbackgroundview.backgroundColor = .clear
        
        // MARK: - Redundant Image Visibility
        if item.redundant == "1" {
            cell.isreduadant.isHidden = false
           /* cell.isreduadant.image = UIImage(named: "redundant_icon")*/ // 👈 replace with your actual image name
        } else {
            cell.isreduadant.isHidden = true
        }
        
        return cell
    }

    // Layout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 10
        let totalSpacing = (numberOfColumns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth) // square buttons
    }
}
