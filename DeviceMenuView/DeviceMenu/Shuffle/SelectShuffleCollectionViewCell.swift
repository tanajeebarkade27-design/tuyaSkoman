//
//  SelectShuffleCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 04/03/25.
//

import UIKit

class SelectShuffleCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImageView: UIImageView!
    
    @IBOutlet weak var cellbackgroundview: UIView!
    @IBOutlet weak var diimimgImage: UIImageView!
    
    @IBOutlet weak var shuffleDeviceNamelabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        cellbackgroundview.layer.cornerRadius =  8
        cellbackgroundview.layer.masksToBounds =  true
cellbackgroundview.layer.borderColor =  UIColor.gray.cgColor
        cellbackgroundview.layer.borderWidth = 1
    }

}
