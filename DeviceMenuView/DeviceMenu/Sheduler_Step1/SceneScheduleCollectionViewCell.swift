//
//  SceneScheduleCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 15/03/25.
//

import UIKit

class SceneScheduleCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundVew: UIView!
    
    @IBOutlet weak var sceneLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
      
        cellbackgroundVew.layer.masksToBounds =  true
        //cellbackgroundVew.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        cellbackgroundVew.cornerRadius = 15
        
    }

}
