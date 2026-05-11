//
//  ConfigureRoomButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 20/08/25.
//

import UIKit

class ConfigureRoomButtonCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var buttonImageView: UIImageView!
    @IBOutlet weak var buttonLabel: UILabel!
    
    @IBOutlet weak var fanAndDimslider: UISlider!
    
    @IBOutlet weak var cellBackgroundView: UIView!
    
    @IBOutlet weak var iselectedImageview: UIImageView!
    var deviceSeries: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        cellBackgroundView.layer.cornerRadius = 10
        cellBackgroundView.clipsToBounds = true
        cellBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    }
    
    
    
    
    
    func configure(with item: SwitchItem) {
        print("🔘 Configuring cell with: \(item)")
        
        buttonLabel.text = item.buttonDetail?.buttonName
        
        // Tint color based on ON/OFF state
        buttonImageView.tintColor = item.isOnState == 1 ? .green : .red
        
        // Border highlight for ON state
        if item.isOnState == 1 {
            cellBackgroundView.layer.borderWidth = 2
            cellBackgroundView.layer.borderColor = UIColor.systemYellow.cgColor
        } else {
            cellBackgroundView.layer.borderWidth = 0
            cellBackgroundView.layer.borderColor = UIColor.clear.cgColor
        }
        
        // Extract details
        let controlName = item.buttonDetail?.buttonControlName ?? ""
        let iconNameRaw = item.buttonDetail?.buttonIconName ?? ""
        
        // Normalize icon name (handle "null", "Unknown", etc.)
        let iconName = iconNameRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let isInvalidIcon = iconName.isEmpty || iconName.lowercased() == "null" || iconName.lowercased() == "unknown"
        
        var imageToUse: UIImage?
        
        // AppIcon1 for Master button
        if controlName == "M" {
            imageToUse = UIImage(named: "AppIcon1")
        }
        else if !isInvalidIcon {
            // Use valid custom icon from API
            imageToUse = UIImage(named: iconName)
        }
        else {
            // Fallbacks for other control types
            switch controlName {
            case "F":
                imageToUse = UIImage(named: "Fan1")
            case "L":
                imageToUse = UIImage(named: "LightBulb")
            case "O", "Q":
                imageToUse = UIImage(named: "curtain-filled")
            default:
                // 🟡 Default placeholder if nothing else matches
                imageToUse = UIImage(named: "default-icon")
            }
        }
        
        // Always show some image
        buttonImageView.image = imageToUse ?? UIImage(named: "default-icon")
        
        // Debug log
        print("✅ Loaded image for control: \(controlName), icon: \(iconNameRaw)")
        
        // Handle dimmer/fan slider
        if item.configDim == "1" || controlName == "F" {
            fanAndDimslider.isHidden = false
            if let speed = item.speed, let value = Float(speed) {
                fanAndDimslider.value = value
            } else {
                fanAndDimslider.value = 0
            }
        } else {
            fanAndDimslider.isHidden = true
        }
    }



}
