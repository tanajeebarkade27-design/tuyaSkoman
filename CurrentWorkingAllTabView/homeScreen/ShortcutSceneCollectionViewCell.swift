//
//  ShortcutSceneCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 03/06/25.
//

import UIKit

class ShortcutSceneCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIView!
    
    @IBOutlet weak var sceneImage: UIImageView!
    
    @IBOutlet weak var sceneNameLabel: UILabel!
    
    @IBOutlet weak var cellbackgroundView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.cornerRadius = 15
        imageView.clipsToBounds = true
//        cellbackgroundView.borderColor =  UIColor.gray
//        cellbackgroundView.borderWidth =  0.5
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
    }

}
