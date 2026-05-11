//
//  DeviceSelCompCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 28/11/25.
//

import UIKit

class DeviceSelCompCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var CellbackgroundView: UIView!
    
    @IBOutlet weak var IsDeviceSelect: UIButton!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    var onDeviceSelect: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        CellbackgroundView.cornerRadius =  10
        CellbackgroundView.clipsToBounds =  true
        CellbackgroundView.borderColor =  .white
        CellbackgroundView.borderWidth =  1
        CellbackgroundView.backgroundColor =  UIColor.white.withAlphaComponent(0.01)
        
        
    }
    
    @IBAction func deviceSelectTapped(_ sender: Any) {
            onDeviceSelect?()
        }
}
