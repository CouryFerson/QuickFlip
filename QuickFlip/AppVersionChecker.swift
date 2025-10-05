//
//  AppVersionChecker.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/5/25.
//

import Combine
import Foundation

@MainActor
class AppVersionChecker: ObservableObject {
    @Published var needsForceUpdate = false
    @Published var updateMessage = ""

    func checkVersion(supabaseService: SupabaseService) async {
        do {
            let config = try await supabaseService.getAppConfig()
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            if currentVersion.compareVersion(to: config.minimumVersion) == .orderedAscending {
                needsForceUpdate = true
                updateMessage = config.forceUpdateMessage
            }
        } catch {
            print("Failed to check version: \(error)")
        }
    }
}

extension String {
    func compareVersion(to version: String) -> ComparisonResult {
        return self.compare(version, options: .numeric)
    }
}
