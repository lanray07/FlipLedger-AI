import Foundation
import Observation

struct DashboardMetrics: Hashable {
    var totalRevenue: Double
    var totalProfit: Double
    var unsoldInventoryValue: Double
    var soldItems: Int
    var bestCategory: String
    var averageProfitMargin: Double
    var subscriptionStatus: String
}

@MainActor
@Observable
final class DashboardViewModel {
    func metrics(items: [InventoryItem], sales: [SaleRecord], subscriptionStatus: String) -> DashboardMetrics {
        let totalRevenue = sales.reduce(0) { $0 + $1.salePrice }
        let totalProfit = sales.reduce(0) { $0 + $1.finalProfit }
        let unsoldValue = items.filter { !$0.isSoldOrClosed }.reduce(0) { $0 + $1.purchasePrice }
        let soldItems = sales.filter {
            $0.status == SaleStatus.sold.rawValue || $0.status == SaleStatus.shipped.rawValue
        }.count

        let categoryProfit = Dictionary(grouping: sales, by: { $0.categorySnapshot.isEmpty ? "Other" : $0.categorySnapshot })
            .mapValues { groupedSales in groupedSales.reduce(0) { $0 + $1.finalProfit } }
        let bestCategory = categoryProfit.max(by: { $0.value < $1.value })?.key ?? "No sales yet"
        let averageMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0

        return DashboardMetrics(
            totalRevenue: totalRevenue,
            totalProfit: totalProfit,
            unsoldInventoryValue: unsoldValue,
            soldItems: soldItems,
            bestCategory: bestCategory,
            averageProfitMargin: averageMargin,
            subscriptionStatus: subscriptionStatus
        )
    }
}

@MainActor
@Observable
final class InventoryFormViewModel {
    var name = ""
    var category = ItemCategory.clothing.rawValue
    var purchasePrice = 0.0
    var purchaseSource = ""
    var purchaseDate = Date.now
    var condition = ItemCondition.good.rawValue
    var size = ""
    var brand = ""
    var photoData: [Data] = []
    var notes = ""
    var targetSellingPrice = 0.0
    var storageLocation = ""
    var status = ItemStatus.inventory.rawValue
    var errorMessage: String?

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func makeItem() -> InventoryItem {
        InventoryItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            condition: condition,
            size: size.trimmingCharacters(in: .whitespacesAndNewlines),
            purchasePrice: purchasePrice.clampedNonNegative,
            targetSellingPrice: targetSellingPrice.clampedNonNegative,
            purchaseSource: purchaseSource.trimmingCharacters(in: .whitespacesAndNewlines),
            purchaseDate: purchaseDate,
            storageLocation: storageLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status
        )
    }
}

@MainActor
@Observable
final class ProfitCalculatorViewModel {
    var purchasePrice = 0.0
    var sellingPrice = 0.0
    var platformFee = 0.0
    var shippingCost = 0.0
    var packagingCost = 0.0
    var promotionCost = 0.0
    var discount = 0.0
    var tax = 0.0

    var result: ProfitCalculationResult {
        ProfitCalculatorService.calculate(ProfitCalculationInput(
            purchasePrice: purchasePrice,
            sellingPrice: sellingPrice,
            platformFee: platformFee,
            shippingCost: shippingCost,
            packagingCost: packagingCost,
            promotionCost: promotionCost,
            discount: discount,
            tax: tax
        ))
    }
}

@MainActor
@Observable
final class SalesTrackerViewModel {
    var selectedItemID: UUID?
    var marketplace = Marketplace.vinted.rawValue
    var salePrice = 0.0
    var saleDate = Date.now
    var shippingCost = 0.0
    var platformFee = 0.0
    var packagingCost = 0.0
    var promotionCost = 0.0
    var buyerDiscount = 0.0
    var status = SaleStatus.sold.rawValue

    func finalProfit(for item: InventoryItem?) -> Double {
        let input = ProfitCalculationInput(
            purchasePrice: item?.purchasePrice ?? 0,
            sellingPrice: salePrice,
            platformFee: platformFee,
            shippingCost: shippingCost,
            packagingCost: packagingCost,
            promotionCost: promotionCost,
            discount: buyerDiscount,
            tax: 0
        )
        return ProfitCalculatorService.calculate(input).netProfit
    }

    func makeSale(for item: InventoryItem?) -> SaleRecord {
        let profit = finalProfit(for: item)
        return SaleRecord(
            inventoryItemId: item?.id,
            itemNameSnapshot: item?.name ?? "Manual sale",
            categorySnapshot: item?.category ?? ItemCategory.other.rawValue,
            marketplace: marketplace,
            salePrice: salePrice.clampedNonNegative,
            saleDate: saleDate,
            platformFee: platformFee.clampedNonNegative,
            shippingCost: shippingCost.clampedNonNegative,
            packagingCost: packagingCost.clampedNonNegative,
            promotionCost: promotionCost.clampedNonNegative,
            discount: buyerDiscount.clampedNonNegative,
            finalProfit: profit,
            status: status,
            inventoryItem: item
        )
    }
}

@MainActor
@Observable
final class AIListingViewModel {
    var selectedItemID: UUID?
    var itemName = ""
    var category = ItemCategory.clothing.rawValue
    var brand = ""
    var condition = ItemCondition.good.rawValue
    var size = ""
    var keyDetails = ""
    var marketplace = Marketplace.vinted.rawValue
    var tone = ListingTone.friendly.rawValue
    var selectedImageData: Data?
    var result: ListingGenerationResult?
    var isLoading = false
    var errorMessage: String?

    func load(item: InventoryItem) {
        selectedItemID = item.id
        itemName = item.name
        category = item.category
        brand = item.brand
        condition = item.condition
        size = item.size
        keyDetails = item.notes
        selectedImageData = item.photos.first?.imageData
    }

    func request() -> ListingGenerationRequest {
        ListingGenerationRequest(
            marketplace: marketplace,
            itemName: itemName,
            category: category,
            brand: brand,
            condition: condition,
            size: size,
            notes: keyDetails,
            tone: tone,
            imageBase64: selectedImageData?.base64EncodedString()
        )
    }

    func generate(service: any AIService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            result = try await service.generateListing(request: request())
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class PricingAssistantViewModel {
    var selectedItemID: UUID?
    var itemName = ""
    var category = ItemCategory.clothing.rawValue
    var brand = ""
    var condition = ItemCondition.good.rawValue
    var marketplace = Marketplace.vinted.rawValue
    var purchasePrice = 0.0
    var targetPrice = 0.0
    var notes = ""
    var suggestion: PricingSuggestion?
    var isLoading = false
    var errorMessage: String?

    func load(item: InventoryItem) {
        selectedItemID = item.id
        itemName = item.name
        category = item.category
        brand = item.brand
        condition = item.condition
        purchasePrice = item.purchasePrice
        targetPrice = item.targetSellingPrice
        notes = item.notes
    }

    func suggest(service: any AIService, item: InventoryItem?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let request = ListingGenerationRequest(
                marketplace: marketplace,
                itemName: itemName,
                category: category,
                brand: brand,
                condition: condition,
                size: item?.size ?? "",
                notes: notes,
                tone: ListingTone.concise.rawValue,
                imageBase64: item?.photos.first?.imageData?.base64EncodedString()
            )
            suggestion = try await service.suggestPrice(
                item: item,
                request: request,
                purchasePrice: purchasePrice,
                targetPrice: targetPrice
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class InventoryScannerViewModel {
    var imageData: Data?
    var marketplace = Marketplace.vinted.rawValue
    var analysis: PhotoAnalysisResult?
    var isLoading = false
    var errorMessage: String?

    func analyze(service: any AIService) async {
        guard let imageData else {
            errorMessage = "Add a photo before scanning."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            analysis = try await service.analyzeItemPhoto(imageData: imageData, marketplace: marketplace)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class AnalyticsViewModel {
    func profitByMarketplace(sales: [SaleRecord]) -> [ChartDataPoint] {
        Dictionary(grouping: sales, by: \.marketplace)
            .map { ChartDataPoint(label: $0.key, value: $0.value.reduce(0) { $0 + $1.finalProfit }) }
            .sorted { $0.value > $1.value }
    }

    func profitByCategory(sales: [SaleRecord]) -> [ChartDataPoint] {
        Dictionary(grouping: sales, by: { $0.categorySnapshot.isEmpty ? ItemCategory.other.rawValue : $0.categorySnapshot })
            .map { ChartDataPoint(label: $0.key, value: $0.value.reduce(0) { $0 + $1.finalProfit }) }
            .sorted { $0.value > $1.value }
    }

    func monthlyRevenue(sales: [SaleRecord]) -> [ChartDataPoint] {
        Dictionary(grouping: sales, by: { Calendar.current.monthKey(for: $0.saleDate) })
            .map { ChartDataPoint(label: $0.key, value: $0.value.reduce(0) { $0 + $1.salePrice }) }
            .sorted { $0.label < $1.label }
    }

    func monthlyProfit(sales: [SaleRecord]) -> [ChartDataPoint] {
        Dictionary(grouping: sales, by: { Calendar.current.monthKey(for: $0.saleDate) })
            .map { ChartDataPoint(label: $0.key, value: $0.value.reduce(0) { $0 + $1.finalProfit }) }
            .sorted { $0.label < $1.label }
    }

    func roiBySource(sales: [SaleRecord]) -> [ChartDataPoint] {
        let grouped = Dictionary(grouping: sales, by: { sale in
            sale.inventoryItem?.purchaseSource.isEmpty == false ? sale.inventoryItem?.purchaseSource ?? "Unknown" : "Unknown"
        })

        return grouped.map { source, records in
            let purchaseCost = records.reduce(0) { $0 + ($1.inventoryItem?.purchasePrice ?? 0) }
            let profit = records.reduce(0) { $0 + $1.finalProfit }
            let roi = purchaseCost > 0 ? (profit / purchaseCost) * 100 : 0
            return ChartDataPoint(label: source, value: roi)
        }
        .sorted { $0.value > $1.value }
    }

    func bestSellingBrands(sales: [SaleRecord]) -> [ChartDataPoint] {
        let grouped = Dictionary(grouping: sales, by: { sale in
            let brand = sale.inventoryItem?.brand ?? ""
            return brand.isEmpty ? "Unbranded" : brand
        })

        return grouped
            .map { ChartDataPoint(label: $0.key, value: Double($0.value.count)) }
            .sorted { $0.value > $1.value }
    }

    func slowMovingInventory(items: [InventoryItem]) -> [InventoryItem] {
        items
            .filter { !$0.isSoldOrClosed }
            .sorted { $0.purchaseDate < $1.purchaseDate }
            .prefix(8)
            .map { $0 }
    }

    func averageDaysToSell(sales: [SaleRecord]) -> Double {
        let days = sales.compactMap { sale -> Double? in
            guard let purchaseDate = sale.inventoryItem?.purchaseDate else { return nil }
            return max(0, sale.saleDate.timeIntervalSince(purchaseDate) / 86_400)
        }
        guard !days.isEmpty else { return 0 }
        return days.reduce(0, +) / Double(days.count)
    }
}
