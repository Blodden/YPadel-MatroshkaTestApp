import AppTrackingTransparency
import AVFoundation
import Contacts
import CoreLocation
import LocalAuthentication
import MapKit
import Photos
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
    private let scorePhaseLabel = UILabel()
    private let scoreLabel = UILabel()
    private let gamesLabel = UILabel()
    private let setsLabel = UILabel()
    private let opponentLabel = UILabel()
    private let statusLabel = UILabel()
    private let mediaPreview = UIImageView()
    private let voiceNoteStatusLabel = UILabel()

    private weak var bluetoothButton: UIButton?
    private weak var ourPointButton: UIButton?
    private weak var theirPointButton: UIButton?
    private weak var voiceNoteButton: UIButton?
    private var bluetoothConnector: BluetoothConnector?
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var voiceNoteURL: URL?
    private var selectedPhoto: UIImage?
    private var selectedPartnerName: String?
    private var snapshot: MatchSnapshot
    private var matchToken: String?

    init(
        configuration: AppConfiguration,
        apiClient: APIClient,
        analytics: AnalyticsReporter,
        installationId: String
    ) {
        self.configuration = configuration
        self.apiClient = apiClient
        self.analytics = analytics
        self.installationId = installationId
        snapshot = MatchSnapshot.load(groupIdentifier: configuration.appGroupIdentifier)
        matchToken = UserDefaults.standard.string(forKey: "match.token")
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    deinit {
        bluetoothConnector?.stop()
        audioRecorder?.stop()
        audioPlayer?.stop()
        locationManager.stopUpdatingLocation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        restoreVoiceNoteIfAvailable()
        configureAppearance()
        configureContent()

        bluetoothConnector = BluetoothConnector(
            initialSnapshot: snapshot,
            statusChanged: { [weak self] status, active in
                self?.showStatus(status)
                self?.bluetoothButton?.configuration?.title = active
                    ? "Отключить Bluetooth-табло"
                    : "Табло по Bluetooth"
            },
            snapshotReceived: { [weak self] remoteSnapshot in
                self?.applyRemoteSnapshot(remoteSnapshot)
            }
        )
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        updateScore()
        apiClient.checkHealth { [weak self] result in
            self?.showStatus(
                result.isSuccess ? "Синхронизация доступна" : "Офлайн-режим"
            )
        }
        analytics.report("main_screen_opened")
    }

    func showMatchFromDeepLink() {
        loadViewIfNeeded()
        navigationController?.popToViewController(self, animated: false)
        openStatistics()
    }

    private func configureAppearance() {
        title = "YPoints"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barTintColor = Palette.background
        view.backgroundColor = Palette.background
    }

    private func configureContent() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        [makeHeader(), makeScoreCard(), makePlayersCard(), makeMediaCard()]
            .forEach(stack.addArrangedSubview)
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
        let titleLabel = makeDynamicLabel(
            text: "Счет и статистика",
            style: .title1,
            weight: .bold,
            color: .white
        )
        let subtitleLabel = makeDynamicLabel(
            text: "Все для текущего матча — на одном экране",
            style: .subheadline,
            weight: .medium,
            color: UIColor.white.withAlphaComponent(0.78)
        )
        statusLabel.text = "Проверяем синхронизацию…"
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        statusLabel.font = .preferredFont(forTextStyle: .caption1)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 0
        statusLabel.accessibilityLabel = "Статус"

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
        scorePhaseLabel.textAlignment = .center
        scorePhaseLabel.textColor = Palette.mutedText
        scorePhaseLabel.font = .preferredFont(forTextStyle: .caption1)
        scorePhaseLabel.adjustsFontForContentSizeCategory = true

        scoreLabel.textAlignment = .center
        scoreLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: .monospacedDigitSystemFont(ofSize: 52, weight: .black)
        )
        scoreLabel.adjustsFontForContentSizeCategory = true
        scoreLabel.textColor = Palette.darkGreen
        scoreLabel.accessibilityLabel = "Счет матча"

        opponentLabel.textAlignment = .center
        opponentLabel.textColor = Palette.mutedText
        opponentLabel.font = .preferredFont(forTextStyle: .subheadline)
        opponentLabel.adjustsFontForContentSizeCategory = true
        opponentLabel.numberOfLines = 0

        [gamesLabel, setsLabel].forEach { label in
            label.textAlignment = .center
            label.textColor = Palette.darkGreen
            label.font = .preferredFont(forTextStyle: .headline)
            label.adjustsFontForContentSizeCategory = true
        }

        let ourPointButton = makePrimaryButton(title: "+ очко нам", action: #selector(addOurPoint))
        let theirPointButton = makePrimaryButton(title: "+ соперникам", action: #selector(addTheirPoint))
        self.ourPointButton = ourPointButton
        self.theirPointButton = theirPointButton
        let scoreButtons = makeButtonRow([ourPointButton, theirPointButton])
        let bluetoothButton = makeActionButton(
            title: "Табло по Bluetooth",
            symbol: "dot.radiowaves.left.and.right",
            action: #selector(toggleBluetooth)
        )
        self.bluetoothButton = bluetoothButton

        let stack = UIStackView(arrangedSubviews: [
            makeSectionTitle("Текущий матч"),
            opponentLabel,
            scorePhaseLabel,
            scoreLabel,
            gamesLabel,
            setsLabel,
            scoreButtons,
            bluetoothButton,
            makeActionButton(
                title: "Напомнить о матче",
                symbol: "bell.badge",
                action: #selector(enableMatchReminder)
            ),
            makeActionButton(
                title: "Открыть статистику",
                symbol: "faceid",
                action: #selector(openStatistics)
            ),
            makeTextButton(
                title: "Завершить матч",
                color: Palette.darkGreen,
                action: #selector(finishMatch)
            ),
            makeTextButton(
                title: "Сбросить счет",
                color: Palette.danger,
                action: #selector(resetScore)
            )
        ])
        install(stack: stack, in: card)
        return card
    }

    private func makePlayersCard() -> UIView {
        let card = makeCard()
        mapView.layer.cornerRadius = 14
        mapView.clipsToBounds = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.heightAnchor.constraint(equalToConstant: 155).isActive = true
        mapView.setRegion(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 55.7512, longitude: 37.6184),
                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            ),
            animated: false
        )
        mapView.accessibilityLabel = "Карта ближайших падел-кортов"

        let stack = UIStackView(arrangedSubviews: [
            makeSectionTitle("Корт и игроки"),
            mapView,
            makeActionButton(
                title: "Найти корты рядом",
                symbol: "location.fill",
                action: #selector(findCourts)
            ),
            makeActionButton(
                title: "Выбрать партнера",
                symbol: "person.crop.circle.badge.plus",
                action: #selector(choosePartner)
            ),
            makeActionButton(
                title: "Оценка продвижения",
                symbol: "chart.line.uptrend.xyaxis",
                action: #selector(requestPromotionMeasurement)
            )
        ])
        install(stack: stack, in: card)
        return card
    }

    private func makeMediaCard() -> UIView {
        let card = makeCard()
        mediaPreview.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 0.94, alpha: 1)
        mediaPreview.contentMode = .scaleAspectFill
        mediaPreview.clipsToBounds = true
        mediaPreview.layer.cornerRadius = 14
        mediaPreview.image = UIImage(systemName: "photo.on.rectangle.angled")
        mediaPreview.tintColor = UIColor(red: 0.18, green: 0.42, blue: 0.31, alpha: 1)
        mediaPreview.translatesAutoresizingMaskIntoConstraints = false
        mediaPreview.heightAnchor.constraint(equalToConstant: 150).isActive = true
        mediaPreview.accessibilityLabel = "Фото матча"

        voiceNoteStatusLabel.font = .preferredFont(forTextStyle: .footnote)
        voiceNoteStatusLabel.adjustsFontForContentSizeCategory = true
        voiceNoteStatusLabel.textColor = Palette.mutedText
        voiceNoteStatusLabel.numberOfLines = 0
        voiceNoteStatusLabel.accessibilityLabel = "Состояние голосовой заметки"

        let voiceNoteButton = makeActionButton(
            title: "Записать голосовую заметку",
            symbol: "mic.fill",
            action: #selector(handleVoiceNote)
        )
        self.voiceNoteButton = voiceNoteButton

        let stack = UIStackView(arrangedSubviews: [
            makeSectionTitle("Материалы матча"),
            mediaPreview,
            makeActionButton(
                title: "Снять фото матча",
                symbol: "camera.fill",
                action: #selector(takeMatchPhoto)
            ),
            makeActionButton(
                title: "Выбрать фото за сегодня",
                symbol: "photo.on.rectangle",
                action: #selector(browseMatchPhotos)
            ),
            voiceNoteButton,
            voiceNoteStatusLabel,
            makeActionButton(
                title: "Сохранить карточку счета",
                symbol: "square.and.arrow.down.fill",
                action: #selector(saveScoreCard)
            )
        ])
        updateVoiceNoteUI()
        install(stack: stack, in: card)
        return card
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 22
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 5)
        return card
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        makeDynamicLabel(text: text, style: .title2, weight: .bold, color: Palette.darkGreen)
    }

    private func makeDynamicLabel(
        text: String,
        style: UIFont.TextStyle,
        weight: UIFont.Weight,
        color: UIColor
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFontMetrics(forTextStyle: style).scaledFont(
            for: .systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize, weight: weight)
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func makePrimaryButton(title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = Palette.lime
        configuration.baseForegroundColor = Palette.darkGreen
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 10, bottom: 14, trailing: 10)
        let button = UIButton(configuration: configuration)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeActionButton(title: String, symbol: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 10
        configuration.imagePlacement = .leading
        configuration.baseBackgroundColor = Palette.actionBackground
        configuration.baseForegroundColor = Palette.darkGreen
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeTextButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(color.withAlphaComponent(0.38), for: .disabled)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
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
        snapshot = snapshot.awardingPoint(to: .left)
        updateScoreAndSync(event: "score_changed")
    }

    @objc private func addTheirPoint() {
        snapshot = snapshot.awardingPoint(to: .right)
        updateScoreAndSync(event: "score_changed")
    }

    @objc private func finishMatch() {
        snapshot = snapshot.finishing()
        updateScoreAndSync(event: "match_finished")
        scheduleNotificationIfAuthorized(body: "Матч завершен. \(snapshot.scoreSummary)")
    }

    @objc private func resetScore() {
        snapshot = snapshot.resetting()
        updateScoreAndSync(event: "score_reset")
    }

    private func updateScoreAndSync(event: String) {
        updateScore()
        analytics.report("feature_action", parameters: ["feature": event])
        syncSnapshot()
    }

    private func updateScore() {
        scorePhaseLabel.text = snapshot.state == .finished
            ? "Матч завершён"
            : (snapshot.isTieBreak ? "Тай-брейк" : "Очки")
        scoreLabel.text = snapshot.pointsScoreText
        scoreLabel.accessibilityValue = snapshot.scoreSummary
        gamesLabel.text = "Геймы   \(snapshot.gamesScoreText)"
        gamesLabel.accessibilityLabel = "Геймы"
        gamesLabel.accessibilityValue = snapshot.gamesScoreText
        setsLabel.text = "Сеты   \(snapshot.setsScoreText)"
        setsLabel.accessibilityLabel = "Сеты"
        setsLabel.accessibilityValue = snapshot.setsScoreText
        ourPointButton?.isEnabled = snapshot.state == .active
        theirPointButton?.isEnabled = snapshot.state == .active
        if let selectedPartnerName {
            opponentLabel.text = "Мы с \(selectedPartnerName)  •  Соперники"
        } else {
            opponentLabel.text = "Мы  •  Соперники"
        }
    }

    private func syncSnapshot() {
        snapshot.save(groupIdentifier: configuration.appGroupIdentifier)
        reloadMatchWidgets()
        bluetoothConnector?.update(snapshot)

        let pushToken = UserDefaults.standard.string(forKey: "push.deviceToken")
        let request = SyncRequest(
            installationId: installationId,
            matchToken: matchToken,
            clientRevision: snapshot.revision,
            snapshot: snapshot,
            push: PushRegistration(
                token: pushToken,
                environment: configuration.pushEnvironment,
                enabled: pushToken != nil
            )
        )
        apiClient.sync(request) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(response):
                self.matchToken = response.matchToken
                UserDefaults.standard.set(response.matchToken, forKey: "match.token")
                if response.serverRevision > self.snapshot.revision {
                    self.applyRemoteSnapshot(response.snapshot)
                }
                self.showStatus(
                    response.pushStatus == "pending_credentials"
                        ? "Синхронизировано • отправка push ожидает APNs-ключ"
                        : "Счет синхронизирован"
                )
                self.analytics.report("sync_result", parameters: ["result": "success"])
            case .failure:
                self.showStatus("Счет сохранён на устройстве • офлайн")
                self.analytics.report("sync_result", parameters: ["result": "offline"])
            }
        }
    }

    private func applyRemoteSnapshot(_ remoteSnapshot: MatchSnapshot) {
        guard remoteSnapshot.revision >= snapshot.revision else { return }
        snapshot = remoteSnapshot
        snapshot.save(groupIdentifier: configuration.appGroupIdentifier)
        reloadMatchWidgets()
        updateScore()
    }

    @objc private func toggleBluetooth() {
        analytics.report("feature_action", parameters: ["feature": "bluetooth_scoreboard"])
        bluetoothConnector?.toggle()
    }

    @objc private func openStatistics() {
        analytics.report("feature_action", parameters: ["feature": "protected_statistics"])
        let context = LAContext()
        context.localizedFallbackTitle = "Использовать код-пароль"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            showPermissionUnavailable("Face ID и код-пароль недоступны на этом устройстве.")
            reportPermission("face_id", result: "unavailable")
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Открыть личную статистику и заметки о матчах"
        ) { [weak self] success, evaluationError in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.reportPermission("face_id", result: "authorized")
                    self.showResult()
                } else {
                    let code = (evaluationError as? LAError)?.code
                    self.reportPermission("face_id", result: code == .userCancel ? "cancelled" : "denied")
                    self.showStatus("Статистика осталась заблокирована")
                }
            }
        }
    }

    private func showResult() {
        let controller = ResultViewController(
            snapshot: snapshot,
            photo: selectedPhoto,
            hasVoiceNote: voiceNoteURL != nil,
            saveAction: { [weak self] in self?.saveScoreCard() }
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func findCourts() {
        analytics.report("feature_action", parameters: ["feature": "nearby_courts"])
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            beginCourtSearch()
        case .denied, .restricted:
            reportPermission("location", result: "denied")
            showSettingsAlert(message: "Разрешите геолокацию, чтобы находить корты рядом. Карту можно изучать и без текущей позиции.")
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
        request.naturalLanguageQuery = "падел-корт"
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
            self.showStatus(
                items.isEmpty
                    ? "Корты не найдены — карту можно изучить вручную"
                    : "Найдено кортов: \(items.count)"
            )
            self.reportPermission("location", result: "authorized")
        }
    }

    @objc private func choosePartner() {
        analytics.report("feature_action", parameters: ["feature": "match_lineup"])
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            loadAuthorizedContactNames()
        case .notDetermined:
            contactsStore.requestAccess(for: .contacts) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        self?.reportPermission("contacts", result: "authorized")
                        self?.loadAuthorizedContactNames()
                    } else {
                        self?.reportPermission("contacts", result: "denied")
                        self?.showSettingsAlert(message: "Разрешите контакты, чтобы выбрать партнера для локального состава.")
                    }
                }
            }
        case .denied, .restricted:
            reportPermission("contacts", result: "denied")
            showSettingsAlert(message: "Разрешите контакты, чтобы выбрать партнера для локального состава.")
        default:
            if #available(iOS 18.0, *), status == .limited {
                loadAuthorizedContactNames()
            } else {
                showStatus("Контакты: неизвестный статус")
            }
        }
    }

    private func loadAuthorizedContactNames() {
        let store = contactsStore
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let keys: [CNKeyDescriptor] = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
            ]
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .userDefault
            var names: [String] = []
            do {
                try store.enumerateContacts(with: request) { contact, stop in
                    if let name = CNContactFormatter.string(from: contact, style: .fullName), !name.isEmpty {
                        names.append(name)
                    }
                    if names.count == 20 {
                        stop.pointee = true
                    }
                }
                DispatchQueue.main.async { self?.presentContactNames(names) }
            } catch {
                DispatchQueue.main.async {
                    self?.showStatus("Не удалось прочитать разрешённые контакты")
                }
            }
        }
    }

    private func presentContactNames(_ names: [String]) {
        guard !names.isEmpty else {
            showInformation(title: "Контакты", message: "Среди доступных контактов нет имён для выбора.")
            return
        }
        let alert = UIAlertController(
            title: "Добавить игрока",
            message: "Имя останется только на этом iPhone.",
            preferredStyle: .actionSheet
        )
        for name in names {
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.selectedPartnerName = name
                self?.updateScore()
                self?.showStatus("Игрок добавлен в локальный состав")
            })
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func requestPromotionMeasurement() {
        analytics.report("feature_action", parameters: ["feature": "promotion_attribution"])
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        guard currentStatus == .notDetermined else {
            handleTrackingStatus(currentStatus, offerSettings: true)
            return
        }
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.handleTrackingStatus(status, offerSettings: false)
            }
        }
    }

    private func handleTrackingStatus(
        _ status: ATTrackingManager.AuthorizationStatus,
        offerSettings: Bool
    ) {
        switch status {
        case .authorized:
            analytics.setAdvertisingIdentifierTracking(enabled: true)
            showStatus("Оценка продвижения через AppMetrica включена")
            reportPermission("tracking", result: "authorized")
        case .denied, .restricted:
            analytics.setAdvertisingIdentifierTracking(enabled: false)
            showStatus("AppMetrica работает без IDFA")
            reportPermission("tracking", result: status == .denied ? "denied" : "restricted")
            if offerSettings {
                showSettingsAlert(message: "Отслеживание отключено. YPoints продолжает работать без IDFA.")
            }
        case .notDetermined:
            showStatus("Решение об оценке продвижения ещё не принято")
        @unknown default:
            showStatus("ATT: неизвестный статус")
        }
    }

    @objc private func takeMatchPhoto() {
        analytics.report("feature_action", parameters: ["feature": "match_camera"])
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.reportPermission("camera", result: granted ? "authorized" : "denied")
                    granted
                        ? self?.presentCamera()
                        : self?.showSettingsAlert(message: "Разрешите камеру, чтобы снять фото матча.")
                }
            }
        case .denied, .restricted:
            reportPermission("camera", result: "denied")
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
        reportPermission("camera", result: "authorized")
    }

    @objc private func browseMatchPhotos() {
        analytics.report("feature_action", parameters: ["feature": "match_day_photos"])
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            presentMatchDayPhotoBrowser(limited: status == .limited)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.reportPermission("photo_read", result: newStatus == .limited ? "limited" : "authorized")
                        self?.presentMatchDayPhotoBrowser(limited: newStatus == .limited)
                    } else {
                        self?.reportPermission("photo_read", result: "denied")
                        self?.showSettingsAlert(message: "Разрешите просмотр Фото, чтобы выбрать снимок за день матча.")
                    }
                }
            }
        case .denied, .restricted:
            reportPermission("photo_read", result: "denied")
            showSettingsAlert(message: "Разрешите просмотр Фото, чтобы выбрать снимок за день матча.")
        @unknown default:
            showStatus("Фото: неизвестный статус")
        }
    }

    private func presentMatchDayPhotoBrowser(limited: Bool) {
        let options = PHFetchOptions()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: snapshot.updatedAt)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()
        options.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate < %@",
            start as NSDate,
            end as NSDate
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 60

        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        guard !assets.isEmpty else {
            showInformation(title: "Фото за день матча", message: "Доступных снимков за этот день не найдено.")
            return
        }

        let controller = MatchPhotoGridViewController(
            assets: assets,
            limited: limited
        ) { [weak self] image in
            self?.selectedPhoto = image
            self?.mediaPreview.image = image
            self?.showStatus("Фото добавлено к карточке результата")
        }
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    @objc private func handleVoiceNote() {
        if audioRecorder?.isRecording == true {
            voiceNoteButton?.isEnabled = false
            voiceNoteStatusLabel.text = "Сохраняем голосовую заметку…"
            audioRecorder?.stop()
            return
        }
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
            audioPlayer = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            updateVoiceNoteUI()
            showStatus("Воспроизведение остановлено")
            return
        }
        if voiceNoteURL != nil {
            presentVoiceNoteActions()
            return
        }

        analytics.report("feature_action", parameters: ["feature": "voice_note"])
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            startVoiceRecording(session: session)
        case .undetermined:
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.reportPermission("microphone", result: granted ? "authorized" : "denied")
                    if granted {
                        self?.startVoiceRecording(session: session)
                    } else {
                        self?.showSettingsAlert(message: "Разрешите микрофон, чтобы записать заметку.")
                    }
                }
            }
        case .denied:
            reportPermission("microphone", result: "denied")
            showSettingsAlert(message: "Разрешите микрофон, чтобы записать заметку.")
        @unknown default:
            showStatus("Микрофон: неизвестный статус")
        }
    }

    private func startVoiceRecording(session: AVAudioSession) {
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try session.setActive(true)
            let directory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let url = voiceNoteFileURL()
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            audioRecorder = recorder
            recorder.record(forDuration: 30)
            updateVoiceNoteUI()
            showStatus("Идёт запись • нажмите ещё раз для остановки • максимум 30 секунд")
            reportPermission("microphone", result: "authorized")
        } catch {
            showStatus("Не удалось начать запись")
        }
    }

    private func presentVoiceNoteActions() {
        let alert = UIAlertController(
            title: "Голосовая заметка записана",
            message: "Она хранится только на этом iPhone. Можно прослушать, записать заново или удалить.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Прослушать", style: .default) { [weak self] _ in
            self?.playVoiceNote()
        })
        alert.addAction(UIAlertAction(title: "Перезаписать", style: .default) { [weak self] _ in
            self?.deleteVoiceNote()
            self?.handleVoiceNote()
        })
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.deleteVoiceNote()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    private func playVoiceNote() {
        guard let voiceNoteURL else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: voiceNoteURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            updateVoiceNoteUI()
            showStatus("Воспроизводим голосовую заметку")
        } catch {
            showStatus("Не удалось воспроизвести заметку")
        }
    }

    private func deleteVoiceNote() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if let voiceNoteURL {
            try? FileManager.default.removeItem(at: voiceNoteURL)
        }
        self.voiceNoteURL = nil
        updateVoiceNoteUI()
        showStatus("Голосовая заметка удалена")
    }

    private func voiceNoteFileURL() -> URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("ypoints-match-note.m4a")
    }

    private func restoreVoiceNoteIfAvailable() {
        let url = voiceNoteFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            voiceNoteURL = url
        }
    }

    private func updateVoiceNoteUI() {
        let title: String
        let symbol: String
        let status: String
        let color: UIColor

        if audioRecorder?.isRecording == true {
            title = "Остановить запись"
            symbol = "stop.circle.fill"
            status = "Идёт запись • нажмите кнопку, чтобы остановить • максимум 30 секунд"
            color = Palette.danger
        } else if audioPlayer?.isPlaying == true {
            title = "Остановить воспроизведение"
            symbol = "stop.fill"
            status = "Воспроизводим сохранённую заметку"
            color = Palette.darkGreen
        } else if voiceNoteURL != nil {
            title = "Управление голосовой заметкой"
            symbol = "waveform"
            status = "Заметка сохранена • нажмите, чтобы прослушать, перезаписать или удалить"
            color = Palette.darkGreen
        } else {
            title = "Записать голосовую заметку"
            symbol = "mic.fill"
            status = "Записи пока нет • максимальная длительность 30 секунд"
            color = Palette.darkGreen
        }

        if var configuration = voiceNoteButton?.configuration {
            configuration.title = title
            configuration.image = UIImage(systemName: symbol)
            configuration.baseForegroundColor = color
            voiceNoteButton?.configuration = configuration
        }
        voiceNoteButton?.accessibilityHint = status
        voiceNoteStatusLabel.text = status
        voiceNoteStatusLabel.accessibilityValue = status
    }

    @objc private func saveScoreCard() {
        analytics.report("feature_action", parameters: ["feature": "save_score_card"])
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            saveGeneratedScoreCard()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.reportPermission("photo_add", result: "authorized")
                        self?.saveGeneratedScoreCard()
                    } else {
                        self?.reportPermission("photo_add", result: "denied")
                        self?.showSettingsAlert(message: "Разрешите сохранение, чтобы добавить карточку счета в Фото.")
                    }
                }
            }
        case .denied, .restricted:
            reportPermission("photo_add", result: "denied")
            showSettingsAlert(message: "Разрешите сохранение, чтобы добавить карточку счета в Фото.")
        @unknown default:
            showStatus("Сохранение в Фото: неизвестный статус")
        }
    }

    private func saveGeneratedScoreCard() {
        let size = CGSize(width: 1200, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            Palette.background.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let centered = NSMutableParagraphStyle()
            centered.alignment = .center

            "YPoints".draw(
                in: CGRect(x: 80, y: 70, width: 1040, height: 110),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: centered
                ]
            )
            if let selectedPhoto {
                selectedPhoto.draw(in: CGRect(x: 120, y: 210, width: 960, height: 480))
            }
            snapshot.pointsScoreText.draw(
                in: CGRect(x: 80, y: 720, width: 1040, height: 190),
                withAttributes: [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 138, weight: .black),
                    .foregroundColor: Palette.lime,
                    .paragraphStyle: centered
                ]
            )
            "Геймы   \(snapshot.gamesScoreText)    •    Сеты   \(snapshot.setsScoreText)".draw(
                in: CGRect(x: 80, y: 915, width: 1040, height: 80),
                withAttributes: [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .semibold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: centered
                ]
            )
            "Мы   •   Соперники".draw(
                in: CGRect(x: 80, y: 1035, width: 1040, height: 80),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 42, weight: .semibold),
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
                if saved {
                    self?.reportPermission("photo_add", result: "authorized")
                    self?.showInformation(
                        title: "Сохранено в Фото",
                        message: "Карточка счёта добавлена в медиатеку."
                    )
                } else {
                    self?.showInformation(
                        title: "Не удалось сохранить",
                        message: "Карточка счёта не была добавлена в Фото."
                    )
                }
            }
        }
    }

    @objc private func enableMatchReminder() {
        analytics.report("feature_action", parameters: ["feature": "match_notifications"])
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self else { return }
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.presentPushPreprompt()
                case .authorized, .provisional, .ephemeral:
                    self.finishPushSetup()
                case .denied:
                    self.reportPermission("push", result: "denied")
                    self.showSettingsAlert(message: "Разрешите уведомления, чтобы получать события матча.")
                @unknown default:
                    self.showStatus("Уведомления: неизвестный статус")
                }
            }
        }
    }

    private func presentPushPreprompt() {
        let alert = UIAlertController(
            title: "Уведомления о матче",
            message: "Уведомления сообщат о приглашении, начале и результате матча.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не сейчас", style: .cancel))
        alert.addAction(UIAlertAction(title: "Продолжить", style: .default) { [weak self] _ in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, _ in
                DispatchQueue.main.async {
                    self?.reportPermission("push", result: granted ? "authorized" : "denied")
                    if granted {
                        self?.finishPushSetup()
                    } else {
                        self?.showStatus("Уведомления не включены")
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func finishPushSetup() {
        UIApplication.shared.registerForRemoteNotifications()
        scheduleNotificationIfAuthorized(
            body: snapshot.state == .finished
                ? "Матч завершен. \(snapshot.scoreSummary)"
                : "Матч продолжается. \(snapshot.scoreSummary)"
        )
        reportPermission("push", result: "authorized")
        syncSnapshot()
    }

    private func scheduleNotificationIfAuthorized(body: String) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
            let content = UNMutableNotificationContent()
            content.title = "YPoints"
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "YPOINTS_MATCH"
            content.userInfo = [
                "score": self?.snapshot.pointsScoreText ?? "0 : 0",
                "games": self?.snapshot.gamesScoreText ?? "0 : 0",
                "sets": self?.snapshot.setsScoreText ?? "0 : 0",
                "revision": self?.snapshot.revision ?? 0,
                "matchToken": self?.matchToken ?? ""
            ]
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            )
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    self?.showStatus(
                        error == nil
                            ? "Проверочное уведомление появится через 5 секунд"
                            : "Не удалось создать уведомление"
                    )
                }
            }
        }
    }

    private func reportPermission(_ permission: String, result: String) {
        analytics.report(
            "permission_result",
            parameters: ["permission": permission, "result": result]
        )
    }

    private func showStatus(_ text: String) {
        statusLabel.text = text
        statusLabel.accessibilityValue = text
    }

    private func showInformation(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        let presenter = navigationController?.visibleViewController ?? self
        presenter.present(alert, animated: true)
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
            reportPermission("location", result: "denied")
            showStatus("Геолокация не разрешена • карта доступна без текущей позиции")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        manager.stopUpdatingLocation()
        searchPadelCourts(center: coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        showStatus("Не удалось определить позицию • карта доступна вручную")
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        selectedPhoto = info[.originalImage] as? UIImage
        mediaPreview.image = selectedPhoto
        picker.dismiss(animated: true)
        showStatus("Фото матча добавлено к карточке результата")
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension MainViewController: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        audioRecorder = nil
        voiceNoteButton?.isEnabled = true
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if flag {
            voiceNoteURL = recorder.url
            showStatus("Голосовая заметка сохранена на этом iPhone")
        } else {
            try? FileManager.default.removeItem(at: recorder.url)
            voiceNoteURL = nil
            showStatus("Запись голосовой заметки прервана")
        }
        updateVoiceNoteUI()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        updateVoiceNoteUI()
        showStatus(flag ? "Воспроизведение завершено" : "Воспроизведение прервано")
    }
}

private final class MatchPhotoGridViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    private let assets: [PHAsset]
    private let limited: Bool
    private let imageManager = PHCachingImageManager()
    private let selection: (UIImage) -> Void

    init(assets: [PHAsset], limited: Bool, selection: @escaping (UIImage) -> Void) {
        self.assets = assets
        self.limited = limited
        self.selection = selection
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        super.init(collectionViewLayout: layout)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Фото за день матча"
        collectionView.backgroundColor = .systemBackground
        collectionView.register(MatchPhotoCell.self, forCellWithReuseIdentifier: "photo")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )
        if limited {
            title = "Доступные фото за день"
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        assets.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "photo",
            for: indexPath
        ) as? MatchPhotoCell ?? MatchPhotoCell()
        let asset = assets[indexPath.item]
        cell.representedIdentifier = asset.localIdentifier
        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFill,
            options: nil
        ) { image, _ in
            guard cell.representedIdentifier == asset.localIdentifier else { return }
            cell.imageView.image = image
        }
        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let asset = assets[indexPath.item]
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 1600, height: 1600),
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, _ in
            guard let self, let image else { return }
            self.selection(image)
            self.dismiss(animated: true)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let side = floor((collectionView.bounds.width - 4) / 3)
        return CGSize(width: side, height: side)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

}

private final class MatchPhotoCell: UICollectionViewCell {
    let imageView = UIImageView()
    var representedIdentifier: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        isAccessibilityElement = true
        accessibilityLabel = "Фотография за день матча"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedIdentifier = nil
        imageView.image = nil
    }
}

private final class ResultViewController: UIViewController {
    private let snapshot: MatchSnapshot
    private let photo: UIImage?
    private let hasVoiceNote: Bool
    private let saveAction: () -> Void

    init(
        snapshot: MatchSnapshot,
        photo: UIImage?,
        hasVoiceNote: Bool,
        saveAction: @escaping () -> Void
    ) {
        self.snapshot = snapshot
        self.photo = photo
        self.hasVoiceNote = hasVoiceNote
        self.saveAction = saveAction
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Результат матча"
        view.backgroundColor = Palette.background

        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 22
        card.translatesAutoresizingMaskIntoConstraints = false

        let scoreLabel = UILabel()
        scoreLabel.text = snapshot.pointsScoreText
        scoreLabel.textAlignment = .center
        scoreLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: .monospacedDigitSystemFont(ofSize: 58, weight: .black)
        )
        scoreLabel.adjustsFontForContentSizeCategory = true
        scoreLabel.textColor = Palette.darkGreen
        scoreLabel.accessibilityLabel = "Итоговый счет"
        scoreLabel.accessibilityValue = snapshot.scoreSummary

        let scoreDetailsLabel = UILabel()
        scoreDetailsLabel.text = "Геймы   \(snapshot.gamesScoreText)\nСеты   \(snapshot.setsScoreText)"
        scoreDetailsLabel.textAlignment = .center
        scoreDetailsLabel.numberOfLines = 2
        scoreDetailsLabel.font = .preferredFont(forTextStyle: .headline)
        scoreDetailsLabel.adjustsFontForContentSizeCategory = true
        scoreDetailsLabel.textColor = Palette.darkGreen

        let imageView = UIImageView(image: photo ?? UIImage(systemName: "sportscourt"))
        imageView.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 0.94, alpha: 1)
        imageView.tintColor = Palette.darkGreen
        imageView.contentMode = photo == nil ? .center : .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.heightAnchor.constraint(equalToConstant: 210).isActive = true
        imageView.accessibilityLabel = photo == nil ? "Фото матча не выбрано" : "Фото матча"

        let voiceLabel = UILabel()
        voiceLabel.text = hasVoiceNote ? "Голосовая заметка сохранена" : "Голосовой заметки нет"
        voiceLabel.font = .preferredFont(forTextStyle: .body)
        voiceLabel.adjustsFontForContentSizeCategory = true
        voiceLabel.textColor = Palette.mutedText

        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.title = "Сохранить карточку"
        buttonConfiguration.image = UIImage(systemName: "square.and.arrow.down")
        buttonConfiguration.imagePadding = 8
        buttonConfiguration.baseBackgroundColor = Palette.lime
        buttonConfiguration.baseForegroundColor = Palette.darkGreen
        buttonConfiguration.cornerStyle = .large
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(
            top: 14,
            leading: 16,
            bottom: 14,
            trailing: 16
        )
        let saveButton = UIButton(configuration: buttonConfiguration)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        let syncLabel = UILabel()
        syncLabel.text = snapshot.state == .finished ? "Матч завершен" : "Матч продолжается"
        syncLabel.font = .preferredFont(forTextStyle: .footnote)
        syncLabel.adjustsFontForContentSizeCategory = true
        syncLabel.textColor = Palette.mutedText

        let stack = UIStackView(arrangedSubviews: [
            scoreLabel,
            scoreDetailsLabel,
            imageView,
            voiceLabel,
            saveButton,
            syncLabel
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }

    @objc private func save() {
        saveAction()
    }
}

private enum Palette {
    static let background = UIColor(red: 0.03, green: 0.25, blue: 0.17, alpha: 1)
    static let darkGreen = UIColor(red: 0.04, green: 0.24, blue: 0.16, alpha: 1)
    static let lime = UIColor(red: 0.68, green: 0.93, blue: 0.22, alpha: 1)
    static let card = UIColor(white: 0.99, alpha: 1)
    static let actionBackground = UIColor(white: 0.91, alpha: 1)
    static let mutedText = UIColor(white: 0.34, alpha: 1)
    static let danger = UIColor(red: 0.68, green: 0.16, blue: 0.19, alpha: 1)
}

private extension Result where Success == Void {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
