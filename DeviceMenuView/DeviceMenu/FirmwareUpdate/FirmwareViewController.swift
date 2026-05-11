//
//  FirmwareViewController.swift
//  SkromanIsra
//
//  Created by Admin on 06/03/25.
//
import UIKit
import AWSCore
import AWSIoT
import Alamofire

class FirmwareViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var avrButton: UIButton!
    @IBOutlet weak var FirmwareView: UIView!
    @IBOutlet weak var EspButton: UIButton!
    
    private var countdownLabel = UILabel()
    private var countdownTimer: Timer?
    private var remainingTime: Int = 60
    private let otaPOPUPeView = UIView()
    private let OTATitleLabel = UILabel()
    
    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var selectedDevice: Device?
    var devices: [Device] = []
    var deviceUinqueId: String?
    private let progressBar = UIProgressView(progressViewStyle: .default)
  
    private var totalDuration: Int = 0
    private var otaSuccessReceived = false


    @IBOutlet weak var backgroundimage: UIImageView!
    
   

    override func viewDidLoad() {
        super.viewDidLoad()
        print("devicestate avr \(devicestate)")
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        closeButton.setTitle("", for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 30, height: 30)) {
            closeButton.setImage(image, for: .normal)
        }

        configureButton(avrButton, title: "AVR", imageName: "firmware")
        configureButton(EspButton, title: "ESP", imageName: "firmware")
        
        if let selectedDevice = selectedDevice {
            deviceUinqueId = selectedDevice.uniqueId
            print("🔗 Tracking OTA for Device: \(deviceUinqueId ?? "nil")")
        } else {
            print("⚠️ selectedDevice is nil in FirmwareViewController")
        }


        FirmwareView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        FirmwareView.cornerRadius = 10

        // ✅ Start observing OTA state updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceStateUpdate(_:)),
            name: NSNotification.Name("DeviceStateUpdated"),
            object: nil
        )
        
        

    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
   
    
    @objc private func handleDeviceStateUpdate(_ notification: Notification) {
        guard
            let uniqueId = notification.userInfo?["uniqueId"] as? String,
            let otaStatus = notification.userInfo?["ota_status"] as? Int
        else {
            print("⚠️ Invalid DeviceStateUpdated payload")
            return
        }

        print("📩 Received DeviceStateUpdated: \(uniqueId) → ota_status = \(otaStatus)")
        print("📍 Tracking: \(deviceUinqueId ?? "nil")")

        // Only process for the selected device
        guard uniqueId == deviceUinqueId else { return }

        // --------------------
        // 🔵 SUCCESS STATUS (1)
        // --------------------
        if otaStatus == 1 {
            print("✅ OTA Update SUCCESS")
            
            otaSuccessReceived = true          // <-- Mark success received
            countdownTimer?.invalidate()       // Stop timer immediately
            
            DispatchQueue.main.async {
                self.showAVRSuccessPopup()
            }
            return
        }

        
        if otaStatus == 0 {
            print("❌ OTA reported failure, but waiting for timer to finish...")
            // No alert here — final result handled in updateCountdown()
            return
        }
    }
   

    private func showOTAFailedPopup() {
        closeOTAPopupView()

        let alert = UIAlertController(
            title: "Failed",
            message: "Device OTA update failed. Please try again.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))

        present(alert, animated: true, completion: nil)
    }


    private func showAVRSuccessPopup() {
        closeOTAPopupView()
        
        let alert = UIAlertController(
            title: "Success",
            message: "Device AVR updated successfully",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        
        present(alert, animated: true, completion: nil)
    }

    @IBAction func closeButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func avrButton(_ sender: Any) {
        handleAVRButtonTap()
    }
    
    @IBAction func espButton(_ sender: Any) {
       
        handleESPButtonTap()
    }
    
    func configureButton(_ button: UIButton, title: String, imageName: String) {
        if let image = UIImage(named: imageName)?.resized(to: CGSize(width: 30, height: 30)) {
            button.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal) // sets the text color
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)

        button.backgroundColor = .clear
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1

        
        // Adjust spacing and alignmentba
        button.semanticContentAttribute = .forceLeftToRight
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
    }
    
    
  func handleESPButtonTap() {
      guard let topic = selectedDevice?.uniqueId else {
              print("Error: PUB_TOPIC_ is nil.")
              return
          }
          
          let ESPButton: Parameters = [
              "control": "ota_update",
              "val": 1,
              "from": "A",
              "topic": topic
          ]
          
          if let theJSONData = try? JSONSerialization.data(withJSONObject: ESPButton, options: []) {
              let theJSONText = String(data: theJSONData, encoding: .ascii)
              print("JSON string = \(theJSONText!)")
              let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
              iotDataManager.publishString(theJSONText!, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
          }
          
          print("ESP Publishing control JSON: \(ESPButton)")
          print("ESP button clicked!")
          
          otaPOPupView(timerDuration: 180) // 1.3 Minutes Countdown
      }
      
    
 func handleAVRButtonTap() {
        guard let topic = selectedDevice?.uniqueId else {
            print("Error: PUB_TOPIC_ is nil.")
            return
        }
        
        let AVRButton: Parameters = [
            "control": "ota_update",
            "val": 2,
            "from": "A",
            "topic": topic
        ]
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: AVRButton, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
        
        print("AVR Publishing control JSON: \(AVRButton)")
        print("AVR button clicked!")
        
        otaPOPupView(timerDuration: 300)
    }
    
    private func otaPOPupView(timerDuration: Int) {

        otaSuccessReceived = false      // Reset success flag
        totalDuration = timerDuration   // Save total time
        remainingTime = timerDuration   // Reset remaining time

        // Remove old popup content
        otaPOPUPeView.subviews.forEach { $0.removeFromSuperview() }

        // Remove existing overlay if present
        if let existing = view.viewWithTag(999) { existing.removeFromSuperview() }

        // 🔒 Overlay (to block UI)
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.tag = 999
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 🔵 Popup container
        otaPOPUPeView.backgroundColor = .white
        otaPOPUPeView.layer.cornerRadius = 20
        otaPOPUPeView.layer.shadowOpacity = 0.3
        otaPOPUPeView.layer.shadowRadius = 5
        otaPOPUPeView.translatesAutoresizingMaskIntoConstraints = false

        overlayView.addSubview(otaPOPUPeView)

        NSLayoutConstraint.activate([
            otaPOPUPeView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            otaPOPUPeView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            otaPOPUPeView.widthAnchor.constraint(equalToConstant: 250),
            otaPOPUPeView.heightAnchor.constraint(equalToConstant: 200)
        ])

        // 🔹 Title
        OTATitleLabel.text = "Device Updating"
        OTATitleLabel.font = .boldSystemFont(ofSize: 18)
        OTATitleLabel.textColor = .black
        OTATitleLabel.translatesAutoresizingMaskIntoConstraints = false

        otaPOPUPeView.addSubview(OTATitleLabel)

        NSLayoutConstraint.activate([
            OTATitleLabel.topAnchor.constraint(equalTo: otaPOPUPeView.topAnchor, constant: 20),
            OTATitleLabel.centerXAnchor.constraint(equalTo: otaPOPUPeView.centerXAnchor)
        ])

        // 🔹 Countdown Label (mm:ss)
        countdownLabel.text = formatTime(timerDuration)
        countdownLabel.font = .boldSystemFont(ofSize: 22)
        countdownLabel.textColor = .black
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        
        otaPOPUPeView.addSubview(countdownLabel)

        NSLayoutConstraint.activate([
            countdownLabel.centerXAnchor.constraint(equalTo: otaPOPUPeView.centerXAnchor),
            countdownLabel.topAnchor.constraint(equalTo: OTATitleLabel.bottomAnchor, constant: 15)
        ])

        // 🔹 Progress Slider bar
        progressBar.progress = 0
        progressBar.trackTintColor = UIColor.lightGray
        progressBar.tintColor = UIColor.systemBlue
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false

        otaPOPUPeView.addSubview(progressBar)

        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: countdownLabel.bottomAnchor, constant: 20),
            progressBar.leadingAnchor.constraint(equalTo: otaPOPUPeView.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: otaPOPUPeView.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 8)
        ])

        // 🔥 Start the countdown
        startCountdown(duration: timerDuration)
    }
    @objc private func updateCountdown() {
        if remainingTime > 0 {
            remainingTime -= 1

            countdownLabel.text = formatTime(remainingTime)

            let progress = Float(totalDuration - remainingTime) / Float(totalDuration)
            progressBar.setProgress(progress, animated: true)

        } else {
            countdownTimer?.invalidate()

            if !otaSuccessReceived {
                DispatchQueue.main.async {
                    self.showOTAFailedPopup()
                }
            }
            return
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func setupCircularProgress(in view: UIView) {
        let radius: CGFloat = 35
        let centerPoint = CGPoint(x: 150, y: 140)

        let circularPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)

        backgroundLayer.path = circularPath.cgPath
            backgroundLayer.strokeColor = UIColor.lightGray.cgColor
            backgroundLayer.lineWidth = 8
            backgroundLayer.fillColor = UIColor.clear.cgColor
            backgroundLayer.lineCap = .round
            view.layer.addSublayer(backgroundLayer)

            // Progress Layer
            progressLayer.path = circularPath.cgPath
            progressLayer.strokeColor = UIColor.systemBlue.cgColor
            progressLayer.lineWidth = 8
            progressLayer.fillColor = UIColor.clear.cgColor
            progressLayer.lineCap = .round
            progressLayer.strokeEnd = 1
            view.layer.addSublayer(progressLayer)

            // Add Watch Image in Center (Resized)
            let imageSize = CGSize(width: radius * 1.2, height: radius * 1.2)
            let watchImage = UIImage(systemName: "clock")?.resized(to: imageSize)
            let watchImageView = UIImageView(image: watchImage)
            watchImageView.contentMode = .scaleAspectFit
            watchImageView.tintColor = .black
            watchImageView.frame = CGRect(
                x: centerPoint.x - (imageSize.width / 2),
                y: centerPoint.y - (imageSize.height / 2),
                width: imageSize.width,
                height: imageSize.height
            )

    }

    
    private func startCountdown(duration: Int) {
        countdownTimer?.invalidate()
        remainingTime = duration
        countdownLabel.text = "\(duration) sec"
        
        progressLayer.strokeEnd = 1
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = 0
        animation.duration = CFTimeInterval(duration)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressLayer.add(animation, forKey: "progressAnim")
        
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }
    
   
    
    private func closeOTAPopupView() {
        otaPOPUPeView.removeFromSuperview()
        view.backgroundColor = .white
    }
}
