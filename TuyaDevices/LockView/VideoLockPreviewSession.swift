//
//  VideoLockPreviewSession.swift
//  SkromanIsra
//
//  Single active ThingSmartWiFiLockDevice preview — avoids P2P conflicts between screens.
//

import UIKit
import AVFoundation
import ThingSmartLockKit
import ThingSmartCameraKit

final class VideoLockPreviewSession: NSObject {

    static let shared = VideoLockPreviewSession()

    private(set) var wifiLock: ThingSmartWiFiLockDevice?
    private(set) var deviceId: String?
    private var didTeardown = false

    private weak var activeHostView: UIView?
    private var previewDefinition: ThingSmartCameraDefinition = .high
    private var watchdogTimer: Timer?
    private var embedAttempts = 0
    private var watchdogTicks = 0

    private override init() {
        super.init()
    }

    // MARK: - Lock lifecycle

    @discardableResult
    func prepareLock(deviceId: String, delegate: ThingSmartWiFiLockDeviceDelegate) -> ThingSmartWiFiLockDevice {
        if self.deviceId == deviceId, let existing = wifiLock, !didTeardown {
            existing.delegate = delegate
            bindCameraDelegate(delegate)
            return existing
        }

        teardown()

        let lock = ThingSmartWiFiLockDevice(deviceId: deviceId)
        lock.delegate = delegate
        bindCameraDelegate(delegate)
        wifiLock = lock
        self.deviceId = deviceId
        didTeardown = false

        prepareAudioSession()
        print("📷 [Session] prepared lock \(deviceId)")
        return lock
    }

    /// Binds both lock and camera delegates (camera callbacks often require this).
    private func bindCameraDelegate(_ delegate: ThingSmartWiFiLockDeviceDelegate) {
        guard let lock = wifiLock else { return }
        lock.delegate = delegate

        guard let cameraObject = lock.cameraType as? NSObject else { return }
        let selector = NSSelectorFromString("setDelegate:")
        guard cameraObject.responds(to: selector) else { return }
        cameraObject.perform(selector, with: delegate)
    }

    func prepareAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("⚠️ VideoLockPreviewSession audio: \(error.localizedDescription)")
        }
    }

    // MARK: - Live stream pipeline

    /// Starts DP request → P2P → embed → preview with a watchdog so video still appears if delegates never fire.
    func startLiveStream(
        deviceId: String,
        hostView: UIView,
        delegate: ThingSmartWiFiLockDeviceDelegate,
        definition: ThingSmartCameraDefinition = .high,
        publishRealtimeDP: Bool = true
    ) {
        activeHostView = hostView
        previewDefinition = definition
        embedAttempts = 0
        watchdogTicks = 0

        _ = prepareLock(deviceId: deviceId, delegate: delegate)
        stopWatchdog()

        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tickPreviewPipeline()
        }
        if let watchdogTimer {
            RunLoop.main.add(watchdogTimer, forMode: .common)
        }

        let afterRequest: () -> Void = { [weak self] in
            self?.connectP2P()
            self?.tickPreviewPipeline()
        }

        if publishRealtimeDP {
            requestRealtimeVideo(completion: afterRequest)
        } else {
            afterRequest()
        }
    }

    /// Stops preview but keeps P2P alive when handing off to another screen.
    func pausePreviewForHandoff() {
        stopWatchdog()
        guard let lock = wifiLock else { return }
        if lock.isTalking() { lock.stopTalk() }
        if lock.isPreviewOn() { lock.stopPreview() }
        activeHostView?.subviews.forEach { $0.removeFromSuperview() }
        activeHostView = nil
        print("📷 [Session] paused preview for handoff (p2p kept)")
    }

    func requestRealtimeVideo(completion: @escaping () -> Void) {
        guard let lock = wifiLock else {
            completion()
            return
        }

        let dpId = lock.getDpId(withDpCode: "video_request_realtime")
        guard !dpId.isEmpty else {
            print("⚠️ video_request_realtime dp id not found, connecting P2P anyway")
            completion()
            return
        }

        let request = ThingSmartLockVideoRequestModel()
        request.requestType = 1
        request.requestContent = 1
        request.schemeType = 2
        request.talkType = 0

        let payload: [String: Any] = [
            "requestType": request.requestType,
            "requestContent": request.requestContent,
            "schemeType": request.schemeType,
            "talkType": request.talkType
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            lock.publishDps([dpId: 1], success: { completion() }, failure: { _ in completion() })
            return
        }

        print("📷 [Session] publish video_request_realtime dp \(dpId)")
        lock.publishDps([dpId: jsonString], success: {
            completion()
        }, failure: { error in
            print("⚠️ [Session] video_request_realtime failed: \(error?.localizedDescription ?? "")")
            completion()
        })
    }

    func connectP2P() {
        guard let lock = wifiLock else { return }
        if !lock.isP2pConnected() && !lock.isP2pConnecting() {
            lock.p2pConnect()
        }
        print("📷 [Session] p2p connecting=\(lock.isP2pConnecting()) connected=\(lock.isP2pConnected())")
    }

    /// Called from WiFi-lock / camera delegate callbacks and from the watchdog timer.
    func tickPreviewPipeline() {
        guard let lock = wifiLock, let hostView = activeHostView else { return }

        watchdogTicks += 1

        if !lock.isP2pConnected() && !lock.isP2pConnecting() {
            lock.p2pConnect()
        }

        let hasEmbeddedSurface = !hostView.subviews.isEmpty

        if !hasEmbeddedSurface {
            embedAttempts += 1
            if VideoLockPreviewSession.embedPreview(from: lock.cameraType, into: hostView) {
                print("📷 [Session] embedded video surface (attempt \(embedAttempts))")
            } else if embedAttempts == 1 || embedAttempts % 5 == 0 {
                print("📷 [Session] waiting for video surface (attempt \(embedAttempts))")
            }
        }

        if !lock.isPreviewOn(), lock.isP2pConnected() || hasEmbeddedSurface {
            lock.startPreview(with: previewDefinition)
            lock.enableMute(true)
            print("📷 [Session] startPreview previewOn=\(lock.isPreviewOn()) p2p=\(lock.isP2pConnected())")
        }

        if lock.isPreviewOn() {
            stopWatchdog()
        } else if watchdogTicks >= 60 {
            print("⚠️ [Session] preview watchdog timeout — no frames after \(watchdogTicks) ticks")
            stopWatchdog()
        }
    }

    func teardown() {
        stopWatchdog()
        activeHostView = nil
        embedAttempts = 0
        watchdogTicks = 0

        guard let lock = wifiLock, !didTeardown else {
            wifiLock = nil
            deviceId = nil
            return
        }
        didTeardown = true

        if lock.isTalking() { lock.stopTalk() }
        if lock.isPreviewOn() { lock.stopPreview() }
        lock.p2pDisConnect()
        lock.cameraType.destory()

        wifiLock = nil
        deviceId = nil
        print("📷 [Session] preview torn down")
    }

    private func stopWatchdog() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
    }

    // MARK: - Video surface helpers

    static func renderSurfaceView(from camera: ThingSmartCameraType) -> UIView? {
        guard let obj = camera as? NSObject else { return nil }

        for name in ["cameraView", "videoView", "previewView", "renderView", "glView", "video_content_view"] {
            let selector = NSSelectorFromString(name)
            guard obj.responds(to: selector) else { continue }
            guard let unmanaged = obj.perform(selector) else { continue }
            if let view = unmanaged.takeUnretainedValue() as? UIView {
                return view
            }
        }
        return nil
    }

    @discardableResult
    static func embedPreview(from camera: ThingSmartCameraType, into hostView: UIView) -> Bool {
        guard let rendered = renderSurfaceView(from: camera) else {
            return false
        }

        hostView.subviews.forEach { $0.removeFromSuperview() }
        configureVideoSurface(rendered, camera: camera)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .black
        container.clipsToBounds = true

        rendered.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(rendered)
        hostView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: hostView.topAnchor),
            container.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            rendered.topAnchor.constraint(equalTo: container.topAnchor),
            rendered.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            rendered.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            rendered.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        hostView.setNeedsLayout()
        hostView.layoutIfNeeded()
        return true
    }

    static func configureVideoSurface(_ surface: UIView, camera: ThingSmartCameraType) {
        surface.backgroundColor = .black
        surface.clipsToBounds = true
        applyScaleMode(2, to: surface)
        surface.contentMode = .scaleAspectFill
        if let inner = renderSurfaceView(from: camera) {
            applyScaleMode(2, to: inner)
            inner.contentMode = .scaleAspectFill
        }
    }

    private static func applyScaleMode(_ mode: Int, to view: UIView) {
        if let obj = view as? NSObject, obj.responds(to: NSSelectorFromString("setScaleMode:")) {
            obj.setValue(mode, forKey: "scaleMode")
        }
        view.subviews.forEach { applyScaleMode(mode, to: $0) }
    }
}
