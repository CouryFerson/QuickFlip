//
//  ItemDetailView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/21/25.
//

import SwiftUI

struct ItemDetailView: View {
    let item: ScannedItem
    let marketplaceAction: () -> Void
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var marketPriceService = eBayMarketPriceService()
    @State private var showingActionSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var imageScale: CGFloat = 1.0
    @State private var marketData: MarketPriceData?

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Hero Image Section
                    ZStack {
                        if let imageURL = item.imageUrl {
                            CachedImageView.detail(width: geometry.size.width, imageUrl: imageURL)
                                .clipped()
                                .scaleEffect(imageScale)
                                .animation(.easeInOut(duration: 0.3), value: imageScale)
                        } else {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 400)
                                .overlay {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                        Text("No Image")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                    }
                                }
                        }

                        // Gradient overlay for better text readability
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.3)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            imageScale = imageScale == 1.0 ? 1.05 : 1.0
                        }
                    }

                        // Content Section
                        VStack(spacing: 0) {
                            // Header Info
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(item.itemName)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.leading)

                                        HStack(spacing: 12) {
                                            if let categoryName = item.categoryName {
                                                CategoryBadge(category: categoryName)
                                            }
                                            ConditionBadge(condition: item.condition)
                                            Spacer()
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                            // Description Section
                            if !item.description.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Description")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }

                                    Text(item.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .lineSpacing(2)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                            }

                            chartView

                            // Quick Actions Section
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Quick Actions")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }

                                HStack(spacing: 12) {
                                    // Status Button

                                    statusButton
                                    Spacer()
                                    deleteButton
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 32)

                            marketplaceButton
                        }
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .offset(y: -24)
                    }
                }
                .ignoresSafeArea(.container, edges: .top)
                .confirmationDialog("Update Status", isPresented: $showingActionSheet, titleVisibility: .visible) {
                    Button("Mark as Listed") {
                        // Handle mark as listed
                    }
                    Button("Mark as Sold") {
                        // Handle mark as sold
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .alert("Delete Item", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        itemStorage.deleteItem(item)
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to delete this item? This action cannot be undone.")
                }
                .sheet(isPresented: $showingShareSheet) {
                    if let imageURL = item.imageUrl {
                        CachedImageView.listItem(imageUrl: imageURL)
                    } else {
                        ShareSheet(items: [item.itemName])
                    }
                }
                .task {
                    marketData = try? await marketPriceService.fetchMarketPrices(for: item.itemName, category: item.category)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }


    private func getStatusIcon() -> String {
        // You can extend this based on item status
        return "circle.fill"
    }

    private func getStatusText() -> String {
        // You can extend this based on item status
        return "Update Status"
    }

    private func getStatusColor() -> Color {
        // You can extend this based on item status
        return .green
    }
}

private extension ItemDetailView {
    private var marketplaceButton: some View {
        // List Item Button at bottom of ScrollView
        Button(action: marketplaceAction) {
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("List Item")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 34)
    }

    private var deleteButton: some View {
        Button(action: { showingDeleteAlert = true }) {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                Text("Delete")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.red)
            .clipShape(Capsule())
        }
    }

    private var statusButton: some View {
        Button(action: { showingActionSheet = true }) {
            HStack(spacing: 8) {
                Image(systemName: getStatusIcon())
                    .font(.system(size: 16, weight: .medium))
                Text(getStatusText())
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(getStatusColor())
            .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var chartView: some View {
        if marketPriceService.isLoading {
            MarketPriceLoadingView()
        } else if let error = marketPriceService.lastError {
            MarketPriceErrorView(errorMessage: error) {
                Task {
                    marketData = try? await marketPriceService.fetchMarketPrices(for: item.itemName, category: item.category)
                }
            }
        } else if let marketData = marketData {
            MarketPriceChartView(marketData: marketData)
        }
    }
}
