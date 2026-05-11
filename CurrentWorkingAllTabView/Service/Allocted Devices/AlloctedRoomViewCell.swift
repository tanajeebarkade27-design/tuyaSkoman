//
//  AlloctedRoomViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 22/11/25.
//

import UIKit

class AlloctedRoomViewCell: UITableViewCell {
    
    
    @IBOutlet weak var imageBackground: UIView!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var cellBackground: UIView!
    
    @IBOutlet weak var roomIamge: UIImageView!
    
    @IBOutlet weak var AllotedDeviceCollection: UICollectionView!
    var devices: [[String: Any]] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        
        imageBackground.cornerRadius =  20
        
        cellBackground.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
        cellBackground.cornerRadius =  20
        cellBackground.clipsToBounds =  true
        
        
              AllotedDeviceCollection.delegate = self
              AllotedDeviceCollection.dataSource = self
              
              AllotedDeviceCollection.register(
                  UINib(nibName: "AlloctedDeviceCell", bundle: nil),
                  forCellWithReuseIdentifier: "AlloctedDeviceCell"
              )
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}

extension AlloctedRoomViewCell : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlloctedDeviceCell", for: indexPath) as! AlloctedDeviceCell
        
        let device = devices[indexPath.row]
        
        cell.deviceNameLabel.text = device["deviceName"] as? String ?? "Device"
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 140, height: 55)
    }
}
