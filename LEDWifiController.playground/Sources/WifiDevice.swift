//
//  WifiDevice.swift
//  LEDWifiController
//
//  Created by Christian Hatch on 12/20/16.
//  Copyright © 2016 Christian Hatch. All rights reserved.
//

import Foundation
import CocoaAsyncSocket


public struct WifiDevice {
    public struct Hardware {
        public let ipAddress: String
        let hardwareAddress: String
        let model: String
    }
    
    public struct Status {
        let deviceType: Byte
        let isOn: Bool
        let versionNumber: Byte
        let mode: Byte
        let slowness: Byte
        let color: UIColor
    }

    public let info: Hardware
    
    init(discoveredString: String) {
        let parts = (discoveredString as NSString).components(separatedBy: ",")
        self.info = Hardware(ipAddress: parts[0], hardwareAddress: parts[1], model: parts[2])
    }
}

extension WifiDevice: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        return asString
    }

    var asString: String {
        return String(describing: WifiDevice.self) + "IP = \(info.ipAddress)\nMAC = \(info.hardwareAddress)\nModel = \(info.model)"
    }
}











