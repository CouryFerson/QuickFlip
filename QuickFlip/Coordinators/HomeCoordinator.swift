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
    case marketInsights(MarketTrends?, PersonalInsights?, Bool, Bool)
    case viewDeals
    case quikList

    var id: Int {
        switch self {
        case .marketInsights:
            return 0
        case .viewDeals:
            return 1
        case .quikList:
            return 2
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
    @EnvironmentObject private var supabaseService: SupabaseService

    public var body: some View {
        NavigationStack(path: $router.paths) {
            EnhancedHomeView { trends, insights, isTrendsLoading, isInsightsLoading in
                router.push(.marketInsights(trends, insights, isTrendsLoading, isInsightsLoading))
            } scanItemAction: {
                appRouter.navigateToCapture()
            } viewAllScansAction: {
                appRouter.navigateToHistory()
            } viewDealsActions: {
                router.push(.viewDeals)
            } quikListAction: {
                router.push(.quikList)
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
        case .marketInsights(let trends, let insights, let isLoadingTrends, let isLoadingPersonal):
            FullMarketInsightsView(trends: trends, personalInsights: insights, isLoadingTrends: isLoadingTrends, isLoadingPersonal: isLoadingPersonal)
        case .viewDeals:
            MarketplaceDealsWebView(
                marketplaceURL: URL(string: "https://www.ebay.com/deals")!,
                marketplaceName: "eBay"
            )
        case .quikList:
            QuikListView(supabaseService: supabaseService)
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
