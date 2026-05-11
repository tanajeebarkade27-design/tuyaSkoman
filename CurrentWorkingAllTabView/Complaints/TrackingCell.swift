//
//  TrackingCell.swift
//  SkromanIsra
//
//  Created by Admin on 21/03/26.
//

import UIKit

class TrackingCell: UITableViewCell {
    
    @IBOutlet weak var cellbackground: UIView!
    

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var customImageView: UIImageView!
    
    @IBOutlet weak var stageLabel: UILabel!
    
    @IBOutlet weak var createdAt: UILabel!
    
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var statusView: UIView!
    
    @IBOutlet weak var statusView1: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        cellbackground.cornerRadius = 10
        cellbackground.clipsToBounds =  true
//        cellbackground.borderColor =  .gray
//        cellbackground.borderWidth =  1
        customImageView.contentMode = .scaleAspectFill
        customImageView.clipsToBounds = true
        customImageView.layer.cornerRadius = 8
      
        statusView1.layer.cornerRadius = statusView1.frame.height / 2
        statusView1.clipsToBounds =  true
    }
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
