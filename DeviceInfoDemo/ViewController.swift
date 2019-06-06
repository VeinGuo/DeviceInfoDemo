//
//  ViewController.swift
//  DeviceInfoDemo
//
//  Created by vein on 2019/6/4.
//  Copyright © 2019 vein. All rights reserved.
//

import Cocoa

import SystemConfiguration

class ViewController: NSViewController {

    @IBOutlet weak var hostName: NSTextField!
    @IBOutlet weak var modelName: NSTextField!
    @IBOutlet weak var modelIdentifier: NSTextField!
    @IBOutlet weak var serialNumber: NSTextField!
    @IBOutlet weak var version: NSTextField!
    @IBOutlet weak var build: NSTextField!
    @IBOutlet weak var diskSize: NSTextField!
    @IBOutlet weak var wifiMAC: NSTextField!
    @IBOutlet weak var ethernetMAC: NSTextField!
    @IBOutlet weak var bluetoothMAC: NSTextField!
    @IBOutlet weak var cpu: NSTextField!
    @IBOutlet weak var ARM: NSTextField!
    @IBOutlet weak var uuid: NSTextField!
    @IBOutlet weak var graphicCard: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hostName.stringValue =  Device.localizedName
        modelName.stringValue = Device.deviceType.rawValue
        modelIdentifier.stringValue = Device.model
        serialNumber.stringValue = Device.serialNumber ?? ""
        version.stringValue = Device.OSVersion
        build.stringValue = Device.osType
        diskSize.stringValue = Device.diskSize ?? ""
        wifiMAC.stringValue = Device.Network.WiFiInterface?.hardwareMAC.formatted ?? ""
        ethernetMAC.stringValue = Device.Network.EthernetInterface?.hardwareMAC.formatted ?? ""
        bluetoothMAC.stringValue = Device.Network.BluetoothPANInterface?.hardwareMAC.formatted ?? ""
        
        cpu.stringValue = Device.CPU.brand
        ARM.stringValue = "\(Device.RAM.ramSize)G"
        uuid.stringValue = Device.UUID ?? ""
        
        graphicCard.stringValue = Device.graphicCard ?? ""
        
    }

    func platform() -> String? {
        if let key = "hw.machine".cString(using: String.Encoding.utf8) {
            var size: Int = 0
            sysctlbyname(key, nil, &size, nil, 0)
            var machine = [CChar](repeating: 0, count: Int(size))
            sysctlbyname(key, &machine, &size, nil, 0)
            return String(cString: machine)
        }
        return nil
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}


