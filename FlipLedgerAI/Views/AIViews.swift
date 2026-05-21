import PhotosUI
import SwiftData
import SwiftUI

struct AIToolsView: View {
    @Environment(SubscriptionService.self) private var subscriptionService

    var body: some View {
        List {
            if !subscriptionService.hasProAccess {
                Section {
                    NavigationLink {
                        PaywallView()
                    } label: {
                        UpgradeBanner()
                    }
                }
            }

            Section("AI tools") {
                NavigationLink {
                    gated {
                        AIListingGeneratorView()
                    }
                } label: {
                    Label("AI Listing Generator", systemImage: "text.badge.plus")
                }

                NavigationLink {
                    gated {
                        AIPricingAssistantView()
                    }
                } label: {
                    Label("AI Pricing Assistant", systemImage: "tag")
                }

                NavigationLink {
                    gated {
                        InventoryScannerView()
                    }
                } label: {
                    Label("Inventory Scanner", systemImage: "camera.viewfinder")
                }

                NavigationLink {
                    ProfitCalculatorView()
                } label: {
                    Label("Profit Calculator", systemImage: "function")
                }
            }

            Section {
                Text(DisclaimerText.short)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI Tools")
    }

    @ViewBuilder
    private func gated<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if subscriptionService.hasProAccess {
            content()
        } else {
            PaywallView()
        }
    }
}

struct AIListingGeneratorView: View {
    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Query(sort: \InventoryItem.name) private var items: [InventoryItem]
    @State private var viewModel = AIListingViewModel()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingCamera = false

    let preselectedItem: InventoryItem?

    init(preselectedItem: InventoryItem? = nil) {
        self.preselectedItem = preselectedItem
    }

    var body: some View {
        Group {
            if subscriptionService.hasProAccess {
                content
            } else {
                PaywallView()
            }
        }
        .navigationTitle("Listing Generator")
        .onAppear {
            if let preselectedItem, viewModel.selectedItemID == nil {
                viewModel.load(item: preselectedItem)
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                inputForm

                Button {
                    Task { await viewModel.generate(service: aiService) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Generate listing", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.flipGreen)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let result = viewModel.result {
                    ListingDraftView(result: result)
                    Button {
                        saveDraft(result)
                    } label: {
                        Label("Save draft to item", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedItem == nil)
                } else {
                    EmptyStateView(title: "Ready for a draft", message: "Add details or choose an inventory item. Mock AI is enabled by default.", systemImage: "sparkles")
                }

                DisclaimerBox()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task { await loadFirstPhoto(newItems) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                viewModel.selectedImageData = image.jpegData(compressionQuality: 0.82)
            }
            .ignoresSafeArea()
        }
    }

    private var inputForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Inventory item", selection: $viewModel.selectedItemID) {
                Text("Manual listing").tag(UUID?.none)
                ForEach(items) { item in
                    Text(item.name).tag(Optional(item.id))
                }
            }
            .pickerStyle(.navigationLink)
            .onChange(of: viewModel.selectedItemID) { _, id in
                guard let id, let item = items.first(where: { $0.id == id }) else { return }
                viewModel.load(item: item)
            }

            TextField("Item name", text: $viewModel.itemName)
            TextField("Brand", text: $viewModel.brand)
            Picker("Category", selection: $viewModel.category) {
                ForEach(ItemCategory.allCases) { category in
                    Text(category.rawValue).tag(category.rawValue)
                }
            }
            Picker("Condition", selection: $viewModel.condition) {
                ForEach(ItemCondition.allCases) { condition in
                    Text(condition.rawValue).tag(condition.rawValue)
                }
            }
            TextField("Size", text: $viewModel.size)
            Picker("Marketplace", selection: $viewModel.marketplace) {
                ForEach(Marketplace.allCases) { marketplace in
                    Text(marketplace.rawValue).tag(marketplace.rawValue)
                }
            }
            Picker("Tone", selection: $viewModel.tone) {
                ForEach(ListingTone.allCases) { tone in
                    Text(tone.rawValue).tag(tone.rawValue)
                }
            }
            TextField("Key details, flaws, measurements", text: $viewModel.keyDetails, axis: .vertical)
                .lineLimit(4, reservesSpace: true)

            HStack {
                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 1, matching: .images) {
                    Label("Photo", systemImage: "photo")
                }
                .buttonStyle(.bordered)

                Button {
                    showingCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            if let imageData = viewModel.selectedImageData {
                PhotoTile(data: imageData, systemImage: "photo")
                    .frame(height: 180)
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator.opacity(0.35), lineWidth: 1))
    }

    private var selectedItem: InventoryItem? {
        items.first(where: { $0.id == viewModel.selectedItemID }) ?? preselectedItem
    }

    private func loadFirstPhoto(_ items: [PhotosPickerItem]) async {
        guard let first = items.first,
              let data = try? await first.loadTransferable(type: Data.self) else {
            return
        }
        await MainActor.run {
            viewModel.selectedImageData = data
        }
    }

    private func saveDraft(_ result: ListingGenerationResult) {
        guard let selectedItem else { return }
        let draft = ListingDraft(
            inventoryItemId: selectedItem.id,
            title: result.title,
            shortDescription: result.shortDescription,
            detailedDescription: result.detailedDescription,
            bulletPoints: result.bulletPoints,
            keywords: result.keywords,
            suggestedPrice: result.suggestedPrice,
            suggestedPriceRange: result.suggestedPriceRange,
            sellingTips: result.sellingTips,
            inventoryItem: selectedItem
        )
        modelContext.insert(draft)
        selectedItem.listingDrafts.append(draft)
        try? modelContext.save()
    }
}

struct AIPricingAssistantView: View {
    @Environment(\.aiService) private var aiService
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @Query(sort: \InventoryItem.name) private var items: [InventoryItem]
    @State private var viewModel = PricingAssistantViewModel()

    var body: some View {
        Group {
            if subscriptionService.hasProAccess {
                content
            } else {
                PaywallView()
            }
        }
        .navigationTitle("Pricing Assistant")
    }

    private var content: some View {
        Form {
            Section("Item") {
                Picker("Inventory item", selection: $viewModel.selectedItemID) {
                    Text("Manual item").tag(UUID?.none)
                    ForEach(items) { item in
                        Text(item.name).tag(Optional(item.id))
                    }
                }
                .pickerStyle(.navigationLink)
                .onChange(of: viewModel.selectedItemID) { _, id in
                    guard let id, let item = items.first(where: { $0.id == id }) else { return }
                    viewModel.load(item: item)
                }

                TextField("Item name", text: $viewModel.itemName)
                TextField("Brand", text: $viewModel.brand)
                Picker("Category", selection: $viewModel.category) {
                    ForEach(ItemCategory.allCases) { category in
                        Text(category.rawValue).tag(category.rawValue)
                    }
                }
                Picker("Condition", selection: $viewModel.condition) {
                    ForEach(ItemCondition.allCases) { condition in
                        Text(condition.rawValue).tag(condition.rawValue)
                    }
                }
                Picker("Marketplace", selection: $viewModel.marketplace) {
                    ForEach(Marketplace.allCases) { marketplace in
                        Text(marketplace.rawValue).tag(marketplace.rawValue)
                    }
                }
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section("Costs") {
                TextField("Purchase price", value: $viewModel.purchasePrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Target selling price", value: $viewModel.targetPrice, format: .number)
                    .keyboardType(.decimalPad)
            }

            Section {
                Button {
                    Task {
                        await viewModel.suggest(service: aiService, item: selectedItem)
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Label("Suggest price", systemImage: "sparkles")
                    }
                }
            }

            if let suggestion = viewModel.suggestion {
                Section {
                    PricingSuggestionCard(suggestion: suggestion, currencyCode: currencyCode)
                }
            }

            Section {
                Text("Suggested price range. Check marketplace comps before listing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var selectedItem: InventoryItem? {
        items.first(where: { $0.id == viewModel.selectedItemID })
    }
}

struct InventoryScannerView: View {
    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var viewModel = InventoryScannerViewModel()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var savedMessage: String?

    var body: some View {
        Group {
            if subscriptionService.hasProAccess {
                content
            } else {
                PaywallView()
            }
        }
        .navigationTitle("Inventory Scanner")
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Marketplace", selection: $viewModel.marketplace) {
                        ForEach(Marketplace.allCases) { marketplace in
                            Text(marketplace.rawValue).tag(marketplace.rawValue)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 1, matching: .images) {
                            Label("Upload", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            showingCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                    }

                    if let data = viewModel.imageData {
                        PhotoTile(data: data, systemImage: "photo")
                            .frame(height: 260)
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator.opacity(0.35), lineWidth: 1))

                Button {
                    Task { await viewModel.analyze(service: aiService) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Scan item", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.flipGreen)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let analysis = viewModel.analysis {
                    analysisView(analysis)
                } else {
                    EmptyStateView(title: "Upload a photo", message: "Mock AI will suggest a category, attributes, and a draft listing for review before saving.", systemImage: "camera.viewfinder")
                }

                if let savedMessage {
                    Text(savedMessage)
                        .font(.footnote)
                        .foregroundStyle(.flipGreen)
                }

                DisclaimerBox()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task { await loadFirstPhoto(newItems) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                viewModel.imageData = image.jpegData(compressionQuality: 0.82)
            }
            .ignoresSafeArea()
        }
    }

    private func analysisView(_ analysis: PhotoAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested category")
                .font(.headline)
            MarketplaceBadge(marketplace: analysis.suggestedCategory)

            if !analysis.suggestedAttributes.isEmpty {
                Text("Suggested attributes")
                    .font(.headline)
                ForEach(analysis.suggestedAttributes.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(analysis.suggestedAttributes[key] ?? "")
                    }
                    .font(.subheadline)
                }
            }

            ListingDraftView(result: analysis.draftListing)

            Button {
                saveScannedItem(analysis)
            } label: {
                Label("Save reviewed item", systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func loadFirstPhoto(_ items: [PhotosPickerItem]) async {
        guard let first = items.first,
              let data = try? await first.loadTransferable(type: Data.self) else {
            return
        }
        await MainActor.run {
            viewModel.imageData = data
        }
    }

    private func saveScannedItem(_ analysis: PhotoAnalysisResult) {
        let item = InventoryItem(
            name: analysis.draftListing.title,
            category: analysis.suggestedCategory,
            brand: analysis.suggestedAttributes["Brand"] ?? "",
            condition: analysis.suggestedAttributes["Condition"] ?? ItemCondition.good.rawValue,
            purchasePrice: 0,
            targetSellingPrice: analysis.draftListing.suggestedPrice,
            purchaseSource: "Inventory scan",
            notes: "Review AI-suggested attributes before listing."
        )
        modelContext.insert(item)

        if let imageData = viewModel.imageData {
            let photo = ItemPhoto(inventoryItemId: item.id, imageData: imageData, inventoryItem: item)
            modelContext.insert(photo)
            item.photos.append(photo)
        }

        let draft = ListingDraft(
            inventoryItemId: item.id,
            title: analysis.draftListing.title,
            shortDescription: analysis.draftListing.shortDescription,
            detailedDescription: analysis.draftListing.detailedDescription,
            bulletPoints: analysis.draftListing.bulletPoints,
            keywords: analysis.draftListing.keywords,
            suggestedPrice: analysis.draftListing.suggestedPrice,
            suggestedPriceRange: analysis.draftListing.suggestedPriceRange,
            sellingTips: analysis.draftListing.sellingTips,
            inventoryItem: item
        )
        modelContext.insert(draft)
        item.listingDrafts.append(draft)
        try? modelContext.save()
        savedMessage = "Saved to inventory. Review costs, brand, size, condition, and pricing before listing."
    }
}
