//
//  CaptureCoordinator.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/19/25.
//

import SwiftUI

enum CaptureFlow: Hashable {
    case singleCapture
    case bulkCapture
    case bulkAnalysis(BulkAnalysisResult)
    case barcodeCapture
    case marketplaceSelection(ScannedItem, UIImage)

    var id: Int {
        switch self {
        case .singleCapture:
            return 0
        case .bulkCapture:
            return 1
        case .bulkAnalysis:
            return 2
        case .barcodeCapture:
            return 3
        case .marketplaceSelection:
            return 4
        }
    }

    static func == (lhs: CaptureFlow, rhs: CaptureFlow) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct CaptureCoordinatorView: View {
    @StateObject private var router = Router<CaptureFlow>()

    public var body: some View {
        NavigationStack(path: $router.paths) {
            CaptureView(captureSingleItemAction: {
                router.push(.singleCapture)
            }, captureBulktemsAction: {
                router.push(.bulkCapture)
            }, captureBarcodeAction: {
                router.push(.barcodeCapture)
            })
            .navigationDestination(for: CaptureFlow.self) { path in
                viewForPath(path)
            }
        }
    }
}

// MARK: - Private Interface

extension CaptureCoordinatorView {
    @ViewBuilder
    private func viewForPath(_ path: CaptureFlow) -> some View {
        switch path {
        case .singleCapture:
            CameraView { analysis, image in
                router.push(.marketplaceSelection(analysis, image))
            }
        case .bulkCapture:
            BulkCameraView { result in
                router.push(.bulkAnalysis(result))
            }
        case .barcodeCapture:
            BarcodeCameraView { scannedItem, image in
                router.push(.marketplaceSelection(scannedItem, image))
            }
        case .marketplaceSelection(let scannedItem, let image):
            MarketplaceSelectionView(scannedItem: scannedItem, capturedImage: image)
        case .bulkAnalysis(let analysis):
            BulkAnalysisResultsView(result: analysis) { scannedItem, image in
                router.push(.marketplaceSelection(scannedItem, image))
            } doneAction: {
                router.popToRoot()
            }
        }
    }
}
