//
//  AllRoomsCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 10/06/25.
//

import UIKit

class AllRoomsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var roomImageView: UIImageView!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellbackgroundView.cornerRadius =  18
        
        cellbackgroundView.clipsToBounds = true
        
    }
    override var isSelected: Bool {
            didSet {
                if isSelected {
                    cellbackgroundView.backgroundColor = .white
                    roomNameLabel.textColor = .black
                    roomImageView.tintColor = .black
                
                } else {
                    cellbackgroundView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
                    roomNameLabel.textColor = .white
                    roomImageView.tintColor = .white
                    
                }
            }
        }
    func configure(with room: Room) {
        roomNameLabel.text = room.name

        // Load image and set it to template rendering mode
        if let image = UIImage(named: room.imageName)?.withRenderingMode(.alwaysTemplate) {
            roomImageView.image = image
            roomImageView.tintColor = isSelected ? .black : .white
        } else {
            print("❌ Failed to load image for room: \(room.name)")
            roomImageView.image = nil
        }
    }

       

}
