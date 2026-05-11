//
//  LockCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 11/04/26.
//

import UIKit

class LockCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var backgroundcell: UIView!
    @IBOutlet weak var lockImge: UIImageView!
    
    @IBOutlet weak var lockname: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundcell.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        backgroundcell.layer.cornerRadius = 12
        backgroundcell.clipsToBounds = true
    }

}
