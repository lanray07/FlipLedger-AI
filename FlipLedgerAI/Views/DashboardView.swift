import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Query(sort: \InventoryItem.createdAt, order: .reverse) private var items: [InventoryItem]
    @Query(sort: \SaleRecord.saleDate, order: .reverse) private var sales: [SaleRecord]
    @State private var viewModel = DashboardViewModel()
    @State private var activeSheet: DashboardSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                metricsGrid
                quickActions

                if !subscriptionService.hasProAccess {
                    Button {
                        activeSheet = .paywall
                    } label: {
                        UpgradeBanner(
                            title: "Free plan active",
                            message: "Free includes 25 inventory items and 10 sales/month. Upgrade when you need unlimited tracking, AI tools, and exports."
                        )
                    }
                    .buttonStyle(.plain)
                }

                recentInventory
                recentSales
                DisclaimerBox()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .addItem
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Item")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .addItem:
                    AddInventoryItemView()
                case .recordSale:
                    RecordSaleView()
                case .generateListing:
                    gatedAIView {
                        AIListingGeneratorView()
                    }
                case .profitCalculator:
                    ProfitCalculatorView()
                case .inventoryScan:
                    gatedAIView {
                        InventoryScannerView()
                    }
                case .exportReport:
                    ReportsExportView()
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private var metrics: DashboardMetrics {
        viewModel.metrics(
            items: items,
            sales: sales,
            subscriptionStatus: subscriptionService.currentPlan.rawValue
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's reseller snapshot")
                .font(.largeTitle.bold())
            Text("Track profit clearly, keep fees visible, and make better listing decisions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 12)], spacing: 12) {
            ProfitSummaryCard(
                title: "Total revenue",
                value: AppFormatters.currency(metrics.totalRevenue, code: currencyCode),
                subtitle: "Recorded sales",
                systemImage: "banknote"
            )
            ProfitSummaryCard(
                title: "Total profit",
                value: AppFormatters.currency(metrics.totalProfit, code: currencyCode),
                subtitle: "After tracked costs",
                systemImage: "arrow.up.right.circle",
                tint: metrics.totalProfit >= 0 ? Color.flipGreen : Color.red
            )
            ProfitSummaryCard(
                title: "Unsold value",
                value: AppFormatters.currency(metrics.unsoldInventoryValue, code: currencyCode),
                subtitle: "Inventory cost basis",
                systemImage: "shippingbox",
                tint: .blue
            )
            ProfitSummaryCard(
                title: "Sold items",
                value: "\(metrics.soldItems)",
                subtitle: "Best: \(metrics.bestCategory)",
                systemImage: "checkmark.seal",
                tint: .purple
            )
            ProfitSummaryCard(
                title: "Avg margin",
                value: AppFormatters.percent(metrics.averageProfitMargin),
                subtitle: "Estimated",
                systemImage: "percent",
                tint: .orange
            )
            ProfitSummaryCard(
                title: "Subscription",
                value: metrics.subscriptionStatus,
                subtitle: subscriptionService.hasProAccess ? "AI tools unlocked" : "Free plan limits apply",
                systemImage: "crown",
                tint: .flipGreen
            )
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                quickAction("Add Item", "plus.circle", .addItem)
                quickAction("Record Sale", "banknote", .recordSale)
                quickAction("Generate Listing", "sparkles", .generateListing)
                quickAction("Profit Calculator", "function", .profitCalculator)
                quickAction("Inventory Scan", "camera.viewfinder", .inventoryScan)
                quickAction("Export Report", "square.and.arrow.up", .exportReport)
            }
        }
    }

    private func quickAction(_ title: String, _ icon: String, _ sheet: DashboardSheet) -> some View {
        Button {
            activeSheet = sheet
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.flipGreen)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var recentInventory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent inventory")
                    .font(.headline)
                Spacer()
                NavigationLink("View all") {
                    InventoryListView()
                }
                .font(.subheadline)
            }

            if items.isEmpty {
                EmptyStateView(title: "No inventory yet", message: "Add your first item to start tracking purchase cost, target price, and sale profit.", systemImage: "shippingbox")
            } else {
                ForEach(items.prefix(3)) { item in
                    NavigationLink {
                        InventoryDetailView(item: item)
                    } label: {
                        InventoryItemCard(item: item, currencyCode: currencyCode)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentSales: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent sales")
                    .font(.headline)
                Spacer()
                NavigationLink("View all") {
                    SalesTrackerView()
                }
                .font(.subheadline)
            }

            if sales.isEmpty {
                EmptyStateView(title: "No sales recorded", message: "Record sales to see revenue, fees, shipping, and final profit.", systemImage: "banknote")
            } else {
                ForEach(sales.prefix(3)) { sale in
                    SaleRecordCard(sale: sale, currencyCode: currencyCode)
                }
            }
        }
    }

    @ViewBuilder
    private func gatedAIView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if subscriptionService.hasProAccess {
            content()
        } else {
            PaywallView()
        }
    }
}

private enum DashboardSheet: Identifiable {
    case addItem
    case recordSale
    case generateListing
    case profitCalculator
    case inventoryScan
    case exportReport
    case paywall

    var id: String {
        String(describing: self)
    }
}
