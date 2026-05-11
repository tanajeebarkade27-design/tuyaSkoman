//
//  EditDeviceCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 17/03/25.
//

import UIKit

class EditDeviceCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backGroundCell: UIView!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var deviceImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
       
        
        backGroundCell.layer.cornerRadius = 10
        backGroundCell.clipsToBounds = true
//        backGroundCell.layer.borderColor = UIColor.gray.cgColor
       // backGroundCell.layer.borderWidth = 1
    }

}
