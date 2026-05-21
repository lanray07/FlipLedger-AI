# App Privacy Answers

Use these answers for the current local-first, mock-AI build.

## Data Collection

Answer: No, this app does not collect data.

Reason: inventory items, photos, notes, listing drafts, sales records, reports, and preferences are stored locally on the user's device. The current app uses `MockAIService` by default and does not transmit this data to the developer or third-party partners.

## Tracking

Answer: No, this app does not track users.

## Advertising

Answer: No third-party advertising. No IDFA usage.

## Payments

StoreKit/App Store handles payment information. The developer does not receive payment card details.

## If Remote AI Is Enabled Later

Update App Privacy before submission if the production build sends data to a backend. Likely disclosures:

- User Content: item photos, item notes, listing draft inputs
- Purchases: only if your backend receives subscription entitlement information
- Usage Data: only if analytics or logging is added
- Purpose: App Functionality
- Linked to user: depends on whether accounts or identifiers are added
- Tracking: No, unless data is used across apps/websites for advertising or data broker purposes
