//
//  FCMTokenManager.swift
//  SkromanIsra
//
//  Created by Admin on 29/01/26.
//

import Foundation

final class FCMTokenManager {
    static let shared = FCMTokenManager()
    private init() {}

    var token: String?
}
