//
//  SelectversionViewController.swift
//  SkromanIsra
//
//  Created by Admin on 20/02/25.
//

import UIKit

class SelectversionViewController: UIViewController {

    @IBOutlet var versionbackgroundview: UIView!
    @IBOutlet weak var closedButton: UIButton!
    
    @IBOutlet weak var popupBackgroundView: UIView!
    
    var selectedRoomId: String?
      var selectedHomeId: String?
      var selectedRoomName: String?
    var  homeName: String?
    var homeId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popupBackgroundView.cornerRadius = 10
        popupBackgroundView.clipsToBounds = true
        
         
        popupBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        
        closedButton.setTitle("", for: .normal)
        
        print("Room ID selecet : \(selectedRoomId ?? "N/A")")
        print("Home ID select: \(selectedHomeId ?? "N/A")")
        print("Room Name select : \(selectedRoomName ?? "N/A")")
        print("homeName at \(homeName)")
        
        
    }
    
    
   
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            
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
    
    @IBAction func skromanNewButton(_ sender: Any) {
        let scanVc = storyboard?.instantiateViewController(identifier: "ScanQRViewController") as! ScanQRViewController
        
        scanVc.versionType =  "skroman_new"
        scanVc.roomId = selectedRoomId
        scanVc.homeId = selectedHomeId
        scanVc.homeName = homeName
        
        
        navigationController?.pushViewController(scanVc, animated: true)
        
    }
    
    
    @IBAction func skromanOldButton(_ sender: Any) {
        let scanVc = storyboard?.instantiateViewController(identifier: "ScanQRViewController") as! ScanQRViewController
        scanVc.roomId = selectedRoomId
        scanVc.homeId = selectedHomeId
        scanVc.homeName = homeName
        scanVc.versionType =  "skroman_old"
        navigationController?.pushViewController(scanVc, animated: true)
        
    }
    
  
    
}
