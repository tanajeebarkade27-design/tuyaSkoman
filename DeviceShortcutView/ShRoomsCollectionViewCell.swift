//
//  ShRoomsCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 10/04/25.
//

import UIKit

class ShRoomsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var backgoundView: UIView!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var underlineView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
//        backgoundView.cornerRadius = 10
//        backgoundView.clipsToBounds =  true
//        backgoundView.borderWidth =  0.5
//        backgoundView.borderColor = .systemGray
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }

    private func updateSelectionState() {
        if isSelected {
            backgoundView.backgroundColor = UIColor.white.withAlphaComponent(0.3) // transparent white
        } else {
            backgoundView.backgroundColor = UIColor.clear // or default background
        }
    }

}
