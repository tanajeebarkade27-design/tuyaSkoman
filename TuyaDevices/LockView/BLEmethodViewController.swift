//import UIKit
//import ThingSmartHomeKit
//import ThingSmartActivatorDiscoveryManager
//import CoreBluetooth
//
//class BLEmethodViewController: UIViewController {
//
//    // MARK: - Variables
//
//    var tuyaHomeId: Int64 = 0
//    var tuyaRoomId: Int64 = 0
//
//    var addedDeviceId: String?
//
//    // Device List
//    var deviceList: [ThingSmartActivatorDeviceModel] = []
//    
//    private let activator = ThingSmartActivatorDiscovery()
//    private var bleTypeModel: ThingSmartActivatorTypeBleModel?
//
//    // MARK: - Life Cycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        startBLESearch()
//    }
//}
//
//// MARK: - BLE Search
//
//extension BLEmethodViewController {
//
//    func startBLESearch() {
//        print("Start BLE Search")
//        
//        activator.loadConfig()
//        activator.setupDelegate(self)
//        
//        let ble = ThingSmartActivatorTypeBleModel()
//        // `ThingSmartActivatorType` is imported as an OptionSet in Swift, so the C constant name
//        // (ThingSmartActivatorTypeBle) might not be available directly.
//        ble.type = ThingSmartActivatorType(rawValue: 1 << 1) // BLE
//        ble.spaceId = tuyaHomeId
//        ble.scanType = ThingActivatorBleScanTypeAll
//        self.bleTypeModel = ble
//        
//        activator.registerWithActivatorList([ble])
//        activator.startSearch([ble])
//    }
//}
//
//// MARK: - Activate Device
//
//extension BLEmethodViewController {
//
//    func activateBLEDevice(_ device: ThingSmartActivatorDeviceModel) {
//        print("Activating Device")
//        
//        guard let ble = bleTypeModel else { return }
//        activator.startActive(ble, deviceList: [device])
//    }
//}
//
//// MARK: - Activator Delegates
//
//extension BLEmethodViewController: ThingSmartActivatorSearchDelegate, ThingSmartActivatorActiveDelegate {
//    
//    func activatorService(_ service: any ThingSmartActivatorSearchProtocol,
//                          activatorType type: ThingSmartActivatorTypeModel,
//                          didFindDevice device: ThingSmartActivatorDeviceModel?,
//                          error errorModel: ThingSmartActivatorErrorModel?) {
//        
//        if let errorModel {
//            print("Search Failed => \(errorModel.localizedDescription)")
//            return
//        }
//        
//        guard let device else { return }
//        
//        print("Found Device => \(device.name)")
//        deviceList.append(device)
//        
//        // AUTO CONNECT FIRST DEVICE
//        activateBLEDevice(device)
//    }
//    
//    func activatorService(_ service: any ThingSmartActivatorActiveProtocol,
//                          activatorType type: ThingSmartActivatorTypeModel,
//                          didReceiveDevices devices: [ThingSmartActivatorDeviceModel]?,
//                          error errorModel: ThingSmartActivatorErrorModel?) {
//        
//        if let errorModel {
//            print("Device Add Failed => \(errorModel.localizedDescription)")
//            return
//        }
//        
//        guard let first = devices?.first else { return }
//        addedDeviceId = first.devId
//        print("Device Added Successfully")
//        print("Added Device ID => \(first.devId)")
//    }
//}
