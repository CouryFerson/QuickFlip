import SwiftUI

struct ModernHistoryItemCard: View {
    let item: ScannedItem
    let isEditMode: Bool
    let isSelected: Bool

    @EnvironmentObject var itemStorage: ItemStorageService

    var body: some View {
        HStack(spacing: 16) {
            // Selection circle (edit mode only)
            if isEditMode {
                selectionCircle
                    .transition(.scale.combined(with: .opacity))
            }

            // Item image
            itemImage

            // Item details
            itemDetails

            Spacer()

            // Right side info
            rightSideInfo
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected && isEditMode ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected && isEditMode ? Color.blue : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - View Components
private extension ModernHistoryItemCard {
    @ViewBuilder
    var selectionCircle: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                .frame(width: 24, height: 24)

            if isSelected {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)

                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }

    @ViewBuilder
    var itemImage: some View {
        CachedImageView.listItem(imageUrl: item.imageUrl)
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    var itemDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.itemName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            // Status badge
            ListingStatusBadge(status: item.listingStatus.status)

            // Category and condition
            HStack(spacing: 8) {
                if let categoryName = item.categoryName, !categoryName.isEmpty {
                    CategoryBadge(category: categoryName.shortForm)
                }

                if !item.condition.isEmpty {
                    ConditionBadge(condition: item.condition.shortForm)
                }
            }
        }
    }

    @ViewBuilder
    var rightSideInfo: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Price based on status
            priceDisplay

            // Additional info based on status
            statusSpecificInfo

            // Chevron
            if !isEditMode {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
    }

    @ViewBuilder
    var priceDisplay: some View {
        Group {
            if item.listingStatus.status == .sold {
                // Show sold price
                if let soldPrice = item.listingStatus.soldPrice {
                    Text("$\(String(format: "%.2f", soldPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            } else {
                // Show estimated value
                if let bestPrice = item.priceAnalysis.averagePrices.values.max() {
                    Text("$\(String(format: "%.0f", bestPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
    }

    @ViewBuilder
    var statusSpecificInfo: some View {
        Group {
            switch item.listingStatus.status {
            case .sold:
                soldInfo
            case .listed:
                listedInfo
            case .readyToList:
                readyToListInfo
            }
        }
    }

    @ViewBuilder
    var soldInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let profit = item.listingStatus.formattedNetProfit {
                Text(profit)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(item.listingStatus.profitColor)
            }

            if let marketplace = item.listingStatus.getSoldMarketplaceAsEnum() {
                Text(marketplace.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    var listedInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            let marketplaces = item.listingStatus.getListedMarketplacesAsEnum()
            if marketplaces.count == 1 {
                Text(marketplaces[0].rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            } else if marketplaces.count > 1 {
                Text("\(marketplaces.count) platforms")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }

            if let dateListed = item.listingStatus.dateListed {
                Text(daysAgoText(from: dateListed))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    var readyToListInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(item.priceAnalysis.recommendedMarketplace)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)

            Text("Suggested")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    func daysAgoText(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day ago"
        } else {
            return "\(days) days ago"
        }
    }
}

// MARK: - Supporting Badge Components (if not already defined)

struct CategoryBadge: View {
    let category: String

    var body: some View {
        Text(category)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct ConditionBadge: View {
    let condition: String

    var conditionColor: Color {
        switch condition.lowercased() {
        case "new", "mint":
            return .green
        case "excellent", "very good", "like new", "good":
            return .blue
        case "fair":
            return .orange
        case "poor", "used":
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        Text(condition)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(conditionColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(conditionColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct ListingStatusBadge: View {
    let status: ItemStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: 10))
            Text(status.rawValue)
                .font(.caption2)
        }
        .fontWeight(.medium)
        .foregroundColor(status.displayColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.displayColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - String Extension
extension String {
    var shortForm: String {
        let categoryMappings: [String: String] = [
            "Electronics": "Tech",
            "Clothing": "Clothes",
            "Collectibles": "Collect",
            "Home & Garden": "Home",
            "Sports & Outdoors": "Sports",
            "Health & Beauty": "Beauty",
            "Toys & Games": "Toys",
            "Books & Media": "Books",
            "Automotive": "Auto",
            "Musical Instruments": "Music"
        ]

        let conditionMappings: [String: String] = [
            "Brand New": "New",
            "Like New": "Like New",
            "Very Good": "Good",
            "Excellent": "Good",
            "Fair": "Used",
            "Poor": "Poor"
        ]

        if let shortCategory = categoryMappings[self] {
            return shortCategory
        }

        if let shortCondition = conditionMappings[self] {
            return shortCondition
        }

        return self.count > 8 ? String(self.prefix(8)) : self
    }
}
