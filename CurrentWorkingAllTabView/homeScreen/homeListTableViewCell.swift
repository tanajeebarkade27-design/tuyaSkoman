//
//  homeListTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 29/05/25.
//

import UIKit

class homeListTableViewCell: UITableViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    @IBOutlet weak var homeImageView: UIImageView!
    
    @IBOutlet weak var homeNameLabel: UILabel!
    @IBOutlet weak var roomCountLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cellbackgroundView.backgroundColor = .clear

        homeNameLabel.textColor = .white
        roomCountLabel.textColor = .lightGray
        
        homeImageView.layer.cornerRadius = 6
        homeImageView.clipsToBounds = true
    }

    func configure(with home: Home) {
        homeNameLabel.text = home.homeName ?? "Unnamed Home"

        // If you have room count:
//        if let roomCount = home.roomCount {
//            roomCountLabel.text = "\(roomCount) Rooms"
//        } else {
//            roomCountLabel.text = ""
//        }

        // Load image if exists
        if let urlString = home.homeUrl, let url = URL(string: urlString) {
            loadImage(from: url)
        } else {
            homeImageView.image = UIImage(named: "defaultHome")
        }
    }

    private func loadImage(from url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.homeImageView.image = img
                }
            }
        }
    }
}

