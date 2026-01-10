// File: App/AppDelegate.swift
import Foundation
import GoogleMobileAds
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Always initialize GoogleMobileAds SDK to prevent verification crash
        // Even in tests, the SDK needs to be started to avoid GADApplicationVerifyPublisherInitializedCorrectly
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
}
