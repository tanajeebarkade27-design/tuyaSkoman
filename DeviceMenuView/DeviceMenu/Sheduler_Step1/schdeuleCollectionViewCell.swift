//
//  schdeuleCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 11/03/25.
//

import UIKit

class schdeuleCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var devicImage: UIImageView!
    
    @IBOutlet weak var cellbackgroundview: UIView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var dimmStattus: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
      
        cellbackgroundview.layer.masksToBounds =  true
       
       // cellbackgroundview.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        cellbackgroundview.cornerRadius = 15
    
    }
    
    

}
