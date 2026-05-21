import SwiftData
import SwiftUI

struct ProfitCalculatorView: View {
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @State private var viewModel = ProfitCalculatorViewModel()

    var body: some View {
        Form {
            Section("Inputs") {
                moneyField("Purchase price", value: $viewModel.purchasePrice)
                moneyField("Selling price", value: $viewModel.sellingPrice)
                moneyField("Platform fee", value: $viewModel.platformFee)
                moneyField("Shipping cost", value: $viewModel.shippingCost)
                moneyField("Packaging cost", value: $viewModel.packagingCost)
                moneyField("Promotion cost", value: $viewModel.promotionCost)
                moneyField("Discount", value: $viewModel.discount)
                moneyField("Tax placeholder", value: $viewModel.tax)
            }

            Section("Outputs") {
                resultRow("Net profit", AppFormatters.currency(viewModel.result.netProfit, code: currencyCode), isProfit: true)
                resultRow("Profit margin", AppFormatters.percent(viewModel.result.profitMargin))
                resultRow("ROI percentage", AppFormatters.percent(viewModel.result.roiPercentage))
                resultRow("Break-even price", AppFormatters.currency(viewModel.result.breakEvenPrice, code: currencyCode))
                resultRow("Recommended minimum selling price", AppFormatters.currency(viewModel.result.recommendedMinimumSellingPrice, code: currencyCode))
            }

            Section {
                Text(DisclaimerText.short)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Profit Calculator")
    }

    private func moneyField(_ title: String, value: Binding<Double>) -> some View {
        TextField(title, value: value, format: .number)
            .keyboardType(.decimalPad)
    }

    private func resultRow(_ title: String, _ value: String, isProfit: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(isProfit && viewModel.result.netProfit < 0 ? Color.red : Color.primary)
        }
    }
}

struct SalesTrackerView: View {
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Query(sort: \SaleRecord.saleDate, order: .reverse) private var sales: [SaleRecord]
    @State private var showingRecordSale = false
    @State private var selectedMarketplace = "All"

    var body: some View {
        List {
            if sales.isEmpty {
                EmptyStateView(title: "No sales yet", message: "Record sale price, platform fee, shipping, packaging, discount, and final profit.", systemImage: "banknote")
                    .listRowSeparator(.hidden)
            } else {
                Section {
                    Picker("Marketplace", selection: $selectedMarketplace) {
                        Text("All").tag("All")
                        ForEach(Marketplace.allCases) { marketplace in
                            Text(marketplace.rawValue).tag(marketplace.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    ForEach(filteredSales) { sale in
                        SaleRecordCard(sale: sale, currencyCode: currencyCode)
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Sales")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingRecordSale = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Record Sale")
            }
        }
        .sheet(isPresented: $showingRecordSale) {
            NavigationStack {
                RecordSaleView()
            }
        }
    }

    private var filteredSales: [SaleRecord] {
        sales.filter { selectedMarketplace == "All" || $0.marketplace == selectedMarketplace }
    }
}

struct RecordSaleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Query(sort: \InventoryItem.name) private var items: [InventoryItem]
    @Query(sort: \SaleRecord.saleDate, order: .reverse) private var existingSales: [SaleRecord]
    @State private var viewModel = SalesTrackerViewModel()

    let preselectedItem: InventoryItem?

    init(preselectedItem: InventoryItem? = nil) {
        self.preselectedItem = preselectedItem
    }

    var body: some View {
        Form {
            if hasReachedFreeSalesLimit {
                Section {
                    UpgradeBanner(title: "Monthly sales limit reached", message: "The Free plan includes 10 sales per month. Upgrade for unlimited sales tracking.")
                }
            }

            Section("Item sold") {
                Picker("Inventory item", selection: $viewModel.selectedItemID) {
                    Text("Manual sale").tag(UUID?.none)
                    ForEach(items) { item in
                        Text(item.name).tag(Optional(item.id))
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Sale details") {
                Picker("Marketplace", selection: $viewModel.marketplace) {
                    ForEach(Marketplace.allCases) { marketplace in
                        Text(marketplace.rawValue).tag(marketplace.rawValue)
                    }
                }
                moneyField("Sale price", value: $viewModel.salePrice)
                DatePicker("Sale date", selection: $viewModel.saleDate, displayedComponents: .date)
                Picker("Status", selection: $viewModel.status) {
                    ForEach(SaleStatus.allCases) { status in
                        Text(status.rawValue).tag(status.rawValue)
                    }
                }
            }

            Section("Costs") {
                moneyField("Shipping cost", value: $viewModel.shippingCost)
                moneyField("Platform fee", value: $viewModel.platformFee)
                moneyField("Packaging cost", value: $viewModel.packagingCost)
                moneyField("Promotion cost", value: $viewModel.promotionCost)
                moneyField("Buyer discount", value: $viewModel.buyerDiscount)
            }

            Section("Final profit") {
                HStack {
                    Text("Estimated final profit")
                    Spacer()
                    Text(AppFormatters.currency(viewModel.finalProfit(for: selectedItem), code: currencyCode))
                        .font(.headline)
                        .foregroundStyle(viewModel.finalProfit(for: selectedItem) >= 0 ? Color.flipGreen : Color.red)
                }
                Text(DisclaimerText.short)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Record Sale")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(viewModel.salePrice <= 0 || hasReachedFreeSalesLimit)
            }
        }
        .onAppear {
            if viewModel.selectedItemID == nil {
                viewModel.selectedItemID = preselectedItem?.id
            }
        }
    }

    private var selectedItem: InventoryItem? {
        items.first(where: { $0.id == viewModel.selectedItemID }) ?? preselectedItem
    }

    private var hasReachedFreeSalesLimit: Bool {
        guard !subscriptionService.hasProAccess,
              let month = Calendar.current.dateInterval(of: .month, for: .now) else {
            return false
        }
        return existingSales.filter { month.contains($0.saleDate) }.count >= 10
    }

    private func moneyField(_ title: String, value: Binding<Double>) -> some View {
        TextField(title, value: value, format: .number)
            .keyboardType(.decimalPad)
    }

    private func save() {
        guard !hasReachedFreeSalesLimit else { return }
        let item = selectedItem
        let sale = viewModel.makeSale(for: item)
        modelContext.insert(sale)

        if let item {
            item.status = statusForInventory(from: viewModel.status)
            item.sales.append(sale)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Unable to save sale: \(error)")
        }
    }

    private func statusForInventory(from saleStatus: String) -> String {
        switch saleStatus {
        case SaleStatus.listed.rawValue:
            ItemStatus.listed.rawValue
        case SaleStatus.shipped.rawValue:
            ItemStatus.shipped.rawValue
        case SaleStatus.returned.rawValue:
            ItemStatus.returned.rawValue
        case SaleStatus.refunded.rawValue:
            ItemStatus.refunded.rawValue
        default:
            ItemStatus.sold.rawValue
        }
    }
}
