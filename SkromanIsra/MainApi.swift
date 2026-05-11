//
//  MainApi.swift
//  SkromanIsra
//
//  Created by Admin on 28/01/25.
//

import UIKit

final class MainApi {
    /// Global API host (single source of truth).
    public static let baseHost = "https://skroman.in"
    
    /// Build full URL string from a path like `skroman/userapi/loginemail`.
    public static func url(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return baseHost }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return trimmed }
        if trimmed.hasPrefix("/") { return baseHost + trimmed }
        return baseHost + "/" + trimmed
    }
    
    // Existing endpoints (kept for compatibility with current call sites)
    public static let baseUrl = url("skroman/Sync/")
    public static let baseUrlUser = url("skroman/userapi/")
    
    public static let sync_everything = baseUrl + "sync_everything"
    
    // Fixed: missing scheme previously.
    public static let homeId = url("skroman/roomapi/rooms/homeId")
    
    public static let loginUrl = baseUrlUser + "loginemail"
    public static let registration = baseUrlUser + "registration"
    public static let forgotpassword = baseUrlUser + "forgotpassword"
    public static let verifyOtp = baseUrlUser + "verifyotp"
}
