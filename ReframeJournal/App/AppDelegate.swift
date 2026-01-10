// File: App/AppDelegate.swift
import Foundation
import GoogleMobileAds
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Skip GoogleMobileAds initialization in test environment
        #if !DEBUG || !targetEnvironment(simulator)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
        return true
    }
}
