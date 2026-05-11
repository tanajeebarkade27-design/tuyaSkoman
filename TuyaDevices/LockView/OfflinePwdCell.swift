//
//  OfflinePwdCell.swift
//  SkromanIsra
//
//  Created by Admin on 20/04/26.
//

import UIKit

class OfflinePwdCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var background: UIView!
    
    @IBOutlet weak var status: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        background.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        background.layer.cornerRadius = 12
        background.clipsToBounds = true 
    }
    
}
