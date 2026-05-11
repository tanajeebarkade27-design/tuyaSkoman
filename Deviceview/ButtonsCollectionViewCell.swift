//
//  ButtonsCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 06/02/25.
//

import UIKit

class ButtonsCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellBackGroundView: UIView!
    @IBOutlet weak var ButtonImage: UIImageView!
    @IBOutlet weak var buttonNamelabel: UILabel!
    
    @IBOutlet weak var childLockImage: UIImageView!
    
    
    @IBOutlet weak var dimImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        cellBackGroundView.layer.cornerRadius = 8
        cellBackGroundView.layer.masksToBounds = true
        cellBackGroundView.layer.borderColor = UIColor.gray.cgColor
        cellBackGroundView.layer.borderWidth = 1
        //applyGradientBackground()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyGradientBackground()  // Reapply gradient on theme change
        }
    }

    func applyGradientBackground() {
        let cellGradientLayer = CAGradientLayer()
        cellGradientLayer.frame = cellBackGroundView.bounds
        cellGradientLayer.cornerRadius = 8
        
        if traitCollection.userInterfaceStyle == .dark {
            cellGradientLayer.colors = [UIColor.black.cgColor, UIColor.darkGray.cgColor]
        } else {
            cellGradientLayer.colors = [
                UIColor.systemBlue.withAlphaComponent(0.2).cgColor,
                UIColor.systemGray6.cgColor
            ]
        }
        
        cellGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        cellGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        cellBackGroundView.layer.sublayers?.removeAll { $0 is CAGradientLayer }
        cellBackGroundView.layer.insertSublayer(cellGradientLayer, at: 0)
    }
    
    func configure(with buttonText: String, index: Int, mappedValues: [[String: String]]) {
        self.buttonNamelabel.text = buttonText
        self.isHidden = false
        self.cellBackGroundView.backgroundColor = UIColor.clear // Default color

        // Find the correct mapped value for this index
        guard index < mappedValues.count else { return }
        let mappedValue = mappedValues[index]

        let lState = mappedValue["L_state"] ?? ""
        let fState = mappedValue["FState"] ?? ""
        let cState = mappedValue["cNm"] == "C" ? mappedValue["L_state"] ?? "" : ""
        let oState = mappedValue["cNm"] == "O" ? mappedValue["L_state"] ?? "" : ""
        let dState = mappedValue["cNm"] == "D" ? mappedValue["L_state"] ?? "" : ""
        
        let masterState = mappedValue["Master"] ?? ""
        
        let childLock = mappedValue["c_l"] ?? "0"
        let dimState = mappedValue["c_dim"] ?? "0"
         print ("at device \(childLock)")

        // Convert HEX to UIColor
        let activeColor = UIColor(hex: "#FAEDCB")
        let inactiveColor = UIColor(hex: "#D3D3D3") 

        if buttonText.starts(with: "L") {
            self.ButtonImage.image = UIImage(named: "bulb")
            self.cellBackGroundView.backgroundColor = (lState == "1") ? activeColor : inactiveColor
        } else if buttonText.starts(with: "O") {
            self.ButtonImage.image = UIImage(named: "curtains_Open")
            self.cellBackGroundView.backgroundColor = (oState == "1") ? activeColor : inactiveColor
        } else if buttonText.starts(with: "C") {
            self.ButtonImage.image = UIImage(named: "curtains_close")
            self.cellBackGroundView.backgroundColor = (cState == "1") ? activeColor : inactiveColor
        }
        else if buttonText.starts(with: "D") {
            self.ButtonImage.image = UIImage(named: "lock-2")
            self.cellBackGroundView.backgroundColor = (cState == "1") ? activeColor : inactiveColor
        }else if buttonText.starts(with: "F") {
            self.ButtonImage.image = UIImage(named: "ceiling-fan")
            self.cellBackGroundView.backgroundColor = (fState == "1") ? activeColor : inactiveColor
        } else if buttonText.starts(with: "Master") {
            self.ButtonImage.image = UIImage(named: "AppIcon1")
            self.cellBackGroundView.backgroundColor = (masterState == "1") ? UIColor.red.withAlphaComponent(0.5) : inactiveColor
        } else {
            self.ButtonImage.image = nil
        }

        if dimState == "1" {
            print("Setting dimm") // Debug log
            DispatchQueue.main.async {
                self.dimImageView.image = UIImage(named: "brightness-2")
                self.dimImageView.isHidden = false
                self.dimImageView.tintColor = .orange
            }
        } else {
            self.dimImageView.image = nil
            self.dimImageView.isHidden = true
        }
     

       
        if childLock == "1" {
            print("Setting lock image") // Debug log
            DispatchQueue.main.async {
                self.childLockImage.image = UIImage(named: "lockIcon")
                self.childLockImage.tintColor =  .black
                self.childLockImage.isHidden = false
            }
        } else {
            self.childLockImage.image = nil
            self.childLockImage.isHidden = true
        }

    }

}
