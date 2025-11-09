# In-App Purchase (IAP) Setup Guide

This guide explains how to set up In-App Purchases for FemCare+ subscriptions.

## Product IDs

The app uses the following product IDs for subscriptions:

- **Monthly**: `femcare_premium_monthly`
- **Quarterly**: `femcare_premium_quarterly`
- **Yearly**: `femcare_premium_yearly`

## Android Setup (Google Play Console)

### 1. Create Subscription Products

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to **Monetize** > **Products** > **Subscriptions**
4. Click **Create subscription**

### 2. Configure Each Subscription

For each subscription tier (Monthly, Quarterly, Yearly):

1. **Product ID**: Use the corresponding ID from above
2. **Name**: e.g., "FemCare+ Premium Monthly"
3. **Description**: Describe the subscription benefits
4. **Billing period**: Set according to the plan (1 month, 3 months, 1 year)
5. **Price**: Set your desired price
6. **Free trial** (optional): Configure if you want to offer a free trial
7. **Grace period**: Configure grace period for failed payments

### 3. Activate Products

- Make sure all products are **Active** before testing
- Products must be published to be available in production

### 4. Testing

1. Create test accounts in Google Play Console
2. Add test accounts to your app's license testing list
3. Use test cards for payment testing

## iOS Setup (App Store Connect)

### 1. Create Subscription Groups

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Navigate to **Features** > **In-App Purchases**
4. Create a **Subscription Group** (e.g., "FemCare+ Premium")

### 2. Create Subscription Products

For each subscription tier:

1. Click **+** to create a new subscription
2. **Product ID**: Use the corresponding ID from above
3. **Reference Name**: e.g., "Monthly Premium"
4. **Subscription Duration**: Set according to the plan
5. **Price**: Set your desired price
6. **Localization**: Add descriptions in all supported languages

### 3. Configure Subscription Details

- **Subscription Display Name**: User-facing name
- **Description**: Benefits of the subscription
- **Review Information**: Screenshots and description for App Review

### 4. Submit for Review

- All subscriptions must be submitted for App Review
- Products must be approved before they're available

### 5. Testing

1. Use Sandbox test accounts
2. Create test accounts in App Store Connect
3. Sign out of your Apple ID on the device
4. Test purchases will use sandbox environment

## Implementation Details

### IAP Service

The `IAPService` class handles:
- Product loading
- Purchase initiation
- Purchase verification
- Subscription status updates
- Restore purchases

### Subscription Service Integration

The `SubscriptionService` integrates with `IAPService` to:
- Create subscriptions from IAP purchases
- Update subscription status in Firestore
- Calculate subscription end dates
- Handle subscription renewals

### Purchase Flow

1. User selects a subscription plan
2. IAP service loads product details
3. User confirms purchase
4. Platform handles payment
5. Purchase is verified
6. Subscription is created/updated in Firestore
7. User gains premium access

### Receipt Validation

**Current Implementation:**
- Basic platform verification (trusts platform)
- Purchase ID validation
- Product ID validation

**Recommended for Production:**
- Server-side receipt validation
- Verify receipts with Google Play/App Store APIs
- Store verification results in backend
- Handle subscription renewals server-side

## Testing Checklist

### Android
- [ ] Products are created and active in Play Console
- [ ] Test accounts are configured
- [ ] Test purchases work correctly
- [ ] Subscription status updates correctly
- [ ] Restore purchases works
- [ ] Subscription renewals work

### iOS
- [ ] Subscription group is created
- [ ] All products are created and submitted
- [ ] Sandbox test accounts are configured
- [ ] Test purchases work correctly
- [ ] Subscription status updates correctly
- [ ] Restore purchases works
- [ ] Subscription renewals work

## Common Issues

### Products Not Loading
- **Android**: Ensure products are published and active
- **iOS**: Ensure products are approved and available
- Check product IDs match exactly
- Verify app bundle ID/package name matches

### Purchase Fails
- Check internet connection
- Verify user is signed in to correct account
- Check payment method is valid
- Review error logs in Firebase Crashlytics

### Subscription Not Activating
- Verify purchase verification logic
- Check Firestore write permissions
- Review subscription service logs
- Ensure user ID is correct

## Security Best Practices

1. **Server-Side Verification**: Always verify receipts on your backend
2. **Encrypt Transaction Data**: Store transaction IDs securely
3. **Monitor for Fraud**: Track unusual purchase patterns
4. **Handle Refunds**: Implement logic to handle refunds
5. **Subscription Expiry**: Check subscription status regularly

## Next Steps

1. Set up products in Google Play Console and App Store Connect
2. Implement server-side receipt validation (recommended)
3. Test thoroughly with sandbox/test accounts
4. Monitor subscription metrics in analytics
5. Set up subscription renewal notifications

## Resources

- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [App Store In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
- [Flutter in_app_purchase Package](https://pub.dev/packages/in_app_purchase)

