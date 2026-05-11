//
//  ScheduleNoCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 13/03/25.
//

import UIKit

class ScheduleNoCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var cellbackgroundview: UIView!
    
    @IBOutlet weak var schdeuleNumberLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        cellbackgroundview.layer.cornerRadius =  8
        cellbackgroundview.layer.masksToBounds =  true
        cellbackgroundview.layer.borderColor =  UIColor.white.cgColor
        cellbackgroundview.layer.borderWidth = 1
    }
    
}
