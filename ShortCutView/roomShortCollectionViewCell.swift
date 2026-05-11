//
//  roomShortCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 26/03/25.
//

import UIKit

class roomShortCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    @IBOutlet weak var roomImageView: UIImageView!
    @IBOutlet weak var roomNamelabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        cellbackgroundView.cornerRadius = 10
        cellbackgroundView.clipsToBounds =  true
        
    }

   
    
    
}
