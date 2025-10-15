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
    }

    /// Register the user for push notifications with OneSignal
    func registerForPushNotifications() {
        guard let userId = authManager.userId else {
            return
        }

        // 1. Register with iOS for remote notifications
        UIApplication.shared.registerForRemoteNotifications()

        // 2. Request permission and login to OneSignal
        OneSignal.Notifications.requestPermission({ accepted in
            if accepted {
                // Opt in first (in case they were previously opted out)
                OneSignal.User.pushSubscription.optIn()

                // Then login to OneSignal with the user's Supabase ID
                OneSignal.login(userId)
            }
        }, fallbackToSettings: true)

        // Optional: Set additional user properties
        // OneSignal.User.addTag(key: "user_type", value: "premium")
    }

    /// Unregister the user from push notifications with OneSignal
    func unregisterFromPushNotifications() {
        // 1. Logout from OneSignal to remove external user ID
        OneSignal.logout()

        // 2. Opt out from OneSignal push subscription
        OneSignal.User.pushSubscription.optOut()

        // 3. Unregister from Apple Push Notification service
        UIApplication.shared.unregisterForRemoteNotifications()
    }

    /// Call this when user logs in to ensure notifications are set up correctly
    func syncNotificationState() {
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
