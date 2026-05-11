//
//  TempPassCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/04/26.
//

import UIKit

class TempPassCell: UITableViewCell {

    @IBOutlet weak var backgroundcell: UIView!
    @IBOutlet weak var passwordName: UILabel!
    
    @IBOutlet weak var passwordDate: UILabel!
    
    @IBOutlet weak var status: UILabel!
    
    @IBOutlet weak var password: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        backgroundcell.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        backgroundcell.layer.cornerRadius = 12
        backgroundcell.clipsToBounds = true // Configure the view for the selected state
    }
    
}
