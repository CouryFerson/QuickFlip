//
//  PrivacySettingsView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 9/18/25.
//

import SwiftUI
import AVFoundation

struct PrivacySettingsView: View {
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showingClearDataAlert = false
    @State private var showingExportSheet = false

    var body: some View {
        List {
            appPermissionsSection
            dataInformationSection
            dataControlSection
            legalSection
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkCameraPermission()
        }
        .alert("Clear Scan History", isPresented: $showingClearDataAlert) {
            Button("Clear", role: .destructive) {
                clearScanHistory()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your scanned items and analysis results. This action cannot be undone.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
                .environmentObject(itemStorage)
        }
    }
}

// MARK: - View Sections
private extension PrivacySettingsView {

    @ViewBuilder
    var appPermissionsSection: some View {
        Section("App Permissions") {
            cameraPermissionRow
        }
    }

    @ViewBuilder
    var cameraPermissionRow: some View {
        HStack {
            Label("Camera", systemImage: "camera")

            Spacer()

            permissionStatusView
        }
    }

    @ViewBuilder
    var permissionStatusView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(cameraPermissionStatusText)
                .foregroundColor(cameraPermissionColor)
                .font(.subheadline)

            if cameraPermissionStatus == .denied {
                Button("Open Settings") {
                    openAppSettings()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }

    @ViewBuilder
    var dataInformationSection: some View {
        Section("Data We Collect") {
            dataCollectionInfo
        }
    }

    @ViewBuilder
    var dataCollectionInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            scannedItemsInfo
            analysisResultsInfo
            userPreferencesInfo
            dataStorageInfo
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    var scannedItemsInfo: some View {
        dataInfoRow(
            icon: "camera.viewfinder",
            title: "Scanned Items",
            description: "Photos and details of items you scan for analysis"
        )
    }

    @ViewBuilder
    var analysisResultsInfo: some View {
        dataInfoRow(
            icon: "chart.bar.doc.horizontal",
            title: "Analysis Results",
            description: "AI-generated price analysis and marketplace insights"
        )
    }

    @ViewBuilder
    var userPreferencesInfo: some View {
        dataInfoRow(
            icon: "gearshape",
            title: "User Preferences",
            description: "Your app settings, display name, and subscription info"
        )
    }

    @ViewBuilder
    var dataStorageInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Storage")
                .font(.subheadline)
                .fontWeight(.medium)

            Text("Your data is securely stored using Supabase and is only accessible by you. We do not share your personal data with third parties.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    func dataInfoRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }

    @ViewBuilder
    var dataControlSection: some View {
        Section("Data Control") {
            exportDataRow
            clearScanHistoryRow
            deleteAccountRow
        }
    }

    @ViewBuilder
    var exportDataRow: some View {
        Button {
            showingExportSheet = true
        } label: {
            HStack {
                Label("Export My Data", systemImage: "square.and.arrow.up")
                    .foregroundColor(.blue)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    var clearScanHistoryRow: some View {
        Button {
            showingClearDataAlert = true
        } label: {
            Label("Clear Scan History", systemImage: "trash")
                .foregroundColor(.orange)
        }
    }

    @ViewBuilder
    var deleteAccountRow: some View {
        NavigationLink(destination: ProfileSettingsView()) {
            Label("Delete Account", systemImage: "person.badge.minus")
                .foregroundColor(.red)
        }
    }

    @ViewBuilder
    var legalSection: some View {
        Section("Legal") {
            termsOfUseRow
            privacyPolicyRow
        }
    }

    @ViewBuilder
    var termsOfUseRow: some View {
        Button {
            openTermsOfUse()
        } label: {
            HStack {
                Label("Terms of Use", systemImage: "doc.text")
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    var privacyPolicyRow: some View {
        Button {
            openPrivacyPolicy()
        } label: {
            HStack {
                Label("Privacy Policy", systemImage: "doc.text")
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Methods
private extension PrivacySettingsView {

    var cameraPermissionStatusText: String {
        switch cameraPermissionStatus {
        case .authorized:
            return "Granted"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Requested"
        @unknown default:
            return "Unknown"
        }
    }

    var cameraPermissionColor: Color {
        switch cameraPermissionStatus {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }

    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    func clearScanHistory() {
        Task {
            await itemStorage.clearAllData()
        }
    }

    func openTermsOfUse() {
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            UIApplication.shared.open(url)
        }
    }

    func openPrivacyPolicy() {
        if let url = URL(string: "https://quikflip.netlify.app/privacy-policy") {
            UIApplication.shared.open(url)
        }
    }
}
