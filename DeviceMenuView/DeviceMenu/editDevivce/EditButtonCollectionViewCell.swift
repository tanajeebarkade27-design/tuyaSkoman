//
//  EditButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 17/03/25.
//

import UIKit

class EditButtonCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var buttonImage: UIImageView!
    
    @IBOutlet weak var buttonNameLabel: UILabel!
    
    
    override func awakeFromNib() {
       
        super.awakeFromNib()
        cellbackgroundView.layer.cornerRadius = 8
        cellbackgroundView.layer.masksToBounds = true
        //cellbackgroundView.layer.borderColor = UIColor.gray.cgColor
       
    }

}
