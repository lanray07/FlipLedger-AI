import SwiftUI
import UIKit

struct ProfitSummaryCard: View {
    var title: String
    var value: String
    var subtitle: String?
    var systemImage: String
    var tint: Color = .flipGreen

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                Spacer()
            }

            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        )
    }
}

struct InventoryItemCard: View {
    var item: InventoryItem
    var currencyCode: String

    var body: some View {
        HStack(spacing: 14) {
            PhotoTile(data: item.photos.first?.imageData, systemImage: "shippingbox")
                .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(item.status)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusTint.opacity(0.12), in: Capsule())
                        .foregroundStyle(statusTint)
                }

                Text([item.brand, item.category, item.condition].filter { !$0.isEmpty }.joined(separator: " / "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    Label(AppFormatters.currency(item.purchasePrice, code: currencyCode), systemImage: "cart")
                    Spacer()
                    Label(AppFormatters.currency(item.targetSellingPrice, code: currencyCode), systemImage: "tag")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        )
    }

    private var statusTint: Color {
        switch item.status {
        case ItemStatus.sold.rawValue, ItemStatus.shipped.rawValue:
            .flipGreen
        case ItemStatus.returned.rawValue, ItemStatus.refunded.rawValue:
            .red
        case ItemStatus.listed.rawValue:
            .blue
        default:
            .secondary
        }
    }
}

struct SaleRecordCard: View {
    var sale: SaleRecord
    var currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sale.itemNameSnapshot.isEmpty ? "Sale" : sale.itemNameSnapshot)
                        .font(.headline)
                    Text("\(sale.marketplace) / \(AppFormatters.shortDate.string(from: sale.saleDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(AppFormatters.currency(sale.finalProfit, code: currencyCode))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(sale.finalProfit >= 0 ? Color.flipGreen : Color.red)
            }

            HStack {
                Label(AppFormatters.currency(sale.salePrice, code: currencyCode), systemImage: "banknote")
                Spacer()
                Label(sale.status, systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        )
    }
}

struct MarketplaceBadge: View {
    var marketplace: String

    var body: some View {
        Text(marketplace)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.green.opacity(0.12), in: Capsule())
            .foregroundStyle(Color.flipGreen)
    }
}

struct ListingDraftView: View {
    var title: String
    var shortDescription: String
    var detailedDescription: String
    var bulletPoints: [String]
    var keywords: [String]
    var suggestedPriceRange: String
    var sellingTips: [String]

    init(result: ListingGenerationResult) {
        title = result.title
        shortDescription = result.shortDescription
        detailedDescription = result.detailedDescription
        bulletPoints = result.bulletPoints
        keywords = result.keywords
        suggestedPriceRange = result.suggestedPriceRange
        sellingTips = result.sellingTips
    }

    init(draft: ListingDraft) {
        title = draft.title
        shortDescription = draft.shortDescription
        detailedDescription = draft.detailedDescription
        bulletPoints = draft.bulletPoints
        keywords = draft.keywords
        suggestedPriceRange = draft.suggestedPriceRange
        sellingTips = draft.sellingTips
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.bold())
            Text(shortDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Text(detailedDescription)
                .font(.body)
                .textSelection(.enabled)

            if !bulletPoints.isEmpty {
                Label("Listing bullets", systemImage: "list.bullet")
                    .font(.headline)
                ForEach(bulletPoints, id: \.self) { bullet in
                    Text("- \(bullet)")
                        .font(.subheadline)
                }
            }

            if !keywords.isEmpty {
                FlowTags(tags: keywords)
            }

            Text(suggestedPriceRange)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.flipGreen)

            if !sellingTips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selling tips")
                        .font(.headline)
                    ForEach(sellingTips, id: \.self) { tip in
                        Label(tip, systemImage: "lightbulb")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        )
    }
}

struct PricingSuggestionCard: View {
    var suggestion: PricingSuggestion
    var currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested price range")
                .font(.headline)
            Text(suggestion.suggestedPriceRange)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                priceColumn("Quick sale", suggestion.quickSalePrice)
                Divider()
                priceColumn("Recommended", suggestion.recommendedPrice)
                Divider()
                priceColumn("Maximum", suggestion.maximumPrice)
            }
            .frame(minHeight: 62)

            Label(suggestion.profitWarning, systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(Color.flipWarning)

            Text(suggestion.confidence)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        )
    }

    private func priceColumn(_ title: String, _ value: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(AppFormatters.currency(value, code: currencyCode))
                .font(.subheadline.bold())
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AnalyticsChartCard<Content: View>: View {
    var title: String
    var subtitle: String?
    @ViewBuilder var content: () -> Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            content()
                .frame(minHeight: 220)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        )
    }
}

struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscriptionService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unlock FlipLedger AI")
                        .font(.largeTitle.bold())
                    Text("Track more inventory, use AI listing tools, export reports, and get richer reseller analytics.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                ForEach([SubscriptionPlan.proMonthly, .proYearly, .businessMonthly], id: \.self) { plan in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.rawValue)
                                    .font(.headline)
                                Text(plan.placeholderPrice)
                                    .font(.title3.bold())
                            }
                            Spacer()
                            Button {
                                Task { await subscriptionService.purchase(plan) }
                            } label: {
                                if subscriptionService.isLoading {
                                    ProgressView()
                                } else {
                                    Text("Choose")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.flipGreen)
                        }

                        Text(plan.featureSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(plan == .proYearly ? Color.flipGreen : Color.secondary.opacity(0.25), lineWidth: plan == .proYearly ? 2 : 1)
                    )
                }

                Button {
                    Task { await subscriptionService.restorePurchases() }
                } label: {
                    Label("Restore purchases", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                if let error = subscriptionService.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                DisclaimerBox()
            }
            .padding()
        }
        .navigationTitle("Plans")
    }
}

struct UpgradeBanner: View {
    var title = "Pro feature"
    var message = "Upgrade to unlock unlimited tracking, AI tools, analytics, and exports."

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.flipGreen)
                .frame(width: 30, height: 30)
                .background(Color.flipGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.flipGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.flipGreen.opacity(0.25), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 38))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct DisclaimerBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Important", systemImage: "info.circle")
                .font(.headline)
            ForEach(DisclaimerText.full, id: \.self) { item in
                Text("- \(item)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct PhotoTile: View {
    var data: Data?
    var systemImage: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.12))

            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .clipped()
    }
}

struct FlowTags: View {
    var tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }
        }
    }
}
