//
//  ScheduleNumberCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 11/03/25.
//

import UIKit

class ScheduleNumberCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backgroundSchedule: UIView!
   
    @IBOutlet weak var isScheduleImage: UIImageView!
    
    @IBOutlet weak var scheduleNollabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let image = UIImage(named: "appointment") {
            let resizedImage = image.resized(to: CGSize(width: 20, height: 20))
            
            backgroundSchedule.cornerRadius =  10
            backgroundSchedule.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            backgroundSchedule.clipsToBounds =  true
        }
    }

}
