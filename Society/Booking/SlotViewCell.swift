//
//  SlotViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 18/02/26.
//

import UIKit
class SlotViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackground: UIView!
    @IBOutlet weak var slotTime: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        cellbackground.layer.cornerRadius = 8
        cellbackground.layer.borderWidth = 1
    }

    func configure(slot: Slot, isSelected: Bool) {

        slotTime.text = "\(slot.from.to12HourFormat()) - \(slot.to.to12HourFormat())"

        if !slot.isAvailable {

            cellbackground.backgroundColor = UIColor.systemGray.withAlphaComponent(0.5)
            cellbackground.layer.borderColor = UIColor.clear.cgColor
            slotTime.textColor = .lightGray
            isUserInteractionEnabled = false
            return
        }

         
        isUserInteractionEnabled = true

        if isSelected {

            // ✅ SELECTED SLOT
            cellbackground.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            cellbackground.layer.borderColor = UIColor.systemGreen.cgColor
            slotTime.textColor = .systemGreen

        } else {

           
            cellbackground.backgroundColor = .clear
            cellbackground.layer.borderColor = UIColor.white.cgColor
            slotTime.textColor = .white
        }
    }

}

