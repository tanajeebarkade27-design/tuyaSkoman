

import UIKit

class ACPopupViewController: UIViewController {

    // MARK: - Data
    var switchItem: SwitchItem?
    var device: Device?
    private var currentFanValue: Int = 1
    private var currentSwingValue: Int = 1
    private var currentWhich: ACWhich = .temperature

    // MARK: - Views
    private let popup = UIView()
    private let acView = UIView()

    private let circularSlider = ACCircularSliderView()

    private let tempButton = UIButton(type: .system)
    private let fanButton = UIButton(type: .system)
    private let swingButton = UIButton(type: .system)

    private let leftRightSwingButton = UIButton(type: .system)
    private let upDownSwingButton = UIButton(type: .system)
    private var swingStack: UIStackView!
    private let closeButton = UIButton(type: .system)
    var onACValueChanged: ((_ temp: Int, _ fan: Int, _ swing: Int, _ which: Int, _ state: Int) -> Void)?

    private let powerButton = UIButton(type: .system)
    private var isOn: Bool = false
    var onPowerChanged: ((Bool) -> Void)?
    

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        setupPopup()
        setupACView()
        setupCircularSlider()
        setupSwingButtonsBelowSlider()
        setupBottomButtons()
        setupCloseButton()
        setupPowerButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       // circularSlider.layer.cornerRadius = circularSlider.frame.width / 2
    }

    // MARK: - Popup Container
    private func setupPopup() {
        popup.backgroundColor = .black
        popup.layer.cornerRadius = 20
        popup.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popup)

        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 320),
            popup.heightAnchor.constraint(equalToConstant: 420)
        ])
    }

    // MARK: - AC View
    private func setupACView() {
        acView.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(acView)

        NSLayoutConstraint.activate([
            acView.topAnchor.constraint(equalTo: popup.topAnchor, constant: 20),
            acView.leadingAnchor.constraint(equalTo: popup.leadingAnchor),
            acView.trailingAnchor.constraint(equalTo: popup.trailingAnchor),
            acView.heightAnchor.constraint(equalToConstant: 260)
        ])
    }

    private func setupPowerButton() {
        powerButton.setImage(UIImage(systemName: "power"), for: .normal)
        powerButton.tintColor = .orange
        powerButton.backgroundColor = .white
        powerButton.layer.cornerRadius = 18
        powerButton.layer.borderWidth = 2
        powerButton.layer.borderColor = UIColor.white.cgColor
        powerButton.translatesAutoresizingMaskIntoConstraints = false

        powerButton.imageView?.contentMode = .scaleAspectFit
        powerButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

        powerButton.addTarget(self, action: #selector(togglePower), for: .touchUpInside)

        acView.addSubview(powerButton)
        
        NSLayoutConstraint.activate([
            powerButton.centerXAnchor.constraint(equalTo: circularSlider.centerXAnchor),
            powerButton.centerYAnchor.constraint(equalTo: circularSlider.centerYAnchor),
            powerButton.widthAnchor.constraint(equalToConstant: 36),
            powerButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }
    
    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
//        closeButton.backgroundColor = UIColor.darkGray.withAlphaComponent(0.6)
//        closeButton.layer.cornerRadius = 14
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        popup.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: popup.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    
    
    // MARK: - Circular Slider
    private func setupCircularSlider() {
        circularSlider.translatesAutoresizingMaskIntoConstraints = false
        acView.addSubview(circularSlider)

        NSLayoutConstraint.activate([
            circularSlider.centerXAnchor.constraint(equalTo: acView.centerXAnchor),
            circularSlider.centerYAnchor.constraint(equalTo: acView.centerYAnchor),
            circularSlider.widthAnchor.constraint(equalTo: acView.widthAnchor, multiplier: 0.8),
            circularSlider.heightAnchor.constraint(equalTo: circularSlider.widthAnchor)
        ])
        circularSlider.onValueChangeEnded = { [weak self] _ in
            guard let self = self else { return }

            if self.circularSlider.mode == .temperature {
                self.currentWhich = .temperature
            } else {
                self.currentWhich = .fan
            }

            self.emitACValues()
        }



        circularSlider.clipsToBounds = true
    }

    
    

    // MARK: - Swing Buttons
    private func setupSwingButtonsBelowSlider() {
        styleSquareButton(leftRightSwingButton, systemImage: "arrow.left.and.right")
        styleSquareButton(upDownSwingButton, systemImage: "arrow.up.and.down")

        swingStack = UIStackView(arrangedSubviews: [
            leftRightSwingButton,
            upDownSwingButton
        ])

        swingStack.axis = .horizontal
        swingStack.spacing = 16
        swingStack.distribution = .fillEqually
        swingStack.translatesAutoresizingMaskIntoConstraints = false
        swingStack.isHidden = true

        popup.addSubview(swingStack)

        NSLayoutConstraint.activate([
            swingStack.topAnchor.constraint(equalTo: acView.bottomAnchor, constant: 8),
            swingStack.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            swingStack.widthAnchor.constraint(equalToConstant: 220),
            swingStack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Bottom Buttons
    private func setupBottomButtons() {
        styleSquareButton(tempButton, systemImage: "snowflake")
        styleSquareButton(fanButton, systemImage: "fan")
        styleSquareButton(swingButton, systemImage: "wind")

        tempButton.addTarget(self, action: #selector(tempTapped), for: .touchUpInside)
        fanButton.addTarget(self, action: #selector(fanTapped), for: .touchUpInside)
        swingButton.addTarget(self, action: #selector(swingTapped), for: .touchUpInside)
        leftRightSwingButton.addTarget(
                self,
                action: #selector(leftRightSwingTapped),
                for: .touchUpInside
            )

            upDownSwingButton.addTarget(
                self,
                action: #selector(upDownSwingTapped),
                for: .touchUpInside
            )

        let stack = UIStackView(arrangedSubviews: [
            tempButton,
            fanButton,
            swingButton
        ])

        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        popup.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: swingStack.bottomAnchor, constant: 20),
            stack.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            stack.widthAnchor.constraint(equalToConstant: 260),
            stack.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Button Styling
    private func styleSquareButton(_ button: UIButton, systemImage: String) {
        button.setImage(UIImage(systemName: systemImage), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    private func setSelected(_ button: UIButton, selected: Bool) {
        button.layer.borderWidth = selected ? 2 : 0
        button.layer.borderColor = selected ? UIColor.systemGreen.cgColor : UIColor.clear.cgColor
    }
    
    
    @objc private func togglePower() {
        isOn.toggle()
        updatePowerButtonAppearance()

        emitACValues()

        onPowerChanged?(isOn)
    }
    private func updatePowerButtonAppearance() {
        powerButton.tintColor = isOn ? .systemGreen : .orange

  
    }

    // MARK: - Actions
    @objc private func fanTapped() {
        selectButton(fanButton)
        circularSlider.mode = .fan
        swingStack.isHidden = true
    }

    @objc private func tempTapped() {
        selectButton(tempButton)
        circularSlider.mode = .temperature
        swingStack.isHidden = true
    }

    @objc private func swingTapped() {
        selectButton(swingButton)
        swingStack.isHidden = false
    }

    private func selectButton(_ selected: UIButton) {
        [tempButton, fanButton, swingButton].forEach {
            $0.backgroundColor = .darkGray
        }
        selected.backgroundColor = .systemGreen
    }
    
    @objc private func leftRightSwingTapped() {
        let isOn = currentSwingValue != 2
        currentSwingValue = isOn ? 2 : 1
        currentWhich = .swing

        setSelected(leftRightSwingButton, selected: isOn)
        setSelected(upDownSwingButton, selected: false)

        emitACValues()
    }

    @objc private func upDownSwingTapped() {
        let isOn = currentSwingValue != 4
        currentSwingValue = isOn ? 4 : 3
        currentWhich = .swing

        setSelected(upDownSwingButton, selected: isOn)
        setSelected(leftRightSwingButton, selected: false)

        emitACValues()
    }


    private func emitACValues() {
        onACValueChanged?(
            circularSlider.temperatureValue,
            circularSlider.fanValue,
            currentSwingValue,
            currentWhich.rawValue,
            isOn ? 1 : 0   // ✅ IMPORTANT
        )
    }


}


private enum ACWhich: Int {
    case temperature = 2
    case fan = 3
    case swing = 4
}

 
