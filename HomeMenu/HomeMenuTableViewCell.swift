//
//  HomeMenuTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 01/08/25.
//

import UIKit

class HomeMenuTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    @IBOutlet weak var optionNameLabel: UILabel!

    @IBOutlet weak var isTrueImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear             // Cell background transparent
        contentView.backgroundColor = .clear // Content area transparent

        cellbackgroundView.backgroundColor = UIColor.clear
        cellbackgroundView.layer.cornerRadius = 10
        cellbackgroundView.clipsToBounds = true
        cellbackgroundView.isUserInteractionEnabled = true
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    
}
