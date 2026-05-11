//
//  FanSlider.swift
//  SkromanIsra
//
//  Created by Admin on 20/06/25.
//

import UIKit

class FanSlider: UIView {

    private let trackView = UIView()
    private let progressView = UIView()
    private let thumbView = UIView()
    private let valueLabel = UILabel()
    var onSliderReleased: ((Int) -> Void)?
    var currentValue: Int = 1 {
        didSet {
            valueLabel.text = "\(currentValue)"
        }
    }

    

    var onValueChanged: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    

    private func setupUI() {
        backgroundColor = .clear

        // Track view
        trackView.backgroundColor = .black
        trackView.layer.cornerRadius = 15
        trackView.clipsToBounds = true
        addSubview(trackView)

        // Progress view
        progressView.backgroundColor = .white
        progressView.layer.cornerRadius = 15
        progressView.clipsToBounds = true
        addSubview(progressView)

        // Thumb view
        thumbView.backgroundColor = .green
        thumbView.layer.cornerRadius = 12.5
        thumbView.layer.borderWidth = 1
        thumbView.layer.borderColor = UIColor.darkGray.cgColor
        addSubview(thumbView)

        // Value label inside thumb
        valueLabel.font = .systemFont(ofSize: 12, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center
        
        valueLabel.text = "\(currentValue)"
        thumbView.addSubview(valueLabel)

        // Pan gesture
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(pan)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        trackView.frame = bounds
        updateThumbPosition(for: currentValue)
        updateProgressView()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let width = self.bounds.width
        let sectionWidth = width / 4

        let clampedX = min(max(location.x, 0), width)
        let index = Int(clampedX / sectionWidth)
        let snappedValue = max(1, min(4, index + 1))

        // Update value during pan
        if gesture.state == .changed {
            currentValue = snappedValue
            updateThumbPosition(for: currentValue)
            updateProgressView()
            onValueChanged?(currentValue)
        }

        // ✅ Publish only after user releases the slider
        if gesture.state == .ended {
            currentValue = snappedValue
            updateThumbPosition(for: currentValue)
            updateProgressView()
            onValueChanged?(currentValue)
            onSliderReleased?(currentValue)
        }
    }

    private func updateThumbPosition(for value: Int) {
        let thumbWidth: CGFloat = 25
        let totalSteps: CGFloat = 4
        let stepWidth = (self.bounds.width - thumbWidth) / (totalSteps - 1)

        let xPos = CGFloat(value - 1) * stepWidth
        let yPos = (self.bounds.height - thumbWidth) / 2

        thumbView.frame = CGRect(x: xPos, y: yPos, width: thumbWidth, height: thumbWidth)
        thumbView.layer.cornerRadius = thumbWidth / 2
        valueLabel.frame = thumbView.bounds
    }

    private func updateProgressView() {
        let thumbMaxX: CGFloat

        switch currentValue {
        case 1:
            // No progress fill
            progressView.frame = .zero
            return
        case 4:
            
            thumbMaxX = self.bounds.width
        default:
            // Fill up to middle of thumb for steps 2 and 3
            thumbMaxX = thumbView.frame.midX
        }

        progressView.frame = CGRect(x: 0, y: 0, width: thumbMaxX, height: self.bounds.height)
    }



}
extension FanSlider {
    func setEnabled(_ enabled: Bool) {
        self.isUserInteractionEnabled = enabled
        self.alpha = enabled ? 1.0 : 0.4  
    }
}
