//
//  visiterModel.swift
//  SkromanIsra
//
//  Created by Admin on 25/02/26.
//


import Foundation

struct VisitorNotificationModel: Codable {

    let type: String?
    let title: String?
    let body: String?

    let visitorId: String?
    let visitorName: String?
    let visitorType: String?

    let flatNo: String?
    let societyId: String?
    let societyName: String?

    let mobileNo: String?
    let status: String?
    let hasVehicle: Bool?

    let screen: String?
    let channelId: String?

    let entryTime: String?

    let visitorPhoto: String?
    let vehiclePhoto: String?
    let idProofPhoto: String?

    let entryBy: EntryBy?

    enum CodingKeys: String, CodingKey {
        case type, title, body
        case visitorId, visitorName, visitorType
        case flatNo, societyId, societyName
        case mobileNo, status, hasVehicle
        case screen, channelId
        case entryTime
        case visitorPhoto, vehiclePhoto, idProofPhoto
        case entryBy
    }
}
struct EntryBy: Codable {
    let gateId: String?
    let gateName: String?
}
extension VisitorNotificationModel {

    static func from(userInfo: [AnyHashable: Any]) -> VisitorNotificationModel? {
        do {
            let data = try JSONSerialization.data(withJSONObject: userInfo)
            return try JSONDecoder().decode(VisitorNotificationModel.self, from: data)
        } catch {
            print("Notification decode error:", error)
            return nil
        }
    }
}
