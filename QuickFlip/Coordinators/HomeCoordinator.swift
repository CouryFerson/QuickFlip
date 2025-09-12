//
//  HomeCoordinator.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/19/25.
//

// Copyright © 2024 Walt Disney Media and Entertainment Distribution. All rights reserved.

import SwiftUI

/// This is used for analytics
enum HomeFlow: Hashable {
    case marketInsights(MarketTrends?, PersonalInsights?, Bool, Bool, () -> Void)

    var id: Int {
        switch self {
        case .marketInsights:
            return 0
        }
    }

    static func == (lhs: HomeFlow, rhs: HomeFlow) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct HomeCoordinatorView: View {
    @StateObject private var router = Router<HomeFlow>()
    @EnvironmentObject private var appRouter: AppRouter

    public var body: some View {
        NavigationStack(path: $router.paths) {
            EnhancedHomeView { trends, insights, isTrendsLoading, isInsightsLoading, block in
                router.push(.marketInsights(trends, insights, isTrendsLoading, isInsightsLoading, block))
            } scanItemAction: {
                appRouter.navigateToCapture()
            } viewAllScansAction: {
                appRouter.navigateToHistory()
            }
            .navigationDestination(for: HomeFlow.self) { path in
                viewForPath(path)
            }
        }
    }

    // MARK: - Private Interface

    @ViewBuilder
    private func viewForPath(_ path: HomeFlow) -> some View {
        switch path {
        case .marketInsights(let trends, let insights, let isLoadingTrends, let isLoadingPersonal, let block):
            FullMarketInsightsView(trends: trends, personalInsights: insights, isLoadingTrends: isLoadingTrends, isLoadingPersonal: isLoadingPersonal, onRefresh: block)
        }
    }
}

final class Router<T: Hashable>: ObservableObject {
    @Published var paths: [T] = []

    // MARK: - Public Interface

    func push(_ path: T) {
        paths.append(path)
    }

    func popToRoot() {
        paths.removeAll()
    }

    func pop() {
        paths.removeLast()
    }

    func replace(with path: T) {
        if paths.count > 0 { pop() }
        push(path)
    }
}
