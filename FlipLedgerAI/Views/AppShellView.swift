import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                AppShellView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode = CurrencyCode.gbp.rawValue
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "chart.pie") }
            .tag(AppTab.dashboard)

            NavigationStack {
                InventoryListView()
            }
            .tabItem { Label("Inventory", systemImage: "shippingbox") }
            .tag(AppTab.inventory)

            NavigationStack {
                SalesTrackerView()
            }
            .tabItem { Label("Sales", systemImage: "banknote") }
            .tag(AppTab.sales)

            NavigationStack {
                AIToolsView()
            }
            .tabItem { Label("AI Tools", systemImage: "sparkles") }
            .tag(AppTab.aiTools)

            NavigationStack {
                AnalyticsView()
            }
            .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
            .tag(AppTab.analytics)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
        .tint(.flipGreen)
        .task {
            DefaultDataSeeder.seedMarketplaceSettingsIfNeeded(in: modelContext, currencyCode: currencyCode)
        }
    }
}

private enum AppTab {
    case dashboard
    case inventory
    case sales
    case aiTools
    case analytics
    case settings
}
