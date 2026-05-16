//
//  LockOpenVC.swift
//  SkromanIsra
//
//  Created by Admin on 14/04/26.
//

import UIKit
import AVFoundation
import ThingSmartLockKit
import ThingSmartHomeKit
import ThingSmartBaseKit
import ThingSmartCameraKit

class LockOpenVC: UIViewController, ThingSmartLockDeviceDelegate, ThingSmartWiFiLockDeviceDelegate {

    var masterSliderView: MasterButtonSliderView?
    var deviceId: String?
    var selectedLock: TuyaDeviceModel?
    var device: ThingSmartDevice?
    var lock: ThingSmartLockDevice?
    var pendingUnlockDevice: ThingSmartLockDevice?
    /// Set when opened from Tuya doorbell / videoCall push (category may not be `videolock` yet).
    var forceVideoPreview = false

    @IBOutlet weak var accessView: UIView?
    @IBOutlet weak var bellbackView: UIView?
    @IBOutlet weak var timercountdown: UILabel?
    @IBOutlet weak var cameraPreview: UIView?

    private var videoHostView: UIView?
    private var doorbellWifiLock: ThingSmartWiFiLockDevice?
    private var didStartPreviewPipeline = false
    private var didTeardownDoorbellPreview = false
    private var didEmbedVideoSurface = false
    private var previewStartAttempts = 0
    /// Bumped on teardown so in-flight embed retries do not touch the SDK after stop.
    private var doorbellPreviewGeneration = 0
    private let livePreviewDefinition: ThingSmartCameraDefinition = .high
    private let controlGreen = UIColor(red: 0, green: 0.977, blue: 0, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        print("📲 Received deviceId:", deviceId ?? "nil")

        guard let devId = deviceId, !devId.isEmpty else {
            print("❌ deviceId is nil or empty")
            return
        }

        resolveSelectedLockIfNeeded(for: devId)

        lock = ThingSmartLockDevice(deviceId: devId)
        lock?.delegate = self

        device = ThingSmartDevice(deviceId: devId)
        device?.delegate = self

        print("✅ Device & Lock initialized, videoLock=\(isVideoLockCategory())")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwipe(_:)),
            name: .masterSliderSwiped,
            object: nil
        )

        applyBellBackViewStyle()
        configureVideoLockChrome()
    }

    private func applyBellBackViewStyle() {
        guard let bellbackView else { return }
        let radius = bellbackView.bounds.height > 0 ? bellbackView.bounds.height / 2 : 75
        bellbackView.layer.cornerRadius = radius
        bellbackView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        // Do not call Tuya preview teardown here — it aborts if the VC is already deallocating.
        doorbellWifiLock = nil
    }

    @IBAction func unclockbtn(_ sender: Any) {
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissed || isMovingFromParent {
            stopVideoPreview()
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.isUnlockVCShown = false
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupMasterSlider()

        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)

        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        guard let devId = deviceId else {
            print("❌ deviceId missing")
            return
        }

        let lock = ThingSmartLockDevice(deviceId: devId)
        lock?.delegate = self
        self.lock = lock

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            pendingUnlockDevice = appDelegate.pendingUnlockDevice
            print("🔄 Updated device in VC:", pendingUnlockDevice != nil)
        }

        configureVideoLockChrome()

        scheduleDoorbellPreviewIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyBellBackViewStyle()
        scheduleDoorbellPreviewIfNeeded()
    }

    private func scheduleDoorbellPreviewIfNeeded() {
        guard shouldShowVideoPreview(), !didStartPreviewPipeline else { return }
        guard view.bounds.width > 0, cameraPreview?.bounds.width ?? 0 > 0 else { return }

        didStartPreviewPipeline = true
        // Slight delay so notification/cold-start presentation and layout are ready (matches surveillance screen).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.startDoorbellPreviewIfNeeded()
        }
    }

    // MARK: - Slider

    private func setupMasterSlider() {
        guard let accessView else {
            print("❌ accessView outlet missing on LockOpenVC")
            return
        }

        accessView.subviews
            .filter { $0 is MasterButtonSliderView }
            .forEach { $0.removeFromSuperview() }

        let slider = MasterButtonSliderView()
        slider.translatesAutoresizingMaskIntoConstraints = false
        accessView.addSubview(slider)

        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: accessView.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: accessView.centerYAnchor),
            slider.leadingAnchor.constraint(equalTo: accessView.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: accessView.trailingAnchor, constant: -20),
            slider.heightAnchor.constraint(equalToConstant: 50)
        ])

        masterSliderView = slider
        applyVideoLockSliderLabels()
    }

    private func applyVideoLockSliderLabels() {
        guard shouldShowVideoPreview() else { return }
        masterSliderView?.configureSideLabels(
            leftText: "Deny",
            leftColor: UIColor(red: 1, green: 0.23, blue: 0.19, alpha: 1),
            rightText: "Answer",
            rightColor: controlGreen
        )
    }

    // MARK: - Swipe

    @objc func handleSwipe(_ notification: Notification) {
        guard let devId = deviceId, !devId.isEmpty else {
            print("❌ Missing devId")
            return
        }

        let direction = notification.userInfo?["direction"] as? String ?? "left"

        if direction == "left" {
            if shouldShowVideoPreview() {
                denyAccess()
            }
            return
        }

        guard direction == "right" else { return }

        if isVideoLockCategory() {
            openVideoSurveillance(devId: devId)
        } else {
            performRemoteUnlock(devId: devId)
        }
    }

    private func performRemoteUnlock(devId: String) {
        let lockDevice = ThingSmartWiFiLockDevice(deviceId: devId)
        lockDevice.remoteLock(
            withDevId: devId,
            open: true,
            confirm: true,
            success: { isSuccess in
                print("✅ Door unlocked via model: \(isSuccess)")
            },
            failure: { error in
                print("❌ Unlock failed: \(error.localizedDescription ?? "")")
            }
        )
    }

    private func openVideoSurveillance(devId: String) {
        stopVideoPreview()
        VideoLockPreviewSession.shared.teardown()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "VideoSurveillanceVc"
        ) as? VideoSurveillanceVc else {
            print("❌ VideoSurveillanceVc not found")
            return
        }

        vc.deviceId = devId
        vc.deviceName = resolvedDeviceName()

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.setNavigationBarHidden(true, animated: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.present(nav, animated: true)
        }
    }

    // MARK: - Video lock helpers

    private func resolveSelectedLockIfNeeded(for devId: String) {
        if let match = TuyaDeviceManager.shared.devices.first(where: { $0.deviceId == devId }) {
            selectedLock = match
            return
        }

        guard let model = ThingSmartDevice(deviceId: devId)?.deviceModel else { return }
        let category = model.category ?? ""
        let name = model.name ?? "Lock"
        selectedLock = TuyaDeviceModel(
            tuyaHomeId: 0,
            tuyaRoomId: 0,
            deviceId: devId,
            deviceName: name,
            deviceCategory: category
        )
    }

    /// Live stream on doorbell screen: video lock devices, or doorbell push (`forceVideoPreview`).
    private func shouldShowVideoPreview() -> Bool {
        isVideoLockCategory() || forceVideoPreview
    }

    private func isVideoLockCategory() -> Bool {
        if selectedLock?.deviceCategory.lowercased() == "videolock" { return true }
        if device?.deviceModel.category?.lowercased() == "videolock" { return true }
        if let devId = deviceId,
           ThingSmartDevice(deviceId: devId)?.deviceModel.category?.lowercased() == "videolock" {
            return true
        }
        return false
    }

    private func resolvedDeviceName() -> String? {
        if let name = selectedLock?.deviceName, !name.isEmpty { return name }
        return device?.deviceModel.name
    }

    private func configureVideoLockChrome() {
        guard let cameraPreview else { return }

        let showLiveVideo = shouldShowVideoPreview()

        if showLiveVideo {
            cameraPreview.isHidden = false
            cameraPreview.backgroundColor = .black
            cameraPreview.layer.cornerRadius = 20
            cameraPreview.layer.borderWidth = 1
            cameraPreview.layer.borderColor = controlGreen.cgColor
            cameraPreview.clipsToBounds = true
            timercountdown?.text = resolvedDeviceName() ?? "Live View"
            timercountdown?.isHidden = false
            bellbackView?.isHidden = true
            videoHostView?.isHidden = false
            _ = ensureVideoHostView()
            applyVideoLockSliderLabels()
        } else {
            stopVideoPreview()
            videoHostView?.isHidden = true
            cameraPreview.isHidden = false
            cameraPreview.backgroundColor = .clear
            cameraPreview.layer.cornerRadius = 12
            cameraPreview.layer.borderWidth = 0
            cameraPreview.layer.borderColor = UIColor.clear.cgColor
            cameraPreview.clipsToBounds = true
            timercountdown?.text = "Door Bell"
            timercountdown?.isHidden = false
            bellbackView?.isHidden = false
        }
    }

    private func showBellOverlay(_ visible: Bool) {
        guard !shouldShowVideoPreview() else {
            bellbackView?.isHidden = true
            return
        }
        bellbackView?.isHidden = !visible
    }

    @discardableResult
    private func ensureVideoHostView() -> UIView? {
        guard let cameraPreview else { return nil }
        if let videoHostView { return videoHostView }

        let host = UIView()
        host.translatesAutoresizingMaskIntoConstraints = false
        host.backgroundColor = .black
        host.clipsToBounds = true
        host.isHidden = false
        cameraPreview.insertSubview(host, at: 0)

        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: cameraPreview.topAnchor),
            host.bottomAnchor.constraint(equalTo: cameraPreview.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: cameraPreview.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: cameraPreview.trailingAnchor)
        ])

        videoHostView = host
        if let bell = bellbackView {
            cameraPreview.bringSubviewToFront(bell)
        }
        if let label = timercountdown {
            cameraPreview.bringSubviewToFront(label)
        }
        return host
    }

    private func prepareAudioSessionForIPC() {
        do {
            let avSession = AVAudioSession.sharedInstance()
            try avSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try avSession.setActive(true)
        } catch {
            print("⚠️ LockOpenVC audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Doorbell DPS

    func device(_ device: ThingSmartDevice?, didReceiveData data: [AnyHashable: Any]?) {
        print("📡 Incoming DPS:", data ?? [:])
        if let dps = data?["dps"] as? [String: Any] {
            print("📊 DPS VALUES:", dps)
        }

        if let dps = data?["dps"] as? [String: Any],
           let doorbell = dps["53"] as? Int,
           doorbell == 1 {
            print("🔔 Doorbell pressed")
            forceVideoPreview = true
            stopVideoPreview()
            didTeardownDoorbellPreview = false
            didStartPreviewPipeline = false
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.configureVideoLockChrome()
                self.startDoorbellPreviewIfNeeded()
            }
        }
    }

    func denyAccess() {
        print("🚫 Access Denied")
        stopVideoPreview()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: true)
        }
    }

    func device(_ device: ThingSmartLockDevice, didReceiveRemoteUnlockRequest seconds: Int) {
        print("📩 Remote unlock request received:", seconds)
        guard seconds > 0 else { return }
        pendingUnlockDevice = device
    }
}

// MARK: - Doorbell live preview (video lock) — own WiFi lock (same pipeline as VideoSurveillanceVc)

extension LockOpenVC {

    private func startDoorbellPreviewIfNeeded() {
        guard shouldShowVideoPreview() else {
            print("⚠️ skip preview — not a video doorbell/lock (force=\(forceVideoPreview))")
            return
        }
        guard let devId = deviceId, !devId.isEmpty else { return }
        guard let hostView = ensureVideoHostView() else {
            print("❌ videoHostView missing — cameraPreview outlet nil?")
            return
        }

        if doorbellWifiLock == nil {
            didTeardownDoorbellPreview = false
            didEmbedVideoSurface = false
            previewStartAttempts = 0
            doorbellPreviewGeneration += 1

            let lock = ThingSmartWiFiLockDevice(deviceId: devId)
            lock.delegate = self
            doorbellWifiLock = lock
            prepareAudioSessionForIPC()
        }

        showBellOverlay(false)
        bellbackView?.isHidden = true
        print("📷 Doorbell live view starting for \(devId)")

        requestDoorbellRealtimeVideo { [weak self] in
            guard let self, !self.didTeardownDoorbellPreview, let lock = self.doorbellWifiLock else { return }
            lock.p2pConnect()
            print("📷 Doorbell p2p connecting=\(lock.isP2pConnecting()) connected=\(lock.isP2pConnected())")
            self.beginDoorbellPreviewIfPossible(in: hostView)
        }
    }

    private func requestDoorbellRealtimeVideo(completion: @escaping () -> Void) {
        guard let lock = doorbellWifiLock else {
            completion()
            return
        }

        let dpId = lock.getDpId(withDpCode: "video_request_realtime")
        guard !dpId.isEmpty else {
            print("⚠️ Doorbell: video_request_realtime dp not found, P2P only")
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

        print("📷 Doorbell publish video_request_realtime dp \(dpId)")
        lock.publishDps([dpId: jsonString], success: {
            completion()
        }, failure: { error in
            print("⚠️ Doorbell video_request_realtime failed: \(error.localizedDescription ?? "")")
            completion()
        })
    }

    private func beginDoorbellPreviewIfPossible(in hostView: UIView) {
        guard !didTeardownDoorbellPreview, let lock = doorbellWifiLock else { return }
        let generation = doorbellPreviewGeneration

        if !didEmbedVideoSurface {
            if VideoLockPreviewSession.embedPreview(from: lock.cameraType, into: hostView) {
                didEmbedVideoSurface = true
                previewStartAttempts = 0
                bellbackView?.isHidden = true
            } else if previewStartAttempts < 20 {
                previewStartAttempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    guard let self, let host = self.videoHostView else { return }
                    guard self.doorbellPreviewGeneration == generation, !self.didTeardownDoorbellPreview else { return }
                    self.beginDoorbellPreviewIfPossible(in: host)
                }
                return
            } else {
                print("⚠️ Doorbell: could not embed video surface")
                return
            }
        }

        guard !lock.isPreviewOn() else { return }
        lock.startPreview(with: livePreviewDefinition)
        lock.enableMute(true)
        print("📷 Doorbell startPreview previewOn=\(lock.isPreviewOn())")
    }

    func stopVideoPreview() {
        let cleanupUI = { [weak self] in
            guard let self else { return }
            self.videoHostView?.subviews.forEach { $0.removeFromSuperview() }
            if self.shouldShowVideoPreview() {
                self.bellbackView?.isHidden = true
            } else {
                self.showBellOverlay(true)
            }
        }

        didStartPreviewPipeline = false
        doorbellPreviewGeneration += 1
        didEmbedVideoSurface = false
        previewStartAttempts = 0

        guard !didTeardownDoorbellPreview else {
            doorbellWifiLock = nil
            if Thread.isMainThread {
                cleanupUI()
            } else {
                DispatchQueue.main.async(execute: cleanupUI)
            }
            return
        }
        didTeardownDoorbellPreview = true

        guard let lock = doorbellWifiLock else {
            doorbellWifiLock = nil
            if Thread.isMainThread {
                cleanupUI()
            } else {
                DispatchQueue.main.async(execute: cleanupUI)
            }
            return
        }

        doorbellWifiLock = nil

        let tearDownSDK = {
            lock.delegate = nil
            Self.clearCameraDelegate(on: lock)

            if lock.isPreviewOn() {
                lock.stopPreview()
            }
            if lock.isP2pConnected() || lock.isP2pConnecting() {
                lock.p2pDisConnect()
            }
            lock.cameraType.destory()
            cleanupUI()
        }

        if Thread.isMainThread {
            tearDownSDK()
        } else {
            DispatchQueue.main.async(execute: tearDownSDK)
        }
    }

    private static func clearCameraDelegate(on lock: ThingSmartWiFiLockDevice) {
        guard let cameraObject = lock.cameraType as? NSObject else { return }
        let selector = NSSelectorFromString("setDelegate:")
        guard cameraObject.responds(to: selector) else { return }
        cameraObject.perform(selector, with: nil)
    }

    func teardownDoorbellPreview() {
        if Thread.isMainThread {
            stopVideoPreview()
        } else {
            DispatchQueue.main.sync { stopVideoPreview() }
        }
    }
}

// MARK: - ThingSmartWiFiLockDeviceDelegate (preview)

extension LockOpenVC {

    func onVideoRequestRealtime(_ device: ThingSmartWiFiLockDevice!, model: String!) {
        print("📷 onVideoRequestRealtime: \(model ?? "")")
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.didTeardownDoorbellPreview, self.doorbellWifiLock != nil,
                  let host = self.videoHostView else { return }
            if !device.isP2pConnected() && !device.isP2pConnecting() {
                device.p2pConnect()
            }
            self.beginDoorbellPreviewIfPossible(in: host)
        }
    }

    func cameraDidConnected(_ camera: ThingSmartCameraType!) {
        print("📷 cameraDidConnected")
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.didTeardownDoorbellPreview, self.doorbellWifiLock != nil,
                  let host = self.videoHostView else { return }
            self.beginDoorbellPreviewIfPossible(in: host)
        }
    }

    func cameraDidBeginPreview(_ camera: ThingSmartCameraType!) {
        print("📷 cameraDidBeginPreview")
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.didTeardownDoorbellPreview, let lock = self.doorbellWifiLock else { return }
            if let surface = self.videoHostView?.subviews.first?.subviews.first {
                VideoLockPreviewSession.configureVideoSurface(surface, camera: lock.cameraType)
            }
            lock.enableMute(true)
            self.bellbackView?.isHidden = true
        }
    }

    func cameraInitFailed(_ errorCode: ThingSmartCameraErrorCode) {
        print("📷 cameraInitFailed: \(errorCode)")
    }

    func camera(_ camera: ThingSmartCameraType!, didOccurredErrorAtStep errStep: ThingCameraErrorCode, specificErrorCode errorCode: Int) {
        print("📷 camera error step=\(errStep) code=\(errorCode)")
    }

    func camera(_ camera: ThingSmartCameraType!, didReceiveFirstFrame image: UIImage!) {
        print("📷 Doorbell first video frame")
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.didTeardownDoorbellPreview else { return }
            self.bellbackView?.isHidden = true
        }
    }

    func cameraDisconnected(_ camera: ThingSmartCameraType!, specificErrorCode errorCode: Int) {
        print("📷 camera disconnected: \(errorCode)")
    }
}
