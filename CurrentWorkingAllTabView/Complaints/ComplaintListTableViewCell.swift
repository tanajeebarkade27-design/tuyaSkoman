//
//  ComplaintListTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 27/11/25.
//

import UIKit

class ComplaintListTableViewCell: UITableViewCell {
    @IBOutlet weak var cellView: UIView!
    
    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var complaintTypeLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var raisedDateLabel: UILabel!
    
    @IBOutlet weak var statuslabel: UILabel!
    
    
    @IBOutlet weak var tiameLabel: UILabel!
    
    
    @IBOutlet weak var updateTimeButton: UIButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        
        contentView.backgroundColor = .clear
        selectionStyle = .none
        cellbackgroundView.backgroundColor = .clear
        
        cellbackgroundView.clipsToBounds = true
        
        cellView.backgroundColor = .clear
        
        statuslabel.clipsToBounds = true
        statuslabel.textAlignment = .center
        statuslabel.numberOfLines = 1
        statuslabel.setContentHuggingPriority(.required, for: .horizontal)
        statuslabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    
    override func layoutSubviews() {
            super.layoutSubviews()

            
            contentView.frame = contentView.frame.inset(
                by: UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
            )

           
            addGradientappBorder(to: cellView, cornerRadius: 15, lineWidth: 1)
            statuslabel.layer.cornerRadius = statuslabel.bounds.height / 2
        }
    
    func addGradientappBorder(to view: UIView, cornerRadius: CGFloat, lineWidth: CGFloat) {

            // Remove old gradient layer only (not all layers)
            view.layer.sublayers?.removeAll(where: { $0.name == "GradientBorder" })

            let gradientLayer = CAGradientLayer()
            gradientLayer.name = "GradientBorder"

            gradientLayer.colors = [
                UIColor.green.withAlphaComponent(0.5).cgColor,
                UIColor.blue.withAlphaComponent(0.5).cgColor
            ]

            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)

            gradientLayer.frame = view.bounds

            let shapeLayer = CAShapeLayer()
            let insetRect = view.bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)

            shapeLayer.path = UIBezierPath(
                roundedRect: insetRect,
                cornerRadius: cornerRadius
            ).cgPath
            shapeLayer.lineWidth = lineWidth
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = UIColor.black.cgColor

            gradientLayer.mask = shapeLayer
            view.layer.addSublayer(gradientLayer)
        }
    
    
}
