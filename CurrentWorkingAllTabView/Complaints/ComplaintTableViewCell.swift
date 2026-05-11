//
//  ComplaintTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 08/12/25.
//

import UIKit

class ComplaintTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var ComplaintTypeLabel: UILabel!
    
    @IBOutlet weak var complaintStatusLabel: UILabel!
    
    @IBOutlet weak var complaintdatelabel: UILabel!
    
    @IBOutlet weak var complaintDescription: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var cellView: UIView!
    
    @IBOutlet weak var updateTimeBtn: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // make entire cell transparent
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        selectionStyle = .none
        
        cellbackgroundView.backgroundColor = .clear
        
        cellbackgroundView.clipsToBounds = true
        
        cellView.backgroundColor = .clear
        
        complaintStatusLabel.clipsToBounds = true
        complaintStatusLabel.textAlignment = .center
        complaintStatusLabel.numberOfLines = 1
        complaintStatusLabel.setContentHuggingPriority(.required, for: .horizontal)
        complaintStatusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
    }

    override func layoutSubviews() {
            super.layoutSubviews()

            
            contentView.frame = contentView.frame.inset(
                by: UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
            )

           
            addGradientappBorder(to: cellView, cornerRadius: 15, lineWidth: 1)
            complaintStatusLabel.layer.cornerRadius = complaintStatusLabel.bounds.height / 2
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

            gradientLayer.frame = view.bounds   // 🔥 Correct final frame applied here

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
