//
//  SceneViewController.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class SceneViewController: UIViewController {
    
    
    @IBOutlet var sceneBackgroundView: UIView!
    
    @IBOutlet weak var sceneView: UIView!
    
    @IBOutlet weak var sceneNameTextField: UITextField!
    @IBOutlet weak var closedButton: UIButton!
    
    @IBOutlet weak var sceneViewButton: UIButton!
    var selectedDeviceUid : String?
    
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var selectedDevice: Device?
    var buttonItems: [String] = []
    var deviceScene: [DeviceScene] = []
    var sceneNumber : String?
    var deviceUinqueId  : String?
    var nextSceneNumber: Int = 1
    var scenename : String?
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet weak var addSceneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        closedButton.setTitle("", for: .normal)
        closedButton.setTitleColor(.black, for: .normal) // Set text color
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 30, height: 30)) {
            closedButton.setImage(image, for: .normal)
        }
       
        sceneView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        sceneView.cornerRadius = 10
        sceneView.borderColor = .gray
        sceneView.borderWidth = 1
        sceneView.layer.cornerRadius = 8
        sceneView.clipsToBounds = true
     
        print("device at \(devicestate)")
        print("devices at scene vc\(devices)")
        print("sceneNumber \(deviceScene)")
        
        // Get the uniqueId from the first available deviceScene
        if let firstScene = devices.first {
            deviceUinqueId = firstScene.uniqueId
            print("firstScene\(firstScene)")
        } else {
            deviceUinqueId = nil
        }
       print("deviceUinqueId at \(deviceUinqueId)")
      
        nextSceneNumber = deviceScene.count + 1
        
        if deviceScene.count >= 8 {
            showAlert(title: "Limit Reached", message: "You cannot create more than 8 scenes.")
            sceneNameTextField.isHidden = true
            addSceneButton.isHidden = true
        } else {
            sceneNameTextField.text = "Scene \(nextSceneNumber)"
            sceneNameTextField.isHidden = false
            addSceneButton.isHidden = false
        }
        
        let buttons: [UIButton] = [ sceneViewButton]
        for button in buttons {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    @IBAction func closedButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func sceneViewButton(_ sender: Any) {
        
        let sceneVC = storyboard?.instantiateViewController(withIdentifier: "ShowSceneViewController") as! ShowSceneViewController
        
        sceneVC.devices =  self.devices
        sceneVC.deviceScene =  self.deviceScene
        sceneVC.devicestate = self.devicestate
        navigationController?.pushViewController(sceneVC, animated: true)
        
        
       
    }
    
    
    func publishScene(control_state : String) {
     
        
        guard let topic = deviceUinqueId  else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }
        
        let scene_pub_parameters : Parameters = [
            "control" : control_state,
            "no" : nextSceneNumber ,
            "from": "A",
            "topic": topic
            
        ]
        
         print("fetchPayload \(scene_pub_parameters)")
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: scene_pub_parameters,options: []) {
            
            let theJSONText = String(data: theJSONData,
                                     encoding: .ascii)
            print("JSON  scene string = \(theJSONText!)")
            
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            let iot_sample_vc = Iot_sample_ViewController()
            
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          
        }
    }
    
    
    
    
    
    
    func fetchAddScene(sceneNo: String, SceneName: String) {
        print("fetchAddScene called with sceneNo: \(sceneNo), SceneName: \(SceneName)")
        guard let deviceState = devicestate.first else {
            
            print("Error: No device states available")
            return
        }
        
        guard let firstScene = devices.first else {
                print("Error: No device scene available.")
                return
            }
        
        let scene_params: Parameters = [
           
            "deviceUid": firstScene.deviceUid ?? "" ,
            "homeId": firstScene.homeId ?? "",
            "roomId": firstScene.roomId ?? "",
            "unique_id": selectedDevice?.uniqueId ?? "",
            "modelNo": selectedDevice?.deviceModelNo ?? "",
            "devicetype": selectedDevice?.deviceType ?? "",
            "sceneNo": sceneNo,
            "sceneName": SceneName,
            "fan_dest": "1",
            "dest_button": deviceState.deviceNumber,
            "config_dim": deviceState.cDim,
            "config_buttons": deviceState.cNm,
            "L_state": deviceState.lightState,
            "L_speed": deviceState.lightSpeed,
            "F_state": deviceState.fanState,
            "F_speed": deviceState.fanSpeed
        ]
        
        print("scene_params  for  scene api \(scene_params)")
        
        AF.request("http://3.7.18.55:3000/skroman/scene", method: .post, parameters: scene_params, encoding: JSONEncoding.default, headers: nil).response { [self] response in
            debugPrint(response)
            
            switch response.result {
            case .success(let data):
                do {
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    print("jsonOne Scene -- >>", jsonOne!)
                    
                    if let parse_json = jsonOne as? [String: AnyObject] {
                        let sceneNo = parse_json["sceneNo"] as? String
                        if sceneNo == sceneNo {
                            DispatchQueue.main.async {
                               
                               
                            }
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            case .failure(let err):
                print(err.localizedDescription)
            }
        }.resume()
    }
    
    @IBAction func sceneNameText(_ sender: Any) {
       
    }
    
    
    
    @IBAction func addSceneButton(_ sender: Any) {
        // Ensure scene name is not empty
        guard let sceneName = sceneNameTextField.text, !sceneName.isEmpty else {
            showAlert(title: "Error", message: "Please enter a scene name.")
            return
        }

        fetchAddScene(sceneNo: String(nextSceneNumber), SceneName: sceneName)
        
        publishScene(control_state: "scene_config")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showPopupScene()
        }
    }


    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func showPopupScene() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "inProcess",
                                     title: "Success!",
                                     subtitle: "Scene Added Sucessfully!")
        
       
    }
    
}
