//
//  HomeAccessTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 15/11/25.
//

import UIKit

class HomeAccessTableViewCell: UITableViewCell {

    @IBOutlet weak var homeNamelabel: UILabel!
    @IBOutlet weak var isSelectedHome: UIButton!
    @IBOutlet weak var cellBackground: UIView!
    
    
    
    @IBOutlet weak var isExpandImage: UIImageView!
    
    var onSelectHome: (() -> Void)?   // ← callback

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        cellBackground.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        cellBackground.layer.cornerRadius = 15
        cellBackground.clipsToBounds = true

        // Button target
        isSelectedHome.addTarget(self, action: #selector(selectHomeTapped), for: .touchUpInside)
    }

    @objc func selectHomeTapped() {
        onSelectHome?()
    }
}
