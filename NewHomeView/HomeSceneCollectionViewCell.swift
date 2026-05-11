//
//  HomeSceneCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 28/03/25.
//

import UIKit

class HomeSceneCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var sceneView: UIView!
    
    @IBOutlet weak var sceneImageView: UIImageView!
    
    @IBOutlet weak var SceneNamelabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sceneView.cornerRadius =  10
        sceneView.clipsToBounds =   true
        sceneView.borderColor = .systemGray
        sceneView.borderWidth =  0.5
        
    }

}
