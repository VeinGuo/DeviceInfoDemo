//
//  Interface.swift
//  DeviceInfoDemo
//
//  Created by vein on 2019/6/4.
//  Copyright © 2019 vein. All rights reserved.
//

import Foundation
import CoreWLAN

class Interface {
    var BSDName: String
    var displayName: String
    var kind: String
    
    private var _hardwareMAC: String
    
    var hardwareMAC: MACAddress {
        return MACAddress(_hardwareMAC)
    }
    
    init(BSDName: String, displayName: String, kind: String, hardwareMAC: String) {
        self.BSDName = BSDName
        self.displayName = displayName
        self.kind = kind
        self._hardwareMAC = hardwareMAC
    }
    
}
