//
//  ViewRoomSceneCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 21/08/25.
//

import UIKit

class ViewRoomSceneCollectionViewCell: UICollectionViewCell {
   
        @IBOutlet weak var deviceImageView: UIImageView!
        @IBOutlet weak var deviceNamelabel: UILabel!
        @IBOutlet weak var cellbackgroundview: UIView!
    
    
    @IBOutlet weak var isreduadant: UIImageView!
    
    
    @IBOutlet weak var fanSlider: UISlider!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        cellbackgroundview.cornerRadius =  10
        cellbackgroundview.clipsToBounds =  true
        cellbackgroundview.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    }

}
