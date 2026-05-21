# App Store Connect Submission Pack

Prepared for FlipLedger AI on May 21, 2026.

This document contains the App Store Connect form values that can be pasted into Apple's forms. You must sign in as the Apple Developer Account Holder, Admin, or App Manager to create the app record and submit it.

## Current Blockers Before App Review

- Upload a real Xcode archive from macOS.
- Add final app icon artwork to `FlipLedgerAI/Resources/Assets.xcassets/AppIcon.appiconset`.
- Create iPhone and iPad screenshots.
- Confirm the bundle identifier in Apple Developer Certificates, Identifiers & Profiles.
- Confirm export compliance answers with the Account Holder.
- Replace placeholder URLs with a production website if you do not want to use GitHub public pages.
- Enable a real backend before marketing AI features as live cloud AI. The current app uses mock AI by default.

## New App Record

| Field | Value |
| --- | --- |
| Platform | iOS |
| Name | FlipLedger AI |
| Primary language | English (U.K.) |
| Bundle ID | `com.flipledgerai.app` |
| SKU | `FLIPLEDGER-AI-IOS-001` |
| User Access | Full Access |

Apple role needed: Account Holder, Admin, or App Manager.

## App Information

| Field | Value |
| --- | --- |
| Category | Business |
| Secondary Category | Finance |
| Content Rights | Does not contain, show, or access third-party content that requires rights clearance, apart from marketplace names used descriptively. Confirm trademark usage before release. |
| Age Rating | Answer questionnaire with no objectionable content, no gambling, no contests, no unrestricted web access, no social networking, no public user-generated content. Do not mark as Made for Kids. Expected rating is likely low, but Apple calculates the final rating. |
| License Agreement | Apple Standard EULA, unless you add a custom EULA. |

## Pricing And Availability

| Field | Value |
| --- | --- |
| App Price | Free |
| Monetization | Auto-renewable subscriptions via StoreKit 2 |
| Availability | All countries/regions, unless your legal/tax review excludes regions |
| Pre-order | No |
| Apple Business Manager / Apple School Manager | Available without reduced price |

## Version Information

| Field | Value |
| --- | --- |
| Version | 1.0.0 |
| Subtitle | Reseller profit tracker |
| Promotional Text | Track reseller inventory, fees, sales, profit, listing drafts, pricing suggestions, analytics, and export-ready reports in one clean dashboard. |
| Keywords | reseller,inventory,profit,Vinted,eBay,Depop,Etsy,Amazon,pricing,sales,shipping,fees |
| Support URL | `https://github.com/lanray07/FlipLedger-AI/blob/main/SUPPORT.md` |
| Marketing URL | `https://github.com/lanray07/FlipLedger-AI` |
| Privacy Policy URL | `https://github.com/lanray07/FlipLedger-AI/blob/main/PRIVACY.md` |
| Copyright | Copyright 2026 Lanray Banks |

## App Description

FlipLedger AI is a profit tracker and inventory workspace for online resellers.

Track what you bought, what it cost, where it is stored, where it sold, and how much profit you actually made after fees, shipping, packaging, discounts, and promotion costs.

Built for Vinted, eBay, Depop, Facebook Marketplace, Etsy, Amazon, and other resale workflows, FlipLedger AI helps beginners and experienced sellers understand their numbers before they list, accept offers, or restock.

Key features:

- Inventory tracking with item photos, purchase cost, source, condition, brand, size, storage location, notes, and target selling price
- Sales tracker for sale price, marketplace, fees, shipping, packaging, discount, status, and final profit
- Profit calculator with net profit, margin, ROI, break-even price, and recommended minimum selling price
- AI listing draft tools for titles, descriptions, bullet points, keywords, suggested price ranges, and selling tips
- AI pricing assistant with recommended, quick-sale, and maximum price suggestions
- Inventory scanner placeholder for photo-assisted item categorization and draft listings
- Analytics for profit by marketplace, category, brand, monthly revenue, monthly profit, slow-moving stock, average days to sell, and ROI by sourcing source
- CSV and PDF export tools for reports, inventory valuation, and tax-prep summaries
- Local-first storage with SwiftData
- Dark and light mode support

FlipLedger AI uses cautious estimates. Profit calculations, fee estimates, pricing suggestions, and AI-generated listing drafts are not guarantees. Always check current marketplace fees, shipping rates, comparable sold listings, and your tax obligations before making business decisions.

## What's New

Initial release of FlipLedger AI with inventory tracking, sales records, profit calculator, listing drafts, pricing suggestions, analytics, subscriptions, and export scaffolding.

## App Review Information

| Field | Value |
| --- | --- |
| Sign-in required | No |
| Demo account | Not required |
| Contact first name | Lanray |
| Contact last name | Banks |
| Phone | Add account holder phone number |
| Email | Add support email |

### Review Notes

FlipLedger AI does not require sign-in.

To test the core flow:

1. Complete onboarding by selecting a marketplace, reseller type, and currency.
2. Open Dashboard and add an inventory item.
3. Record a sale and review the final profit calculation.
4. Open Profit Calculator and enter sample costs.
5. Open Reports to generate a PDF report.
6. Use a sandbox subscription to unlock Pro-gated AI tools, analytics, CSV exports, and unlimited tracking.

AI features currently use the app's mock AI service by default. Generated listing text and price ranges are cautious examples and remind users to verify marketplace comparable listings and fees.

## Export Compliance

Recommended App Store Connect answer for the current app:

- Uses non-exempt encryption: No
- Reason: the app does not implement proprietary encryption. Any networking uses standard Apple platform capabilities such as HTTPS/TLS.

The project includes `ITSAppUsesNonExemptEncryption = false` in `Info.plist`. The Account Holder should confirm this answer for the final production build.

## Advertising Identifier

| Question | Answer |
| --- | --- |
| Does this app use the Advertising Identifier (IDFA)? | No |

## Privacy Nutrition Label

For the current mock-AI local-first build:

| Question | Answer |
| --- | --- |
| Do you or your third-party partners collect data from this app? | No |
| Tracking | No |
| Third-party advertising | No |

If you enable `RemoteAIService` in production, update the privacy label before submission because item details, notes, and selected photos may be transmitted to your backend for app functionality.

## Subscriptions

Create one subscription group:

| Field | Value |
| --- | --- |
| Reference Name | FlipLedger AI Plans |
| Display Name | FlipLedger AI Plans |

Products:

| Product | Product ID | Duration | Placeholder Price | Level |
| --- | --- | --- | --- | --- |
| Business Monthly | `com.flipledgerai.business.monthly` | 1 month | GBP 24.99 | 1 |
| Pro Yearly | `com.flipledgerai.pro.yearly` | 1 year | GBP 79.99 | 2 |
| Pro Monthly | `com.flipledgerai.pro.monthly` | 1 month | GBP 9.99 | 3 |

### Subscription Localizations

Business Monthly description:
Advanced reseller analytics, advanced reports, sourcing insights, multi-marketplace tracking, and business placeholders.

Pro Yearly description:
Annual access to unlimited inventory, unlimited sales, AI listing tools, AI pricing, analytics, CSV exports, and PDF reports.

Pro Monthly description:
Monthly access to unlimited inventory, unlimited sales, AI listing tools, AI pricing, analytics, CSV exports, and PDF reports.

### Subscription Review Notes

Subscriptions unlock higher usage limits and Pro/Business tools. Free users can track up to 25 inventory items, 10 sales per month, and use the basic profit calculator. Pro unlocks unlimited inventory, unlimited sales, AI listing generator, AI pricing assistant, analytics, CSV/PDF exports, monthly reports, sourcing insights, slow-moving inventory alerts, and multi-marketplace tracking.

Upload a screenshot of the in-app paywall for each subscription product before submitting the IAPs for review.
