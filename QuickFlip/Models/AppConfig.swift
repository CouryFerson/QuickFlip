//
//  AppConfig.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/5/25.
//

struct AppConfig: Codable {
    let minimumVersion: String
    let latestVersion: String
    let forceUpdateMessage: String

    enum CodingKeys: String, CodingKey {
        case minimumVersion = "minimum_version"
        case latestVersion = "latest_version"
        case forceUpdateMessage = "force_update_message"
    }
}
