//
//  SettingsCoordinatorView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/29/25.
//

import SwiftUI

/// This is used for analytics
enum SettingsFlow: Hashable {
    case profile
    case subscription
    case privacy
    case storageUsage
    case backUPSettings
    case aiModel
    case marketplacePreferances
    case helpCenter
    case termsOfService

    var id: Int {
        switch self {
        case .profile:
            return 0
        case .subscription:
            return 1
        case .privacy:
            return 2
        case .storageUsage:
            return 3
        case .backUPSettings:
            return 4
        case .aiModel:
            return 5
        case .marketplacePreferances:
            return 6
        case .helpCenter:
            return 7
        case .termsOfService:
            return 8
        }
    }

    static func == (lhs: SettingsFlow, rhs: SettingsFlow) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct SettingsCoordinatorView: View {
    @StateObject private var router = Router<SettingsFlow>()

    public var body: some View {
        NavigationStack(path: $router.paths) {
            SettingsView(actions: SettingsActions(router: router))
                .navigationDestination(for: SettingsFlow.self) { path in
                    viewForPath(path)
                }
        }
    }

    // MARK: - Private Interface

    @ViewBuilder
    private func viewForPath(_ path: SettingsFlow) -> some View {
        switch path {
        case .profile:
            ProfileSettingsView()
        case .subscription:
            SubscriptionView()
        case .privacy:
            PrivacySettingsView()
        case .storageUsage:
            StorageUsageView()
        case .backUPSettings:
            BackupSettingsView()
        case .aiModel:
            AIModelSettingsView()
        case .marketplacePreferances:
            MarketplacePreferencesView()
        case .helpCenter:
            HelpCenterView()
        case .termsOfService:
            TermsOfServiceView()
        }
    }
}

struct SettingsActions {
    let router: Router<SettingsFlow>
    let actions: [SettingsFlow: () -> Void]

    init(router: Router<SettingsFlow>) {
        self.router = router
        self.actions = [.profile: { router.push(.profile) },
                        .subscription: { router.push(.subscription) },
                        .privacy: { router.push(.privacy) },
                        .storageUsage: { router.push(.storageUsage) },
                        .backUPSettings: { router.push(.backUPSettings) },
                        .aiModel: { router.push(.aiModel) },
                        .marketplacePreferances: { router.push(.marketplacePreferances) },
                        .helpCenter: { router.push(.helpCenter) },
                        .termsOfService: { router.push(.termsOfService )}]
    }
}
