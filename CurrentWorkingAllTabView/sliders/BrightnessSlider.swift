//
//  BrtithnessSlider.swift
//  SkromanIsra
//
//  Created by Admin on 30/05/25.
//

import UIKit

class CustomSlider: UIView {

    private let trackView = UIView()
    private let progressView = UIView()
    private let thumbView = UIView()
    private let valueLabel = UILabel()
    var onValueChangeEnded: ((Int) -> Void)?
    var currentValue: Int = 0 {
        didSet {
            valueLabel.text = "\(currentValue)"
            onValueChanged?(currentValue)
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
        self.backgroundColor = .clear

       
        trackView.backgroundColor = .black
        trackView.layer.cornerRadius = 15      // <-- Adjust corner radius here
        trackView.clipsToBounds = true         // Make sure corners are clipped
        addSubview(trackView)

      
        progressView.backgroundColor = .white
        progressView.layer.cornerRadius = 15   // <-- Same corner radius to keep consistent
        progressView.clipsToBounds = true
        addSubview(progressView)

     
        thumbView.backgroundColor = .green
        thumbView.layer.cornerRadius = 12
        //thumbView.layer.borderWidth = 1
        //thumbView.layer.borderColor = UIColor.darkGray.cgColor
        addSubview(thumbView)

      
        valueLabel.font = .systemFont(ofSize: 12, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center
        thumbView.addSubview(valueLabel)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(pan)
        valueLabel.text = "\(currentValue)"

    }

    private var isSliding = false

      // Add to `handlePan`
      @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
          let location = gesture.location(in: self)
          let clampedX = min(max(location.x, 0), self.bounds.width)
          let percent = clampedX / self.bounds.width
          currentValue = Int(percent * 100)
          updateThumbPosition(for: currentValue)
          updateProgressView()

          // Call while sliding
          onValueChanged?(currentValue)

          if gesture.state == .ended {
              onValueChangeEnded?(currentValue) // call when release
          }
      }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Reduce width from right by 5 points
        let rightInset: CGFloat = 5
        let sliderWidth = self.bounds.width - rightInset

        // Layout track
        trackView.frame = CGRect(x: 0, y: 0, width: sliderWidth, height: self.bounds.height)
        updateThumbPosition(for: currentValue)
        updateProgressView()
    }

    private func updateThumbPosition(for value: Int) {
        let thumbWidth: CGFloat = 25
        let rightInset: CGFloat = 5
        let sliderWidth = self.bounds.width - rightInset

        let xPos = CGFloat(value) / 100.0 * (sliderWidth - thumbWidth)
        let yPos = (self.bounds.height - thumbWidth) / 2
        thumbView.frame = CGRect(x: xPos, y: yPos, width: thumbWidth, height: thumbWidth)

        thumbView.layer.cornerRadius = thumbView.bounds.width / 2
        valueLabel.frame = thumbView.bounds
    }

    private func updateProgressView() {
        let rightInset: CGFloat = 5
        let sliderWidth = self.bounds.width - rightInset

        if currentValue <= 0 {
            progressView.frame = .zero
        } else if currentValue >= 100 {
            progressView.frame = CGRect(x: 0, y: 0, width: sliderWidth, height: self.bounds.height)
        } else {
            let centerX = thumbView.center.x
            progressView.frame = CGRect(x: 0, y: 0, width: centerX, height: self.bounds.height)
        }
    }

    func setEnabled(_ enabled: Bool) {
        self.isUserInteractionEnabled = enabled
        self.alpha = enabled ? 1.0 : 0.5
    }

}
