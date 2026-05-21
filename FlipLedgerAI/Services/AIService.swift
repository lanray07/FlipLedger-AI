import Foundation
import SwiftUI

protocol AIService: Sendable {
    func generateListing(request: ListingGenerationRequest) async throws -> ListingGenerationResult
    func suggestPrice(item: InventoryItem?, request: ListingGenerationRequest, purchasePrice: Double, targetPrice: Double) async throws -> PricingSuggestion
    func analyzeItemPhoto(imageData: Data, marketplace: String) async throws -> PhotoAnalysisResult
    func generateSellingTips(request: ListingGenerationRequest) async throws -> [String]
    func generateMonthlySummary(items: [InventoryItem], sales: [SaleRecord], currencyCode: String) async throws -> MonthlySummary
}

struct MockAIService: AIService {
    func generateListing(request: ListingGenerationRequest) async throws -> ListingGenerationResult {
        let brandPrefix = request.brand.isEmpty ? "" : "\(request.brand) "
        let sizeSuffix = request.size.isEmpty ? "" : " - \(request.size)"
        let cleanName = request.itemName.isEmpty ? request.category : request.itemName
        let title = "\(brandPrefix)\(cleanName) \(request.condition)\(sizeSuffix)"
            .replacingOccurrences(of: "  ", with: " ")

        let details = [
            request.brand.isEmpty ? nil : "Brand: \(request.brand)",
            request.size.isEmpty ? nil : "Size: \(request.size)",
            "Condition: \(request.condition)",
            request.notes.isEmpty ? nil : request.notes
        ].compactMap { $0 }

        let lower = max(8, request.itemName.count + request.category.count)
        let suggested = Double(lower) * 1.6
        let rounded = (suggested / 5).rounded() * 5

        return ListingGenerationResult(
            title: title,
            shortDescription: "Clean \(request.category.lowercased()) listing for \(request.marketplace). Please check current comparable listings before posting.",
            detailedDescription: """
            \(title)

            \(details.joined(separator: "\n"))

            This draft uses cautious resale language and should be checked against live marketplace comps, final postage, and current platform fees before listing.
            """,
            bulletPoints: [
                "Clear photos recommended from the front, back, label, and any flaws",
                "Mention measurements or fit notes where relevant",
                "Check current \(request.marketplace) sold/comparable listings before final pricing"
            ],
            keywords: [
                request.brand,
                request.category,
                request.condition,
                request.marketplace,
                request.size
            ].filter { !$0.isEmpty },
            suggestedPriceRange: "Suggested price range: \(Int(max(rounded - 8, 1)))-\(Int(rounded + 10)). Check marketplace comps before listing.",
            suggestedPrice: rounded,
            sellingTips: [
                "Photograph flaws clearly to reduce returns.",
                "Build shipping and packaging into your minimum acceptable price.",
                "Review current platform fees before accepting offers."
            ]
        )
    }

    func suggestPrice(item: InventoryItem?, request: ListingGenerationRequest, purchasePrice: Double, targetPrice: Double) async throws -> PricingSuggestion {
        let baseline = max(targetPrice, purchasePrice * 2.2, 10)
        let quick = max(purchasePrice * 1.45, baseline * 0.82)
        let maxPrice = baseline * 1.22
        let warning = quick <= purchasePrice
            ? "Profit warning: quick-sale pricing may not cover costs once fees and shipping are included."
            : "Profit reminder: confirm current fees, shipping, and comparable sold listings before accepting offers."

        return PricingSuggestion(
            recommendedPrice: baseline,
            quickSalePrice: quick,
            maximumPrice: maxPrice,
            profitWarning: warning,
            confidence: "Medium confidence with mock AI. Check marketplace comps before listing.",
            suggestedPriceRange: "Suggested price range: \(Int(quick.rounded()))-\(Int(maxPrice.rounded()))"
        )
    }

    func analyzeItemPhoto(imageData: Data, marketplace: String) async throws -> PhotoAnalysisResult {
        let draft = ListingGenerationResult(
            title: "Photo-scanned resale item",
            shortDescription: "AI draft created from an uploaded item photo.",
            detailedDescription: "Review this draft before saving. Add brand, size, measurements, condition notes, and any visible flaws.",
            bulletPoints: [
                "Confirm category and condition manually",
                "Add measurements and material details",
                "Check current marketplace comps before listing"
            ],
            keywords: ["resale", "preloved", marketplace],
            suggestedPriceRange: "Suggested price range: 12-28. Check marketplace comps before listing.",
            suggestedPrice: 20,
            sellingTips: [
                "Use daylight photos where possible.",
                "Retake any blurry or shadowed images.",
                "Make sure defects are visible and described."
            ]
        )

        return PhotoAnalysisResult(
            suggestedCategory: ItemCategory.clothing.rawValue,
            suggestedAttributes: [
                "Condition": ItemCondition.good.rawValue,
                "Marketplace": marketplace,
                "Review needed": "Confirm brand, size, material, and flaws"
            ],
            draftListing: draft
        )
    }

    func generateSellingTips(request: ListingGenerationRequest) async throws -> [String] {
        [
            "Lead with brand, item type, size, and condition in the title.",
            "Show flaws honestly and include close-up photos.",
            "Use a minimum price that covers fees, shipping, packaging, and your target profit."
        ]
    }

    func generateMonthlySummary(items: [InventoryItem], sales: [SaleRecord], currencyCode: String) async throws -> MonthlySummary {
        let revenue = sales.reduce(0) { $0 + $1.salePrice }
        let profit = sales.reduce(0) { $0 + $1.finalProfit }
        let unsold = items.filter { !$0.isSoldOrClosed }.count

        return MonthlySummary(
            summary: "This month you tracked \(sales.count) sales, \(AppFormatters.currency(revenue, code: currencyCode)) revenue, and \(AppFormatters.currency(profit, code: currencyCode)) estimated profit.",
            highlights: [
                "Unsold inventory count: \(unsold)",
                "Average profit per sale: \(AppFormatters.currency(sales.isEmpty ? 0 : profit / Double(sales.count), code: currencyCode))"
            ],
            cautions: [
                "Profit figures are estimates.",
                "Check marketplace fees and tax obligations before filing or making pricing decisions."
            ]
        )
    }
}

struct RemoteAIService: AIService {
    var endpoint = URL(string: "https://YOUR_BACKEND_URL.com/flipledger-ai")!
    var session: URLSession = .shared

    func generateListing(request: ListingGenerationRequest) async throws -> ListingGenerationResult {
        let response = try await post(module: "generateListing", request: request)
        return ListingGenerationResult(
            title: response.title,
            shortDescription: response.summary.isEmpty ? response.description : response.summary,
            detailedDescription: response.description,
            bulletPoints: response.sellingTips,
            keywords: response.keywords,
            suggestedPriceRange: response.suggestedPriceRange,
            suggestedPrice: 0,
            sellingTips: response.sellingTips
        )
    }

    func suggestPrice(item: InventoryItem?, request: ListingGenerationRequest, purchasePrice: Double, targetPrice: Double) async throws -> PricingSuggestion {
        let response = try await post(module: "suggestPrice", request: request)
        let recommended = targetPrice > 0 ? targetPrice : max(purchasePrice * 2, 10)
        return PricingSuggestion(
            recommendedPrice: recommended,
            quickSalePrice: max(purchasePrice * 1.35, recommended * 0.85),
            maximumPrice: recommended * 1.2,
            profitWarning: response.summary.isEmpty ? "Check marketplace comps before listing." : response.summary,
            confidence: "Remote AI placeholder. Validate against marketplace comps.",
            suggestedPriceRange: response.suggestedPriceRange
        )
    }

    func analyzeItemPhoto(imageData: Data, marketplace: String) async throws -> PhotoAnalysisResult {
        let request = ListingGenerationRequest(
            marketplace: marketplace,
            itemName: "",
            category: "",
            brand: "",
            condition: "",
            size: "",
            notes: "",
            tone: ListingTone.friendly.rawValue,
            imageBase64: imageData.base64EncodedString()
        )
        let listing = try await generateListing(request: request)
        return PhotoAnalysisResult(
            suggestedCategory: ItemCategory.other.rawValue,
            suggestedAttributes: ["Review": "Remote analysis placeholder returned a draft. Confirm details before saving."],
            draftListing: listing
        )
    }

    func generateSellingTips(request: ListingGenerationRequest) async throws -> [String] {
        let response = try await post(module: "generateSellingTips", request: request)
        return response.sellingTips
    }

    func generateMonthlySummary(items: [InventoryItem], sales: [SaleRecord], currencyCode: String) async throws -> MonthlySummary {
        let response = try await post(module: "generateMonthlySummary", request: .empty)
        return MonthlySummary(
            summary: response.summary,
            highlights: response.sellingTips,
            cautions: ["Not tax or financial advice.", "Verify fees and obligations before acting."]
        )
    }

    private func post(module: String, request: ListingGenerationRequest) async throws -> RemoteAIResponse {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(RemoteAIRequest(module: module, listingRequest: request))

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AIServiceError.invalidResponse
        }
        return try JSONDecoder().decode(RemoteAIResponse.self, from: data)
    }
}

enum AIServiceError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "FlipLedger AI could not read the backend response."
    }
}

private struct RemoteAIRequest: Encodable {
    var module: String
    var marketplace: String
    var itemName: String
    var category: String
    var brand: String
    var condition: String
    var notes: String
    var imageBase64: String
    var internalPrompt: String

    init(module: String, listingRequest: ListingGenerationRequest) {
        self.module = module
        marketplace = listingRequest.marketplace
        itemName = listingRequest.itemName
        category = listingRequest.category
        brand = listingRequest.brand
        condition = listingRequest.condition
        notes = listingRequest.notes
        imageBase64 = listingRequest.imageBase64 ?? ""
        internalPrompt = DisclaimerText.internalAIPrompt
    }
}

private struct RemoteAIResponse: Decodable {
    var title: String
    var description: String
    var keywords: [String]
    var suggestedPriceRange: String
    var sellingTips: [String]
    var summary: String
}

private extension ListingGenerationRequest {
    static let empty = ListingGenerationRequest(
        marketplace: "",
        itemName: "",
        category: "",
        brand: "",
        condition: "",
        size: "",
        notes: "",
        tone: "",
        imageBase64: nil
    )
}

private struct AIServiceKey: EnvironmentKey {
    static let defaultValue: any AIService = MockAIService()
}

extension EnvironmentValues {
    var aiService: any AIService {
        get { self[AIServiceKey.self] }
        set { self[AIServiceKey.self] = newValue }
    }
}
