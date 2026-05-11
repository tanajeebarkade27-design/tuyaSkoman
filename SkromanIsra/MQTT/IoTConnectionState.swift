import Foundation

final class IoTConnectionState {
    static let shared = IoTConnectionState()

    private let lock = NSLock()
    private var _isConnected: Bool = false

    private init() {}

    var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isConnected
    }

    func setConnected(_ connected: Bool) {
        lock.lock()
        _isConnected = connected
        lock.unlock()
    }
}

extension Notification.Name {
    static let iotConnectionRequested = Notification.Name("iotConnectionRequested")
    static let iotConnectionStatusChanged = Notification.Name("iotConnectionStatusChanged")
}

