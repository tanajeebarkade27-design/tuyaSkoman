//
//  SocietyCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 23/01/26.
//

import UIKit

class SocietyCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var backgroundCell: UIView!
    
    @IBOutlet weak var iconImageView: UIImageView!
       @IBOutlet weak var titleLabel: UILabel!

       override func awakeFromNib() {
           super.awakeFromNib()

           contentView.layer.cornerRadius = 12
           contentView.clipsToBounds = true
           backgroundCell.cornerRadius =  12
           backgroundCell.clipsToBounds =  true
           backgroundCell.backgroundColor = .white.withAlphaComponent(0.4)
           
           titleLabel.numberOfLines = 2
              titleLabel.lineBreakMode = .byWordWrapping
       }

       func configure(with item: SocietyTabItem) {
           titleLabel.text = item.title
           iconImageView.image = UIImage(named: item.imageName)
           
       }
}
