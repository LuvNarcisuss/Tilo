import AVFoundation
import Combine
import UIKit

@MainActor
final class VideoCallPreviewController: TiloPage {
    private let conversationTitle: String
    private let capture = VideoPreviewCapture()
    private let surface = VideoPreviewSurface()
    private let status = text("Starting camera…", 16, color: TiloTheme.muted)
    private let navigation = UIStackView()
    private let controls = UIStackView()
    private var cameraPosition: AVCaptureDevice.Position = .front
    private var captureRequest: UUID?
    private var requestingPermission = false
    private var isVisible = false
    private var isEnding = false
    private var microphoneEnabled = true
    private var speakerEnabled = true

    private lazy var flip = action("Flip camera", icon: .camera) { [weak self] in
        self?.flipCamera()
    }
    private lazy var retry = action("Try again", icon: .clock) { [weak self] in self?.resumePreview() }
    private lazy var settings = action("Open Settings", icon: .settings) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    private lazy var microphone = action("Microphone on", icon: .microphone) { [weak self] in
        guard let self else { return }
        microphoneEnabled.toggle()
        updateAudioControls()
    }
    private lazy var speaker = action("Speaker on", icon: .speaker) { [weak self] in
        guard let self else { return }
        speakerEnabled.toggle()
        updateAudioControls()
    }
    private lazy var hangUp = action("End call", icon: .close, filled: true) { [weak self] in self?.endPreview() }

    init(conversationTitle: String) {
        self.conversationTitle = conversationTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "video-call-preview"
        surface.previewLayer.session = capture.session
        surface.previewLayer.videoGravity = .resizeAspectFill
        surface.isAccessibilityElement = false
        surface.isUserInteractionEnabled = false
        view.insertSubview(surface, belowSubview: scroll)
        surface.fill(view)

        let close = action("Close", icon: .back) { [weak self] in self?.endPreview() }
        navigation.spacing = 10
        navigation.addArrangedSubview(close)
        navigation.addArrangedSubview(flip)
        add(navigation)
        status.accessibilityIdentifier = "video-preview-status"
        add(panel([
            text("Video call", 28, heading: true),
            text(conversationTitle, 19, heading: true),
            text("Local camera preview. Only you can see it."),
            status, retry, settings
        ]))

        controls.spacing = 8
        for button in [microphone, hangUp, speaker] {
            var configuration = button.configuration
            configuration?.imagePlacement = .top
            configuration?.titleAlignment = .center
            configuration?.imagePadding = 5
            configuration?.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 5, bottom: 9, trailing: 5)
            button.configuration = configuration
            controls.addArrangedSubview(button)
        }
        microphone.accessibilityIdentifier = "video-preview-microphone"
        speaker.accessibilityIdentifier = "video-preview-speaker"
        hangUp.accessibilityIdentifier = "video-preview-end"
        hangUp.configuration?.image = TiloIcon.close.image().withTintColor(.white, renderingMode: .alwaysOriginal)
        let audioNote = text("Audio controls change this screen only.", 14, color: TiloTheme.muted)
        audioNote.textAlignment = .center
        let spacer = UIView()
        add(spacer)
        spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        content.setCustomSpacing(0, after: spacer)
        add(panel([audioNote, controls]))
        content.heightAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor, constant: -40).isActive = true
        updateAudioControls()
        updateControlLayout()
        showCameraState(.starting)

        let notifications = NotificationCenter.default
        notifications.addObserver(self, selector: #selector(sceneActivated), name: UIScene.didActivateNotification, object: nil)
        notifications.addObserver(self, selector: #selector(sceneDeactivated), name: UIScene.willDeactivateNotification, object: nil)
        for name in [AVCaptureSession.wasInterruptedNotification, AVCaptureSession.runtimeErrorNotification] {
            notifications.publisher(for: name, object: capture.session)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self, captureRequest != nil else { return }
                    pausePreview()
                    showCameraState(.unavailable)
                }
                .store(in: &observations)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
        resumePreview()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
        pausePreview()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateControlLayout()
    }

    func endPreview() {
        guard !isEnding else { return }
        isEnding = true
        pausePreview()
        dismiss(animated: true)
    }

    @objc private func sceneActivated(_ notification: Notification) {
        guard notification.object as? UIScene === viewIfLoaded?.window?.windowScene else { return }
        resumePreview()
    }

    @objc private func sceneDeactivated(_ notification: Notification) {
        guard notification.object as? UIScene === viewIfLoaded?.window?.windowScene else { return }
        pausePreview()
    }

    private var canPreview: Bool {
        isVisible && !isEnding && viewIfLoaded?.window?.windowScene?.activationState == .foregroundActive
    }

    private func resumePreview() {
        guard canPreview, !requestingPermission, captureRequest == nil else { return }
        guard VideoPreviewCapture.camera(at: cameraPosition) != nil else {
            showCameraState(.unavailable)
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCamera(position: cameraPosition)
        case .notDetermined:
            requestingPermission = true
            showCameraState(.starting)
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.requestingPermission = false
                    self.resumePreview()
                }
            }
        case .denied:
            showCameraState(.denied)
        case .restricted:
            showCameraState(.restricted)
        @unknown default:
            showCameraState(.unavailable)
        }
    }

    private func startCamera(position: AVCaptureDevice.Position) {
        guard canPreview else { return }
        let request = UUID()
        captureRequest = request
        showCameraState(.starting)
        capture.start(at: position) { [weak self] state in
            guard let self, captureRequest == request, canPreview else { return }
            if case .ready = state {
                cameraPosition = position
                surface.orient(for: position)
            } else {
                captureRequest = nil
            }
            showCameraState(state)
        }
    }

    private func flipCamera() {
        guard flip.isEnabled else { return }
        startCamera(position: cameraPosition == .front ? .back : .front)
    }

    private func pausePreview() {
        if captureRequest != nil {
            captureRequest = nil
            capture.stop()
        }
        showCameraState(.paused)
    }

    private func showCameraState(_ state: VideoPreviewState) {
        surface.isHidden = true
        flip.isEnabled = false
        retry.isHidden = true
        settings.isHidden = true
        status.isHidden = false
        switch state {
        case .starting: status.text = "Starting camera…"
        case .paused: status.text = "Camera paused."
        case .ready(let canFlip):
            status.isHidden = true
            surface.isHidden = false
            flip.isEnabled = canFlip
        case .denied:
            status.text = "Camera access is off. Allow camera access in Settings to see your preview."
            settings.isHidden = false
        case .restricted:
            status.text = "Camera access is restricted on this device."
        case .unavailable:
            status.text = "The camera is unavailable on this device right now."
            retry.isHidden = false
        }
        flip.alpha = flip.isEnabled ? 1 : 0.55
    }

    private func updateAudioControls() {
        for (button, name, enabled) in [(microphone, "Microphone", microphoneEnabled), (speaker, "Speaker", speakerEnabled)] {
            var configuration = button.configuration
            configuration?.title = enabled ? "\(name) on" : "\(name) off"
            configuration?.background.backgroundColor = enabled ? .white : TiloTheme.cream
            configuration?.background.strokeColor = enabled ? .clear : TiloTheme.muted
            configuration?.background.strokeWidth = enabled ? 0 : 1
            button.configuration = configuration
            button.accessibilityLabel = name
            button.accessibilityValue = enabled ? "On" : "Off"
        }
    }

    private func updateControlLayout() {
        let accessible = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        navigation.axis = accessible ? .vertical : .horizontal
        navigation.distribution = accessible ? .fill : .fillEqually
        controls.axis = accessible ? .vertical : .horizontal
        controls.distribution = accessible ? .fill : .fillEqually
        for case let button as UIButton in controls.arrangedSubviews {
            button.configuration?.imagePlacement = accessible ? .leading : .top
        }
    }
}

private enum VideoPreviewState {
    case starting, paused, ready(canFlip: Bool), denied, restricted, unavailable
}

private final class VideoPreviewSurface: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    func orient(for position: AVCaptureDevice.Position) {
        guard let connection = previewLayer.connection else { return }
        if #available(iOS 17.0, *) {
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = position == .front
        }
    }
}

private final class VideoPreviewCapture {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.toli.cooking.video-preview")

    static func camera(at position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    func start(at position: AVCaptureDevice.Position, completion: @escaping (VideoPreviewState) -> Void) {
        queue.async { [self] in
            let state = configure(at: position)
            DispatchQueue.main.async { completion(state) }
        }
    }

    func stop() {
        queue.async { [session] in Self.stop(session) }
    }

    private func configure(at position: AVCaptureDevice.Position) -> VideoPreviewState {
        guard let camera = Self.camera(at: position), let input = try? AVCaptureDeviceInput(device: camera) else {
            Self.stop(session)
            return .unavailable
        }
        session.beginConfiguration()
        session.inputs.forEach(session.removeInput)
        let canAdd = session.canAddInput(input)
        if canAdd { session.addInput(input) }
        session.commitConfiguration()
        if canAdd, !session.isRunning { session.startRunning() }
        guard canAdd, session.isRunning else {
            Self.stop(session)
            return .unavailable
        }
        return .ready(canFlip: Self.camera(at: position == .front ? .back : .front) != nil)
    }

    private static func stop(_ session: AVCaptureSession) {
        if session.isRunning { session.stopRunning() }
        session.beginConfiguration()
        session.inputs.forEach(session.removeInput)
        session.commitConfiguration()
    }

    deinit { stop() }
}
