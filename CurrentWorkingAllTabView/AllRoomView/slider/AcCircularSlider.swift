import UIKit

class CircularSliderView: UIView {
    
    var minValue: Int = 16
    var maxValue: Int = 32
    var onPowerTapped: (() -> Void)?
    var onACValueChanged: ((_ temp: Int, _ fan: Int, _ swing: Int, _ which: Int, _ state: Int) -> Void)?
    private var currentSwingValue: Int = 1
    private var currentWhich: Int = 4   // swing
    var currentValue: Int = 24 {
        didSet {
            temperatureLabel.text = "\(currentValue)°C"
            setNeedsDisplay()
        }
    }
    
    private let lineWidth: CGFloat = 5
    private let radiusInset: CGFloat = 20
    private var angle: CGFloat = 0
    private var isOn: Bool = false

    private var powerButton: UIButton?
    private var leftSwingButton: UIButton?
    private var upDownSwingButton: UIButton?
    private var glowLayer: CALayer?

    private lazy var temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = "\(currentValue)°"
        label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(temperatureLabel)
        setupPowerButton()
        setupSwingButtons()
        //showComingSoonOverlay() // 👈 Add overlay
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        temperatureLabel.frame = CGRect(x: bounds.midX - 40,
                                        y: bounds.midY - 60,
                                        width: 80,
                                        height: 50)

        powerButton?.frame = CGRect(x: bounds.midX - 15,
                                    y: temperatureLabel.frame.maxY + 5,
                                    width: 30,
                                    height: 30)

        let radius = getRadius()
        let yOffset: CGFloat = bounds.midY + radius + 20
       

        let buttonWidth: CGFloat = 70
        let buttonHeight: CGFloat = 40
        let spacing: CGFloat = 20
        
        leftSwingButton?.frame = CGRect(
            x: bounds.midX - buttonWidth - spacing / 2,
            y: yOffset,
            width: buttonWidth,
            height: buttonHeight
        )

        upDownSwingButton?.frame = CGRect(
            x: bounds.midX + spacing / 2,
            y: yOffset,
            width: buttonWidth,
            height: buttonHeight
        )
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let radius = getRadius()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let startAngle = CGFloat.pi * 0.5
        let endAngle = startAngle + angle

        context.setStrokeColor(UIColor.systemGreen.cgColor)
        context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        context.strokePath()

        // Fill inner circle (transparent)
        let innerRadius = radius - lineWidth - 8
        context.setFillColor(UIColor.white.withAlphaComponent(0.05).cgColor)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
        context.fillPath()

  
        context.setLineWidth(lineWidth)
        context.setStrokeColor(UIColor.gray.withAlphaComponent(0.2).cgColor)
        context.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()


        context.setStrokeColor(UIColor.systemGreen.cgColor)
        context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        context.strokePath()

     
        let bubbleX = center.x + radius * cos(endAngle)
        let bubbleY = center.y + radius * sin(endAngle)
        let bubbleCenter = CGPoint(x: bubbleX, y: bubbleY)
        let bubbleRadius: CGFloat = 10
        let bubblePath = UIBezierPath(arcCenter: bubbleCenter, radius: bubbleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)

        context.setFillColor(UIColor.systemGreen.cgColor)
        context.addPath(bubblePath.cgPath)
        context.fillPath()

        // Glow
        let glowLayer = CAShapeLayer()
        glowLayer.path = bubblePath.cgPath
        glowLayer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25).cgColor
        glowLayer.shadowColor = UIColor.systemGreen.cgColor
        glowLayer.shadowRadius = 6
        glowLayer.shadowOpacity = 0.8
        glowLayer.shadowOffset = .zero

        layer.sublayers?.removeAll(where: { $0.name == "endBubbleGlow" })
        glowLayer.name = "endBubbleGlow"
        layer.insertSublayer(glowLayer, above: layer)
    }

    private func updateAngle(with location: CGPoint) {

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = location.x - center.x
        let dy = location.y - center.y
        var newAngle = atan2(dy, dx) - CGFloat.pi / 2

        if newAngle < 0 {
            newAngle += CGFloat.pi * 2
        }

        angle = newAngle

        let progress = angle / (CGFloat.pi * 2)
        let temp = Int(round(progress * CGFloat(maxValue - minValue))) + minValue

        let finalTemp = min(max(temp, minValue), maxValue)

        // ✅ Only trigger when value actually changes
        if finalTemp != currentValue {
            currentValue = finalTemp

            currentWhich = 2
            emitACValues()    
        }

        updateGlowEffect()
        updateTemperatureGlow()
    }
    private func getRadius() -> CGFloat {
        let maxRadius: CGFloat = 140
        let dynamicRadius = min(bounds.width, bounds.height) * 0.30
        return min(dynamicRadius, maxRadius)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // ✅ Ignore if touch is on button
        if let view = hitTest(location, with: event),
           view != self {
            return
        }

        updateAngle(with: location)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // ✅ If tap is on button → ignore slider
        if let view = hitTest(location, with: event),
           view != self {
            return
        }

        updateAngle(with: location)
    }

    @objc private func togglePower() {
        isOn.toggle()
        updatePowerButtonAppearance()

        print("🔥 AC Power tapped:", isOn)

        currentWhich = 1

        emitACValues()    
    }
    
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        glowLayer?.removeFromSuperlayer()
        temperatureLabel.layer.shadowOpacity = 0
    }

    private func setupPowerButton() {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "power"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .orange
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(togglePower), for: .touchUpInside)

        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center

        addSubview(button)
        powerButton = button
        updatePowerButtonAppearance()
    }

  

    private func updatePowerButtonAppearance() {
        guard let button = powerButton else { return }

        button.tintColor = isOn ?  .green :  .gray
        button.backgroundColor = .white
        button.layer.borderWidth = 2
        button.layer.borderColor = isOn ? UIColor.green.cgColor : UIColor.white.cgColor
    }

    private func setupSwingButtons() {
        leftSwingButton = createSwingButton(named: "arrow.left.and.right", title: "")
        upDownSwingButton = createSwingButton(named: "arrow.up.and.down", title: "")

        if let left = leftSwingButton, let right = upDownSwingButton {
            addSubview(left)
            addSubview(right)
            leftSwingButton?.layer.cornerRadius = 15
            upDownSwingButton?.layer.cornerRadius = 15
        }
        
        leftSwingButton?.addTarget(self, action: #selector(leftRightSwingTapped), for: .touchUpInside)
        upDownSwingButton?.addTarget(self, action: #selector(upDownSwingTapped), for: .touchUpInside)
    }
    private func setSelected(_ button: UIButton, selected: Bool) {
        button.layer.borderWidth = selected ? 2 : 0
        button.layer.borderColor = selected ? UIColor.systemGreen.cgColor : UIColor.clear.cgColor
    }
    
    @objc private func leftRightSwingTapped() {

        let isOn = currentSwingValue != 2
        currentSwingValue = isOn ? 2 : 1
        currentWhich = 4

        setSelected(leftSwingButton!, selected: isOn)
        setSelected(upDownSwingButton!, selected: false)

        emitACValues()
    }
    private func emitACValues() {

        print("📤 FULL AC PAYLOAD")
        print("Temp:", currentValue)
        print("Swing:", currentSwingValue)
        print("State:", isOn ? 1 : 0)

        onACValueChanged?(
            currentValue,
            1, // fan (or your variable)
            currentSwingValue,
            currentWhich,
            isOn ? 1 : 0
        )
    }
    @objc private func upDownSwingTapped() {

        let isOn = currentSwingValue != 4
        currentSwingValue = isOn ? 4 : 3
        currentWhich = 4

        setSelected(upDownSwingButton!, selected: isOn)
        setSelected(leftSwingButton!, selected: false)

        emitACValues()
    }

    private func createSwingButton(named imageName: String, title: String) -> UIButton {
        let button = UIButton(type: .system)

        // ✅ FIX: Use system image
        let img = UIImage(systemName: imageName)

        button.setImage(img, for: .normal)
        button.setTitle(" " + title, for: .normal)

        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        button.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true

        button.imageView?.contentMode = .scaleAspectFit

        return button
    }
    private func updateGlowEffect() {
        glowLayer?.removeFromSuperlayer()

        let radius = getRadius()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let startAngle = CGFloat.pi * 0.5
        let endAngle = startAngle + angle

        let glowPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

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

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.text = "Coming Soon"
      
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = .center
        overlay.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

//        let animation = CABasicAnimation(keyPath: "opacity")
//        animation.fromValue = 1.0
//        animation.toValue = 0.2
//        animation.duration = 0.7
//        animation.autoreverses = true
//        animation.repeatCount = .infinity
//        label.layer.add(animation, forKey: "blinking")

//        alpha = 0.5
    }
}
