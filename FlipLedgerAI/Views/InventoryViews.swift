import PhotosUI
import SwiftData
import SwiftUI

struct InventoryListView: View {
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Query(sort: \InventoryItem.createdAt, order: .reverse) private var items: [InventoryItem]
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingAddItem = false

    var body: some View {
        List {
            if items.isEmpty {
                EmptyStateView(title: "Inventory starts here", message: "Add purchases as soon as you source them so fees, prices, and profit stay visible.", systemImage: "shippingbox")
                    .listRowSeparator(.hidden)
            } else {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag("All")
                        ForEach(ItemCategory.allCases) { category in
                            Text(category.rawValue).tag(category.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            InventoryDetailView(item: item)
                        } label: {
                            InventoryItemCard(item: item, currencyCode: currencyCode)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search inventory")
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Inventory Item")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            NavigationStack {
                AddInventoryItemView()
            }
        }
    }

    private var filteredItems: [InventoryItem] {
        items.filter { item in
            let categoryMatch = selectedCategory == "All" || item.category == selectedCategory
            let searchMatch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand.localizedCaseInsensitiveContains(searchText) ||
                item.purchaseSource.localizedCaseInsensitiveContains(searchText)
            return categoryMatch && searchMatch
        }
    }
}

struct AddInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService
    @Query private var existingItems: [InventoryItem]
    @State private var viewModel = InventoryFormViewModel()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingCamera = false

    var body: some View {
        Form {
            if hasReachedFreeLimit {
                Section {
                    UpgradeBanner(title: "Inventory limit reached", message: "The Free plan includes 25 inventory items. Upgrade for unlimited inventory tracking.")
                }
            }

            Section("Item") {
                TextField("Item name", text: $viewModel.name)
                Picker("Category", selection: $viewModel.category) {
                    ForEach(ItemCategory.allCases) { category in
                        Text(category.rawValue).tag(category.rawValue)
                    }
                }
                TextField("Brand", text: $viewModel.brand)
                Picker("Condition", selection: $viewModel.condition) {
                    ForEach(ItemCondition.allCases) { condition in
                        Text(condition.rawValue).tag(condition.rawValue)
                    }
                }
                TextField("Size", text: $viewModel.size)
                Picker("Status", selection: $viewModel.status) {
                    ForEach(ItemStatus.allCases) { status in
                        Text(status.rawValue).tag(status.rawValue)
                    }
                }
            }

            Section("Costs and pricing") {
                TextField("Purchase price", value: $viewModel.purchasePrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Target selling price", value: $viewModel.targetSellingPrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Purchase source", text: $viewModel.purchaseSource)
                DatePicker("Purchase date", selection: $viewModel.purchaseDate, displayedComponents: .date)
                TextField("Storage location", text: $viewModel.storageLocation)
            }

            Section("Photos") {
                PhotoImportControls(selectedItems: $selectedPhotoItems) {
                    showingCamera = true
                }
                PhotoDataGrid(photos: viewModel.photoData)
            }

            Section("Notes") {
                TextField("Condition notes, flaws, measurements", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
        }
        .navigationTitle("Add Item")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!viewModel.canSave || hasReachedFreeLimit)
            }
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task { await loadPhotos(newItems) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                if let data = image.jpegData(compressionQuality: 0.82) {
                    viewModel.photoData.append(data)
                }
            }
            .ignoresSafeArea()
        }
    }

    private var hasReachedFreeLimit: Bool {
        !subscriptionService.hasProAccess && existingItems.count >= 25
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            await MainActor.run {
                if !viewModel.photoData.contains(data) {
                    viewModel.photoData.append(data)
                }
            }
        }
    }

    private func save() {
        guard !hasReachedFreeLimit else { return }
        let item = viewModel.makeItem()
        modelContext.insert(item)

        for data in viewModel.photoData {
            let photo = ItemPhoto(inventoryItemId: item.id, imageData: data, inventoryItem: item)
            modelContext.insert(photo)
            item.photos.append(photo)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

struct InventoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @State private var sheet: InventoryDetailSheet?

    var item: InventoryItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                photos
                header
                financials
                details
                listingDrafts
                salesHistory
                DisclaimerBox()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        sheet = .recordSale
                    } label: {
                        Label("Record Sale", systemImage: "banknote")
                    }
                    Button {
                        sheet = subscriptionService.hasProAccess ? .generateListing : .paywall
                    } label: {
                        Label("Generate Listing", systemImage: "sparkles")
                    }
                    Button(role: .destructive) {
                        modelContext.delete(item)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $sheet) { sheet in
            NavigationStack {
                switch sheet {
                case .recordSale:
                    RecordSaleView(preselectedItem: item)
                case .generateListing:
                    AIListingGeneratorView(preselectedItem: item)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private var photos: some View {
        Group {
            if item.photos.isEmpty {
                PhotoTile(data: nil, systemImage: "photo")
                    .frame(height: 220)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(item.photos) { photo in
                            PhotoTile(data: photo.imageData, systemImage: "photo")
                                .frame(width: 220, height: 220)
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title.bold())
                    Text([item.brand, item.category, item.condition, item.size].filter { !$0.isEmpty }.joined(separator: " / "))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(item.status)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.flipGreen.opacity(0.12), in: Capsule())
                    .foregroundStyle(.flipGreen)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator.opacity(0.35), lineWidth: 1))
    }

    private var financials: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            ProfitSummaryCard(title: "Purchase price", value: AppFormatters.currency(item.purchasePrice, code: currencyCode), subtitle: item.purchaseSource, systemImage: "cart")
            ProfitSummaryCard(title: "Target price", value: AppFormatters.currency(item.targetSellingPrice, code: currencyCode), subtitle: "Before fees", systemImage: "tag", tint: .blue)
            ProfitSummaryCard(title: "Estimated gross", value: AppFormatters.currency(item.estimatedGrossProfit, code: currencyCode), subtitle: "Before selling costs", systemImage: "arrow.up.right", tint: item.estimatedGrossProfit >= 0 ? .flipGreen : .red)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            detailRow("Purchase date", AppFormatters.shortDate.string(from: item.purchaseDate))
            detailRow("Storage location", item.storageLocation.isEmpty ? "Not set" : item.storageLocation)
            detailRow("Notes", item.notes.isEmpty ? "No notes" : item.notes)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator.opacity(0.35), lineWidth: 1))
    }

    private var listingDrafts: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Listing drafts")
                    .font(.headline)
                Spacer()
                Button {
                    sheet = subscriptionService.hasProAccess ? .generateListing : .paywall
                } label: {
                    Image(systemName: "sparkles")
                }
                .accessibilityLabel("Generate Listing")
            }

            if item.listingDrafts.isEmpty {
                Text("No AI drafts saved yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(item.listingDrafts.sorted(by: { $0.createdAt > $1.createdAt })) { draft in
                    ListingDraftView(draft: draft)
                }
            }
        }
    }

    private var salesHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sales history")
                .font(.headline)
            if item.sales.isEmpty {
                Text("No sale recorded for this item.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(item.sales.sorted(by: { $0.saleDate > $1.saleDate })) { sale in
                    SaleRecordCard(sale: sale, currencyCode: currencyCode)
                }
            }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private enum InventoryDetailSheet: Identifiable {
    case recordSale
    case generateListing
    case paywall

    var id: String { String(describing: self) }
}
