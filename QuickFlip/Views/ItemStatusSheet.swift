//
//  ItemStatusSheet.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/16/25.
//

import SwiftUI

// MARK: - Status Update Sheet Views

/// Sheet for marking item as listed
struct MarkAsListedSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedMarketplaces: Set<Marketplace> = []
    let item: ScannedItem
    let onSave: ([Marketplace]) -> Void

    var body: some View {
        NavigationView {
            marketplaceSelectionList
                .navigationTitle("Select Marketplaces")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        saveButton
                    }
                }
        }
        .onAppear {
            // Pre-select the recommended marketplace
            selectedMarketplaces.insert(item.priceAnalysis.toMarketplacePriceAnalysis().recommendedMarketplace)
        }
    }
}

private extension MarkAsListedSheet {
    @ViewBuilder
    var marketplaceSelectionList: some View {
        List {
            Section {
                ForEach(Marketplace.allCases, id: \.self) { marketplace in
                    marketplaceRow(for: marketplace)
                }
            } header: {
                Text("Where did you list this item?")
            } footer: {
                Text("Select all marketplaces where you've posted this item.")
            }
        }
    }

    @ViewBuilder
    func marketplaceRow(for marketplace: Marketplace) -> some View {
        Button {
            toggleMarketplace(marketplace)
        } label: {
            HStack {
                Text(marketplace.rawValue)
                    .foregroundColor(.primary)
                Spacer()
                if selectedMarketplaces.contains(marketplace) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
        }
    }

    @ViewBuilder
    var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
    }

    @ViewBuilder
    var saveButton: some View {
        Button("Save") {
            onSave(Array(selectedMarketplaces))
            dismiss()
        }
        .disabled(selectedMarketplaces.isEmpty)
        .fontWeight(.semibold)
    }

    func toggleMarketplace(_ marketplace: Marketplace) {
        if selectedMarketplaces.contains(marketplace) {
            selectedMarketplaces.remove(marketplace)
        } else {
            selectedMarketplaces.insert(marketplace)
        }
    }
}

// MARK: - Mark As Sold Sheet

/// Sheet for marking item as sold
struct MarkAsSoldSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var soldPrice: String = ""
    @State private var costBasis: String = ""
    @State private var selectedMarketplace: Marketplace?
    @FocusState private var focusedField: Field?

    let item: ScannedItem
    let onSave: (Double, Marketplace, Double?) -> Void

    enum Field {
        case soldPrice
        case costBasis
    }

    private var listedMarketplaces: [Marketplace] {
        item.listingStatus.getListedMarketplacesAsEnum()
    }

    private var canSave: Bool {
        guard let price = Double(soldPrice), price > 0 else { return false }
        guard selectedMarketplace != nil else { return false }
        return true
    }

    var body: some View {
        NavigationView {
            soldForm
                .navigationTitle("Mark as Sold")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        saveButton
                    }
                    ToolbarItem(placement: .keyboard) {
                        keyboardToolbar
                    }
                }
        }
        .onAppear {
            // Pre-select marketplace if only one option
            if listedMarketplaces.count == 1 {
                selectedMarketplace = listedMarketplaces.first
            }
        }
    }
}

private extension MarkAsSoldSheet {
    @ViewBuilder
    var soldForm: some View {
        Form {
            soldPriceSection
            marketplaceSection
            costBasisSection
            profitPreviewSection
        }
    }

    @ViewBuilder
    var soldPriceSection: some View {
        Section {
            HStack {
                Text("$")
                    .foregroundColor(.secondary)
                TextField("0.00", text: $soldPrice)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .soldPrice)
            }
        } header: {
            Text("Sold Price")
        } footer: {
            Text("Enter the final sale price")
        }
    }

    @ViewBuilder
    var marketplaceSection: some View {
        Section {
            if listedMarketplaces.isEmpty {
                Text("No marketplaces selected")
                    .foregroundColor(.secondary)
            } else {
                Picker("Marketplace", selection: $selectedMarketplace) {
                    Text("Select...").tag(nil as Marketplace?)
                    ForEach(listedMarketplaces, id: \.self) { marketplace in
                        Text(marketplace.rawValue).tag(marketplace as Marketplace?)
                    }
                }
            }
        } header: {
            Text("Where did it sell?")
        }
    }

    @ViewBuilder
    var costBasisSection: some View {
        Section {
            HStack {
                Text("$")
                    .foregroundColor(.secondary)
                TextField("0.00 (Optional)", text: $costBasis)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .costBasis)
            }
        } header: {
            Text("What You Paid (Optional)")
        } footer: {
            Text("Add what you originally paid to calculate profit")
        }
    }

    @ViewBuilder
    var profitPreviewSection: some View {
        if let soldAmount = Double(soldPrice),
           let costAmount = Double(costBasis),
           soldAmount > 0,
           costAmount > 0 {
            Section {
                HStack {
                    Text("Estimated Profit")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatProfit(soldAmount - costAmount))
                        .fontWeight(.semibold)
                        .foregroundColor(soldAmount >= costAmount ? .green : .red)
                }
            }
        }
    }

    @ViewBuilder
    var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
    }

    @ViewBuilder
    var saveButton: some View {
        Button("Save") {
            saveSoldData()
        }
        .disabled(!canSave)
        .fontWeight(.semibold)
    }

    @ViewBuilder
    var keyboardToolbar: some View {
        HStack {
            Spacer()
            Button("Done") {
                focusedField = nil
            }
        }
    }

    func saveSoldData() {
        guard let price = Double(soldPrice),
              let marketplace = selectedMarketplace else { return }

        let cost = Double(costBasis)
        onSave(price, marketplace, cost)
        dismiss()
    }

    func formatProfit(_ amount: Double) -> String {
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", amount))"
    }
}
