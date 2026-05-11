//
//  ShortcutButtonsCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 03/05/25.
//

import UIKit

class ShortcutButtonsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var deviceview: UIView!
    @IBOutlet weak var buttonImageView: UIImageView!
    
    @IBOutlet weak var buttonNamelabel: UILabel!
    
    @IBOutlet weak var selectedImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        deviceview.layer.cornerRadius = 10
        deviceview.clipsToBounds = true
    }

}
