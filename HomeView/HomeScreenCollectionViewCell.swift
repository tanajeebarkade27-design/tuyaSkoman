//
//  HomeScreenCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 22/02/25.
//

import UIKit

class HomeScreenCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var homeNameLabel: UILabel!
    @IBOutlet weak var HomeImage: UIImageView!
    @IBOutlet weak var cellbackgreound: UIView!
    
    @IBOutlet weak var defaultHomeImage: UIImageView!
    @IBOutlet weak var menuButton: UIButton!
    
    var parentVC: HomeScreenViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        menuButton.setTitle("", for: .normal)
        
        
        cellbackgreound.layer.cornerRadius = 8
        cellbackgreound.layer.masksToBounds = true
     
        contentView.layer.cornerRadius = 8
           contentView.layer.masksToBounds = false
           contentView.layer.shadowColor = UIColor.black.cgColor
           contentView.layer.shadowOpacity = 0.2  // Adjust for stronger or lighter shadow
           contentView.layer.shadowOffset = CGSize(width: 3, height: 3) // Soft shadow at bottom-right
           contentView.layer.shadowRadius = 6
       
        applyGradientBackground()
    }
   

    
    
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = cellbackgreound.bounds

        if traitCollection.userInterfaceStyle == .dark {
            // Dark Mode: #232323 (Common Dark) to #313131 (Darker Gray)
            mainScreen.colors = [
                UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 1).cgColor,
                UIColor(red: 49/255, green: 49/255, blue: 49/255, alpha: 1).cgColor
            ]
        } else {
           
            mainScreen.colors = [
                UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1).cgColor,
                UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1).cgColor
            ]
        }

        mainScreen.startPoint = CGPoint(x: 0, y: 0)  // Top-left corner
        mainScreen.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right corner

        // Remove existing gradient layers before adding a new one
        cellbackgreound.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        cellbackgreound.layer.insertSublayer(mainScreen, at: 0)
    }


    
    func configure(with home: Home) {
        homeNameLabel.text = home.homeName ?? "Unknown"
           
           if let urlString = home.homeUrl, let url = URL(string: urlString) {
               loadImage(from: url)
               defaultHomeImage.isHidden =  true
           } else {
               HomeImage.image = UIImage(named: "defaultHomeImage")  // Set a placeholder
           }
       }
       
       private func loadImage(from url: URL) {
           DispatchQueue.global().async {
               if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                   DispatchQueue.main.async {
                       self.HomeImage.image = image
                   }
               }
           }
       }
    
    @IBAction func menuButton(_ sender: Any) {
        
        parentVC?.showBottomSheet()
    }
    
   
    
}
