//
//  PricingDisclaimerSheet.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/4/25.
//
import SwiftUI

struct PricingDisclaimerView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    howPricingWorksSection
                    importantDisclaimersSection

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("About Pricing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Pricing Disclaimer Components
private extension PricingDisclaimerView {

    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("Marketplace & Pricing Analysis")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Understanding how we determine the best marketplace and estimate prices")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    var howPricingWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.headline)
                .fontWeight(.semibold)

            infoCard(
                icon: "chart.line.uptrend.xyaxis",
                color: .blue,
                title: "Historical Data Analysis",
                description: "Our AI analyzes recent comparable sales, market trends, and historical pricing data from multiple marketplaces to generate accurate estimates."
            )

            infoCard(
                icon: "storefront",
                color: .green,
                title: "Best Marketplace Selection",
                description: "We evaluate factors like item category, typical selling prices, platform fees, buyer demographics, and historical success rates to recommend the optimal marketplace."
            )

            infoCard(
                icon: "clock.arrow.circlepath",
                color: .orange,
                title: "Data Freshness",
                description: "Pricing estimates are based on recent market data and trends, but are not real-time. Market conditions can change quickly based on demand, seasonality, and other factors."
            )
        }
    }

    @ViewBuilder
    func infoCard(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    @ViewBuilder
    var importantDisclaimersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)

                Text("Important Disclaimers")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 12) {
                disclaimerRow(
                    icon: "chart.bar.fill",
                    text: "Prices are estimates only. Actual selling prices may vary significantly based on real-time market conditions, buyer demand, item condition, and timing."
                )

                disclaimerRow(
                    icon: "arrow.clockwise",
                    text: "Estimates are not real-time. While we use recent data and trends, marketplace prices can fluctuate daily. Always check current listings before pricing your item."
                )

                disclaimerRow(
                    icon: "checkmark.shield.fill",
                    text: "Verify independently. We recommend researching current active listings and recently sold items on your chosen platform before finalizing your price."
                )

                disclaimerRow(
                    icon: "building.columns.fill",
                    text: "No guarantees. Our recommendations are educated estimates based on data analysis, not guarantees of selling price or marketplace performance."
                )

                disclaimerRow(
                    icon: "person.crop.circle.badge.checkmark",
                    text: "Use as a starting point. These insights are designed to help you make informed decisions, but your judgment and research are essential for optimal results."
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    @ViewBuilder
    func disclaimerRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.orange)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
