//
//  ProfileSettingsView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 9/17/25.
//

import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var displayName = ""
    @State private var isEditingName = false
    @State private var showingDeleteAlert = false
    @State private var showingExportSheet = false
    @State private var isLoading = false

    var body: some View {
        List {
            personalInfoSection
            accountInfoSection
            accountActionsSection
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserProfile()
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
        }
    }
}

// MARK: - View Sections
private extension ProfileSettingsView {

    @ViewBuilder
    var personalInfoSection: some View {
        Section("Personal Information") {
            displayNameRow
        }
    }

    @ViewBuilder
    var displayNameRow: some View {
        HStack {
            Label("Display Name", systemImage: "person.text.rectangle")

            Spacer()

            if isEditingName {
                TextField("Enter name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 150)

                Button("Save") {
                    saveDisplayName()
                }
                .font(.caption)
                .foregroundColor(.blue)
                .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)

//                Button("Cancel") {
//                    cancelEditingName()
//                }
                .font(.caption)
                .foregroundColor(.red)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(displayName.isEmpty ? "Not set" : displayName)
                        .foregroundColor(displayName.isEmpty ? .gray : .primary)

                    Button("Edit") {
                        isEditingName = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }

    @ViewBuilder
    var accountInfoSection: some View {
        Section("Account Information") {
            emailRow
            memberSinceRow
            accountStatsRow
        }
    }

    @ViewBuilder
    var emailRow: some View {
        HStack {
            Label("Email", systemImage: "envelope")

            Spacer()

            Text(userEmail)
                .foregroundColor(.gray)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    var memberSinceRow: some View {
        HStack {
            Label("Member Since", systemImage: "calendar")

            Spacer()

            Text(memberSinceDate)
                .foregroundColor(.gray)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    var accountStatsRow: some View {
        HStack {
            Label("Current Plan", systemImage: "crown")

            Spacer()

            if let currentTier = subscriptionManager.currentTier {
                Text(currentTier.tierName.capitalized)
                    .foregroundColor(.gray)
                    .font(.subheadline)
            } else {
                Text("Free")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    var accountActionsSection: some View {
        Section("Account Actions") {
            exportDataRow
            // TODO: Add when ready to delete accounts
//            deleteAccountRow
        }
    }

    @ViewBuilder
    var exportDataRow: some View {
        Button {
            showingExportSheet = true
        } label: {
            Label("Export My Data", systemImage: "square.and.arrow.up")
                .foregroundColor(.blue)
        }
    }

    @ViewBuilder
    var deleteAccountRow: some View {
        Button {
            showingDeleteAlert = true
        } label: {
            Label("Delete Account", systemImage: "trash")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Helper Methods
private extension ProfileSettingsView {

    var userEmail: String {
        // Get from AuthManager - this would be the Apple ID email
        return authManager.userEmail ?? "Not available"
    }

    var memberSinceDate: String {
        // Format the account creation date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return formatter.string(from: authManager.currentUser?.createdAt ?? Date())
    }

    func loadUserProfile() {
        displayName = authManager.userName
    }

    func saveDisplayName() {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isLoading = true

        Task {
            do {
                print("display name \(displayName)")
                try await authManager.updateUserDisplayName(displayName)

                await MainActor.run {
                    isEditingName = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Handle error - maybe show an alert
                    isLoading = false
                }
            }
        }
    }

    func deleteAccount() {
        Task {
            do {
                // This would:
                // 1. Delete user_profiles record
                // 2. Delete from Supabase auth
                // 3. Sign out locally
                // TODO: Add delete functionality to SupabaseService
//                try await authManager.deleteAccount()
            } catch {
                // Handle error
                print("Failed to delete account: \(error)")
            }
        }
    }
}

