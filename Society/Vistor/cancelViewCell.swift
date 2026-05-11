//
//  cancelViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/26.
//

import UIKit

class cancelViewCell: UITableViewCell {
    
    
    @IBOutlet weak var cellbackground: UIView!
    
    @IBOutlet weak var profilebackground: UIView!
    
    @IBOutlet weak var userProfileImage: UIImageView!
    
    @IBOutlet weak var visitername: UILabel!
    
    @IBOutlet weak var visterContcat: UILabel!
    
    @IBOutlet weak var visterType: UILabel!
    
    @IBOutlet weak var cancel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
            contentView.backgroundColor = .clear
            selectionStyle = .none
        profilebackground.cornerRadius = 30
        profilebackground.clipsToBounds =  true
        profilebackground.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        
        cellbackground.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cellbackground.cornerRadius = 10
        cellbackground.clipsToBounds =  true
        cancel.borderColor =  .red
        cancel.borderWidth = 1
        cancel.cornerRadius =  10
        cancel.clipsToBounds =  true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
