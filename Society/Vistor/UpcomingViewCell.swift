//
//  UpcomingViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/26.
//

import UIKit
protocol UpcomingViewCellDelegate: AnyObject {
    func didTapApprove(visitor: VisitorItem)
    func didTapReject(visitor: VisitorItem)
}

class UpcomingViewCell: UITableViewCell {
    
    
    @IBOutlet weak var cellBackground: UIView!
    @IBOutlet weak var profilebackground: UIView!
    
    @IBOutlet weak var profileimage: UIImageView!
    
    @IBOutlet weak var visiterContact: UILabel!
    
    @IBOutlet weak var visitername: UILabel!
    
    @IBOutlet weak var visiterType: UILabel!
    
    private let separatorLine = UIView()
    
    weak var delegate: UpcomingViewCellDelegate?
    var visitor: VisitorItem?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
            contentView.backgroundColor = .clear
            selectionStyle = .none
        profilebackground.cornerRadius = 30
        profilebackground.clipsToBounds =  true
        profilebackground.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        cellBackground.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
        cellBackground.cornerRadius = 10
        cellBackground.clipsToBounds =  true
        
        
        // Custom separator
        separatorLine.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        cellBackground.addSubview(separatorLine)

        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: cellBackground.leadingAnchor, constant: 15),
            separatorLine.trailingAnchor.constraint(equalTo: cellBackground.trailingAnchor, constant: -15),
            separatorLine.topAnchor.constraint(equalTo: visiterType.bottomAnchor, constant: 8),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

      
    }
    
    @IBAction func cancelBtn(_ sender: Any) {
        if let visitor = visitor {
            delegate?.didTapReject(visitor: visitor)
        }
    }

    @IBAction func approveBtn(_ sender: Any) {
        if let visitor = visitor {
            delegate?.didTapApprove(visitor: visitor)
        }
    }

}
