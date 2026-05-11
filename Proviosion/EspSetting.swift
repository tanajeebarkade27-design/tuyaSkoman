//
//  EspSetting.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/25.
//


import Foundation
import ESPProvision

struct ESPAppSettings {
    var appAllowsQrCodeScan:Bool
    var appSettingsEnabled:Bool
    var deviceType:DeviceType
    var securityMode:ESPSecurity
    var allowPrefixSearch:Bool
    
}
