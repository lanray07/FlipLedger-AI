import SwiftData
import SwiftUI

@main
struct FlipLedgerAIApp: App {
    private let modelContainer: ModelContainer
    @State private var subscriptionService = SubscriptionService()

    init() {
        let schema = Schema([
            InventoryItem.self,
            ItemPhoto.self,
            SaleRecord.self,
            MarketplaceSettings.self,
            ListingDraft.self,
            SubscriptionState.self
        ])

        let configuration = ModelConfiguration(
            "FlipLedgerLocalStore",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create FlipLedger AI SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.aiService, MockAIService())
                .environment(subscriptionService)
                .task {
                    await subscriptionService.loadProducts()
                    await subscriptionService.updatePurchasedProducts()
                }
        }
        .modelContainer(modelContainer)
    }
}
