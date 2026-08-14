import AppTrackingTransparency
import AVFoundation
import Contacts
import ContactsUI
import CoreLocation
import LocalAuthentication
import MapKit
import Photos
import PhotosUI
import UIKit
import UserNotifications

final class MainViewController: UIViewController {
    private let configuration: AppConfiguration
    private let apiClient: APIClient
    private let analytics: AnalyticsReporter
    private let installationId: String
    private let contactsStore = CNContactStore()
    private let locationManager = CLLocationManager()
    private let mapView = MKMapView()
    private let scoreLabel = UILabel()
    private let opponentLabel = UILabel()
    private let statusLabel = UILabel()
    private let mediaPreview = UIImageView()
    private var bluetoothConnector: BluetoothConnector?
    private var audioRecorder: AVAudioRecorder?
    private var leftScore: Int
    private var rightScore: Int

    init(configuration: AppConfiguration, apiClient: APIClient, analytics: AnalyticsReporter) {
        self.configuration = configuration
        self.apiClient = apiClient
        self.analytics = analytics

        let defaults = UserDefaults.standard
        if let storedId = defaults.string(forKey: "installation.id") {
            installationId = storedId
        } else {
            let newId = UUID().uuidString
            defaults.set(newId, forKey: "installation.id")
            installationId = newId
        }

        let snapshot = MatchSnapshot.load(groupIdentifier: configuration.appGroupIdentifier)
        leftScore = snapshot.leftScore
        rightScore = snapshot.rightScore
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        configureContent()

        bluetoothConnector = BluetoothConnector { [weak self] status in
            self?.showStatus(status)
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        updateScore()
        apiClient.checkHealth { [weak self] isAvailable in
            self?.showStatus(isAvailable ? "Синхронизация доступна" : "Офлайн-режим")
        }
        analytics.report("main_screen_opened")
    }

    private func configureAppearance() {
        title = "YPadel"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.03, green: 0.25, blue: 0.17, alpha: 1)
        view.backgroundColor = UIColor(red: 0.03, green: 0.25, blue: 0.17, alpha: 1)
    }

    private func configureContent() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        let header = makeHeader()
        let scoreCard = makeScoreCard()
        let playersCard = makePlayersCard()
        let mediaCard = makeMediaCard()

        [header, scoreCard, playersCard, mediaCard].forEach(stack.addArrangedSubview)
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28)
        ])
    }

    private func makeHeader() -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = "Счет и статистика"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Все для текущего матча — на одном экране"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)

        statusLabel.text = "Проверяем синхронизацию…"
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        statusLabel.font = .systemFont(ofSize: 12, weight: .regular)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, statusLabel])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])
        return container
    }

    private func makeScoreCard() -> UIView {
        let card = makeCard()
        let titleLabel = makeSectionTitle("Текущий матч")

        scoreLabel.textAlignment = .center
        scoreLabel.font = .monospacedDigitSystemFont(ofSize: 52, weight: .black)
        scoreLabel.textColor = UIColor(red: 0.04, green: 0.24, blue: 0.16, alpha: 1)

        opponentLabel.text = "Мы  •  Соперники"
        opponentLabel.textAlignment = .center
        opponentLabel.textColor = .secondaryLabel
        opponentLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        let ourPointButton = makePrimaryButton(title: "+ очко нам", action: #selector(addOurPoint))
        let theirPointButton = makePrimaryButton(title: "+ соперникам", action: #selector(addTheirPoint))
        let scoreButtons = makeButtonRow([ourPointButton, theirPointButton])

        let bluetoothButton = makeActionButton(
            title: "Табло по Bluetooth",
            symbol: "dot.radiowaves.left.and.right",
            action: #selector(connectBluetooth)
        )
        let pushButton = makeActionButton(
            title: "Напомнить о матче",
            symbol: "bell.badge",
            action: #selector(enableMatchReminder)
        )
        let statisticsButton = makeActionButton(
            title: "Открыть статистику",
            symbol: "faceid",
            action: #selector(openStatistics)
        )
        let resetButton = makeTextButton(title: "Сбросить счет", action: #selector(resetScore))

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            opponentLabel,
            scoreLabel,
            scoreButtons,
            bluetoothButton,
            pushButton,
            statisticsButton,
            resetButton
        ])
        install(stack: stack, in: card)
        return card
    }

    private func makePlayersCard() -> UIView {
        let card = makeCard()
        let titleLabel = makeSectionTitle("Корт и игроки")

        mapView.layer.cornerRadius = 14
        mapView.clipsToBounds = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.heightAnchor.constraint(equalToConstant: 155).isActive = true
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 44.8125, longitude: 20.4612),
            span: MKCoordinateSpan(latitudeDelta: 0.13, longitudeDelta: 0.13)
        )
        mapView.setRegion(initialRegion, animated: false)

        let courtsButton = makeActionButton(
            title: "Найти корты рядом",
            symbol: "location.fill",
            action: #selector(findCourts)
        )
        let contactsButton = makeActionButton(
            title: "Выбрать партнера",
            symbol: "person.crop.circle.badge.plus",
            action: #selector(choosePartner)
        )
        let offersButton = makeActionButton(
            title: "Персональные предложения",
            symbol: "sparkles",
            action: #selector(enablePersonalOffers)
        )

        let stack = UIStackView(arrangedSubviews: [titleLabel, mapView, courtsButton, contactsButton, offersButton])
        install(stack: stack, in: card)
        return card
    }

    private func makeMediaCard() -> UIView {
        let card = makeCard()
        let titleLabel = makeSectionTitle("Материалы матча")

        mediaPreview.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 0.94, alpha: 1)
        mediaPreview.contentMode = .scaleAspectFill
        mediaPreview.clipsToBounds = true
        mediaPreview.layer.cornerRadius = 14
        mediaPreview.image = UIImage(systemName: "photo.on.rectangle.angled")
        mediaPreview.tintColor = UIColor(red: 0.18, green: 0.42, blue: 0.31, alpha: 1)
        mediaPreview.translatesAutoresizingMaskIntoConstraints = false
        mediaPreview.heightAnchor.constraint(equalToConstant: 150).isActive = true

        let cameraButton = makeActionButton(
            title: "Снять фото матча",
            symbol: "camera.fill",
            action: #selector(takeMatchPhoto)
        )
        let galleryButton = makeActionButton(
            title: "Выбрать из фотогалереи",
            symbol: "photo.on.rectangle",
            action: #selector(pickMatchPhoto)
        )
        let voiceButton = makeActionButton(
            title: "Записать голосовую заметку",
            symbol: "mic.fill",
            action: #selector(toggleVoiceNote)
        )
        let saveButton = makeActionButton(
            title: "Сохранить карточку счета",
            symbol: "square.and.arrow.down.fill",
            action: #selector(saveScoreCard)
        )

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            mediaPreview,
            cameraButton,
            galleryButton,
            voiceButton,
            saveButton
        ])
        install(stack: stack, in: card)
        return card
    }

    private func makeCard() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 22
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowRadius = 12
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        return view
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red: 0.04, green: 0.24, blue: 0.16, alpha: 1)
        return label
    }

    private func makePrimaryButton(title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = UIColor(red: 0.68, green: 0.93, blue: 0.22, alpha: 1)
        configuration.baseForegroundColor = UIColor(red: 0.04, green: 0.22, blue: 0.14, alpha: 1)
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 10, bottom: 14, trailing: 10)
        let button = UIButton(configuration: configuration)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeActionButton(title: String, symbol: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.gray()
        configuration.title = title
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 10
        configuration.imagePlacement = .leading
        configuration.baseForegroundColor = UIColor(red: 0.05, green: 0.32, blue: 0.21, alpha: 1)
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeTextButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeButtonRow(_ buttons: [UIButton]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }

    private func install(stack: UIStackView, in container: UIView) {
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18)
        ])
    }

    @objc private func addOurPoint() {
        leftScore += 1
        updateScoreAndSync(event: "score_left_changed")
    }

    @objc private func addTheirPoint() {
        rightScore += 1
        updateScoreAndSync(event: "score_right_changed")
    }

    @objc private func resetScore() {
        leftScore = 0
        rightScore = 0
        updateScoreAndSync(event: "score_reset")
    }

    private func updateScoreAndSync(event: String) {
        updateScore()
        analytics.report(event)
        syncSnapshot()
    }

    private func updateScore() {
        scoreLabel.text = "\(leftScore) : \(rightScore)"
    }

    private func syncSnapshot() {
        let snapshot = MatchSnapshot(leftScore: leftScore, rightScore: rightScore)
        snapshot.save(groupIdentifier: configuration.appGroupIdentifier)
        reloadMatchWidgets()

        let payload = SyncRequest(
            installationId: installationId,
            deviceToken: UserDefaults.standard.string(forKey: "push.deviceToken"),
            match: snapshot
        )
        apiClient.sync(payload) { [weak self] succeeded in
            self?.showStatus(succeeded ? "Счет синхронизирован" : "Счет сохранён на устройстве")
        }
    }

    @objc private func connectBluetooth() {
        analytics.report("permission_bluetooth_started")
        bluetoothConnector?.connect()
    }

    @objc private func openStatistics() {
        analytics.report("permission_face_id_started")
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            showPermissionUnavailable("Face ID недоступен на этом устройстве")
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Открыть статистику матчей"
        ) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.showInformation(
                        title: "Статистика",
                        message: "Текущий счет \(self.leftScore):\(self.rightScore). Данные защищены Face ID."
                    )
                    self.analytics.report("permission_face_id_granted")
                } else {
                    self.showStatus("Face ID: проверка не пройдена")
                }
            }
        }
    }

    @objc private func findCourts() {
        analytics.report("permission_location_started")
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            beginCourtSearch()
        case .denied, .restricted:
            showSettingsAlert(message: "Разрешите геолокацию, чтобы находить корты рядом.")
        @unknown default:
            showStatus("Геолокация: неизвестный статус")
        }
    }

    private func beginCourtSearch() {
        mapView.showsUserLocation = true
        locationManager.startUpdatingLocation()
        searchPadelCourts(center: locationManager.location?.coordinate ?? mapView.region.center)
    }

    private func searchPadelCourts(center: CLLocationCoordinate2D) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "padel court"
        request.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        )

        MKLocalSearch(request: request).start { [weak self] response, _ in
            guard let self else { return }
            self.mapView.removeAnnotations(self.mapView.annotations)
            let items = Array((response?.mapItems ?? []).prefix(8))
            for item in items {
                let annotation = MKPointAnnotation()
                annotation.title = item.name ?? "Падел-корт"
                annotation.coordinate = item.placemark.coordinate
                self.mapView.addAnnotation(annotation)
            }
            self.mapView.setRegion(request.region, animated: true)
            self.showStatus(items.isEmpty ? "Корты не найдены — карту можно изучить вручную" : "Найдено кортов: \(items.count)")
            self.analytics.report("permission_location_granted")
        }
    }

    @objc private func choosePartner() {
        analytics.report("permission_contacts_started")
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            presentContactPicker()
        case .notDetermined:
            contactsStore.requestAccess(for: .contacts) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        self?.presentContactPicker()
                    } else {
                        self?.showSettingsAlert(message: "Разрешите контакты, чтобы выбрать партнера.")
                    }
                }
            }
        case .denied, .restricted:
            showSettingsAlert(message: "Разрешите контакты, чтобы выбрать партнера.")
        @unknown default:
            showStatus("Контакты: неизвестный статус")
        }
    }

    private func presentContactPicker() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        present(picker, animated: true)
        analytics.report("permission_contacts_granted")
    }

    @objc private func enablePersonalOffers() {
        analytics.report("permission_tracking_started")
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            handleTrackingStatus(ATTrackingManager.trackingAuthorizationStatus)
            return
        }

        let alert = UIAlertController(
            title: "Персональные предложения",
            message: "Разрешение поможет оценивать рекламу и показывать более подходящие предложения. Функции приложения останутся доступны при любом выборе.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не сейчас", style: .cancel))
        alert.addAction(UIAlertAction(title: "Продолжить", style: .default) { [weak self] _ in
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async { self?.handleTrackingStatus(status) }
            }
        })
        present(alert, animated: true)
    }

    private func handleTrackingStatus(_ status: ATTrackingManager.AuthorizationStatus) {
        if status == .authorized {
            showStatus("Персональные предложения включены")
            analytics.report("permission_tracking_granted")
        } else {
            showStatus("Предложения работают без рекламного трекинга")
        }
    }

    @objc private func takeMatchPhoto() {
        analytics.report("permission_camera_started")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.presentCamera() : self?.showSettingsAlert(message: "Разрешите камеру, чтобы снять фото матча.")
                }
            }
        case .denied, .restricted:
            showSettingsAlert(message: "Разрешите камеру, чтобы снять фото матча.")
        @unknown default:
            showStatus("Камера: неизвестный статус")
        }
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showPermissionUnavailable("Камера недоступна в симуляторе. Проверьте функцию на iPhone.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
        analytics.report("permission_camera_granted")
    }

    @objc private func pickMatchPhoto() {
        analytics.report("permission_photo_read_started")
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            presentPhotoPicker()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.presentPhotoPicker()
                    } else {
                        self?.showSettingsAlert(message: "Разрешите просмотр фото, чтобы выбрать материал матча.")
                    }
                }
            }
        case .denied, .restricted:
            showSettingsAlert(message: "Разрешите просмотр фото, чтобы выбрать материал матча.")
        @unknown default:
            showStatus("Фотогалерея: неизвестный статус")
        }
    }

    private func presentPhotoPicker() {
        var pickerConfiguration = PHPickerConfiguration(photoLibrary: .shared())
        pickerConfiguration.filter = .images
        pickerConfiguration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: pickerConfiguration)
        picker.delegate = self
        present(picker, animated: true)
        analytics.report("permission_photo_read_granted")
    }

    @objc private func toggleVoiceNote() {
        if audioRecorder?.isRecording == true {
            audioRecorder?.stop()
            audioRecorder = nil
            showStatus("Голосовая заметка сохранена на устройстве")
            analytics.report("voice_note_recorded")
            return
        }

        analytics.report("permission_microphone_started")
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            startVoiceRecording(session: session)
        case .undetermined:
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startVoiceRecording(session: session)
                    } else {
                        self?.showSettingsAlert(message: "Разрешите микрофон, чтобы записать заметку.")
                    }
                }
            }
        case .denied:
            showSettingsAlert(message: "Разрешите микрофон, чтобы записать заметку.")
        @unknown default:
            showStatus("Микрофон: неизвестный статус")
        }
    }

    private func startVoiceRecording(session: AVAudioSession) {
        do {
            try session.setCategory(.record, mode: .spokenAudio)
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ypadel-note.m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            showStatus("Идет запись — нажмите кнопку ещё раз, чтобы остановить")
            analytics.report("permission_microphone_granted")
        } catch {
            showStatus("Не удалось начать запись")
        }
    }

    @objc private func saveScoreCard() {
        analytics.report("permission_photo_add_started")
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            saveGeneratedScoreCard()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.saveGeneratedScoreCard()
                    } else {
                        self?.showSettingsAlert(message: "Разрешите сохранение фото, чтобы добавить карточку счета.")
                    }
                }
            }
        case .denied, .restricted:
            showSettingsAlert(message: "Разрешите сохранение фото, чтобы добавить карточку счета.")
        @unknown default:
            showStatus("Сохранение фото: неизвестный статус")
        }
    }

    private func saveGeneratedScoreCard() {
        let size = CGSize(width: 1200, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor(red: 0.03, green: 0.25, blue: 0.17, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let title = "YPadel"
            let score = "\(leftScore) : \(rightScore)"
            let centered = NSMutableParagraphStyle()
            centered.alignment = .center

            title.draw(
                in: CGRect(x: 80, y: 220, width: 1040, height: 130),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 84, weight: .bold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: centered
                ]
            )
            score.draw(
                in: CGRect(x: 80, y: 450, width: 1040, height: 240),
                withAttributes: [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 170, weight: .black),
                    .foregroundColor: UIColor(red: 0.68, green: 0.93, blue: 0.22, alpha: 1),
                    .paragraphStyle: centered
                ]
            )
            "Мы   •   Соперники".draw(
                in: CGRect(x: 80, y: 720, width: 1040, height: 90),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 44, weight: .semibold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: centered
                ]
            )
        }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { [weak self] saved, _ in
            DispatchQueue.main.async {
                self?.showStatus(saved ? "Карточка счета сохранена в Фото" : "Не удалось сохранить карточку")
                if saved { self?.analytics.report("permission_photo_add_granted") }
            }
        }
    }

    @objc private func enableMatchReminder() {
        analytics.report("permission_push_started")
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self else { return }
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.presentPushPreprompt()
                case .authorized, .provisional, .ephemeral:
                    self.finishPushSetup()
                case .denied:
                    self.showSettingsAlert(message: "Разрешите уведомления, чтобы получать напоминания о матчах.")
                @unknown default:
                    self.showStatus("Уведомления: неизвестный статус")
                }
            }
        }
    }

    private func presentPushPreprompt() {
        let alert = UIAlertController(
            title: "Напоминания о матчах",
            message: "Чтобы сообщать о важных событиях и изменениях",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не сейчас", style: .cancel))
        alert.addAction(UIAlertAction(title: "Продолжить", style: .default) { [weak self] _ in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        self?.finishPushSetup()
                    } else {
                        self?.showStatus("Напоминания не включены")
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func finishPushSetup() {
        UIApplication.shared.registerForRemoteNotifications()

        let content = UNMutableNotificationContent()
        content.title = "YPadel"
        content.body = "Матч сохранён. Счет можно открыть с экрана блокировки."
        content.sound = .default
        content.categoryIdentifier = "YPADEL_MATCH"
        content.userInfo = ["score": "\(leftScore):\(rightScore)"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                self?.showStatus(error == nil ? "Напоминание появится через 5 секунд" : "Не удалось создать напоминание")
            }
        }
        analytics.report("permission_push_granted")
    }

    private func showStatus(_ text: String) {
        statusLabel.text = text
    }

    private func showInformation(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Готово", style: .default))
        present(alert, animated: true)
    }

    private func showPermissionUnavailable(_ message: String) {
        showInformation(title: "Функция недоступна", message: message)
    }

    private func showSettingsAlert(message: String) {
        let alert = UIAlertController(title: "Нужен доступ", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Настройки", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            beginCourtSearch()
        case .denied, .restricted:
            showStatus("Геолокация не разрешена")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        manager.stopUpdatingLocation()
        searchPadelCourts(center: coordinate)
    }
}

extension MainViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Партнер"
        opponentLabel.text = "Мы с \(name)  •  Соперники"
        showStatus("Партнер выбран")
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        mediaPreview.image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true)
        showStatus("Фото матча готово")
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension MainViewController: PHPickerViewControllerDelegate {
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                self?.mediaPreview.image = object as? UIImage
                self?.showStatus("Фото выбрано из галереи")
            }
        }
    }
}
