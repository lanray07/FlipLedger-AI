import Foundation
import SwiftData

protocol DisplayOption: CaseIterable, Identifiable, Codable, Hashable, RawRepresentable where RawValue == String {
    var rawValue: String { get }
}

extension DisplayOption {
    var id: String { rawValue }
    var label: String { rawValue }
}

enum Marketplace: String, DisplayOption {
    case vinted = "Vinted"
    case ebay = "eBay"
    case depop = "Depop"
    case facebookMarketplace = "Facebook Marketplace"
    case etsy = "Etsy"
    case amazon = "Amazon"
    case other = "Other"
}

enum ResellerType: String, DisplayOption {
    case beginner = "Beginner"
    case partTimeSeller = "Part-time seller"
    case fullTimeReseller = "Full-time reseller"
    case shopOwner = "Shop owner"
}

enum CurrencyCode: String, DisplayOption {
    case gbp = "GBP"
    case usd = "USD"
    case eur = "EUR"
    case ngn = "NGN"

    var symbol: String {
        switch self {
        case .gbp: "£"
        case .usd: "$"
        case .eur: "€"
        case .ngn: "₦"
        }
    }
}

enum ItemCategory: String, DisplayOption {
    case clothing = "Clothing"
    case shoes = "Shoes"
    case accessories = "Accessories"
    case electronics = "Electronics"
    case books = "Books"
    case toys = "Toys"
    case homeware = "Homeware"
    case beauty = "Beauty"
    case collectibles = "Collectibles"
    case other = "Other"
}

enum ItemCondition: String, DisplayOption {
    case newWithTags = "New with tags"
    case new = "New"
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case forParts = "For parts"
}

enum ItemStatus: String, DisplayOption {
    case inventory = "In inventory"
    case listed = "Listed"
    case sold = "Sold"
    case shipped = "Shipped"
    case returned = "Returned"
    case refunded = "Refunded"
}

enum SaleStatus: String, DisplayOption {
    case listed = "Listed"
    case sold = "Sold"
    case shipped = "Shipped"
    case returned = "Returned"
    case refunded = "Refunded"
}

enum ListingTone: String, DisplayOption {
    case friendly = "Friendly"
    case premium = "Premium"
    case concise = "Concise"
    case playful = "Playful"
}

enum SubscriptionPlan: String, DisplayOption {
    case free = "Free"
    case proMonthly = "Pro Monthly"
    case proYearly = "Pro Yearly"
    case businessMonthly = "Business Monthly"

    var productID: String? {
        switch self {
        case .free: nil
        case .proMonthly: "com.flipledgerai.pro.monthly"
        case .proYearly: "com.flipledgerai.pro.yearly"
        case .businessMonthly: "com.flipledgerai.business.monthly"
        }
    }

    var placeholderPrice: String {
        switch self {
        case .free: "£0"
        case .proMonthly: "£9.99/mo"
        case .proYearly: "£79.99/yr"
        case .businessMonthly: "£24.99/mo"
        }
    }

    var featureSummary: String {
        switch self {
        case .free:
            "25 inventory items, 10 sales/month, basic calculator"
        case .proMonthly, .proYearly:
            "Unlimited tracking, AI listing and pricing, analytics, exports"
        case .businessMonthly:
            "Advanced reports, sourcing insights, custom category placeholders"
        }
    }

    static var paidProductIDs: Set<String> {
        Set(allCases.compactMap(\.productID))
    }

    init?(productID: String) {
        guard let plan = SubscriptionPlan.allCases.first(where: { $0.productID == productID }) else {
            return nil
        }
        self = plan
    }
}

@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var brand: String
    var condition: String
    var size: String
    var purchasePrice: Double
    var targetSellingPrice: Double
    var purchaseSource: String
    var purchaseDate: Date
    var storageLocation: String
    var notes: String
    var status: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ItemPhoto.inventoryItem)
    var photos: [ItemPhoto] = []

    @Relationship(deleteRule: .cascade, inverse: \SaleRecord.inventoryItem)
    var sales: [SaleRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \ListingDraft.inventoryItem)
    var listingDrafts: [ListingDraft] = []

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        brand: String = "",
        condition: String,
        size: String = "",
        purchasePrice: Double,
        targetSellingPrice: Double,
        purchaseSource: String = "",
        purchaseDate: Date = .now,
        storageLocation: String = "",
        notes: String = "",
        status: String = ItemStatus.inventory.rawValue,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.brand = brand
        self.condition = condition
        self.size = size
        self.purchasePrice = purchasePrice
        self.targetSellingPrice = targetSellingPrice
        self.purchaseSource = purchaseSource
        self.purchaseDate = purchaseDate
        self.storageLocation = storageLocation
        self.notes = notes
        self.status = status
        self.createdAt = createdAt
    }

    var isSoldOrClosed: Bool {
        status == ItemStatus.sold.rawValue ||
        status == ItemStatus.shipped.rawValue ||
        status == ItemStatus.returned.rawValue ||
        status == ItemStatus.refunded.rawValue
    }

    var estimatedGrossProfit: Double {
        targetSellingPrice - purchasePrice
    }
}

@Model
final class ItemPhoto {
    @Attribute(.unique) var id: UUID
    var inventoryItemId: UUID?
    @Attribute(.externalStorage) var imageData: Data?
    var localImageURL: String?
    var caption: String
    var createdAt: Date
    var inventoryItem: InventoryItem?

    init(
        id: UUID = UUID(),
        inventoryItemId: UUID? = nil,
        imageData: Data? = nil,
        localImageURL: String? = nil,
        caption: String = "",
        createdAt: Date = .now,
        inventoryItem: InventoryItem? = nil
    ) {
        self.id = id
        self.inventoryItemId = inventoryItemId
        self.imageData = imageData
        self.localImageURL = localImageURL
        self.caption = caption
        self.createdAt = createdAt
        self.inventoryItem = inventoryItem
    }
}

@Model
final class SaleRecord {
    @Attribute(.unique) var id: UUID
    var inventoryItemId: UUID?
    var itemNameSnapshot: String
    var categorySnapshot: String
    var marketplace: String
    var salePrice: Double
    var saleDate: Date
    var platformFee: Double
    var shippingCost: Double
    var packagingCost: Double
    var promotionCost: Double
    var discount: Double
    var finalProfit: Double
    var status: String
    var createdAt: Date
    var inventoryItem: InventoryItem?

    init(
        id: UUID = UUID(),
        inventoryItemId: UUID? = nil,
        itemNameSnapshot: String = "",
        categorySnapshot: String = "",
        marketplace: String,
        salePrice: Double,
        saleDate: Date = .now,
        platformFee: Double,
        shippingCost: Double,
        packagingCost: Double,
        promotionCost: Double = 0,
        discount: Double = 0,
        finalProfit: Double,
        status: String = SaleStatus.sold.rawValue,
        createdAt: Date = .now,
        inventoryItem: InventoryItem? = nil
    ) {
        self.id = id
        self.inventoryItemId = inventoryItemId
        self.itemNameSnapshot = itemNameSnapshot
        self.categorySnapshot = categorySnapshot
        self.marketplace = marketplace
        self.salePrice = salePrice
        self.saleDate = saleDate
        self.platformFee = platformFee
        self.shippingCost = shippingCost
        self.packagingCost = packagingCost
        self.promotionCost = promotionCost
        self.discount = discount
        self.finalProfit = finalProfit
        self.status = status
        self.createdAt = createdAt
        self.inventoryItem = inventoryItem
    }
}

@Model
final class MarketplaceSettings {
    @Attribute(.unique) var id: UUID
    var marketplaceName: String
    var defaultFeePercentage: Double
    var fixedFee: Double
    var currency: String

    init(
        id: UUID = UUID(),
        marketplaceName: String,
        defaultFeePercentage: Double,
        fixedFee: Double,
        currency: String
    ) {
        self.id = id
        self.marketplaceName = marketplaceName
        self.defaultFeePercentage = defaultFeePercentage
        self.fixedFee = fixedFee
        self.currency = currency
    }
}

@Model
final class ListingDraft {
    @Attribute(.unique) var id: UUID
    var inventoryItemId: UUID?
    var title: String
    var shortDescription: String
    var detailedDescription: String
    var bulletPointsJSON: String
    var keywordsJSON: String
    var suggestedPrice: Double
    var suggestedPriceRange: String
    var sellingTipsJSON: String
    var createdAt: Date
    var inventoryItem: InventoryItem?

    init(
        id: UUID = UUID(),
        inventoryItemId: UUID? = nil,
        title: String,
        shortDescription: String,
        detailedDescription: String,
        bulletPoints: [String] = [],
        keywords: [String] = [],
        suggestedPrice: Double = 0,
        suggestedPriceRange: String = "",
        sellingTips: [String] = [],
        createdAt: Date = .now,
        inventoryItem: InventoryItem? = nil
    ) {
        self.id = id
        self.inventoryItemId = inventoryItemId
        self.title = title
        self.shortDescription = shortDescription
        self.detailedDescription = detailedDescription
        self.bulletPointsJSON = Self.encodeList(bulletPoints)
        self.keywordsJSON = Self.encodeList(keywords)
        self.suggestedPrice = suggestedPrice
        self.suggestedPriceRange = suggestedPriceRange
        self.sellingTipsJSON = Self.encodeList(sellingTips)
        self.createdAt = createdAt
        self.inventoryItem = inventoryItem
    }

    var bulletPoints: [String] {
        get { Self.decodeList(bulletPointsJSON) }
        set { bulletPointsJSON = Self.encodeList(newValue) }
    }

    var keywords: [String] {
        get { Self.decodeList(keywordsJSON) }
        set { keywordsJSON = Self.encodeList(newValue) }
    }

    var sellingTips: [String] {
        get { Self.decodeList(sellingTipsJSON) }
        set { sellingTipsJSON = Self.encodeList(newValue) }
    }

    private static func encodeList(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    private static func decodeList(_ string: String) -> [String] {
        guard let data = string.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return values
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var plan: String
    var isActive: Bool
    var renewsAt: Date?

    init(
        id: UUID = UUID(),
        plan: String = SubscriptionPlan.free.rawValue,
        isActive: Bool = false,
        renewsAt: Date? = nil
    ) {
        self.id = id
        self.plan = plan
        self.isActive = isActive
        self.renewsAt = renewsAt
    }
}

struct ListingGenerationRequest: Codable, Hashable {
    var marketplace: String
    var itemName: String
    var category: String
    var brand: String
    var condition: String
    var size: String
    var notes: String
    var tone: String
    var imageBase64: String?
}

struct ListingGenerationResult: Codable, Hashable {
    var title: String
    var shortDescription: String
    var detailedDescription: String
    var bulletPoints: [String]
    var keywords: [String]
    var suggestedPriceRange: String
    var suggestedPrice: Double
    var sellingTips: [String]
}

struct PricingSuggestion: Codable, Hashable {
    var recommendedPrice: Double
    var quickSalePrice: Double
    var maximumPrice: Double
    var profitWarning: String
    var confidence: String
    var suggestedPriceRange: String
}

struct PhotoAnalysisResult: Codable, Hashable {
    var suggestedCategory: String
    var suggestedAttributes: [String: String]
    var draftListing: ListingGenerationResult
}

struct MonthlySummary: Codable, Hashable {
    var summary: String
    var highlights: [String]
    var cautions: [String]
}
