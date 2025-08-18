//
//  Untitled.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct BulkListingWorkflowView: View {
    let selectedItems: [BulkAnalyzedItem]
    let originalImage: UIImage
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @State private var currentItemIndex = 0
    @State private var completedListings: [ScannedItem] = []

    var currentItem: BulkAnalyzedItem {
        selectedItems[currentItemIndex]
    }

    var progress: Double {
        return Double(currentItemIndex + 1) / Double(selectedItems.count)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Creating Listings")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Text("\(currentItemIndex + 1) of \(selectedItems.count)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))

                    Text(currentItem.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.05))

                // Current Item Analysis
                MarketplaceSelectionView(
                    itemAnalysis: currentItem.toItemAnalysis(),
                    capturedImage: originalImage
                )
                .environmentObject(itemStorage)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .itemListingCompleted)) { _ in
            // Move to next item or finish
            if currentItemIndex < selectedItems.count - 1 {
                currentItemIndex += 1
            } else {
                // All done!
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let itemListingCompleted = Notification.Name("itemListingCompleted")
}
