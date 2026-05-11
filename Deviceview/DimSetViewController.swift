import UIKit
import AWSCore
import AWSIoT
import Alamofire
import Lottie
protocol DimSetViewControllerDelegate: AnyObject {
    func didDismissDimSet()
}

class DimSetViewController: UIViewController {
    @IBOutlet weak var closedButton: UIButton!
    @IBOutlet weak var dimValueLabel: UILabel!
    @IBOutlet weak var dimSlider: UISlider!

    @IBOutlet var dimmView: UIView!
    var devicestate: [DeviceStateArray] = []
    var devices: [Device] = []
    var deviceUinqueId: String?
    var isSliderBeingUsed = false
    weak var delegate: DimSetViewControllerDelegate?


    override func viewDidLoad() {
        super.viewDidLoad()
        closedButton.setTitle("", for: .normal)
        print("device data at dim\(devices)")
        print("device state data at dim\(devicestate)")

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupBulbShapeLabel()
        configureSlider()
        
        if let firstScene = devices.first {
            deviceUinqueId = firstScene.uniqueId
        } else {
            deviceUinqueId = nil
        }
        closedButton.setTitleColor(.black, for: .normal)  
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 30, height: 30)) {
            closedButton.setImage(image, for: .normal)
        }
        
       
        deviceCornerView()
    }
    
    func deviceCornerView() {
        let views = [dimmView]
        
        for view in views {
            view?.layer.cornerRadius = 10
            view?.clipsToBounds = true
            view?.layer.borderWidth = 1
            view?.layer.borderColor = UIColor.gray.cgColor
        }
    }


    func configureSlider() {
        guard let firstDevice = devices.first else {
            setSliderRange(min: 1, max: 7) // Default range
            return
        }

        if firstDevice.deviceCategory == "skroman_new" {
            if firstDevice.deviceDimmingType == "zcd" {
                setSliderRange(min: 1, max: 4)
            } else if firstDevice.deviceDimmingType == "PWM" {
                setSliderRange(min: 1, max: 8)
            } else {
                setSliderRange(min: 1, max: 7)
            }
        } else {
            setSliderRange(min: 1, max: 7)
        }

        dimSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        dimSlider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: .touchUpInside)
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        updateSliderLabel() // Update UI but don't call allDimSet yet
    }

    @objc func sliderTouchEnded(_ sender: UISlider) {
        // Check if user has actually stopped interacting
        if !sender.isTracking {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(allDimSet), object: nil)
            perform(#selector(allDimSet), with: nil, afterDelay: 0.2) // Call function only after release
        }
    }

    func setupBulbShapeLabel() {
        let bulbPath = UIBezierPath()
        let width = dimValueLabel.bounds.width
        let height = dimValueLabel.bounds.height

        // Start from top center
        bulbPath.move(to: CGPoint(x: width / 2, y: 0))

        // Create the rounded bulb top
        bulbPath.addCurve(to: CGPoint(x: width, y: height * 0.7),
                          controlPoint1: CGPoint(x: width * 1.2, y: height * 0.3),
                          controlPoint2: CGPoint(x: width, y: height * 0.5))

        // Create the bottom narrow part
        bulbPath.addQuadCurve(to: CGPoint(x: 0, y: height * 0.7),
                              controlPoint: CGPoint(x: width / 2, y: height * 0.85))

        // Curve back to the top center
        bulbPath.addCurve(to: CGPoint(x: width / 2, y: 0),
                          controlPoint1: CGPoint(x: 0, y: height * 0.5),
                          controlPoint2: CGPoint(x: -width * 0.2, y: height * 0.3))

       
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bulbPath.cgPath
        dimValueLabel.layer.mask = shapeLayer

        // Styling for a glowing effect
        dimValueLabel.backgroundColor = UIColor.yellow.withAlphaComponent(0.8) // Light bulb color
        dimValueLabel.textColor = .black
        dimValueLabel.textAlignment = .center
        dimValueLabel.font = UIFont.boldSystemFont(ofSize: 16)

        // Adding Glow Effect
        dimValueLabel.layer.shadowColor = UIColor.systemOrange.cgColor
        dimValueLabel.layer.shadowOpacity = 0.6
        dimValueLabel.layer.shadowOffset = CGSize(width: 0, height: 5)
        dimValueLabel.layer.shadowRadius = 10
    }

  
   


    func setSliderRange(min: Float, max: Float) {
        dimSlider.minimumValue = min
        dimSlider.maximumValue = max
        dimSlider.value = min
        updateSliderLabel()
    }

    func updateSliderLabel() {
        dimValueLabel.text = "\(Int(dimSlider.value))"
    }

   
  
    @IBAction func sliderTouchUp(_ sender: UISlider) {
        allDimSet() // Send payload when slider is released
    }

    
    
    

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        delegate?.didDismissDimSet() // Notify DeviceViewController
        dismiss(animated: true, completion: nil)
    }

    
    
    @objc func allDimSet() {
        guard let topic = deviceUinqueId else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }

        let speedValue = Int(dimSlider.value)

        let allDim: Parameters = [
            "control": "all_dim",
            "speed": "\(speedValue)",
            "from": "A",
            "topic": topic
        ]

        print("all dim para\(allDim)")

        if let theJSONData = try? JSONSerialization.data(withJSONObject: allDim, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .utf8)
            print("JSON string = \(theJSONText!)")
            //showPopupdim()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    @objc func showPopupdim() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "light",
                                     title: "Success!",
                                     subtitle: "Dimming value updated Sucessfully ")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismiss(animated: true, completion: nil)
            }
       
    }
    

}
