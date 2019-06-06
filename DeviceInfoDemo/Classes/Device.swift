//
//  Device.swift
//  DeviceInfoDemo
//
//  Created by vein on 2019/6/4.
//  Copyright © 2019 vein. All rights reserved.
//

import Foundation

import IOKit.network
import IOBluetooth
import IOKit.storage
import CoreWLAN

enum MacDeviceType: String {
    case MacBook = "MacBook"
    case MacBookAir = "MacBook Air"
    case MacBookPro = "MacBook Pro"
    case iMac = "iMac"
    case iMacPro = "iMac Pro"
    case MacPro = "Mac Pro"
    case Macmini = "Mac mini"
    case unknown = "unknown"
}

class Device {
    static var localizedName: String {
        return Host.current().localizedName ?? ""
    }
    
    /// OS type
    /// ex. "Darwin"
    static var osType: String {
        do {
            let string = try stringForKeys([CTL_KERN, KERN_OSVERSION])
            return string
        } catch {
            return ""
        }
    }
    
    /// Model of the machine
    /// ex. "MacBookPro11,2"
    static var model: String {
        do {
            let string = try stringForKeys([CTL_HW, HW_MODEL])
            return string
        } catch {
            return ""
        }
    }
    
    static var deviceType: MacDeviceType {
        do {
            let keys = try keysForName("hw.model")
            let hardwareModelVal = try stringForKeys(keys)
            if hardwareModelVal.hasPrefix("Macmini") {
                return .Macmini
            } else if hardwareModelVal.hasPrefix("MacBookAir") {
                return .MacBook
            } else if hardwareModelVal.hasPrefix("MacBookPro") {
                return .MacBookPro
            } else if hardwareModelVal.hasPrefix("MacPro") {
                return .MacPro
            } else if hardwareModelVal.hasPrefix("iMac") {
                return .iMac
            } else if hardwareModelVal.hasPrefix("MacBook") {
                return .MacBook
            }
            return .unknown
        } catch {
            return .unknown
        }
    }

    static var UUID: String? {
        let dev = IOServiceMatching("IOPlatformExpertDevice")
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        IOObjectRelease(platformExpert)
        
        if let ser: CFTypeRef = serialNumberAsCFString?.takeUnretainedValue(),
            let result = ser as? String {
            return result
        }
        return nil
    }
    
    static var serialNumber: String? {
        let dev = IOServiceMatching("IOPlatformExpertDevice")
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
        IOObjectRelease(platformExpert)
        
        if let ser: CFTypeRef = serialNumberAsCFString?.takeUnretainedValue(),
            let result = ser as? String {
            return result
        }
        return nil
    }
    
    static var graphicCard: String? {
        let dev = IOServiceMatching("IOPCIDevice")
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMasterPortDefault, dev, &iterator) == kIOReturnSuccess {
            while case let serialPort = IOIteratorNext(iterator), serialPort != 0 {
                var serviceDictionary: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(serialPort, &serviceDictionary, kCFAllocatorDefault, 0) != kIOReturnSuccess {
                    IOObjectRelease(serialPort);
                    continue
                }
                
                if let dic = serviceDictionary?.takeUnretainedValue() as? [String: Any],
                    let GPUModel = dic["model"] {
                    if CFGetTypeID(GPUModel as CFTypeRef) == CFDataGetTypeID() {
                        let modelName = String(data: (GPUModel as! CFData) as Data, encoding: .ascii)
                        return modelName
                    }
                }
            }
        }

        return nil
    }
    
    static var diskSize: String? {
        do {
            let dic = try FileManager.default.attributesOfFileSystem(forPath: "/")
            //    fileSystemFreeSize
            //    fileSystemSize
            //        let freeSize = (dic[FileAttributeKey.systemFreeSize] as? Float64 ?? 0) / 1000.0 / 1000.0 / 1000.0
            let size = (dic[FileAttributeKey.systemSize] as? Float64 ?? 0) / 1000.0 / 1000.0 / 1000.0
            return "\(size)"
        } catch {
            return nil
        }
        
    }
    
    func BytesToGigaBytes(b: Int) -> Int {
        return b / 1024 / 1024 / 1024
    }
    
    static var OSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    enum DarwinError: Error {
        case unknown
        case malformedUTF8
        case invalidSize
        case posixError(POSIXErrorCode)
    }
    
    /// Uses sysctl to return a byte array of data for given keys to retrieve system configurations
    fileprivate static func dataForKeys(_ keys: [Int32]) throws -> [Int8] {
        
        return try keys.withUnsafeBufferPointer { keysPointer throws -> [Int8] in
            // Interface with sysctl to first retrieve the size of the byte array
            var requiredSize: Int = 0
            guard Darwin.sysctl(UnsafeMutablePointer<Int32>(mutating: keysPointer.baseAddress), UInt32(keys.count), nil, &requiredSize, nil, 0) == 0 else {
                throw POSIXErrorCode(rawValue: errno).map { DarwinError.posixError($0) } ?? DarwinError.unknown
            }
            
            // Retrieve data now that the appropriate size is known
            let data = [Int8](repeating: 0, count: requiredSize)
            let resultCode = data.withUnsafeBufferPointer() { dataPointer -> Int32 in
                return Darwin.sysctl(UnsafeMutablePointer<Int32>(mutating: keysPointer.baseAddress), UInt32(keys.count), UnsafeMutableRawPointer(mutating: dataPointer.baseAddress), &requiredSize, nil, 0)
            }
            
            guard resultCode == 0 else {
                throw POSIXErrorCode(rawValue: errno).map { DarwinError.posixError($0) } ?? DarwinError.unknown
            }
            
            return data
        }
    }
    
    /// Returns a string representation of sysctl for given keys
    fileprivate static func stringForKeys(_ keys: [Int32]) throws -> String {
        let utf8DataString = try dataForKeys(keys).withUnsafeBufferPointer() { dataPointer -> String? in
            dataPointer.baseAddress.flatMap { String(validatingUTF8: $0) }
        }
        
        guard let string = utf8DataString else {
            throw DarwinError.malformedUTF8
        }
        
        return string
    }
    
    /// Convert a string like "machdep.cpu.brand_string" to an array of integer keys reference values
    fileprivate static func keysForName(_ name: String) throws -> [Int32] {
        var keysBufferSize = Int(CTL_MAXNAME)
        var keysBuffer = [Int32](repeating: 0, count: keysBufferSize)
        try keysBuffer.withUnsafeMutableBufferPointer() { (bytePointer: inout UnsafeMutableBufferPointer<Int32>) throws in
            try name.withCString() { (cString: UnsafePointer<Int8>) throws in
                guard sysctlnametomib(cString, bytePointer.baseAddress, &keysBufferSize) == 0 else {
                    throw POSIXErrorCode(rawValue: errno).map { DarwinError.posixError($0) } ?? DarwinError.unknown
                }
            }
        }
        
        // truncate range if needed
        if keysBuffer.count > keysBufferSize {
            keysBuffer.removeSubrange(keysBufferSize..<keysBuffer.count)
        }
        return keysBuffer
    }
    
    /// Will rebind data as the memory type provided. Throws errors if memory type expected is invalid
    fileprivate static func interpretDataAsType<T>(_ data: [Int8], type: T.Type) throws -> T {
        if data.count != MemoryLayout<T>.size {
            throw DarwinError.invalidSize
        }
        
        return try data.withUnsafeBufferPointer() { bufferPointer throws -> T in
            guard let baseAddress = bufferPointer.baseAddress else { throw DarwinError.unknown }
            return baseAddress.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        }
    }
}

extension Device {
    class Network {
        static var EthernetInterface: Interface? {
            let interfaces = Interfaces.all()
            
            for interface in interfaces {
                if interface.displayName == "Ethernet" && interface.kind == "Ethernet" {
                    return interface
                }
            }
            return nil
        }
        
        static var WiFiInterface: Interface? {
            let interfaces = Interfaces.all()
            
            for interface in interfaces {
                if interface.displayName == "Wi-Fi" {
                    return interface
                }
            }
            return nil
        }
        
        static var BluetoothPANInterface: Interface? {
            let interfaces = Interfaces.all()
            
            for interface in interfaces {
                if interface.displayName == "Bluetooth PAN" &&  interface.kind == "Ethernet" {
                    return interface
                }
            }
            return nil
        }
    }
}

extension Device {
    class CPU {
        
        /// CPU model info
        /// ex. "x86_64" or "N71mAP"
        static var model: String {
            do {
                let string = try stringForKeys([CTL_HW, HW_MACHINE])
                return string
            } catch {
                return ""
            }
        }
        
        /// Number of available (physical and virtual) cpus for the system
        static var availableCPUs: Int32 {
            do {
                let sysData = try dataForKeys([CTL_HW, HW_AVAILCPU])
                let cups = try interpretDataAsType(sysData, type: Int32.self)
                return cups
            } catch {
                return 0
            }
        }
        
        static var brand: String {
            do {
                let keys = try keysForName("machdep.cpu.brand_string")
                let string = try stringForKeys(keys)
                return string
            } catch {
                return ""
            }
        }
    }
}

extension Device {
    class RAM {
        static var ramSize: UInt32 {
            do {
                let sysData = try dataForKeys([CTL_HW, HW_MEMSIZE])
                let memInBytes = try interpretDataAsType(sysData, type: UInt64.self)
                return UInt32(memInBytes / 1024 / 1024 / 1024) // result in GB
            } catch {
                return 0
            }
        }
    }
}

