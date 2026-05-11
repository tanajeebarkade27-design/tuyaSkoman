//
//  ACCircularSliderView.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/26.
//


import Foundation
import UIKit

class ACCircularSliderView: UIView {
    var onValueChanged: ((Int) -> Void)?
    var onValueChangeEnded: ((Int) -> Void)?
    private(set) var temperatureValue: Int = 24
       private(set) var fanValue: Int = 1
    var minValue: Int = 16
    var maxValue: Int = 32
    
    
    var mode: SliderMode = .temperature {
           didSet {
               configureForMode()
           }
       }

    var currentValue: Int = 24 {
        didSet {
            switch mode {
            case .temperature:
                temperatureValue = currentValue
                temperatureLabel.text = "\(temperatureValue)°C"

            case .fan:
                fanValue = currentValue
                temperatureLabel.text = "Fan \(fanValue)"
            }

            updateAngleFromCurrentValue()
            setNeedsDisplay()
            onValueChanged?(currentValue)
        }
    }



    
    
    private let lineWidth: CGFloat = 5
    private let radiusInset: CGFloat = 30
    private var angle: CGFloat = 0
    private var isOn: Bool = false

    private var powerButton: UIButton?
    private var leftSwingButton: UIButton?
    private var rightSwingButton: UIButton?
    private var glowLayer: CALayer?
    private let arcCoverage: CGFloat = 0.8
    private let arcStartOffset: CGFloat = 0.1


    private lazy var temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = "\(currentValue)°"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(temperatureLabel)
     
        setupSwingButtons()
        //showComingSoonOverlay()
    }
    
    private func configureForMode() {
        switch mode {

        case .temperature:
            minValue = 16
            maxValue = 32
            currentValue = temperatureValue

        case .fan:
            minValue = 0
            maxValue = 3
            currentValue = fanValue
        }
    }



    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var arcStartAngle: CGFloat {
        (CGFloat.pi / 2) + (2 * .pi * arcStartOffset)
    }

    private var arcEndAngle: CGFloat {
        arcStartAngle + (2 * .pi * arcCoverage)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        temperatureLabel.frame = CGRect(x: bounds.midX - 50,
                                        y: bounds.midY - 80,
                                        width: 100,
                                        height: 60)

        powerButton?.frame = CGRect(x: bounds.midX - 17.5,
                                    y: temperatureLabel.frame.maxY + 5,
                                    width: 35,
                                    height: 35)

        let radius = min(bounds.width, bounds.height) / 2 - radiusInset
        let yOffset: CGFloat = bounds.midY + radius + 35
        let buttonSize: CGFloat = 100
        let spacing: CGFloat = 60

        leftSwingButton?.frame = CGRect(x: bounds.midX - spacing - buttonSize / 2,
                                        y: yOffset,
                                        width: buttonSize,
                                        height: 45)

        rightSwingButton?.frame = CGRect(x: bounds.midX + spacing - buttonSize / 2,
                                         y: yOffset,
                                         width: buttonSize,
                                         height: 45)
    }
    
    private func updateAngleFromCurrentValue() {
        let progress = CGFloat(currentValue - minValue) / CGFloat(maxValue - minValue)
        angle = progress * (arcEndAngle - arcStartAngle)
    }

    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let radius = min(bounds.width, bounds.height) / 2 - radiusInset
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let startAngle = arcStartAngle
        let endAngle = arcStartAngle + angle

        context.setLineWidth(lineWidth)

      
        context.beginPath()
        context.setStrokeColor(UIColor.gray.cgColor)

        context.addArc(
            center: center,
            radius: radius,
            startAngle: arcStartAngle,
            endAngle: arcEndAngle,
            clockwise: false
        )
        context.strokePath()


        context.beginPath()
        context.setStrokeColor(UIColor.systemGreen.cgColor)
        context.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        context.strokePath()

        let bubbleCenter = CGPoint(
            x: center.x + radius * cos(endAngle),
            y: center.y + radius * sin(endAngle)
        )

        context.beginPath()
        context.setFillColor(UIColor.systemGreen.cgColor)
        context.addArc(
            center: bubbleCenter,
            radius: 10,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: false
        )
        context.fillPath()
    }

    private func updateAngle(with location: CGPoint) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = location.x - center.x
        let dy = location.y - center.y

        var touchAngle = atan2(dy, dx)

        // Normalize
        if touchAngle < arcStartAngle {
            touchAngle += 2 * .pi
        }

        let clampedAngle = min(
            max(touchAngle, arcStartAngle),
            arcEndAngle
        )

        angle = clampedAngle - arcStartAngle

        let progress = angle / (arcEndAngle - arcStartAngle)

        let tempRange = maxValue - minValue
        let temp = Int(round(progress * CGFloat(tempRange))) + minValue
        currentValue = min(max(temp, minValue), maxValue)

        updateGlowEffect()
        updateTemperatureGlow()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            updateAngle(with: touch.location(in: self))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        glowLayer?.removeFromSuperlayer()
        temperatureLabel.layer.shadowOpacity = 0
        onValueChangeEnded?(currentValue)
        
    }

  

    
    
    @objc private func togglePower() {
        isOn.toggle()
        updatePowerButtonAppearance()
    }

    private func updatePowerButtonAppearance() {
        guard let button = powerButton else { return }

        button.tintColor = .orange
        button.backgroundColor = .white
        button.layer.borderWidth = 2
        button.layer.borderColor = isOn ? UIColor.systemBlue.cgColor : UIColor.white.cgColor
    }

    private func setupSwingButtons() {
        leftSwingButton = createSwingButton(named: "leftswing", title: "SwingOut")
        rightSwingButton = createSwingButton(named: "rightSwing", title: "SwingIn")

        if let left = leftSwingButton, let right = rightSwingButton {
            addSubview(left)
            addSubview(right)

            let buttonWidth: CGFloat = 130
            let buttonHeight: CGFloat = 40
            let spacing: CGFloat = 20
            let yPosition = bounds.midY + bounds.height / 4

            leftSwingButton?.frame = CGRect(x: bounds.midX - buttonWidth - spacing / 2,
                                            y: yPosition,
                                            width: buttonWidth,
                                            height: buttonHeight)

            rightSwingButton?.frame = CGRect(x: bounds.midX + spacing / 2,
                                             y: yPosition,
                                             width: buttonWidth,
                                             height: buttonHeight)

            leftSwingButton?.layer.cornerRadius = 15
            rightSwingButton?.layer.cornerRadius = 15
        }
    }

    private func createSwingButton(named imageName: String, title: String) -> UIButton {
        let button = UIButton(type: .system)
        let img = UIImage(named: imageName)?.resize(to: CGSize(width: 20, height: 20))
        button.setImage(img, for: .normal)
        button.setTitle(" " + title, for: .normal)

        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        button.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true

        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)

        return button
    }

    private func updateGlowEffect() {
        glowLayer?.removeFromSuperlayer()

        let radius = min(bounds.width, bounds.height) / 2 - radiusInset
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let startAngle = arcStartAngle
        let endAngle = arcStartAngle + angle


        let glowPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = glowPath.cgPath
        shapeLayer.strokeColor = UIColor.systemGreen.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.shadowColor = UIColor.systemGreen.cgColor
        shapeLayer.shadowRadius = 10
        shapeLayer.shadowOpacity = 0.8
        shapeLayer.shadowOffset = .zero

        layer.addSublayer(shapeLayer)
        glowLayer = shapeLayer
    }

    private func updateTemperatureGlow() {
        temperatureLabel.layer.shadowColor = UIColor.systemGreen.cgColor
        temperatureLabel.layer.shadowRadius = 10
        temperatureLabel.layer.shadowOpacity = 0.9
        temperatureLabel.layer.shadowOffset = .zero
    }

    // MARK: - Coming Soon Overlay

    func showComingSoonOverlay() {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.isUserInteractionEnabled = true // Block all touches
        overlay.tag = 999
        addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

      
    }
    
    
    
}
extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
enum SliderMode {
    case temperature
    case fan
}
