//
//  SwitchArray.swift
//  SkromanIsra
//
//  Created by Admin on 14/05/25.
//

import Foundation

enum SwitchType: String {
    case light = "L"
    case fan = "F"
    case master = "M"
    case ac     = "A"
}

struct SwitchItem {
    let name: String
    let type: SwitchType
    let switchIndex: Int
    var isOnState: Int
    let isChildLocked: Int
    let speed: String?
    let uniqueID: String
    let buttonDetail: ButtonDetails?
    var configDim: String?
    let destButton: Int?
    let fanDest: Int?
    let isShortcut: Int?
    var nextState: Int?
    let rRegulator: String?
    
    var description: String {
        return """
        SwitchItem(
          name: \(name),
          type: \(type),
          switchIndex: \(switchIndex),
          isOn: \(isOnState),
          isChildLocked: \(isChildLocked),
          speed: \(speed ?? "nil"),
          uniqueID: \(uniqueID),
          isShortcut: \(isShortcut ?? -1),
          buttonDetail: \(buttonDetail != nil ? "\(buttonDetail!)" : "nil")
          
        
        )
        """
    }
}





