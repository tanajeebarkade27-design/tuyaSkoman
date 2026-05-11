//
//  DeviceSelectViewController.swift
//  SkromanIsra
//
//  Created by Admin on 06/04/26.
//

import UIKit

class DeviceSelectViewController: UIViewController {
    var selectedRoomId: String?
      var selectedHomeId: String?
      var selectedRoomName: String?
    var  homeName: String?
    var homeId :  String?
   
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var addSwitch: UIButton!
    
    @IBOutlet weak var addLock: UIButton!
    
    @IBOutlet weak var addCamera: UIButton!
    var tuyaHomeid: Int64?
    var tuyaRoomid: String?
    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundView.layer.cornerRadius = 12
        backgroundView.clipsToBounds = true
        backgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        setupButtons()
    }
    
    
    @IBAction func backbutton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    func setupButtons() {
        
        let buttons = [addSwitch, addLock, addCamera]
        
        for btn in buttons {
            guard let button = btn else { continue }
             
            button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
             
            button.tintColor = .white
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 12
            button.clipsToBounds = true
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        }
    }
    
    @IBAction func addSwitch(_ sender: Any) {
        navigateToSwitchVc()
    }
    
    
    @IBAction func addLocks(_ sender: Any) {
            let  lockVc =   storyboard?.instantiateViewController(identifier: "AddLockViewController") as!
        AddLockViewController
        lockVc.selectedRoomId = self.selectedRoomId
        lockVc.selectedHomeId = self.selectedHomeId
        lockVc.tuyaHomeId = self.tuyaHomeid
        lockVc.roomName = self.selectedRoomName
            navigationController?.pushViewController(lockVc, animated: true)
       
    }
    

    @IBAction func addCamera(_ sender: Any) {
        
        let  cameraVc =   storyboard?.instantiateViewController(identifier: "AddCameraViewController") as!
        AddCameraViewController
        
        cameraVc.selectedRoomId = self.selectedRoomId
        cameraVc.selectedHomeId = self.selectedHomeId
        cameraVc.tuyaHomeId = self.tuyaHomeid
        cameraVc.roomName = self.selectedRoomName
        navigationController?.pushViewController(cameraVc, animated: true)
    }
    
    func navigateToSwitchVc(){
        let  versionVc =   storyboard?.instantiateViewController(identifier: "SelectversionViewController") as!
        SelectversionViewController
        versionVc.selectedRoomId = self.selectedRoomId
            versionVc.selectedHomeId = self.selectedHomeId
            versionVc.selectedRoomName = self.selectedRoomName
            versionVc.homeName =  homeName
        
        
        navigationController?.pushViewController(versionVc, animated: true)
    }
    
    
    
     
}
