# FlipLedger AI

FlipLedger AI is a SwiftUI + SwiftData iOS app for reseller profit tracking across Vinted, eBay, Depop, Facebook Marketplace, Etsy, Amazon, and other marketplaces.

## What is included

- Onboarding with marketplace, reseller type, currency, and disclaimer setup
- Dashboard with revenue, profit, inventory value, sold items, best category, margin, and subscription status
- Inventory tracker with photo upload/camera support
- Profit calculator with fees, shipping, packaging, promotion, discount, and tax placeholder
- Sales tracker with final profit calculation
- Mock-first AI listing generator, pricing assistant, photo scanner, tips, and monthly summary service
- Remote AI service placeholder using `POST https://YOUR_BACKEND_URL.com/flipledger-ai`
- Analytics with Swift Charts
- PDF and CSV export services with native share sheet
- StoreKit 2 subscription scaffolding and StoreKit config placeholders
- Settings for subscriptions, currency, marketplace fee defaults, exports, local data deletion, privacy, terms, and AI disclaimer

## Notes before production release

- Replace the placeholder backend URL in `FlipLedgerAI/Services/AIService.swift`.
- Never place API keys in the iOS app. Call your own backend from `RemoteAIService`.
- Configure real App Store Connect subscription products for the StoreKit product IDs.
- Add final app icons to `FlipLedgerAI/Resources/Assets.xcassets/AppIcon.appiconset`.
- Verify current marketplace fees and legal/tax wording before shipping.
