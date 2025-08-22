//import SwiftUI
//
//struct BulkListingWorkflowView: View {
//    let savedItems: [ScannedItem]
//    let originalImage: UIImage
//    @EnvironmentObject var itemStorage: ItemStorageService
//    @Environment(\.presentationMode) var presentationMode
//    @State private var currentItemIndex = 0
//    @State private var completedListings: [ScannedItem] = []
//
//    var currentItem: ScannedItem {
//        savedItems[currentItemIndex]
//    }
//
//    var progress: Double {
//        return Double(currentItemIndex + 1) / Double(savedItems.count)
//    }
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                progressHeader
//                currentItemListing
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Done") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .itemListingCompleted)) { _ in
//            moveToNextItem()
//        }
//    }
//}
//
//// MARK: - View Components
//private extension BulkListingWorkflowView {
//    @ViewBuilder
//    private var progressHeader: some View {
//        VStack(spacing: 12) {
//            HStack {
//                Text("Creating Listings")
//                    .font(.title2)
//                    .fontWeight(.bold)
//
//                Spacer()
//
//                Text("\(currentItemIndex + 1) of \(savedItems.count)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//
//            ProgressView(value: progress)
//                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
//
//            Text(currentItem.itemName)
//                .font(.headline)
//                .multilineTextAlignment(.center)
//        }
//        .padding()
//        .background(Color.gray.opacity(0.05))
//    }
//
//    @ViewBuilder
//    private var currentItemListing: some View {
//        MarketplaceSelectionView(
//            scannedItem: currentItem,
//            capturedImage: currentItem.image!
//        )
//        .environmentObject(itemStorage)
//    }
//}
//
//// MARK: - Actions
//private extension BulkListingWorkflowView {
//    private func moveToNextItem() {
//        if currentItemIndex < savedItems.count - 1 {
//            withAnimation(.easeInOut(duration: 0.3)) {
//                currentItemIndex += 1
//            }
//        } else {
//            // All done!
//            showCompletionMessage()
//        }
//    }
//
//    private func showCompletionMessage() {
//        let alert = UIAlertController(
//            title: "All Listings Created!",
//            message: "You've successfully created \(savedItems.count) listings. Great work!",
//            preferredStyle: .alert
//        )
//
//        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
//            presentationMode.wrappedValue.dismiss()
//        })
//
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let window = windowScene.windows.first,
//           let rootVC = window.rootViewController {
//            rootVC.present(alert, animated: true)
//        }
//    }
//}
//
//// MARK: - Notification Extension
//extension Notification.Name {
//    static let itemListingCompleted = Notification.Name("itemListingCompleted")
//}
