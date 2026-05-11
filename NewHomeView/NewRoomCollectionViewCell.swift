//
//  NewRoomCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 28/03/25.
//

import UIKit

class NewRoomCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellbackgroundView: UIView!
    @IBOutlet weak var roomImageView: UIImageView!
    @IBOutlet weak var roomNamelabel: UILabel!
    
    
    
    var parentVC: NewHomeViewController?
    var homeServerID: String?
       var roomID: String?
    var selecetdRoomId : String?
    var selectedHomeid : String?
    var selectedRoomName: String?  
    override func awakeFromNib() {
        super.awakeFromNib()
      
        cellbackgroundView.cornerRadius =  10
        cellbackgroundView.clipsToBounds = true
        
    }
    
}
