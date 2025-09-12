//
//  HistoryCoordinator.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/20/25.
//

import SwiftUI

enum HistoryFlow: Hashable {
    case itemDetail(ScannedItem)
    case marketplaceSelection(ScannedItem)

    var id: Int {
        switch self {
        case .itemDetail:
            return 0
        case .marketplaceSelection:
            return 1
        }
    }

    static func == (lhs: HistoryFlow, rhs: HistoryFlow) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct HistoryCoordinator: View {
    @StateObject private var router = Router<HistoryFlow>()
    @EnvironmentObject private var appRouter: AppRouter

    public var body: some View {
        NavigationStack(path: $router.paths) {
            HistoryView { scannedItem in
                router.push(.itemDetail(scannedItem))
            } scanFirstItemAction: {
                appRouter.navigateToCapture()
            }
            .navigationDestination(for: HistoryFlow.self) { path in
                viewForPath(path)
            }
        }
    }

    // MARK: - Private Interface

    @ViewBuilder
    private func viewForPath(_ path: HistoryFlow) -> some View {
        switch path {
        case .itemDetail(let item):
            ItemDetailView(item: item) {
                router.push(.marketplaceSelection(item))
            }
        case .marketplaceSelection(let scannedImage):
            if let imageUrl = scannedImage.imageUrl,
               let image = ImageCacheManager.shared.loadImageFromDisk(url: imageUrl) {
                MarketplaceSelectionView(scannedItem: scannedImage, capturedImage: image)
            } else {
                Text("Something went wrong. Try again")
            }
        }
    }
}
