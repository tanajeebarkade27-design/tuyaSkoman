//
//  NewDeviceMenuCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 25/07/25.
//

import UIKit

class NewDeviceMenuCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellBackgroundView: UIView!
    @IBOutlet weak var imagebackgroundView: UIView!
    @IBOutlet weak var menuImage: UIImageView!
    @IBOutlet weak var menulabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        imagebackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        
        cellBackgroundView.layer.cornerRadius = 10
        cellBackgroundView.clipsToBounds = true
        cellBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        
        menulabel.numberOfLines = 2
        menulabel.lineBreakMode = .byWordWrapping
        menulabel.adjustsFontSizeToFitWidth = false
        menulabel.textAlignment = .center
        menulabel.sizeToFit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imagebackgroundView.layer.cornerRadius = imagebackgroundView.frame.height / 2
        
        imagebackgroundView.clipsToBounds = true
    }
}
