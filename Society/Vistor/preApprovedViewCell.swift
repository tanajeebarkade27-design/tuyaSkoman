//
//  preApprovedViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/26.
//
protocol PreApprovedCellDelegate: AnyObject {
    func didTapEdit(cell: preApprovedViewCell)
}
import UIKit

class preApprovedViewCell: UITableViewCell {
    
    
    @IBOutlet weak var cellbackgroundView: UIView!
    @IBOutlet weak var imagebackground: UIView!
    
    @IBOutlet weak var userProfileIamge: UIImageView!
    
    @IBOutlet weak var visiterNamelabel: UILabel!
    
    @IBOutlet weak var visitercontact: UILabel!
    
    @IBOutlet weak var visiterType: UILabel!
    private let separatorLine = UIView()
    
    
    @IBOutlet weak var editBtn: UIButton!
    
    weak var delegate: PreApprovedCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
            contentView.backgroundColor = .clear
            selectionStyle = .none
        imagebackground.cornerRadius = 30
        imagebackground.clipsToBounds =  true
        imagebackground.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        
        cellbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cellbackgroundView.cornerRadius = 10
        cellbackgroundView.clipsToBounds =  true
        
        // Custom separator
        separatorLine.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        cellbackgroundView.addSubview(separatorLine)

        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: cellbackgroundView.leadingAnchor, constant: 15),
            separatorLine.trailingAnchor.constraint(equalTo: cellbackgroundView.trailingAnchor, constant: -15),
            separatorLine.topAnchor.constraint(equalTo: visiterType.bottomAnchor, constant: 8),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
    }
    
    @IBAction func editTapped(_ sender: UIButton) {
        delegate?.didTapEdit(cell: self)
    }
    
    @IBAction func cancelPreApproved(_ sender: Any) {
        
        
    }
    
    
}
