//
//  FamilyMemberListTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/11/25.
//

import UIKit

class FamilyMemberListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellbackground: UIView!
    
    @IBOutlet weak var imageBackground: UIView!
    
    @IBOutlet weak var memberEmailLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        imageBackground.cornerRadius =  20
        imageBackground.clipsToBounds =  true
        cellbackground.cornerRadius  =  10
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
