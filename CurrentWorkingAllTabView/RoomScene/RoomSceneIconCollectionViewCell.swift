//
//  RoomSceneIconCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 21/08/25.
//

import UIKit

class RoomSceneIconCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellBackgroundView: UIView!
    
    @IBOutlet weak var sceneImage: UIImageView!
    
    @IBOutlet weak var imageBackgroundView: UIView!
    
    
    @IBOutlet weak var sceneNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
//        cellBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
//        cellBackgroundView.cornerRadius =  10
//        cellBackgroundView.clipsToBounds =  true
        imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.frame.height / 2
        imageBackgroundView.clipsToBounds = true
         
    }

}
