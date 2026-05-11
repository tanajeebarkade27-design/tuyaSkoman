//
//  StatusViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 05/02/26.
//

import UIKit

class StatusViewCell: UITableViewCell {
    
    @IBOutlet weak var backgroundCell: UIView!
    
    @IBOutlet weak var statuslabel: UILabel!
    
    
    @IBOutlet weak var submitDate: UILabel!
    
    
    @IBOutlet weak var winglabel: UILabel!
    
    @IBOutlet weak var flatNumber: UILabel!
    
    @IBOutlet weak var mobileNumber: UILabel!
    
    @IBOutlet weak var cellBackground: UIView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellBackground.backgroundColor = .clear
        cellBackground.clipsToBounds =  true
        
        cellBackground.cornerRadius =  12
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
