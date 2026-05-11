import UIKit

class EnergyLineGraphView: UIView {

    var months: [String] = [] {
        didSet { redrawGraph() }
    }

    var values: [CGFloat] = [] {
        didSet { redrawGraph() }
    }

    private let lineLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        lineLayer.fillColor = nil
        lineLayer.strokeColor = UIColor.green.cgColor
        lineLayer.lineWidth = 2
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
        layer.addSublayer(lineLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        redrawGraph()
    }

    private func redrawGraph() {
        guard values.count >= 2, values.count == months.count else { return }

        // Remove previous labels and layers
        subviews.forEach { $0.removeFromSuperview() }

        let margin: CGFloat = 40
        let topMargin: CGFloat = 20
        let bottomMargin: CGFloat = 40
        let graphHeight = bounds.height - topMargin - bottomMargin
        let graphWidth = bounds.width - margin - 20

        // Calculate min/max range
        let maxValue = values.max() ?? 1
        let minValue = values.min() ?? 0
        let range = max(maxValue - minValue, 1)

        let stepCount = 5
        let stepValue = range / CGFloat(stepCount)

        // Y-axis grid lines and labels
        for i in 0...stepCount {
            let yValue = minValue + CGFloat(i) * stepValue
            let y = bounds.height - bottomMargin - ((yValue - minValue) / range * graphHeight)

            let line = UIView(frame: CGRect(x: margin, y: y, width: bounds.width - margin - 10, height: 0.5))
            line.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            addSubview(line)

            let label = UILabel(frame: CGRect(x: 0, y: y - 10, width: margin - 5, height: 20))
            label.font = UIFont.systemFont(ofSize: 8)
            label.textColor = .white
            label.textAlignment = .right
            label.text = "\(Int(yValue))W"
            addSubview(label)
        }

        // X-axis point spacing
        let spacing = graphWidth / CGFloat(values.count - 1)
        var points: [CGPoint] = []

        for i in 0..<values.count {
            let x = margin + CGFloat(i) * spacing
            let y = bounds.height - bottomMargin - ((values[i] - minValue) / range * graphHeight)
            points.append(CGPoint(x: x, y: y))
        }

        // Create curve path
        let path = UIBezierPath()
        path.move(to: points[0])
        for i in 1..<points.count {
            let prev = points[i - 1]
            let current = points[i]
            let mid = CGPoint(x: (prev.x + current.x) / 2, y: (prev.y + current.y) / 2)
            path.addQuadCurve(to: mid, controlPoint: prev)
        }
        path.addLine(to: points.last!)

        // Assign path to line layer
        lineLayer.path = path.cgPath

        // Animate stroke
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 1.2
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        lineLayer.add(animation, forKey: "lineAnimation")

        // X-axis labels
        for (i, labelText) in months.enumerated() {
            let x = margin + CGFloat(i) * spacing - 15
            let label = UILabel(frame: CGRect(x: x, y: bounds.height - bottomMargin + 4, width: 50, height: 16))
            label.text = labelText
            label.font = UIFont.systemFont(ofSize: 10)
            label.textColor = .lightGray
            label.textAlignment = .center
            addSubview(label)
        }
    }
    func updateGraph(with months: [String], values: [CGFloat]) {
        self.months = months
        self.values = values
        setNeedsDisplay()
    }

}
