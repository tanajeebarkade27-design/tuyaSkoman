//
//  sirrpublish.swift
//  SkromanIsra
//
//  Created by Admin on 15/04/25.
//

import Foundation
import AWSIoT

class SmartDeviceController {
    static let shared = SmartDeviceController()

    func publish_button(control: String, no: Int, state: Int, speed: Int, topic: String) {
        let payload: [String: Any] = [
            "control": control,
            "no": no,
            "state": state,
            "speed": speed,
            "from": "A",
            "topic": topic
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Failed to create JSON")
            return
        }

        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
        iotDataManager.publishString(jsonString, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)

        print("Published to \(topic): \(jsonString)")
    }
}

