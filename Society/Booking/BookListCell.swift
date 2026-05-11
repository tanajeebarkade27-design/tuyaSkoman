//
//  BookListCell.swift
//  SkromanIsra
//
//  Created by Admin on 23/02/26.
//

import UIKit

class BookListCell: UITableViewCell {
    
    @IBOutlet weak var cellabckgroundView: UIView!
    
    @IBOutlet weak var aminityName: UILabel!
    
    @IBOutlet weak var aminityCatgory: UILabel!
    
    @IBOutlet weak var section: UILabel!
    
    @IBOutlet weak var dateTime: UILabel!
    
    @IBOutlet weak var slot: UILabel!
    
    
    @IBOutlet weak var totalPrice: UILabel!
    
    
    @IBOutlet weak var status: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
            contentView.backgroundColor = .clear
            selectionStyle = .none
        
        cellabckgroundView.cornerRadius =  10
        cellabckgroundView.clipsToBounds = true
        cellabckgroundView.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
