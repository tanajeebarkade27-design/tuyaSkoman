

import Foundation
import Foundation

class TuyaDeviceManager {
    static let shared = TuyaDeviceManager()
    private init() {}

    var devices: [TuyaDeviceModel] = []

    // ✅ Set devices (overwrite)
    func setDevices(_ newDevices: [TuyaDeviceModel]) {
        self.devices = newDevices
        print("✅ TuyaDeviceManager updated:", devices)
    }

    // ✅ Get devices by room
    func getDevices(for tuyaRoomId: Int64?) -> [TuyaDeviceModel] {
        guard let tuyaRoomId = tuyaRoomId else { return [] }

        let filtered = devices.filter { $0.tuyaRoomId == tuyaRoomId }

        print("📦 Filtering Tuya Devices for room:", tuyaRoomId)
        print("📦 Matched:", filtered)

        return filtered
    }

    // ✅ Debug
    func printAllDevices() {
        print("📦 All Tuya Devices:", devices)
    }
}

