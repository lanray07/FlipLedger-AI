import Foundation
import Observation
import StoreKit
import SwiftData
import UIKit

struct ProfitCalculationInput: Hashable {
    var purchasePrice: Double = 0
    var sellingPrice: Double = 0
    var platformFee: Double = 0
    var shippingCost: Double = 0
    var packagingCost: Double = 0
    var promotionCost: Double = 0
    var discount: Double = 0
    var tax: Double = 0
}

struct ProfitCalculationResult: Hashable {
    var netProfit: Double
    var profitMargin: Double
    var roiPercentage: Double
    var breakEvenPrice: Double
    var recommendedMinimumSellingPrice: Double
}

enum ProfitCalculatorService {
    static func calculate(_ input: ProfitCalculationInput) -> ProfitCalculationResult {
        let totalCosts = input.purchasePrice +
            input.platformFee +
            input.shippingCost +
            input.packagingCost +
            input.promotionCost +
            input.discount +
            input.tax

        let netProfit = input.sellingPrice - totalCosts
        let margin = input.sellingPrice > 0 ? (netProfit / input.sellingPrice) * 100 : 0
        let roi = input.purchasePrice > 0 ? (netProfit / input.purchasePrice) * 100 : 0
        let recommendedMinimum = totalCosts * 1.15

        return ProfitCalculationResult(
            netProfit: netProfit,
            profitMargin: margin,
            roiPercentage: roi,
            breakEvenPrice: totalCosts,
            recommendedMinimumSellingPrice: recommendedMinimum
        )
    }
}

@MainActor
enum ExportService {
    static func exportInventoryCSV(items: [InventoryItem], currencyCode: String) throws -> URL {
        let header = [
            "Name",
            "Category",
            "Brand",
            "Condition",
            "Purchase Price",
            "Target Selling Price",
            "Purchase Source",
            "Purchase Date",
            "Storage Location",
            "Status",
            "Notes"
        ]

        let rows = items.map { item in
            [
                item.name,
                item.category,
                item.brand,
                item.condition,
                String(format: "%.2f", item.purchasePrice),
                String(format: "%.2f", item.targetSellingPrice),
                item.purchaseSource,
                AppFormatters.shortDate.string(from: item.purchaseDate),
                item.storageLocation,
                item.status,
                item.notes
            ]
        }

        return try writeCSV(named: "flipledger-inventory.csv", header: header, rows: rows)
    }

    static func exportSalesCSV(sales: [SaleRecord], currencyCode: String) throws -> URL {
        let header = [
            "Item",
            "Category",
            "Marketplace",
            "Sale Price",
            "Platform Fee",
            "Shipping",
            "Packaging",
            "Promotion",
            "Discount",
            "Final Profit",
            "Sale Date",
            "Status"
        ]

        let rows = sales.map { sale in
            [
                sale.itemNameSnapshot,
                sale.categorySnapshot,
                sale.marketplace,
                String(format: "%.2f", sale.salePrice),
                String(format: "%.2f", sale.platformFee),
                String(format: "%.2f", sale.shippingCost),
                String(format: "%.2f", sale.packagingCost),
                String(format: "%.2f", sale.promotionCost),
                String(format: "%.2f", sale.discount),
                String(format: "%.2f", sale.finalProfit),
                AppFormatters.shortDate.string(from: sale.saleDate),
                sale.status
            ]
        }

        return try writeCSV(named: "flipledger-sales.csv", header: header, rows: rows)
    }

    static func exportProfitReportPDF(items: [InventoryItem], sales: [SaleRecord], currencyCode: String, includeFooter: Bool) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("flipledger-profit-report.pdf")
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let totalRevenue = sales.reduce(0) { $0 + $1.salePrice }
        let totalProfit = sales.reduce(0) { $0 + $1.finalProfit }
        let inventoryValue = items.filter { !$0.isSoldOrClosed }.reduce(0) { $0 + $1.purchasePrice }

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 42

            func draw(_ text: String, font: UIFont, color: UIColor = .label, indent: CGFloat = 42, spacing: CGFloat = 28) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                text.draw(in: CGRect(x: indent, y: y, width: page.width - (indent * 2), height: spacing * 2), withAttributes: attributes)
                y += spacing
            }

            draw("FlipLedger AI Profit Report", font: .boldSystemFont(ofSize: 24), spacing: 36)
            draw("Generated \(AppFormatters.shortDate.string(from: .now))", font: .systemFont(ofSize: 12), color: .secondaryLabel)
            y += 12
            draw("Total revenue: \(AppFormatters.currency(totalRevenue, code: currencyCode))", font: .boldSystemFont(ofSize: 18))
            draw("Estimated profit: \(AppFormatters.currency(totalProfit, code: currencyCode))", font: .boldSystemFont(ofSize: 18), color: UIColor.systemGreen)
            draw("Unsold inventory value: \(AppFormatters.currency(inventoryValue, code: currencyCode))", font: .systemFont(ofSize: 16))
            draw("Sold items: \(sales.count)", font: .systemFont(ofSize: 16))
            y += 20

            draw("Recent sales", font: .boldSystemFont(ofSize: 18), spacing: 32)
            for sale in sales.sorted(by: { $0.saleDate > $1.saleDate }).prefix(10) {
                if y > 700 {
                    context.beginPage()
                    y = 42
                }
                draw("\(sale.itemNameSnapshot) / \(sale.marketplace) / \(AppFormatters.currency(sale.finalProfit, code: currencyCode)) profit", font: .systemFont(ofSize: 12), spacing: 20)
            }

            y = max(y + 20, 710)
            draw("Disclaimer: \(DisclaimerText.short)", font: .systemFont(ofSize: 10), color: .secondaryLabel, spacing: 28)

            if includeFooter {
                draw("Generated with FlipLedger AI Free", font: .boldSystemFont(ofSize: 10), color: .secondaryLabel, spacing: 18)
            }
        }

        try data.write(to: url, options: .atomic)
        return url
    }

    private static func writeCSV(named name: String, header: [String], rows: [[String]]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        let csv = ([header] + rows)
            .map { row in row.map(csvCell).joined(separator: ",") }
            .joined(separator: "\n")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func csvCell(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

@MainActor
@Observable
final class SubscriptionService {
    private(set) var products: [Product] = []
    var currentPlan: SubscriptionPlan = .free
    var isLoading = false
    var errorMessage: String?

    var hasProAccess: Bool {
        currentPlan != .free
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Array(SubscriptionPlan.paidProductIDs))
                .sorted { $0.displayName < $1.displayName }
        } catch {
            errorMessage = "StoreKit products are not available yet. Check product IDs or the StoreKit configuration."
        }
    }

    func purchase(_ plan: SubscriptionPlan) async {
        guard let productID = plan.productID else {
            currentPlan = .free
            return
        }
        guard let product = products.first(where: { $0.id == productID }) else {
            errorMessage = "This subscription product is not loaded yet."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                currentPlan = SubscriptionPlan(productID: transaction.productID) ?? .free
                await transaction.finish()
            case .pending:
                errorMessage = "Purchase pending. Check again after approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "Purchase could not be completed."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updatePurchasedProducts() async {
        var resolvedPlan: SubscriptionPlan = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  let plan = SubscriptionPlan(productID: transaction.productID) else {
                continue
            }
            if plan == .businessMonthly {
                resolvedPlan = .businessMonthly
            } else if resolvedPlan == .free {
                resolvedPlan = plan
            }
        }

        currentPlan = resolvedPlan
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, _):
            throw SubscriptionStoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }
}

enum SubscriptionStoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "The App Store could not verify this transaction."
    }
}

@MainActor
enum DefaultDataSeeder {
    static func seedMarketplaceSettingsIfNeeded(in context: ModelContext, currencyCode: String) {
        do {
            let existing = try context.fetch(FetchDescriptor<MarketplaceSettings>())
            guard existing.isEmpty else { return }

            let defaults: [(Marketplace, Double, Double)] = [
                (.vinted, 0, 0),
                (.ebay, 12.8, 0.30),
                (.depop, 10, 0),
                (.facebookMarketplace, 5, 0),
                (.etsy, 6.5, 0.20),
                (.amazon, 15, 0),
                (.other, 10, 0)
            ]

            for item in defaults {
                context.insert(MarketplaceSettings(
                    marketplaceName: item.0.rawValue,
                    defaultFeePercentage: item.1,
                    fixedFee: item.2,
                    currency: currencyCode
                ))
            }
            try context.save()
        } catch {
            assertionFailure("Unable to seed marketplace settings: \(error)")
        }
    }
}
