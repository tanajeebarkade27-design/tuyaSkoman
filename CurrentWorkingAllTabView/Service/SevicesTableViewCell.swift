//
//  SevicesTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 13/11/25.
//

import UIKit

class SevicesTableViewCell: UITableViewCell {
    @IBOutlet weak var imageBackground: UIView!
    
    
    @IBOutlet weak var seviceImage: UIImageView!
    
    @IBOutlet weak var serviceNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageBackground.cornerRadius = 20
        imageBackground.clipsToBounds =  true
        imageBackground.cornerRadius =  10
        imageBackground.clipsToBounds =  true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
