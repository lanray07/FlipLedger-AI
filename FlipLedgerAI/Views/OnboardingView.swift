import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("primaryMarketplace") private var primaryMarketplace = Marketplace.vinted.rawValue
    @AppStorage("resellerType") private var resellerType = ResellerType.beginner.rawValue
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(.flipGreen)
                            .frame(width: 64, height: 64)
                            .background(Color.flipGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                        Text("FlipLedger AI")
                            .font(.largeTitle.bold())
                        Text("A reseller profit tracker for inventory, sales, fees, pricing, AI listings, and clear analytics.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Marketplace", selection: $primaryMarketplace) {
                            ForEach(Marketplace.allCases) { marketplace in
                                Text(marketplace.rawValue).tag(marketplace.rawValue)
                            }
                        }

                        Picker("Reseller type", selection: $resellerType) {
                            ForEach(ResellerType.allCases) { type in
                                Text(type.rawValue).tag(type.rawValue)
                            }
                        }

                        Picker("Currency", selection: $currencyCode) {
                            ForEach(CurrencyCode.allCases) { currency in
                                Text(currency.rawValue).tag(currency.rawValue)
                            }
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.separator.opacity(0.35), lineWidth: 1)
                    )

                    DisclaimerBox()

                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        Label("Start tracking profit", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.flipGreen)
                }
                .padding()
            }
            .navigationTitle("Welcome")
        }
    }
}
