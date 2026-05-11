//
//  ScheduleDaysCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 15/03/25.
//

import UIKit

class ScheduleDaysCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellbackGroundView: UIView!
    @IBOutlet weak var daylabel: UILabel!
    
    func configure(day: String, isSelected: Bool) {
        daylabel.text = day
        cellbackGroundView.backgroundColor = isSelected ? UIColor.systemGreen : UIColor.clear
        
        cellbackGroundView.layer.cornerRadius =  8
        cellbackGroundView.layer.masksToBounds =  true
        cellbackGroundView.borderColor =  .white
      
        cellbackGroundView.layer.borderWidth = 1
    }
}



