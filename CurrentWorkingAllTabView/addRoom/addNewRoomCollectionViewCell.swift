//
//  addNewRoomCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/07/25.
//

import UIKit

class addNewRoomCollectionViewCell: UICollectionViewCell {
    
    
    
    @IBOutlet weak var imageBackgroundView: UIView!
    
    @IBOutlet weak var roomImageView: UIImageView!
    
    @IBOutlet weak var cellBackgroundView: UIView!
    
    @IBOutlet weak var roomNamelabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
      
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.frame.height / 2
        imageBackgroundView.clipsToBounds = true
        imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        roomNamelabel.textColor = .white

        
        
    }

}
