//
//  SceneNumberCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//

import UIKit

class SceneNumberCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var sceneBackgroundview: UIView!
    @IBOutlet weak var sceneNumberLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sceneBackgroundview.layer.cornerRadius =  12
        
        sceneBackgroundview.layer.masksToBounds =  true
       
        sceneBackgroundview.layer.borderWidth = 1
    }

}
