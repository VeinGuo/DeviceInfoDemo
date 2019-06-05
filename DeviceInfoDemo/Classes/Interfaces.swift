//
//  Interfaces.swift
//  DeviceInfoDemo
//
//  Created by vein on 2019/6/4.
//  Copyright © 2019 vein. All rights reserved.
//

import SystemConfiguration

struct Interfaces {
    static func all() -> [Interface] {
        let interfaces = SCNetworkInterfaceCopyAll()
        var instances: [Interface] = []
        
        for interfaceRef in interfaces {
            guard let BSDName = SCNetworkInterfaceGetBSDName(interfaceRef as! SCNetworkInterface) else { continue }
            guard let displayName = SCNetworkInterfaceGetLocalizedDisplayName(interfaceRef as! SCNetworkInterface) else { continue }
            guard let hardMAC = SCNetworkInterfaceGetHardwareAddressString(interfaceRef as! SCNetworkInterface) else { continue }
            guard let type = SCNetworkInterfaceGetInterfaceType(interfaceRef as! SCNetworkInterface) else { continue }
            
            let interface = Interface(BSDName: BSDName as String, displayName: displayName as String, kind: type as String, hardwareMAC: hardMAC as String)
            instances.append(interface)
        }
        return instances.sorted { $0.BSDName < $1.BSDName }
    }
}

extension CFArray: Sequence {
    public func makeIterator() -> AnyIterator<AnyObject> {
        var index = -1
        let maxIndex = CFArrayGetCount(self)
        return AnyIterator{
            index += 1
            guard index < maxIndex else {
                return nil
            }
            let unmanagedObject: UnsafeRawPointer = CFArrayGetValueAtIndex(self, index)
            let rec = unsafeBitCast(unmanagedObject, to: AnyObject.self)
            return rec
        }
    }
}
