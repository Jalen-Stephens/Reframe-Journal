# CloudKit/iCloud Sync Troubleshooting

If your journal entries aren't syncing between your iPhone and iPad, follow these steps:

## Quick Checks

1. **Same iCloud Account**
   - Both devices must be signed into the **same iCloud account**
   - Check: Settings → [Your Name] → Verify the Apple ID matches on both devices

2. **CloudKit Enabled in Xcode**
   - Open the project in Xcode
   - Select the app target
   - Go to "Signing & Capabilities"
   - Ensure "CloudKit" capability is added
   - The container should be: `iCloud.com.JalenStephens.ReframeJournal`

3. **Network Connection**
   - Both devices must be connected to the internet (WiFi or cellular)
   - CloudKit sync requires an active network connection

4. **App Active on Both Devices**
   - Open the app on both devices
   - CloudKit sync is triggered when the app is active
   - Pull down to refresh on either device to manually trigger sync

## First-Time Sync

- **First sync can take 5-10 minutes** after installing the app on a new device
- Be patient and keep the app open
- Pull down to refresh to manually trigger sync

## Manual Refresh

- **Pull down** on the Home screen or All Entries screen to refresh
- This forces SwiftData to check for CloudKit updates

## Verify CloudKit is Working

1. Create a new entry on your iPhone
2. Wait 1-2 minutes
3. Pull down to refresh on your iPad
4. The entry should appear

If it still doesn't sync after 10 minutes:

1. **Check Xcode Console** for CloudKit errors
2. **Verify Entitlements**: The `ReframeJournal.entitlements` file should have:
   - `com.apple.developer.icloud-services` with `CloudKit`
   - `com.apple.developer.icloud-container-identifiers` with `iCloud.$(PRODUCT_BUNDLE_IDENTIFIER)`

3. **Check ModelContainerConfig**: Should use `cloudKitDatabase: .automatic`

## Common Issues

### "No entries showing on iPad"
- **Solution**: Pull down to refresh, wait 2-3 minutes, try again
- Ensure both devices are on the same iCloud account

### "Entries created on iPad don't appear on iPhone"
- **Solution**: CloudKit sync is bidirectional but can have delays
- Pull down to refresh on iPhone
- Ensure both devices have internet connection

### "Sync was working but stopped"
- **Solution**: 
  - Close and reopen the app on both devices
  - Check internet connection
  - Verify iCloud account is still signed in

## Technical Details

- The app uses **SwiftData with CloudKit** for automatic sync
- Data is stored in your personal iCloud account
- Sync happens automatically when the app is active
- All journal entries and values profiles sync via CloudKit

## Still Not Working?

If sync still doesn't work after trying all steps:

1. Check Xcode console for CloudKit errors
2. Verify the bundle identifier matches in both Xcode and entitlements
3. Ensure CloudKit capability is enabled in Xcode Signing & Capabilities
4. Try signing out and back into iCloud on one device (as a last resort)
