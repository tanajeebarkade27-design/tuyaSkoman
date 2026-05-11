//
//  DeviceModel.swift
//  SkromanIsra
//
//  Created by Admin on 25/02/25.
//


import Foundation

struct DeviceStateArray: Codable {
   
    let uniqueID: String
    let modelNo: Int?
    let deviceNumber: String
    let cDim: String
    let cNm: String
    let cL: String
    let cF: String
    let cM: String
    let workingMode: String?
    let master: Int
    let ack: String
    let lightState: String
    let lightSpeed: String
    var fanState: String
    let fanSpeed: String
    let controlFrom: String
    let series: String?
    let otaStatus: Int?
    let rRegulator: String?

    enum CodingKeys: String, CodingKey {
      
        case uniqueID = "unique_id"
        case modelNo = "ModelNo"
        case deviceNumber = "d_no"
        case cDim = "c_dim"
        case cNm = "c_nm"
        case cL = "c_l"
        case cF = "c_f"
        case cM = "c_m"
        case workingMode = "working_mode"
        case master
        case ack
        case lightState = "L_state"
        case lightSpeed = "L_speed"
        case fanState = "F_state"
        case fanSpeed = "F_speed"
        case controlFrom = "control_from"
        case series
        case otaStatus = "ota_status"
        case rRegulator = "F_regulator"
    }
}




struct TheftDetectorState: Codable {

    let ack: String?
    let series: String?
    let uniqueId: String
    let controlFrom: String?
    let humanStatus: Int?
    let activeStatus: Int?
    let modelNo: String?

    enum CodingKeys: String, CodingKey {
        case ack
        case series
        case uniqueId = "unique_id"
        case controlFrom = "control_from"
        case humanStatus = "human_status"
        case activeStatus = "active_status"
        case modelNo = "Model_No"
    }
}
