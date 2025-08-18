import SwiftUI

struct HistoryItemCard: View {
    let item: ScannedItem
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Item Image
                Group {
                    if let image = item.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)

                // Item Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.itemName)
                        .font(.headline)
                        .lineLimit(2)

                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(.blue)

                    HStack {
                        Text(item.condition)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)

                        Text(item.formattedTimestamp)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Price and Marketplace
                VStack(alignment: .trailing, spacing: 4) {
                    if let bestPrice = item.priceAnalysis.averagePrices.values.max() {
                        Text("$\(String(format: "%.2f", bestPrice))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    Text(item.priceAnalysis.recommendedMarketplace)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.trailing)

                    // Profit indicator if available
                    if let profitBreakdown = item.profitBreakdowns?.first {
                        Text(profitBreakdown.formattedNetProfit)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(profitBreakdown.profitColor)
                    }
                }
            }
            .padding()

            // Action Buttons Row
            HStack(spacing: 0) {
                // Re-analyze Button
                Button {
                    // TODO: Re-run price analysis
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-analyze")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Divider()
                    .frame(height: 20)

                // Share Button
                Button {
                    shareItem()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Divider()
                    .frame(height: 20)

                // Delete Button
                Button {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .background(Color.gray.opacity(0.05))
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                itemStorage.deleteItem(item)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(item.itemName)' from your history?")
        }
    }

    private func shareItem() {
        let bestPrice = item.priceAnalysis.averagePrices.values.max() ?? 0
        let shareText = """
        Check out this item I analyzed with QuickFlip:
        
        📱 \(item.itemName)
        💰 Best price: $\(String(format: "%.2f", bestPrice))
        🏪 Recommended marketplace: \(item.priceAnalysis.recommendedMarketplace)
        📅 Analyzed: \(item.formattedTimestamp)
        """

        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
