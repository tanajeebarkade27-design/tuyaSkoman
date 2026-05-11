//
//  DimmingCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 13/02/25.
//

import UIKit

class DimmingCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellBackGroundview: UIView!
   
    
    @IBOutlet weak var deviceLabel: UILabel!
    
    @IBOutlet weak var deviceImageView: UIImageView!
    
    
    @IBOutlet weak var isdimImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        cellBackGroundview.layer.cornerRadius =  8
        cellBackGroundview.layer.masksToBounds =  true
       
        
        cellBackGroundview.layer.borderWidth = 1
        isdimImageView.image = UIImage(systemName: "brightness-2")
    }
    func configure(imageName: String, text: String, isDim: Bool) {
        if let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate) {
           
        }

        deviceLabel.text = text

        if isDim {
            isdimImageView.isHidden = false
            isdimImageView.image = UIImage(systemName: "sun.max")
            isdimImageView.tintColor = .orange
        } else {
            isdimImageView.isHidden = true
        }
    }



}
