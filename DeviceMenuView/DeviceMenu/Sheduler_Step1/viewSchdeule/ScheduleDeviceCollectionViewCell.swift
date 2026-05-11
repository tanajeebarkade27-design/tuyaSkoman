//
//  ScheduleDeviceCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 15/03/25.
//

import UIKit

class ScheduleDeviceCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var deviceImage: UIImageView!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
  
    @IBOutlet weak var backroundCell: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        backroundCell.layer.cornerRadius = 15
        backroundCell.layer.masksToBounds =  true
        backroundCell.layer.borderColor =  UIColor.gray.cgColor
        backroundCell.layer.borderWidth = 1
    }

}
