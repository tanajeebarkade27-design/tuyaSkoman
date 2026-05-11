//
//  ShSceneCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 07/04/25.
//

import UIKit

class ShSceneCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var sceneImage: UIImageView!
    
    @IBOutlet weak var sceneLabel: UILabel!
    
    @IBOutlet weak var sceneBackgroundView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        sceneBackgroundView.cornerRadius = 10
        sceneBackgroundView.clipsToBounds =  true
        sceneBackgroundView.borderWidth =  0.5
        sceneBackgroundView.borderColor = .systemGray
    }

}
