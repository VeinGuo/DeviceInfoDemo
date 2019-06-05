//
//  MACAddress.swift
//  DeviceInfoDemo
//
//  Created by vein on 2019/6/4.
//  Copyright © 2019 vein. All rights reserved.
//

import Foundation

struct MACAddress: Equatable {
    
    var formatted: String {
        return String(sanitized.enumerated().map() {
            $0.offset % 2 == 1 ? [$0.element] : [":", $0.element]
            }.joined().dropFirst())
    }
    
    private var sanitized: String {
        let nonHexCharacters = CharacterSet(charactersIn: "0123456789abcdef").inverted
        return raw.lowercased().components(separatedBy: nonHexCharacters).joined()
    }
    
    private var raw: String
    
    init(_ raw: String) {
        self.raw = raw
    }
}

func ==(lhs: MACAddress, rhs: MACAddress) -> Bool {
    return lhs.formatted == rhs.formatted
}
