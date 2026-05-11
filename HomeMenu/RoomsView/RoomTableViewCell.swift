//
//  RoomTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 04/02/25.
//

import UIKit

class RoomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var roomaNamelLabel: UILabel!
    @IBOutlet weak var roomIconImage: UIImageView!
    
    @IBOutlet weak var roomSubTitlelLabel: UILabel!
    @IBOutlet weak var settingButton: UIButton!
    
    @IBOutlet weak var cellbackgroundView: UIView!
    var parentVC: RoomViewController?
    var homeServerID: String? // Store Home Server ID
       var roomID: String?
    var selecetdRoomId : String?
    var selectedHomeid : String?
    var selectedRoomName: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        settingButton.setTitle("", for: .normal)
        cellbackgroundView.layer.cornerRadius = 8
        cellbackgroundView.layer.masksToBounds = true
        applyGradientBackground()
         print("selecetdRoomId\(selecetdRoomId), selectedHomeid\(selectedHomeid) ")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        guard let originalImage = UIImage(named: "gear") else {
            print("Image not found!")
            return
        }
        super.setSelected(selected, animated: animated)
        let targetSize = settingButton.bounds.size
        if let resizedImage = resizeImage(image: originalImage, targetSize: targetSize) {
            settingButton.setImage(resizedImage, for: .normal)
            settingButton.imageView?.contentMode = .scaleAspectFit
        }
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyGradientBackground()  // Reapply gradient on theme change
        }
    }

    
    
    func applyGradientBackground() {
        let cellGradientLayer = CAGradientLayer()
        cellGradientLayer.frame = cellbackgroundView.bounds
        cellGradientLayer.cornerRadius = 8
        
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode gradient (Black to Dark Gray)
            cellGradientLayer.colors = [UIColor.black.cgColor, UIColor.darkGray.cgColor]
        } else {
            // Light mode gradient (Soft Blue to Light Gray)
            cellGradientLayer.colors = [
                UIColor.systemBlue.withAlphaComponent(0.2).cgColor,  // Light Blue Tint
                UIColor.systemGray6.cgColor  // Soft Gray
            ]
        }
        
        cellGradientLayer.startPoint = CGPoint(x: 0, y: 0)  // Top-left
        cellGradientLayer.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right
        
        cellbackgroundView.layer.sublayers?.removeAll { $0 is CAGradientLayer } // Remove old gradient
        cellbackgroundView.layer.insertSublayer(cellGradientLayer, at: 0)
    }

    
    @IBAction func roomSettingButtonTapped(_ sender: UIButton) {
        guard let roomId = selecetdRoomId, let homeId = selectedHomeid,
        let roomName = selectedRoomName  else {
            print("Room ID or Home ID is nil")
            return
        }
        
        parentVC?.showBottomSheet(roomId: roomId, homeId: homeId, roomName: roomName)
    }


    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
