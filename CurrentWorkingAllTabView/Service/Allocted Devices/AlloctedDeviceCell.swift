//
//  AlloctedDeviceCell.swift
//  SkromanIsra
//
//  Created by Admin on 22/11/25.
//

import UIKit

class AlloctedDeviceCell: UICollectionViewCell {
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    
    @IBOutlet weak var cellBackground: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellBackground.backgroundColor =  UIColor.white.withAlphaComponent(0.1)
        cellBackground.cornerRadius =  20
        cellBackground.clipsToBounds =  true
       
    }

}
