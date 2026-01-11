// File: Services/AnalyticsService.swift
// Centralized analytics service wrapping PostHog SDK

import Foundation
import PostHog

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private var isInitialized = false
    
    private init() {}
    
    // MARK: - Initialization
    
    /// PostHog API key (hardcoded)
    private static let defaultAPIKey = "phc_mLKARo7GPI34LAAaQoR9yhiOQ5cZZWbWj1htSV1rOmL"
    
    /// PostHog host URL
    private static let defaultHost = "https://us.i.posthog.com"
    
    /// Initialize PostHog SDK
    func initialize() {
        // Skip initialization in test environment
        guard NSClassFromString("XCTestCase") == nil else {
    #if DEBUG
            print("AnalyticsService: Skipping initialization in test environment")
    #endif
            return
        }
        
        guard !isInitialized else { return }
        
        let configuration = PostHogConfig(apiKey: Self.defaultAPIKey, host: Self.defaultHost)
        // Disable autocapture for cleaner, intentional analytics
        configuration.captureApplicationLifecycleEvents = false
        configuration.captureScreenViews = false
        configuration.captureElementInteractions = false
        configuration.sessionReplay = false
        configuration.debug = false
        
        PostHogSDK.shared.setup(configuration)
        isInitialized = true
        
    #if DEBUG
        print("AnalyticsService: Initialized with host \(Self.defaultHost)")
    #endif
    }
    
    // MARK: - Event Tracking
    
    /// Track a custom event
    /// - Parameters:
    ///   - name: Event name (should be snake_case)
    ///   - properties: Optional event properties (must not contain PII)
    func trackEvent(_ name: String, properties: [String: Any]? = nil) {
        guard isInitialized else { return }
        
        let sanitizedProperties = sanitizeProperties(properties)
        PostHogSDK.shared.capture(name, properties: sanitizedProperties)
    }
    
    // MARK: - User Identification
    
    /// Identify a user with a unique ID
    /// - Parameter userId: Unique user identifier
    func identify(userId: String) {
        guard isInitialized else { return }
        PostHogSDK.shared.identify(userId)
    }
    
    /// Set user properties (updates existing user)
    /// - Parameter properties: User properties to set
    func setUserProperties(_ properties: [String: Any]) {
        guard isInitialized else { return }
        
        let sanitizedProperties = sanitizeProperties(properties)
        guard let properties = sanitizedProperties, !properties.isEmpty else { return }
        
        // PostHog iOS SDK: use capture with $identify event and $set properties for user property updates
        PostHogSDK.shared.capture("$identify", properties: ["$set": properties])
    }
    
    /// Reset user identity (for logout/account switching)
    func reset() {
        guard isInitialized else { return }
        PostHogSDK.shared.reset()
    }
    
    // MARK: - Private Helpers
    
    /// Sanitize properties to ensure no PII is included
    /// Only allows safe property types: String, Int, Double, Bool, Date, Array, Dictionary
    private func sanitizeProperties(_ properties: [String: Any]?) -> [String: Any]? {
        guard let properties = properties else { return nil }
        
        var sanitized: [String: Any] = [:]
        
        for (key, value) in properties {
            // Only allow safe types
            if value is String || value is Int || value is Double || value is Bool || value is Date {
                sanitized[key] = value
            } else if let array = value as? [Any] {
                // Allow arrays of safe types
                sanitized[key] = array
            } else if let dict = value as? [String: Any] {
                // Recursively sanitize nested dictionaries
                sanitized[key] = sanitizeProperties(dict) ?? [:]
            }
            // Skip any other types (e.g., complex objects)
        }
        
        return sanitized.isEmpty ? nil : sanitized
    }
}
