# App Store Asset Upload Checklist

Generated on May 21, 2026.

## Required Assets Created

### App Icon

- `FlipLedgerAI/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- `AppStoreConnect/Assets/AppIcon/AppIcon-1024.png`

Use the Xcode asset catalog icon in the app build. The App Store icon is delivered with the uploaded build.

### iPhone Screenshots

Device well: iPhone 6.9" Display  
Size: 1320 x 2868 px  
Format: PNG  
Path: `AppStoreConnect/Assets/iPhone-6.9/`

Files:

- `01-dashboard.png`
- `02-inventory.png`
- `03-profit-calculator.png`
- `04-ai-listing.png`
- `05-analytics.png`

### iPad Screenshots

Device well: iPad 13" Display  
Size: 2048 x 2732 px  
Format: PNG  
Path: `AppStoreConnect/Assets/iPad-13/`

Files:

- `01-dashboard.png`
- `02-inventory.png`
- `03-profit-calculator.png`
- `04-ai-listing.png`
- `05-analytics.png`

### Subscription Review Screenshot

Path: `AppStoreConnect/Assets/SubscriptionReview/paywall-review.png`

Upload this same screenshot in each subscription product's Review Information section:

- `com.flipledgerai.pro.monthly`
- `com.flipledgerai.pro.yearly`
- `com.flipledgerai.business.monthly`

## Upload Steps

1. Sign in to App Store Connect.
2. Open `My Apps` > `FlipLedger AI` > iOS version `1.0.0`.
3. In App Previews and Screenshots, upload the five iPhone PNG files to the iPhone 6.9" screenshot well.
4. Upload the five iPad PNG files to the iPad 13" screenshot well.
5. Upload a build from Xcode that includes the generated app icon asset catalog.
6. Add `AppStoreConnect/Assets/SubscriptionReview/paywall-review.png` to each subscription product's Review Information section.

## Notes

These are designed App Store marketing screenshots based on the implemented app screens. Before final App Review, compare them against a real simulator/device build and replace any screenshot that no longer matches the shipped interface.
