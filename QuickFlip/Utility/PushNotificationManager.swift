//
//  PushNotificationManager.swift
//  QuickFlip
//
//  Manages push notification registration/unregistration with OneSignal
//

import Foundation
import OneSignalFramework
import UIKit

@MainActor
class PushNotificationManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "pushNotificationsEnabled")
            if isEnabled {
                registerForPushNotifications()
            } else {
                unregisterFromPushNotifications()
            }
        }
    }

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
        // Load saved preference, default to true for new users
        self.isEnabled = UserDefaults.standard.object(forKey: "pushNotificationsEnabled") as? Bool ?? true

        print("🔔 PushNotificationManager initialized")
        print("   - isEnabled: \(isEnabled)")
        print("   - userId: \(authManager.userId ?? "nil")")
    }

    /// Register the user for push notifications with OneSignal
    func registerForPushNotifications() {
        guard let userId = authManager.userId else {
            print("⚠️ Cannot register for push notifications: No user ID available yet")
            return
        }

        print("✅ Registering user for push notifications with ID: \(userId)")

        // 1. Register with iOS for remote notifications
        UIApplication.shared.registerForRemoteNotifications()
        print("✅ iOS registerForRemoteNotifications called")

        // 2. Request permission and login to OneSignal
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")

            if accepted {
                // Opt in first (in case they were previously opted out)
                OneSignal.User.pushSubscription.optIn()
                print("✅ OneSignal optIn called")

                // Then login to OneSignal with the user's Supabase ID
                OneSignal.login(userId)
                print("✅ OneSignal logged in with user ID: \(userId)")
            } else {
                print("⚠️ User declined push notification permission")
            }
        }, fallbackToSettings: true)

        // Optional: Set additional user properties
        // OneSignal.User.addTag(key: "user_type", value: "premium")
    }

    /// Unregister the user from push notifications with OneSignal
    func unregisterFromPushNotifications() {
        print("🔕 Unregistering user from push notifications")

        // 1. Logout from OneSignal to remove external user ID
        OneSignal.logout()
        print("✅ OneSignal logout called")

        // 2. Opt out from OneSignal push subscription
        OneSignal.User.pushSubscription.optOut()
        print("✅ OneSignal optOut called")

        // 3. Unregister from Apple Push Notification service
        UIApplication.shared.unregisterForRemoteNotifications()
        print("✅ iOS unregisterForRemoteNotifications called")

        print("📊 Opted in status: \(OneSignal.User.pushSubscription.optedIn)")
    }

    /// Call this when user logs in to ensure notifications are set up correctly
    func syncNotificationState() {
        print("🔄 Syncing notification state...")
        print("   - isEnabled: \(isEnabled)")
        print("   - userId: \(authManager.userId ?? "nil")")

        if isEnabled {
            registerForPushNotifications()
        } else {
            unregisterFromPushNotifications()
        }
    }

    /// Call this when user logs out to clean up
    func handleLogout() {
        unregisterFromPushNotifications()
        // Reset to default (enabled) for next login
        isEnabled = true
    }
}
