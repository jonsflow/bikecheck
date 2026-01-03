import UserNotifications
import BackgroundTasks
import UIKit
import os.log

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.bikecheck", category: "Notifications")
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion(granted, error)
        }
    }
    
    func sendNotification(for interval: ServiceInterval) {
        if interval.notify {
            // Throttle: max once per week (604800 seconds = 7 days)
            if let lastNotificationDate = interval.lastNotificationDate,
               Date().timeIntervalSince(lastNotificationDate) < 604800 {
                logger.info("Skipping notification for \(interval.part) - sent within last 7 days")
                return
            }

            logger.info("Sending notification for \(interval.part)")
            let content = UNMutableNotificationContent()
            content.title = "\(interval.bike.name) Service Reminder"
            content.body = "It's time to service your \(interval.part)."
            content.sound = UNNotificationSound.default

            // Use consistent identifier based on service interval ID to prevent duplicate notifications
            // This ensures that subsequent notifications for the same interval replace previous ones
            let identifier = "service-interval-\(interval.id?.uuidString ?? UUID().uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

            center.add(request) { [weak self] (error) in
                if let error = error {
                    self?.logger.error("Error adding notification request: \(error.localizedDescription)")
                } else {
                    self?.logger.info("Notification request added successfully for interval: \(identifier)")

                    // Update lastNotificationDate after successful notification
                    interval.lastNotificationDate = Date()
                    try? interval.managedObjectContext?.save()
                }
            }
        }
    }
    
    func scheduleBackgroundTask() {
        print("scheduling serviceInt Notification background task")
        // Delegate scheduling to the BackgroundTaskManager
        BackgroundTaskManager.shared.scheduleBackgroundTask(identifier: .checkServiceInterval)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received notification while in the foreground")
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User tapped notification: \(response.notification.request.identifier)")
        
        // Parse service interval ID from notification identifier and create deep link
        // Format: "service-interval-[UUID]"
        let identifier = response.notification.request.identifier
        if identifier.hasPrefix("service-interval-"),
           let serviceIntervalUUID = extractServiceIntervalUUID(from: identifier) {
            
            // Create deep link URL and open it
            let deepLinkURL = URL(string: "bikecheck://service-interval/\(serviceIntervalUUID.uuidString)")!
            UIApplication.shared.open(deepLinkURL)
        }
        
        completionHandler()
    }
    
    private func extractServiceIntervalUUID(from identifier: String) -> UUID? {
        // Extract UUID from "service-interval-[UUID]" format
        let prefix = "service-interval-"
        guard identifier.hasPrefix(prefix) else { return nil }
        
        let uuidString = String(identifier.dropFirst(prefix.count))
        return UUID(uuidString: uuidString)
    }
}