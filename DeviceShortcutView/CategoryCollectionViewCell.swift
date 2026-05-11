//
//  CategoryCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 28/03/25.
//
import UIKit
class CategoryCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var categoryLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellView.layer.cornerRadius = 10
        cellView.clipsToBounds = true
        cellView.layer.borderWidth = 0.5
        cellView.layer.borderColor = UIColor.systemGray.cgColor
        updateSelectionState()
    }

    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }

    private func updateSelectionState() {
        if isSelected {
            cellView.backgroundColor = UIColor.white.withAlphaComponent(0.3) // transparent white
        } else {
            cellView.backgroundColor = UIColor.clear // or default background
        }
    }
}
