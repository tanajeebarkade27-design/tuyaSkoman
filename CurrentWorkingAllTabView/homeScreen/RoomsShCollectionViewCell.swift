//
//  RoomsShCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 23/06/25.
//

import UIKit

class RoomsShCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    
    
    @IBOutlet weak var imageView: UIView!
    
    @IBOutlet weak var roomImage: UIImageView!
    
    
    @IBOutlet weak var roomName: UILabel!
    
    
    @IBOutlet weak var enegryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        roomName.lineBreakMode = .byTruncatingTail
        roomName.numberOfLines = 1
        roomName.adjustsFontSizeToFitWidth = false
        roomName.allowsDefaultTighteningForTruncation = true
       
        roomName.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func configure(with room: Room) {
        let name = room.name ?? ""
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let maxChars = 8
        if trimmed.count > maxChars {
            roomName.text = String(trimmed.prefix(maxChars)) + "..."
        } else {
            roomName.text = trimmed
        }
        roomName.lineBreakMode = .byTruncatingTail
        roomName.numberOfLines = 1
        roomImage.image = UIImage(named: room.imageName)
        imageView.cornerRadius = 20
        imageView.clipsToBounds =  true
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        
    }

}

