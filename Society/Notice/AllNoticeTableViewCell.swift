//
//  AllNoticeTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 07/03/26.
//

import UIKit

class AllNoticeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellabckgroundView: UIView!
    @IBOutlet weak var audianceType: UILabel!
    
    @IBOutlet weak var noticeDate: UILabel!
    
    @IBOutlet weak var noticeTitle: UILabel!
    
    @IBOutlet weak var noticeBody: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
            contentView.backgroundColor = .clear
            selectionStyle = .none
        cellabckgroundView.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
        cellabckgroundView.cornerRadius =  12
        cellabckgroundView.clipsToBounds =  true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
    }
    
}
