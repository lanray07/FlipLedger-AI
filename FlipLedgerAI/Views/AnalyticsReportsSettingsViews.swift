import Charts
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Query(sort: \InventoryItem.createdAt, order: .reverse) private var items: [InventoryItem]
    @Query(sort: \SaleRecord.saleDate, order: .reverse) private var sales: [SaleRecord]
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        Group {
            if subscriptionService.hasProAccess {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if sales.isEmpty {
                            EmptyStateView(title: "Analytics need sales", message: "Record sales to see marketplace profit, categories, brands, monthly revenue, and ROI by sourcing source.", systemImage: "chart.xyaxis.line")
                        } else {
                            headlineMetrics
                            profitByMarketplace
                            profitByCategory
                            monthlyRevenue
                            monthlyProfit
                            bestBrands
                            sourcingROI
                        }

                        slowMovingInventory
                        NavigationLink {
                            ReportsExportView()
                        } label: {
                            Label("Reports and export", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.flipGreen)

                        DisclaimerBox()
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            } else {
                PaywallView()
            }
        }
        .navigationTitle("Analytics")
    }

    private var headlineMetrics: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
            ProfitSummaryCard(
                title: "Average days to sell",
                value: String(format: "%.0f days", viewModel.averageDaysToSell(sales: sales)),
                subtitle: "Based on purchase date",
                systemImage: "calendar"
            )
            ProfitSummaryCard(
                title: "Monthly profit",
                value: AppFormatters.currency(viewModel.monthlyProfit(sales: sales).last?.value ?? 0, code: currencyCode),
                subtitle: "Latest tracked month",
                systemImage: "chart.line.uptrend.xyaxis"
            )
        }
    }

    private var profitByMarketplace: some View {
        AnalyticsChartCard("Profit by marketplace", subtitle: "Estimated final profit") {
            Chart(viewModel.profitByMarketplace(sales: sales)) { point in
                BarMark(
                    x: .value("Marketplace", point.label),
                    y: .value("Profit", point.value)
                )
                .foregroundStyle(Color.flipGreen)
            }
            .chartYAxisLabel("Profit")
        }
    }

    private var profitByCategory: some View {
        AnalyticsChartCard("Profit by category", subtitle: "Spot which products make money") {
            Chart(viewModel.profitByCategory(sales: sales)) { point in
                BarMark(
                    x: .value("Category", point.label),
                    y: .value("Profit", point.value)
                )
                .foregroundStyle(Color.blue)
            }
            .chartYAxisLabel("Profit")
        }
    }

    private var monthlyRevenue: some View {
        AnalyticsChartCard("Monthly revenue", subtitle: "Sale price before costs") {
            Chart(viewModel.monthlyRevenue(sales: sales)) { point in
                LineMark(
                    x: .value("Month", point.label),
                    y: .value("Revenue", point.value)
                )
                .foregroundStyle(Color.flipGreen)
                PointMark(
                    x: .value("Month", point.label),
                    y: .value("Revenue", point.value)
                )
                .foregroundStyle(Color.flipGreen)
            }
        }
    }

    private var monthlyProfit: some View {
        AnalyticsChartCard("Monthly profit", subtitle: "After tracked costs") {
            Chart(viewModel.monthlyProfit(sales: sales)) { point in
                LineMark(
                    x: .value("Month", point.label),
                    y: .value("Profit", point.value)
                )
                .foregroundStyle(Color.orange)
                AreaMark(
                    x: .value("Month", point.label),
                    y: .value("Profit", point.value)
                )
                .foregroundStyle(Color.orange.opacity(0.18))
            }
        }
    }

    private var bestBrands: some View {
        AnalyticsChartCard("Best-selling brands", subtitle: "Count of recorded sales") {
            Chart(viewModel.bestSellingBrands(sales: sales).prefix(8).map { $0 }) { point in
                BarMark(
                    x: .value("Sales", point.value),
                    y: .value("Brand", point.label)
                )
                .foregroundStyle(Color.purple)
            }
        }
    }

    private var sourcingROI: some View {
        AnalyticsChartCard("ROI by sourcing source", subtitle: "Profit compared with item cost") {
            Chart(viewModel.roiBySource(sales: sales).prefix(8).map { $0 }) { point in
                BarMark(
                    x: .value("Source", point.label),
                    y: .value("ROI", point.value)
                )
                .foregroundStyle(Color.teal)
            }
        }
    }

    private var slowMovingInventory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Slow-moving inventory")
                .font(.headline)
            let slowItems = viewModel.slowMovingInventory(items: items)
            if slowItems.isEmpty {
                Text("No unsold inventory yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(slowItems) { item in
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
}

struct ReportsExportView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Query(sort: \InventoryItem.createdAt, order: .reverse) private var items: [InventoryItem]
    @Query(sort: \SaleRecord.saleDate, order: .reverse) private var sales: [SaleRecord]
    @State private var shareableURL: ShareableURL?
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        List {
            Section {
                if !subscriptionService.hasProAccess {
                    NavigationLink {
                        PaywallView()
                    } label: {
                        UpgradeBanner(title: "Exports are a Pro feature", message: "Free reports include FlipLedger AI footer placeholders. Upgrade for full CSV/PDF export workflows.")
                    }
                }
            }

            Section("Reports") {
                Button {
                    exportPDF()
                } label: {
                    Label("PDF profit report", systemImage: "doc.richtext")
                }

                Button {
                    exportPDF()
                } label: {
                    Label("Monthly reseller report", systemImage: "calendar")
                }

                Button {
                    exportPDF()
                } label: {
                    Label("Inventory valuation report", systemImage: "shippingbox")
                }

                Button {
                    exportPDF()
                } label: {
                    Label("Tax-prep summary placeholder", systemImage: "folder")
                }
            }

            Section("CSV") {
                Button {
                    exportInventoryCSV()
                } label: {
                    Label("Inventory CSV", systemImage: "tablecells")
                }
                .disabled(!subscriptionService.hasProAccess)

                Button {
                    exportSalesCSV()
                } label: {
                    Label("Sales CSV", systemImage: "tablecells.badge.ellipsis")
                }
                .disabled(!subscriptionService.hasProAccess)
            }

            if isWorking {
                Section {
                    ProgressView("Preparing export")
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Text(DisclaimerText.short)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Reports")
        .sheet(item: $shareableURL) { item in
            ShareSheet(activityItems: [item.url])
        }
    }

    private func exportPDF() {
        doExport {
            try ExportService.exportProfitReportPDF(
                items: items,
                sales: sales,
                currencyCode: currencyCode,
                includeFooter: !subscriptionService.hasProAccess
            )
        }
    }

    private func exportInventoryCSV() {
        guard subscriptionService.hasProAccess else { return }
        doExport {
            try ExportService.exportInventoryCSV(items: items, currencyCode: currencyCode)
        }
    }

    private func exportSalesCSV() {
        guard subscriptionService.hasProAccess else { return }
        doExport {
            try ExportService.exportSalesCSV(sales: sales, currencyCode: currencyCode)
        }
    }

    private func doExport(_ work: () throws -> URL) {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            shareableURL = ShareableURL(url: try work())
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section("Subscription") {
                HStack {
                    Text("Current plan")
                    Spacer()
                    Text(subscriptionService.currentPlan.rawValue)
                        .foregroundStyle(.secondary)
                }
                NavigationLink {
                    PaywallView()
                } label: {
                    Label("Manage subscription", systemImage: "crown")
                }
            }

            Section("Preferences") {
                Picker("Currency", selection: $currencyCode) {
                    ForEach(CurrencyCode.allCases) { currency in
                        Text(currency.rawValue).tag(currency.rawValue)
                    }
                }

                NavigationLink {
                    MarketplaceFeeSettingsView()
                } label: {
                    Label("Marketplace fee settings", systemImage: "percent")
                }
            }

            Section("Data") {
                NavigationLink {
                    ReportsExportView()
                } label: {
                    Label("Export data", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete all local data", systemImage: "trash")
                }
            }

            Section("Legal") {
                NavigationLink("Privacy policy") {
                    LegalTextView(title: "Privacy Policy", lines: [
                        "FlipLedger AI stores inventory, sales, listing drafts, and settings locally with SwiftData.",
                        "Do not store API keys in the iOS app. Remote AI requests should go through your own secure backend.",
                        "Photos are stored locally unless you later connect a backend."
                    ])
                }
                NavigationLink("Terms of use") {
                    LegalTextView(title: "Terms of Use", lines: [
                        "Use FlipLedger AI as an organizational and estimation tool.",
                        "You are responsible for verifying fees, shipping, taxes, marketplace rules, and listing accuracy.",
                        "AI outputs require review before use."
                    ])
                }
                NavigationLink("AI disclaimer") {
                    LegalTextView(title: "AI Disclaimer", lines: DisclaimerText.full)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Delete all local data?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAllLocalData()
            }
        } message: {
            Text("This removes local inventory, photos, sales, listing drafts, marketplace settings, and subscription cache records.")
        }
    }

    private func deleteAllLocalData() {
        do {
            for photo in try modelContext.fetch(FetchDescriptor<ItemPhoto>()) {
                modelContext.delete(photo)
            }
            for sale in try modelContext.fetch(FetchDescriptor<SaleRecord>()) {
                modelContext.delete(sale)
            }
            for draft in try modelContext.fetch(FetchDescriptor<ListingDraft>()) {
                modelContext.delete(draft)
            }
            for item in try modelContext.fetch(FetchDescriptor<InventoryItem>()) {
                modelContext.delete(item)
            }
            for setting in try modelContext.fetch(FetchDescriptor<MarketplaceSettings>()) {
                modelContext.delete(setting)
            }
            for state in try modelContext.fetch(FetchDescriptor<SubscriptionState>()) {
                modelContext.delete(state)
            }
            try modelContext.save()
        } catch {
            assertionFailure("Unable to delete local data: \(error)")
        }
    }
}

struct MarketplaceFeeSettingsView: View {
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MarketplaceSettings.marketplaceName) private var settings: [MarketplaceSettings]

    var body: some View {
        List {
            if settings.isEmpty {
                Section {
                    EmptyStateView(title: "No fee defaults", message: "Seed marketplace defaults to estimate fees faster.", systemImage: "percent")
                    Button("Seed defaults") {
                        DefaultDataSeeder.seedMarketplaceSettingsIfNeeded(in: modelContext, currencyCode: currencyCode)
                    }
                }
            } else {
                Section {
                    ForEach(settings) { setting in
                        MarketplaceFeeRow(setting: setting)
                    }
                } footer: {
                    Text("Fee defaults are estimates. Check the current marketplace fee pages before making final pricing decisions.")
                }
            }
        }
        .navigationTitle("Fee Settings")
    }
}

struct MarketplaceFeeRow: View {
    @Bindable var setting: MarketplaceSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(setting.marketplaceName)
                .font(.headline)
            HStack {
                TextField("Fee %", value: $setting.defaultFeePercentage, format: .number)
                    .keyboardType(.decimalPad)
                Text("%")
                    .foregroundStyle(.secondary)
                TextField("Fixed fee", value: $setting.fixedFee, format: .number)
                    .keyboardType(.decimalPad)
            }
            .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 6)
    }
}

struct LegalTextView: View {
    var title: String
    var lines: [String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(title)
    }
}
