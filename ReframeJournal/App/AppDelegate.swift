// File: App/AppDelegate.swift
import Foundation
import GoogleMobileAds
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
#if DEBUG
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [GADSimulatorID]
#endif
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
}
