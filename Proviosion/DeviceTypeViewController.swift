//
//  DeviceTypeViewController.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/25.
//
// Copyright 2020 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  DeviceTypeViewController.swift
//  ESPProvisionSample
//

import UIKit



// Class that manages manual flow by allowing user to select device from BLE or SoftAP
class DeviceTypeViewController: UIViewController {
    var devices: [Device] = []
    var prov_flag : Bool!
    let userDefault = UserDefaults()
    var uniqueId : String?
    var devicePop: String?
    var selectedDevice: Device?
    
    @IBOutlet weak var BLE_button: UIButton!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "bleDeviceSegue",
           let destinationVC = segue.destination as? BLELandingViewController {
            destinationVC.uniqueId = self.uniqueId ?? ""
            destinationVC.devicePop = self.devicePop
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
   

    
    
    
    @IBOutlet var main_view: UIView!
    
    
    @IBOutlet weak var sec_view: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        print("deviecPOP at \(uniqueId)")
        
        main_view.backgroundColor = UICOLOR_MAIN_BG
        sec_view.backgroundColor = UICOLOR_MAIN_BG
        
        print("prov_flag",prov_flag!)
        userDefault.set(prov_flag, forKey: "provisioning_flag")
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    

}
