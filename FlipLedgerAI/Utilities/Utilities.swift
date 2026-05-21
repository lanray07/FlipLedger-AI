import Foundation
import SwiftUI

enum AppFormatters {
    static func currency(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = code == CurrencyCode.ngn.rawValue ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(code) \(value)"
    }

    static func percent(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value / 100)) ?? "\(value)%"
    }

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let monthAndYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
}

enum DisclaimerText {
    static let short = "Estimates only. Check current marketplace fees, comparable listings, shipping, and tax obligations before making decisions."

    static let full = [
        "Profit calculations are estimates and may not include every cost.",
        "Marketplace fees, promoted listing charges, taxes, and shipping rates can change.",
        "Suggested prices are not guaranteed sale prices.",
        "FlipLedger AI does not provide tax, legal, or financial advice.",
        "Always verify fees, comparable listings, and your local tax obligations."
    ]

    static let internalAIPrompt = """
    You are FlipLedger AI, an assistant for online resellers. Help users create accurate listings, estimate resale pricing, calculate profit, and understand reseller performance. Do not guarantee sales, profits, marketplace ranking, or tax outcomes. Use practical, cautious language and remind users to check current marketplace fees and comparable listings.
    """
}

extension Color {
    static let flipGreen = Color(red: 0.0, green: 0.55, blue: 0.31)
    static let flipGreenSoft = Color(red: 0.88, green: 0.97, blue: 0.92)
    static let flipCharcoal = Color(red: 0.09, green: 0.10, blue: 0.11)
    static let flipMuted = Color(red: 0.43, green: 0.47, blue: 0.50)
    static let flipWarning = Color(red: 0.84, green: 0.50, blue: 0.05)
}

extension Double {
    var clampedNonNegative: Double {
        max(0, self)
    }
}

struct ChartDataPoint: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var value: Double
}

struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

extension Calendar {
    func monthKey(for date: Date) -> String {
        let components = dateComponents([.year, .month], from: date)
        let normalized = self.date(from: components) ?? date
        return AppFormatters.monthAndYear.string(from: normalized)
    }
}
