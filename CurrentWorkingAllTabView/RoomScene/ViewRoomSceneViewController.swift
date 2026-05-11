//
//  ViewRoomSceneViewController.swift
//  SkromanIsra
//
//  Created by Admin on 20/08/25.
//

import UIKit

class ViewRoomSceneViewController: UIViewController {
    var devices: [Device] = []
    var sceneIndex: Int?
    
    
    var expandedIndexPath: IndexPath? = nil
    @IBOutlet weak var roomSceneTableView: UITableView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("view scene devices\(devices)")
        print("view scene devices..\(sceneIndex)")
        
        registerFile()
        for device in devices {
            let deviecScene = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: device.uniqueId)
            print("device at scene\(deviecScene)")
        }
      
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func registerFile(){
        let uinib =  UINib(nibName: "ViewRoomSceneTableViewCell", bundle: nil)
        roomSceneTableView.register(uinib, forCellReuseIdentifier: "ViewRoomSceneTableViewCell")
        roomSceneTableView.dataSource =  self
        roomSceneTableView.delegate =  self
        
    }
    

}

extension ViewRoomSceneViewController:UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ViewRoomSceneTableViewCell", for: indexPath) as! ViewRoomSceneTableViewCell
        let device = devices[indexPath.row]

        // Fetch all scenes of this device
        let deviceScenes = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: device.uniqueId)

        // Filter only scenes that match sceneIndex
        if let index = sceneIndex {
            let adjustedIndex = index + 1
            let filteredScenes = deviceScenes.filter { $0.sceneNo == "\(adjustedIndex)" }
            print("📌 Row \(indexPath.row) → Device: \(device.uniqueId), Filtered Scenes: \(filteredScenes)")
            cell.configure(with: device, scenes: filteredScenes)
        }
else  {
            print("📌 Row \(indexPath.row) → Device: \(device.uniqueId), No sceneIndex provided, passing empty scenes")
            cell.configure(with: device, scenes: [])
        }

        return cell
    }

    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if expandedIndexPath == indexPath {
          
            expandedIndexPath = nil
        } else {
           
            expandedIndexPath = indexPath
        }
        
       
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedIndexPath == indexPath {
            return 450
        } else {
            return 50
        }
    }

    
    
}
