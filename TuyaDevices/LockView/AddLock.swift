//
//  AddLock.swift
//  SkromanIsra
//
//  Created by Admin on 11/04/26.
//

import Foundation
import Network
import ThingSmartHomeKit
import ThingSmartActivatorKit
class DevicePairingManager {

    static let shared = DevicePairingManager()

    var pendingDeviceId: String?
    var tuyaHomeId: Int64?
    var tuyaRoomId: Int64?
    var selectedRoomId: String?
    func startMonitoringAndAssign() {

        guard let deviceId = pendingDeviceId else { return }

        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetMonitor")

        // ✅ HANDLE IMMEDIATE CASE
        if monitor.currentPath.status == .satisfied {
            print("⚡ Internet already available")
            assignDevice(deviceId: deviceId)
            return
        }

        monitor.pathUpdateHandler = { path in
            
            if path.status == .satisfied {
                
                print("✅ Internet restored globally")

                monitor.cancel()

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.assignDevice(deviceId: deviceId)
                }
            }
        }

        monitor.start(queue: queue)
    }
    func assignDevice(deviceId: String) {

        guard let homeId = tuyaHomeId else {
            print("❌ Missing HomeId")
            return
        }

        guard let roomIdStr = selectedRoomId else {
            print("❌ Missing selectedRoomId")
            return
        }

        // ✅ GET CORRECT ROOM ID FROM DB
        guard let validRoomId = SkromanIsraDatabaseHelper.shared
            .getTuyaRoomIdFromDB(roomId: roomIdStr),
              validRoomId > 0 else {
            
            print("❌ Invalid TuyaRoomId from DB")
            return
        }

        print("✅ FINAL IDs")
        print("HomeId:", homeId)
        print("RoomId:", validRoomId)
        print("DeviceId:", deviceId)

        let room = ThingSmartRoom(roomId: validRoomId, homeId: homeId)

        room?.addDevice(withDeviceId: deviceId, success: {

            print("✅ Device added to room SUCCESS")

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("DeviceAssigned"), object: nil)
            }

        }, failure: { error in
            print("❌ Failed:", error?.localizedDescription ?? "")
        })
    }
}
