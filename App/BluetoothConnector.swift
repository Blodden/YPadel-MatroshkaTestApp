import CoreBluetooth
import Foundation

final class BluetoothConnector: NSObject {
    private let serviceUUID = CBUUID(string: "F5D61724-4528-4BD2-B3D3-76452F85B801")
    private let scoreUUID = CBUUID(string: "8D6648E7-6B77-41B2-8E74-E6B9B77F9E73")
    private let statusChanged: (String, Bool) -> Void
    private let snapshotReceived: (MatchSnapshot) -> Void

    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var connectedPeripheral: CBPeripheral?
    private var remoteCharacteristic: CBCharacteristic?
    private var localCharacteristic: CBMutableCharacteristic?
    private var latestSnapshot: MatchSnapshot
    private var active = false

    init(
        initialSnapshot: MatchSnapshot,
        statusChanged: @escaping (String, Bool) -> Void,
        snapshotReceived: @escaping (MatchSnapshot) -> Void
    ) {
        latestSnapshot = initialSnapshot
        self.statusChanged = statusChanged
        self.snapshotReceived = snapshotReceived
    }

    func toggle() {
        active ? stop() : start()
    }

    func update(_ snapshot: MatchSnapshot) {
        latestSnapshot = snapshot
        sendToConnectedPeer()
        notifySubscribers()
    }

    func stop() {
        active = false
        if let connectedPeripheral {
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
        }
        centralManager?.stopScan()
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        connectedPeripheral = nil
        remoteCharacteristic = nil
        localCharacteristic = nil
        centralManager = nil
        peripheralManager = nil
        statusChanged(L10n.text("bluetooth.off"), false)
    }

    private func start() {
        active = true
        statusChanged(L10n.text("bluetooth.searchingPhone"), true)
        centralManager = CBCentralManager(delegate: self, queue: .main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    }

    private func encodedSnapshot() -> Data? {
        try? JSONEncoder().encode(latestSnapshot)
    }

    private func accept(_ data: Data) {
        guard let snapshot = try? JSONDecoder().decode(MatchSnapshot.self, from: data) else { return }
        latestSnapshot = snapshot
        snapshotReceived(snapshot)
        statusChanged(L10n.text("bluetooth.scoreReceived"), true)
    }

    private func sendToConnectedPeer() {
        guard
            active,
            let connectedPeripheral,
            let remoteCharacteristic,
            let data = encodedSnapshot()
        else { return }
        connectedPeripheral.writeValue(data, for: remoteCharacteristic, type: .withResponse)
    }

    private func notifySubscribers() {
        guard
            active,
            let peripheralManager,
            let localCharacteristic,
            let data = encodedSnapshot()
        else { return }
        peripheralManager.updateValue(data, for: localCharacteristic, onSubscribedCentrals: nil)
    }
}

extension BluetoothConnector: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard active else { return }
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: [serviceUUID])
            statusChanged(L10n.text("bluetooth.searchingScoreboard"), true)
        case .unauthorized:
            statusChanged(L10n.text("bluetooth.denied"), false)
        case .poweredOff:
            statusChanged(L10n.text("bluetooth.poweredOff"), false)
        case .unsupported:
            statusChanged(L10n.text("bluetooth.unsupported"), false)
        default:
            statusChanged(L10n.text("bluetooth.unavailable"), false)
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard active, connectedPeripheral == nil else { return }
        connectedPeripheral = peripheral
        peripheral.delegate = self
        central.stopScan()
        statusChanged(
            L10n.format("bluetooth.connectingFormat", peripheral.name ?? "YPoints"),
            true
        )
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusChanged(
            L10n.format("bluetooth.connectedFormat", peripheral.name ?? "YPoints"),
            true
        )
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectedPeripheral = nil
        statusChanged(L10n.text("bluetooth.connectionFailed"), true)
        central.scanForPeripherals(withServices: [serviceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connectedPeripheral = nil
        remoteCharacteristic = nil
        guard active else { return }
        statusChanged(L10n.text("bluetooth.disconnectedSearching"), true)
        central.scanForPeripherals(withServices: [serviceUUID])
    }
}

extension BluetoothConnector: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            statusChanged(L10n.text("bluetooth.serviceUnavailable"), true)
            return
        }
        peripheral.services?
            .filter { $0.uuid == serviceUUID }
            .forEach { peripheral.discoverCharacteristics([scoreUUID], for: $0) }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard
            error == nil,
            let characteristic = service.characteristics?.first(where: { $0.uuid == scoreUUID })
        else {
            statusChanged(L10n.text("bluetooth.characteristicUnavailable"), true)
            return
        }
        remoteCharacteristic = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
        sendToConnectedPeer()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil, let data = characteristic.value else { return }
        accept(data)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        statusChanged(
            error == nil
                ? L10n.text("bluetooth.scoreSynced")
                : L10n.text("bluetooth.scoreNotSent"),
            true
        )
    }
}

extension BluetoothConnector: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard active else { return }
        switch peripheral.state {
        case .poweredOn:
            let characteristic = CBMutableCharacteristic(
                type: scoreUUID,
                properties: [.read, .write, .notify],
                value: nil,
                permissions: [.readable, .writeable]
            )
            let service = CBMutableService(type: serviceUUID, primary: true)
            service.characteristics = [characteristic]
            localCharacteristic = characteristic
            peripheral.add(service)
        case .unauthorized:
            statusChanged(L10n.text("bluetooth.denied"), false)
        case .poweredOff:
            statusChanged(L10n.text("bluetooth.poweredOff"), false)
        default:
            break
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: Error?
    ) {
        guard active, error == nil else { return }
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "YPoints"
        ])
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveRead request: CBATTRequest
    ) {
        guard let data = encodedSnapshot(), request.offset <= data.count else {
            peripheral.respond(to: request, withResult: .invalidOffset)
            return
        }
        request.value = data.subdata(in: request.offset..<data.count)
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for request in requests {
            guard let data = request.value else {
                peripheral.respond(to: request, withResult: .invalidAttributeValueLength)
                continue
            }
            accept(data)
            peripheral.respond(to: request, withResult: .success)
        }
        notifySubscribers()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        statusChanged(L10n.text("bluetooth.phoneConnected"), true)
        notifySubscribers()
    }
}
