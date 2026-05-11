//
//  EditDeviceButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 23/07/25.
//

import UIKit

class EditDeviceButtonCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellBcakgroundView: UIView!
    @IBOutlet weak var buttonImage: UIImageView!
    @IBOutlet weak var buttonNameLabel: UILabel!

    @IBOutlet weak var imageBackgroundView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.frame.height / 2
        imageBackgroundView.clipsToBounds = true
        imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        imageBackgroundView.layer.borderWidth = 0
        imageBackgroundView.layer.borderColor = UIColor.clear.cgColor
        buttonNameLabel.lineBreakMode = .byTruncatingTail
        cellBcakgroundView.layer.cornerRadius = 10
        cellBcakgroundView.clipsToBounds = true
        buttonImage.tintColor =  .white
        buttonNameLabel.textColor = .white
        buttonNameLabel.numberOfLines = 1
        buttonNameLabel.lineBreakMode = .byTruncatingTail
        buttonNameLabel.adjustsFontSizeToFitWidth = false
        buttonNameLabel.minimumScaleFactor = 0.85
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applySelectedStyle(false)
    }
    
    override var isSelected: Bool {
        didSet { applySelectedStyle(isSelected) }
    }
    
    func applySelectedStyle(_ selected: Bool) {
        if selected {
            cellBcakgroundView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.22)
            imageBackgroundView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.18)
            imageBackgroundView.layer.borderWidth = 2
            imageBackgroundView.layer.borderColor = UIColor.systemGreen.cgColor
            buttonImage.tintColor = .systemGreen
        } else {
            cellBcakgroundView.backgroundColor = .clear
            imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            imageBackgroundView.layer.borderWidth = 0
            imageBackgroundView.layer.borderColor = UIColor.clear.cgColor
            buttonImage.tintColor = .white
        }
    }
    
}
