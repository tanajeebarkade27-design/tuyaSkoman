//
//  visiterTypeCell.swift
//  SkromanIsra
//
//  Created by Admin on 13/02/26.
//

import UIKit

class visiterTypeCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
     
        containerView.layer.cornerRadius = 10
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        titleLabel.textColor = isSelected ? .systemGreen : .white

    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 1.5 : 0
            layer.borderColor = isSelected ? UIColor.systemGreen.cgColor : UIColor.clear.cgColor
            layer.cornerRadius = 8
        }
    }

}
