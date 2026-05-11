//
//  ACSliderView.swift
//  SkromanIsra
//
//  Created by Admin on 20/06/25.
//


import UIKit

class ACSliderView: UIView {

    private let fanSlider = FanSlider()
    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let tempLabel = UILabel()
    private let swingHorizontalButton = UIButton(type: .system)
    private let swingVerticalButton = UIButton(type: .system)

    private var temperature: Int = 21 {
        didSet {
            tempLabel.text = "\(temperature)°C"
            onTemperatureChanged?(temperature)
        }
    }

    var onFanSpeedChanged: ((Int) -> Void)?
    var onTemperatureChanged: ((Int) -> Void)?

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

        // MARK: - Swing Buttons
        swingHorizontalButton.setImage(UIImage(systemName: "arrow.left.and.right.circle"), for: .normal)
        swingHorizontalButton.tintColor = .white
        swingHorizontalButton.translatesAutoresizingMaskIntoConstraints = false
        swingHorizontalButton.addTarget(self, action: #selector(toggleSwingHorizontal), for: .touchUpInside)
        addSubview(swingHorizontalButton)

        swingVerticalButton.setImage(UIImage(systemName: "swingR"), for: .normal)
        swingVerticalButton.tintColor = .white
        swingVerticalButton.translatesAutoresizingMaskIntoConstraints = false
        swingVerticalButton.addTarget(self, action: #selector(toggleSwingVertical), for: .touchUpInside)
        addSubview(swingVerticalButton)
        
        
        

        // MARK: - Temp Label
        tempLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center
        tempLabel.text = "\(temperature)°C"
        tempLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tempLabel)

        // MARK: - Minus & Plus Buttons
        minusButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        minusButton.tintColor = .white
        minusButton.translatesAutoresizingMaskIntoConstraints = false
        minusButton.addTarget(self, action: #selector(decreaseTemp), for: .touchUpInside)
        addSubview(minusButton)

        plusButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        plusButton.tintColor = .white
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.addTarget(self, action: #selector(increaseTemp), for: .touchUpInside)
        addSubview(plusButton)

        // MARK: - Fan Slider
        fanSlider.translatesAutoresizingMaskIntoConstraints = false
        fanSlider.onValueChanged = { [weak self] value in
            self?.onFanSpeedChanged?(value)
        }
        addSubview(fanSlider)

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            // Swing buttons at top
            swingHorizontalButton.topAnchor.constraint(equalTo: topAnchor),
            swingHorizontalButton.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -8),

            swingVerticalButton.topAnchor.constraint(equalTo: topAnchor),
            swingVerticalButton.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 8),

            // Temp label below swing buttons
            tempLabel.topAnchor.constraint(equalTo: swingHorizontalButton.bottomAnchor, constant: 4),
            tempLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            // Fan slider with plus/minus
            minusButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            minusButton.centerYAnchor.constraint(equalTo: fanSlider.centerYAnchor),

            plusButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            plusButton.centerYAnchor.constraint(equalTo: fanSlider.centerYAnchor),

            fanSlider.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 8),
            fanSlider.trailingAnchor.constraint(equalTo: plusButton.leadingAnchor, constant: -8),
            fanSlider.topAnchor.constraint(equalTo: tempLabel.bottomAnchor, constant: 8),
            fanSlider.heightAnchor.constraint(equalToConstant: 30),
            fanSlider.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Temp Button Actions
    @objc private func decreaseTemp() {
        if temperature > 16 {
            temperature -= 1
        }
    }

    @objc private func increaseTemp() {
        if temperature < 30 {
            temperature += 1
        }
    }

    // MARK: - Swing Button Actions
    @objc private func toggleSwingHorizontal() {
        print("Swing Left-Right tapped")
    }

    @objc private func toggleSwingVertical() {
        print("Swing Up-Down tapped")
    }
}
