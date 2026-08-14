import CoreBluetooth
import Foundation

final class BluetoothConnector: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    private var pendingPeripheral: CBPeripheral?
    private let statusChanged: (String) -> Void

    init(statusChanged: @escaping (String) -> Void) {
        self.statusChanged = statusChanged
    }

    func connect() {
        statusChanged("Bluetooth: проверяем доступ…")
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusChanged("Bluetooth: ищем табло…")
            central.scanForPeripherals(withServices: nil)
        case .unauthorized:
            statusChanged("Bluetooth: доступ запрещён")
        case .poweredOff:
            statusChanged("Bluetooth выключен")
        case .unsupported:
            statusChanged("Bluetooth не поддерживается")
        default:
            statusChanged("Bluetooth пока недоступен")
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard pendingPeripheral == nil else { return }
        pendingPeripheral = peripheral
        central.stopScan()
        statusChanged("Bluetooth: подключаем \(peripheral.name ?? "устройство")…")
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusChanged("Bluetooth: табло подключено")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusChanged("Bluetooth: не удалось подключиться")
    }
}
