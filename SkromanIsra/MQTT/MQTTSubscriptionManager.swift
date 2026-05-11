import Foundation
import AWSIoT

/// Global MQTT subscription manager.
/// - Ensures each topic is subscribed only once per app runtime.
/// - Fan-outs incoming payloads to multiple listeners.
final class MQTTSubscriptionManager {
    static let shared = MQTTSubscriptionManager()

    private let lock = NSLock()
    private var subscribedTopics: Set<String> = []
    private var handlersByTopic: [String: [(Data) -> Void]] = [:]

    private init() {}

    /// Subscribe to a topic once. If already subscribed, it only adds the handler.
    func subscribeIfNeeded(
        topic: String,
        handler: @escaping (Data) -> Void
    ) {
        let shouldSubscribe: Bool = lock.withLock {
            var handlers = handlersByTopic[topic] ?? []
            handlers.append(handler)
            handlersByTopic[topic] = handlers

            if subscribedTopics.contains(topic) {
                return false
            }
            subscribedTopics.insert(topic)
            return true
        }

        guard shouldSubscribe else { return }

        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
        print("📡 [MQTT] Subscribing once to: \(topic)")

        iotDataManager.subscribe(toTopic: topic, qoS: .messageDeliveryAttemptedAtMostOnce) { [weak self] payload in
            guard let self = self else { return }
            guard let data = payload as? Data else {
                print("⚠️ [MQTT] Invalid payload on topic: \(topic)")
                return
            }
            self.dispatch(topic: topic, data: data)
        }
    }

    /// Convenience: subscribe to `uniqueId/HA/E/ack`.
    func subscribeToAckIfNeeded(
        uniqueId: String,
        handler: @escaping (Data) -> Void
    ) {
        subscribeIfNeeded(topic: uniqueId + "/HA/E/ack", handler: handler)
    }

    private func dispatch(topic: String, data: Data) {
        let handlers: [(Data) -> Void] = lock.withLock {
            return handlersByTopic[topic] ?? []
        }

        if handlers.isEmpty { return }

        DispatchQueue.main.async {
            for h in handlers {
                h(data)
            }
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

