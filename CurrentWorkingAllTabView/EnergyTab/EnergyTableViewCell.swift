//
//  EnergyTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 04/08/25.
//

import UIKit

class EnergyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var energyValueLabel: UILabel!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var imageBackgroundView: UIView!
    
    
    @IBOutlet weak var roomImageView: UIImageView!
    override func layoutSubviews() {
        super.layoutSubviews()

        // Corner radius
        cellbackgroundView.layer.cornerRadius = 15
        cellbackgroundView.clipsToBounds = true
       cellbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
//
       imageBackgroundView.layer.cornerRadius = imageBackgroundView.frame.height / 2
        imageBackgroundView.clipsToBounds = true
        imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
    }
    
    func configure(with room: Room, energy: Double) {
        roomNameLabel.text = room.name
        roomImageView.image = UIImage(named: room.imageName)
        energyValueLabel.text = "\(energy) kWh"

        imageBackgroundView.clipsToBounds = true
        imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
    }

    
}
