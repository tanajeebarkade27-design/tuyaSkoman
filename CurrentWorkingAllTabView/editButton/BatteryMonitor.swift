//
//  BatteryMonitor.swift
//  SkromanIsra
//
//  Created by Admin on 08/10/25.
//


import UIKit
import AWSIoT

class BatteryMonitor {
    static let shared = BatteryMonitor()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func startMonitoring(uniqueId: String) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(batteryLevelChanged),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
        registerBackgroundTask()
        print("🔋 Battery monitoring started.")
    }
    
    @objc func batteryLevelChanged() {
        let batteryLevel = UIDevice.current.batteryLevel
        let percent = Int(batteryLevel * 100)
        print("Battery level changed: \(percent)%")
        
        if percent >= 100 {
            sendAutoSocketPayload(uniqueId: "YOUR_UNIQUE_ID")
            endBackgroundTask()
        }
    }
    
    func sendAutoSocketPayload(uniqueId: String) {
        let payload: [String: Any] = [
            "control": "L",
            "state": "0",
            "from": "A",
            "topic": uniqueId
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Publishing payload: \(jsonString)")
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: uniqueId + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "BatteryMonitor") {
            self.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
