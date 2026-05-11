//
//  AlloctedHomeViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 22/11/25.
//

import UIKit

class AlloctedHomeViewCell: UITableViewCell {
    
    @IBOutlet weak var homeNameLabel: UILabel!
    
    @IBOutlet weak var cellBackground: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cellBackground.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        cellBackground.layer.cornerRadius = 15
        cellBackground.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
