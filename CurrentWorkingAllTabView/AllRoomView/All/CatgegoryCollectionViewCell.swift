//
//  CatgegoryCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 19/06/25.
//
import UIKit

class CatgegoryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var categoryNameLabel: UILabel!
    @IBOutlet weak var indicatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        indicatorView.layer.cornerRadius = 2
        indicatorView.isHidden = true
    }

    func configure(with title: String, isSelected: Bool) {
        categoryNameLabel.text = title
        updateAppearance(isSelected: isSelected)
    }

    override var isSelected: Bool {
        didSet {
            updateAppearance(isSelected: isSelected)
        }
    }

    private func updateAppearance(isSelected: Bool) {
        indicatorView.isHidden = !isSelected
        categoryNameLabel.textColor = isSelected ? .white : .lightGray
        categoryNameLabel.font = isSelected
            ? UIFont.systemFont(ofSize: 14, weight: .semibold)
            : UIFont.systemFont(ofSize: 14, weight: .regular)
    }
}
