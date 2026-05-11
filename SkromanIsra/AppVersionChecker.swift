//
//  AppVersionChecker.swift
//  SkromanIsra
//
//  Created by Admin on 26/02/26.
//


import UIKit

class AppVersionChecker {

    static func checkForUpdate(completion: @escaping (Bool, String?) -> Void) {
        guard let bundleId = Bundle.main.bundleIdentifier,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            completion(false, nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion(false, nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreVersion = results.first?["version"] as? String {

                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

                    if appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        completion(true, appStoreVersion)
                    } else {
                        completion(false, nil)
                    }
                }
            } catch {
                completion(false, nil)
            }
        }.resume()
    }
}
