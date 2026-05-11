import Foundation
import UIKit
import  Lottie

class MasterButtonSliderView: UIView {
    
    private let sliderButton = UIView()
    private let thumbView = UIView()
    private let arrowImageView = UIImageView()
    private let centerLabel = UILabel()
    
    private var thumbLeadingConstraint: NSLayoutConstraint!
    private var thumbTrailingConstraint: NSLayoutConstraint!
    private var arrowLeadingConstraint: NSLayoutConstraint!
    private var arrowTrailingConstraint: NSLayoutConstraint!
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private var thumbCenterXConstraint: NSLayoutConstraint!
    private let leftLabel = UILabel()
    private let rightLabel = UILabel()
    private let leftArrowAnimation = LottieAnimationView(name: "skroman")
    private let rightArrowAnimation = LottieAnimationView(name: "skroman")
    private var totalTranslationX: CGFloat = 0
    private let thumbImageView = UIImageView()

    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    private var isOn = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSlider()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSlider()
    }
    
    private func setupSlider() {
        // Slider background
        sliderButton.backgroundColor = UIColor(white: 1, alpha: 0.2)
        sliderButton.layer.cornerRadius = 22
    
        addSubview(sliderButton)
        sliderButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sliderButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            sliderButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            sliderButton.topAnchor.constraint(equalTo: topAnchor),
            sliderButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add arrow Lottie animations
        leftArrowAnimation.loopMode = .loop
        leftArrowAnimation.contentMode = .scaleAspectFit
        sliderButton.addSubview(leftArrowAnimation)
        leftArrowAnimation.translatesAutoresizingMaskIntoConstraints = false

        rightArrowAnimation.loopMode = .loop
        rightArrowAnimation.contentMode = .scaleAspectFit
        sliderButton.addSubview(rightArrowAnimation)
        rightArrowAnimation.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leftArrowAnimation.leadingAnchor.constraint(equalTo: sliderButton.leadingAnchor, constant: 10),
            leftArrowAnimation.centerYAnchor.constraint(equalTo: sliderButton.centerYAnchor),
            leftArrowAnimation.widthAnchor.constraint(equalToConstant: 30),
            leftArrowAnimation.heightAnchor.constraint(equalToConstant: 30),

            rightArrowAnimation.trailingAnchor.constraint(equalTo: sliderButton.trailingAnchor, constant: -10),
            rightArrowAnimation.centerYAnchor.constraint(equalTo: sliderButton.centerYAnchor),
            rightArrowAnimation.widthAnchor.constraint(equalToConstant: 30),
            rightArrowAnimation.heightAnchor.constraint(equalToConstant: 30)
        ])

        leftArrowAnimation.play()
        rightArrowAnimation.play()

        // Add labels (below thumb)
        leftLabel.text = "Master On"
        
        leftLabel.textColor = .white
        leftLabel.font = .systemFont(ofSize: 12, weight: .medium)
        leftLabel.textAlignment = .right
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        sliderButton.addSubview(leftLabel)

        rightLabel.text = "Master Off"
        rightLabel.textColor = .white
        rightLabel.font = .systemFont(ofSize: 12, weight: .medium)
        rightLabel.textAlignment = .left
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        sliderButton.addSubview(rightLabel)

        NSLayoutConstraint.activate([
            leftLabel.leadingAnchor.constraint(equalTo: leftArrowAnimation.trailingAnchor, constant: 5),
            leftLabel.centerYAnchor.constraint(equalTo: sliderButton.centerYAnchor),

            rightLabel.trailingAnchor.constraint(equalTo: rightArrowAnimation.leadingAnchor, constant: -5),
            rightLabel.centerYAnchor.constraint(equalTo: sliderButton.centerYAnchor)
        ])

        // Add thumb on top of everything
        thumbView.backgroundColor = .white
        thumbView.layer.borderColor = UIColor.clear.cgColor
        thumbView.layer.borderWidth = 1

        
        thumbView.layer.cornerRadius = 15
        thumbView.clipsToBounds = true
        sliderButton.addSubview(thumbView)
        
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbView.widthAnchor.constraint(equalToConstant: 30),
            thumbView.heightAnchor.constraint(equalToConstant: 30),
            thumbView.centerYAnchor.constraint(equalTo: sliderButton.centerYAnchor)
        ])

        // Center thumb initially
        thumbCenterXConstraint = thumbView.centerXAnchor.constraint(equalTo: sliderButton.centerXAnchor)
        thumbCenterXConstraint.isActive = true

        // Image inside thumb
        thumbImageView.image = UIImage(named: "SKLogo")
        thumbImageView.contentMode = .scaleAspectFit
        thumbView.addSubview(thumbImageView)
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbImageView.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor),
            thumbImageView.centerYAnchor.constraint(equalTo: thumbView.centerYAnchor),
            thumbImageView.widthAnchor.constraint(equalToConstant: 50),
            thumbImageView.heightAnchor.constraint(equalToConstant: 50)
        ])

      

        // Pan gesture
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        thumbView.addGestureRecognizer(panGestureRecognizer)
        
        // Add arrow Lottie animations
        leftArrowAnimation.loopMode = .loop
        leftArrowAnimation.contentMode = .scaleAspectFit
        leftArrowAnimation.transform = CGAffineTransform(scaleX: -1, y: 1) // <-- Flip horizontally
        sliderButton.addSubview(leftArrowAnimation)
        leftArrowAnimation.translatesAutoresizingMaskIntoConstraints = false

        rightArrowAnimation.loopMode = .loop
        rightArrowAnimation.contentMode = .scaleAspectFit
        sliderButton.addSubview(rightArrowAnimation)
        rightArrowAnimation.translatesAutoresizingMaskIntoConstraints = false

    }
    func setMasterActive(_ isActive: Bool) {
        if isActive {
            sliderButton.backgroundColor = UIColor.red.withAlphaComponent(0.4)
          
            thumbView.layer.borderColor = UIColor.red.cgColor
            thumbView.layer.borderWidth = 1
        } else {
          
            thumbView.backgroundColor = .white
            thumbView.layer.borderColor = UIColor.clear.cgColor
            thumbView.layer.borderWidth = 0
        }
    }

    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: sliderButton)

        switch gesture.state {
        case .began:
            thumbView.translatesAutoresizingMaskIntoConstraints = true
            thumbCenterXConstraint.isActive = false
            feedbackGenerator.prepare()
            totalTranslationX = 0

        case .changed:
            var newX = thumbView.center.x + translation.x
            let halfWidth = thumbView.bounds.width / 2
            newX = max(halfWidth, min(sliderButton.bounds.width - halfWidth, newX))
            thumbView.center.x = newX
            gesture.setTranslation(.zero, in: sliderButton)

            totalTranslationX += translation.x

            // 🔁 Image and animation logic
            let center = sliderButton.bounds.midX
            if thumbView.center.x < center {
                leftArrowAnimation.isHidden = false
                rightArrowAnimation.isHidden = true
                if !leftArrowAnimation.isAnimationPlaying {
                    leftArrowAnimation.play()
                }
                rightArrowAnimation.stop()

                // ⬅️ Set left image
                thumbImageView.image = UIImage(named: "masterOn")
            } else {
                rightArrowAnimation.isHidden = false
                leftArrowAnimation.isHidden = true
                if !rightArrowAnimation.isAnimationPlaying {
                    rightArrowAnimation.play()
                }
                leftArrowAnimation.stop()

                // ➡️ Set right image
                thumbImageView.image = UIImage(named: "masterOn")
            }

        case .ended, .cancelled:
            feedbackGenerator.impactOccurred()

            let swipeDirection = totalTranslationX < 0 ? "left" : "right"
            NotificationCenter.default.post(name: .masterSliderSwiped, object: nil, userInfo: ["direction": swipeDirection])

            // 🌀 Reset to center
            thumbView.translatesAutoresizingMaskIntoConstraints = false
            thumbCenterXConstraint.isActive = true
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.8,
                           options: [.curveEaseOut],
                           animations: {
                self.layoutIfNeeded()
            })

            // 🔁 Optional: Set image based on direction after release
            thumbImageView.image = swipeDirection == "left" ? UIImage(named: "masterOn") : UIImage(named: "SKLogo")

            // 🔁 Play both arrows
            leftArrowAnimation.isHidden = false
            rightArrowAnimation.isHidden = false
            if !leftArrowAnimation.isAnimationPlaying {
                leftArrowAnimation.play()
            }
            if !rightArrowAnimation.isAnimationPlaying {
                rightArrowAnimation.play()
            }

        default:
            break
        }
    }




    }

