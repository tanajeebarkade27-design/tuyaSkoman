//
//  AllRoomModel.swift
//  SkromanIsra
//
//  Created by Admin on 23/03/26.
//

import Foundation
class AllRoomsViewModel {

    var devices: [Device] = []
    var deviceStates: [String: DeviceStateArray] = [:] // 🔥 Dictionary

    func updateState(_ state: DeviceStateArray) {
        deviceStates[state.uniqueID] = state
    }

    func state(for id: String) -> DeviceStateArray? {
        return deviceStates[id]
    }
}
