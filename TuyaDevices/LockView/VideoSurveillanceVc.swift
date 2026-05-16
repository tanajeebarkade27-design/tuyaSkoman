//
//  VideoSurveillanceVc.swift
//  SkromanIsra
//
//  Wi‑Fi video lock live view — use ThingSmartWiFiLockDevice (ThingSmartLockKit), not raw
//  ThingSmartCameraFactory. See: https://developer.tuya.com/en/docs/app-development/smartlock-video?id=Kbno0aqn72j28
//

import UIKit
import AVFoundation
import Photos
import ThingSmartHomeKit
import ThingSmartCameraKit
import ThingSmartLockKit

final class VideoSurveillanceVc: UIViewController {

    var deviceId: String?
    var deviceName: String?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!

    @IBOutlet weak var videoPreview: UIView!

    @IBOutlet weak var micBtn: UIButton!
    @IBOutlet weak var speakerBtn: UIButton!
    @IBOutlet weak var voiceModular: UIButton!
    @IBOutlet weak var lockOpen: UIButton!
    
    @IBOutlet weak var screenShotBtn: UIButton!
    
    @IBOutlet weak var videoRecord: UIButton!
    
    private var wifiLock: ThingSmartWiFiLockDevice?
    private var didTeardown = false
    private var didEmbedVideoSurface = false
    private var previewStartAttempts = 0

    private var livePreviewDefinition: ThingSmartCameraDefinition = .high

    private var isSpeakerUnmuted = false
    private var isMicTalkOn = false
    private var isRecordingVideo = false
    private var isUnlocking = false
    private var selectedVoiceEffect: VoiceEffectOption = .original

    private let controlGreen = UIColor(red: 0, green: 0.977, blue: 0, alpha: 1)

    private let voiceEffectBar = UIView()
    private var voiceEffectBarHeightConstraint: NSLayoutConstraint?
    private var isVoiceEffectBarVisible = false
    private var voiceEffectButtons: [UIButton] = []

    private enum VoiceEffectOption: String, CaseIterable {
        case girl, robot, man, original, boy

        var title: String { rawValue.capitalized }

        /// Maps UI label → Tuya `ThingCameraAudioEffectType` for intercom voice change.
        var sdkType: ThingCameraAudioEffectType {
            switch self {
            case .original: return .none
            case .girl: return .lolita
            case .robot: return .robot
            case .man: return .uncle
            case .boy: return .brother
            }
        }
    }

    private var mediaDirectory: String {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VideoLockCapture", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.path
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel?.text = deviceName ?? "Video Surveillance"

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

        backButton.tintColor = .white

        setupUI()
        setupVoiceEffectBar()
        applyControlSymbols()

        micBtn.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        speakerBtn.addTarget(self, action: #selector(speakerTapped), for: .touchUpInside)
        voiceModular.addTarget(self, action: #selector(voiceModulatorTapped), for: .touchUpInside)
        screenShotBtn.addTarget(self, action: #selector(screenshotTapped), for: .touchUpInside)
        videoRecord.addTarget(self, action: #selector(videoRecordTapped), for: .touchUpInside)
        lockOpen.addTarget(self, action: #selector(lockOpenTapped), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.tabBar.isHidden = true
        // Doorbell screen may have held the shared session — release before own live view.
        VideoLockPreviewSession.shared.teardown()
        startLiveViewIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        if isMovingFromParent || isBeingDismissed {
            teardownLiveView()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        roundControlButtons()
    }

    private func setupUI() {
        videoPreview.backgroundColor = .black
        videoPreview.layer.cornerRadius = 20
        videoPreview.layer.borderWidth = 1
        videoPreview.layer.borderColor = UIColor.green.cgColor
        videoPreview.clipsToBounds = true

        styleStandardControlButton(speakerBtn)
        styleStandardControlButton(voiceModular)
        styleStandardControlButton(screenShotBtn)
        styleStandardControlButton(videoRecord)
        styleAccentControlButton(micBtn)
        styleAccentControlButton(lockOpen)
    }

    private func styleStandardControlButton(_ button: UIButton?) {
        guard let button else { return }
        button.tintColor = .white
        button.layer.borderWidth = 0.5
        button.layer.borderColor = controlGreen.cgColor
        button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    }

    private func styleAccentControlButton(_ button: UIButton?) {
        guard let button else { return }
        button.tintColor = .white
        button.layer.borderWidth = 0.5
        button.layer.borderColor = controlGreen.cgColor
        button.backgroundColor = controlGreen.withAlphaComponent(0.55)
    }

    private func setButtonIcon(_ button: UIButton?, systemName: String) {
        guard let button else { return }
        var config = button.configuration ?? UIButton.Configuration.plain()
        config.image = UIImage(systemName: systemName)
        config.baseForegroundColor = .white
        button.configuration = config
        button.tintColor = .white
    }

    private func setButtonIcon(_ button: UIButton?, assetName: String, fallbackSystemName: String) {
        guard let button else { return }
        let image = (UIImage(named: assetName) ?? UIImage(systemName: fallbackSystemName))?
            .withRenderingMode(.alwaysTemplate)
        var config = button.configuration ?? UIButton.Configuration.plain()
        config.image = image
        config.baseForegroundColor = .white
        button.configuration = config
        button.tintColor = .white
    }

    private func roundControlButtons() {
        [micBtn, speakerBtn, voiceModular, screenShotBtn, videoRecord, lockOpen].forEach {
            $0?.layer.cornerRadius = ($0?.frame.height ?? 0) / 2
        }
    }

    private func setupVoiceEffectBar() {
        guard let anchorView = screenShotBtn.superview?.superview else { return }

        voiceEffectBar.translatesAutoresizingMaskIntoConstraints = false
        voiceEffectBar.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        voiceEffectBar.layer.cornerRadius = 10
        voiceEffectBar.clipsToBounds = true
        voiceEffectBar.isHidden = true

        anchorView.addSubview(voiceEffectBar)

        let height = voiceEffectBar.heightAnchor.constraint(equalToConstant: 0)
        voiceEffectBarHeightConstraint = height

        NSLayoutConstraint.activate([
            voiceEffectBar.leadingAnchor.constraint(equalTo: anchorView.leadingAnchor, constant: 10),
            voiceEffectBar.trailingAnchor.constraint(equalTo: anchorView.trailingAnchor, constant: -10),
            voiceEffectBar.bottomAnchor.constraint(equalTo: anchorView.topAnchor, constant: -6),
            height
        ])

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 6
        voiceEffectBar.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: voiceEffectBar.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: voiceEffectBar.bottomAnchor, constant: -4),
            stack.leadingAnchor.constraint(equalTo: voiceEffectBar.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: voiceEffectBar.trailingAnchor, constant: -6)
        ])

        voiceEffectButtons.removeAll()

        for (index, effect) in VoiceEffectOption.allCases.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(effect.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.7
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 0
            button.layer.borderColor = controlGreen.cgColor
            button.tag = index
            button.addTarget(self, action: #selector(voiceEffectSelected(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
            voiceEffectButtons.append(button)
        }

        updateVoiceEffectButtonSelection()
    }

    private func applyControlSymbols() {
        setButtonIcon(speakerBtn, systemName: "speaker.slash.fill")
        setButtonIcon(screenShotBtn, systemName: "camera.viewfinder")
        updateMicButtonAppearance()
        updateLockButtonAppearance()
        updateVoiceModulatorAppearance()
        updateRecordButtonAppearance()
    }

    private func updateVoiceModulatorAppearance() {
        if isVoiceEffectBarVisible {
            styleAccentControlButton(voiceModular)
            voiceModular.backgroundColor = controlGreen.withAlphaComponent(0.85)
        } else {
            styleStandardControlButton(voiceModular)
        }
        setButtonIcon(voiceModular, systemName: "waveform.circle")
        voiceModular.accessibilityLabel = "Voice effect: \(selectedVoiceEffect.title)"
    }

    private func updateMicButtonAppearance() {
        styleAccentControlButton(micBtn)
        let symbol = isMicTalkOn ? "mic.fill" : "mic.slash.fill"
        setButtonIcon(micBtn, systemName: symbol)
    }

    private func updateLockButtonAppearance() {
        styleAccentControlButton(lockOpen)
        if isUnlocking {
            setButtonIcon(lockOpen, assetName: "lock", fallbackSystemName: "lock.open")
        } else {
            setButtonIcon(lockOpen, assetName: "lock", fallbackSystemName: "lock.open")
        }
    }

    private func setLockUnlocking(_ unlocking: Bool) {
        isUnlocking = unlocking
        lockOpen.isEnabled = !unlocking
        updateLockButtonAppearance()
    }

    private func prepareAudioSessionForIPC() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("⚠️ Audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Live view (ThingSmartWiFiLockDevice)

    private func startLiveViewIfNeeded() {
        guard wifiLock == nil else { return }
        guard let devId = deviceId, !devId.isEmpty else {
            presentAlert(title: "Device", message: "Missing device id.")
            return
        }

        didTeardown = false
        didEmbedVideoSurface = false
        previewStartAttempts = 0

        let lock = ThingSmartWiFiLockDevice(deviceId: devId)
        lock.delegate = self
        wifiLock = lock

        prepareAudioSessionForIPC()
        print("📷 Starting video lock live view for \(devId)")

        requestRealtimeVideo { [weak self] in
            guard let self, let lock = self.wifiLock else { return }
            lock.p2pConnect()
            print("📷 p2pConnect connecting=\(lock.isP2pConnecting()) connected=\(lock.isP2pConnected())")
        }
    }

    private func requestRealtimeVideo(completion: @escaping () -> Void) {
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

        print("📷 publish video_request_realtime dp \(dpId)")
        lock.publishDps([dpId: jsonString], success: {
            completion()
        }, failure: { error in
            print("⚠️ video_request_realtime failed: \(error?.localizedDescription ?? "unknown")")
            completion()
        })
    }

    private func beginPreviewIfPossible() {
        guard let lock = wifiLock else { return }

        if !didEmbedVideoSurface {
            if VideoLockPreviewSession.embedPreview(from: lock.cameraType, into: videoPreview) {
                didEmbedVideoSurface = true
                previewStartAttempts = 0
            } else if previewStartAttempts < 15 {
                previewStartAttempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.beginPreviewIfPossible()
                }
                return
            } else {
                presentAlert(title: "Preview", message: "Could not get video surface from the lock SDK.")
                return
            }
        }

        guard !lock.isPreviewOn() else { return }

        lock.startPreview(with: livePreviewDefinition)
        print("📷 startPreview previewOn=\(lock.isPreviewOn())")
    }

    private func teardownLiveView() {
        guard !didTeardown else { return }
        didTeardown = true

        guard let lock = wifiLock else { return }

        if isMicTalkOn || lock.isTalking() {
            lock.stopTalk()
            isMicTalkOn = false
        }

        if lock.isRecording() {
            lock.stopRecordAndFetchPath()
            isRecordingVideo = false
        }

        if lock.isPreviewOn() {
            lock.stopPreview()
        }

        hideVoiceEffectBar()
        updateVoiceModulatorAppearance()

        lock.p2pDisConnect()
        lock.cameraType.destory()

        wifiLock = nil
        didEmbedVideoSurface = false
        previewStartAttempts = 0

        DispatchQueue.main.async { [weak self] in
            self?.videoPreview.subviews.forEach { $0.removeFromSuperview() }
        }
    }

    // MARK: - Controls

    private func setSpeakerUnmuted(_ on: Bool) {
        guard let lock = wifiLock else { return }
        isSpeakerUnmuted = on
        lock.enableMute(!on)

        setButtonIcon(speakerBtn, systemName: on ? "speaker.wave.2.fill" : "speaker.slash.fill")
    }

    private func setMicTalk(_ on: Bool) {
        guard let lock = wifiLock else { return }

        if on {
            guard lock.isSupportedTalk() else {
                presentAlert(title: "Intercom", message: "This lock does not support two-way talk.")
                return
            }
            guard lock.isPreviewOn() || lock.isP2pConnected() else {
                presentAlert(title: "Intercom", message: "Wait for live video to connect, then try again.")
                return
            }

            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    guard granted else {
                        self.presentAlert(title: "Microphone", message: "Allow microphone access to talk through the lock.")
                        return
                    }
                    self.prepareAudioSessionForIPC()
                    lock.startTalk()
                    self.isMicTalkOn = lock.isTalking()
                    if self.isMicTalkOn {
                        self.applyVoiceEffect(self.selectedVoiceEffect)
                    }
                    if self.isMicTalkOn {
                        self.updateMicButtonAppearance()
                    } else {
                        self.presentAlert(title: "Intercom", message: "Could not start talk. Ensure preview is running.")
                        self.updateMicButtonAppearance()
                    }
                }
            }
        } else {
            lock.stopTalk()
            isMicTalkOn = false
            updateMicButtonAppearance()
        }
    }

    private func guardPreviewReady(for action: String) -> ThingSmartWiFiLockDevice? {
        guard let lock = wifiLock else {
            presentAlert(title: action, message: "Device not ready.")
            return nil
        }
        guard lock.isPreviewOn() || lock.isP2pConnected() else {
            presentAlert(title: action, message: "Wait for live video to connect.")
            return nil
        }
        return lock
    }

    private func applyVoiceEffectToCamera(_ effect: VoiceEffectOption) {
        guard let camera = wifiLock?.cameraType else { return }
        let result = camera.setAudioEffect?(effect.sdkType)
        print("🎙️ Voice effect \(effect.title) → sdkType \(effect.sdkType.rawValue), result: \(result ?? -1)")
    }

    private func applyVoiceEffect(_ effect: VoiceEffectOption) {
        selectedVoiceEffect = effect
        updateVoiceEffectButtonSelection()
        updateVoiceModulatorAppearance()

        guard let lock = wifiLock else {
            applyVoiceEffectToCamera(effect)
            return
        }

        if lock.isTalking() {
            lock.stopTalk()
            applyVoiceEffectToCamera(effect)
            lock.startTalk()
            isMicTalkOn = lock.isTalking()
            updateMicButtonAppearance()
        } else {
            applyVoiceEffectToCamera(effect)
        }
    }

    private func updateVoiceEffectButtonSelection() {
        for (index, button) in voiceEffectButtons.enumerated() {
            guard index < VoiceEffectOption.allCases.count else { continue }
            let effect = VoiceEffectOption.allCases[index]
            let selected = effect == selectedVoiceEffect

            button.backgroundColor = selected
                ? controlGreen.withAlphaComponent(0.85)
                : UIColor.white.withAlphaComponent(0.1)
            button.layer.borderWidth = selected ? 2 : 0
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = selected
                ? UIFont.boldSystemFont(ofSize: 11)
                : UIFont.systemFont(ofSize: 11, weight: .semibold)
        }
    }

    private func showVoiceEffectBar() {
        isVoiceEffectBarVisible = true
        voiceEffectBar.isHidden = false
        voiceEffectBarHeightConstraint?.constant = 50
        updateVoiceEffectButtonSelection()
        updateVoiceModulatorAppearance()
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    private func hideVoiceEffectBar() {
        isVoiceEffectBarVisible = false
        voiceEffectBarHeightConstraint?.constant = 0
        voiceEffectBar.isHidden = true
        updateVoiceModulatorAppearance()
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    private func updateRecordButtonAppearance() {
        styleStandardControlButton(videoRecord)
        let symbol = isRecordingVideo ? "stop.circle.fill" : "record.circle"
        setButtonIcon(videoRecord, systemName: symbol)
        videoRecord.tintColor = isRecordingVideo ? .systemRed : .white
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    self.presentAlert(title: "Photos", message: "Allow photo library access to save screenshots.")
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }, completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.presentAlert(title: "Screenshot", message: "Saved to your photo library.")
                        } else {
                            self.presentAlert(title: "Screenshot", message: error?.localizedDescription ?? "Could not save image.")
                        }
                    }
                })
            }
        }
    }

    @objc private func micTapped() {
        setMicTalk(!isMicTalkOn)
    }

    @objc private func speakerTapped() {
        setSpeakerUnmuted(!isSpeakerUnmuted)
    }

    @objc private func voiceModulatorTapped() {
        if isVoiceEffectBarVisible {
            hideVoiceEffectBar()
        } else {
            showVoiceEffectBar()
        }
    }

    @objc private func voiceEffectSelected(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0, index < VoiceEffectOption.allCases.count else { return }
        let effect = VoiceEffectOption.allCases[index]
        applyVoiceEffect(effect)
    }

    @objc private func screenshotTapped() {
        guard let lock = guardPreviewReady(for: "Screenshot") else { return }

        let timestamp = Int(Date().timeIntervalSince1970)
        let filePath = (mediaDirectory as NSString).appendingPathComponent("shot_\(timestamp).jpg")
        let thumbPath = (mediaDirectory as NSString).appendingPathComponent("shot_\(timestamp)_thumb.jpg")

        let image = lock.snapShoot(
            with: .up,
            savedAtPath: filePath,
            thumbnilPath: thumbPath
        )

        if image.size.width > 0, image.size.height > 0 {
            saveImageToPhotoLibrary(image)
        } else if let fileImage = UIImage(contentsOfFile: filePath) {
            saveImageToPhotoLibrary(fileImage)
        } else {
            presentAlert(title: "Screenshot", message: "Could not capture image.")
        }
    }

    @objc private func videoRecordTapped() {
        guard let lock = wifiLock else { return }

        if lock.isRecording() {
            lock.stopRecordAndFetchPath()
            return
        }

        guard guardPreviewReady(for: "Record") != nil else { return }

        let timestamp = Int(Date().timeIntervalSince1970)
        let filePath = (mediaDirectory as NSString).appendingPathComponent("record_\(timestamp).mp4")
        lock.startRecord(with: .up, filePath: filePath)
        isRecordingVideo = true
        updateRecordButtonAppearance()
    }

    @objc private func lockOpenTapped() {
        guard let devId = deviceId, !devId.isEmpty else { return }
        guard !isUnlocking else { return }

        setLockUnlocking(true)

        let lock = wifiLock ?? ThingSmartWiFiLockDevice(deviceId: devId)
        lock.remoteLock(
            withDevId: devId,
            open: true,
            confirm: true,
            success: { [weak self] isSuccess in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if isSuccess {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.setLockUnlocking(false)
                        }
                    } else {
                        self.setLockUnlocking(false)
                    }
                    let msg = isSuccess ? "Unlock command sent." : "Unlock was not confirmed."
                    self.presentAlert(title: "Lock", message: msg)
                }
            },
            failure: { [weak self] error in
                DispatchQueue.main.async {
                    self?.setLockUnlocking(false)
                    self?.presentAlert(title: "Lock", message: error?.localizedDescription ?? "Unlock failed.")
                }
            }
        )
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        teardownLiveView()
        if let nav = navigationController, nav.viewControllers.first !== self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ThingSmartWiFiLockDeviceDelegate + ThingSmartCameraDelegate

extension VideoSurveillanceVc: ThingSmartWiFiLockDeviceDelegate {

    func onVideoRequestRealtime(_ device: ThingSmartWiFiLockDevice!, model: String!) {
        print("📷 onVideoRequestRealtime: \(model ?? "")")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !device.isP2pConnected() && !device.isP2pConnecting() {
                device.p2pConnect()
            }
            self.beginPreviewIfPossible()
        }
    }

    func cameraDidConnected(_ camera: ThingSmartCameraType!) {
        print("📷 cameraDidConnected")
        DispatchQueue.main.async { [weak self] in
            self?.beginPreviewIfPossible()
        }
    }

    func cameraDidBeginPreview(_ camera: ThingSmartCameraType!) {
        print("📷 cameraDidBeginPreview")
        DispatchQueue.main.async { [weak self] in
            guard let self, let lock = self.wifiLock else { return }
            if let surface = self.videoPreview.subviews.first?.subviews.first {
                VideoLockPreviewSession.configureVideoSurface(surface, camera: lock.cameraType)
            }
            lock.enableMute(true)
            self.isSpeakerUnmuted = false
            self.setButtonIcon(self.speakerBtn, systemName: "speaker.slash.fill")
        }
    }

    func onRemoteUnlockReport(_ device: ThingSmartWiFiLockDevice!) {
        DispatchQueue.main.async { [weak self] in
            self?.setLockUnlocking(false)
        }
    }

    func camera(_ camera: ThingSmartCameraType!, didReceiveFirstFrame image: UIImage!) {
        print("📷 first video frame received")
    }

    func cameraSnapShootSuccess(_ camera: ThingSmartCameraType!) {
        print("📷 screenshot saved by SDK")
    }

    func cameraDidStartRecord(_ camera: ThingSmartCameraType!) {
        DispatchQueue.main.async {
            self.isRecordingVideo = true
            self.updateRecordButtonAppearance()
        }
    }

    func cameraDidStopRecord(_ camera: ThingSmartCameraType!) {
        DispatchQueue.main.async {
            self.isRecordingVideo = false
            self.updateRecordButtonAppearance()
            self.presentAlert(title: "Recording", message: "Video saved to app storage. You can export from Files if needed.")
        }
    }

    func cameraDisconnected(_ camera: ThingSmartCameraType!, specificErrorCode errorCode: Int) {
        print("📷 camera disconnected: \(errorCode)")
    }

    func cameraInitFailed(_ errorCode: ThingSmartCameraErrorCode) {
        DispatchQueue.main.async {
            self.presentAlert(title: "Camera", message: "Initialization failed (code \(errorCode)).")
        }
    }

    func camera(_ camera: ThingSmartCameraType!, didOccurredErrorAtStep errStep: ThingCameraErrorCode, specificErrorCode errorCode: Int) {
        print("📷 IPC step \(errStep) err \(errorCode)")
    }
}
