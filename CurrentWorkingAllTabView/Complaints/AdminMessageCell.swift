//
//  AdminMessageCell.swift
//  SkromanIsra
//
//  Created by Admin on 11/12/25.
//

import UIKit

class AdminMessageCell: UITableViewCell {

   // @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        bubbleView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.masksToBounds = true
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .white
        selectionStyle = .none 
//        profileImageView.layer.cornerRadius = 18
//        profileImageView.clipsToBounds = true
    }
}
