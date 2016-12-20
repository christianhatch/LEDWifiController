//
//  WifiDevice.swift
//  RGB Remote
//
//  Created by Christian Hatch on 10/19/16.
//  Copyright © 2016 Knot Labs. All rights reserved.
//

import Foundation
import CocoaAsyncSocket


public struct WifiDevice {
    fileprivate struct Hardware {
        fileprivate let ipAddress: String
        fileprivate let hardwareAddress: String
        fileprivate let model: String
    }

    fileprivate let info: Hardware
    fileprivate let api: LEDWifiControllerAPI
    
    init(discoveredString: String) {
        let parts = (discoveredString as NSString).components(separatedBy: ",")
        self.info = Hardware(ipAddress: parts[0], hardwareAddress: parts[1], model: parts[2])
        self.api = LEDWifiControllerAPI(ipAddress: self.info.ipAddress)
    }
}


//MARK: - Public API 

public extension WifiDevice {
    
    func on() {
        api.send(packet: LEDWifiControllerAPI.PacketFactory.on)
    }
    
    func off() {
        api.send(packet: LEDWifiControllerAPI.PacketFactory.off)
    }
    
    func setColor(_ color: UIColor, persist: Bool = true) {
        api.send(packet: LEDWifiControllerAPI.PacketFactory.color(color: color, persist: persist))
    }
    
    func getStatus(completion: ((String) -> Void)?) {
        
    }
}

extension WifiDevice: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        return asString
    }

    var asString: String {
        return "Wifi Device: IP = \(info.ipAddress)\nMAC = \(info.hardwareAddress)\nModel = \(info.model)"
    }
}



































fileprivate class LEDWifiControllerAPI: NSObject {
    fileprivate static let port: UInt16 = 5577
    
    fileprivate let socket = GCDAsyncSocket()
    fileprivate let ipAddress: String
    
    
    //MARK: - Public API
    
    init(ipAddress: String) {
        self.ipAddress = ipAddress
        super.init()
        socket.synchronouslySetDelegate(self, delegateQueue: DispatchQueue(label: "LEDWifiControllerAPITCP"))
    }
}



//MARK: - Private Implementation

fileprivate extension LEDWifiControllerAPI {
    
    private func connect() {
        do {
            try socket.connect(toHost: ipAddress, onPort: LEDWifiControllerAPI.port, withTimeout: 5)
        } catch {
            print(#function, error)
        }
    }
    
    func send(packet: Packet) {
        if !socket.isConnected {
            connect()
        }
        
        let data = Data(bytes: packet)
        self.write(data: data)
    }
    
    @objc func write(data: Data) {
        print(Date(), #function, data)
        socket.write(data, withTimeout: 0.5, tag: 1)
    }
}


//MARK: - TCP Delegate

extension LEDWifiControllerAPI: GCDAsyncSocketDelegate {
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
//        print(#function, err)
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print(#function, host, port)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        print(#function, partialLength, tag)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print(#function, tag)
    }
}



extension LEDWifiControllerAPI {
    fileprivate typealias Byte = UInt8
    fileprivate typealias Packet = [Byte]
    
    fileprivate struct PacketFactory {
        
//        static let remote: Byte = 0xf0
        static let local: Byte = 0x0f
        static let power: Byte = 0x71
        static let colorPersisted: Byte = 0x31
        static let colorTemporary: Byte = 0x41
        
//    }
//    
//    fileprivate extension PacketFactory {
        
        static var on: Packet {
            let on: Byte = 0x23
            return checkSum(packet: [power, on, local])
        }
        
        static var off: Packet {
            let off: Byte = 0x24
            return checkSum(packet: [power, off, local])
        }
        
        static func color(color aColor: UIColor, persist: Bool) -> Packet {
            var redFloat: CGFloat = 0
            var greenFloat: CGFloat = 0
            var blueFloat: CGFloat = 0
            
            aColor.getRed(&redFloat, green: &greenFloat, blue: &blueFloat, alpha: nil)
            
            let red = toByte(float: redFloat)
            let green = toByte(float: greenFloat)
            let blue = toByte(float: blueFloat)
            let warmWhite: Byte = 0x00
            let coolWhite: Byte = 0x00
            let setRGB: Byte = 0xf0
            
            let persisted = persist ? colorPersisted : colorTemporary
            return checkSum(packet: [persisted, red, green, blue, warmWhite, coolWhite, setRGB, local])
        }
//    }
//    
//    
//    //MARK: - Helpers
//    
//    fileprivate extension PacketFactory {
        
        static func toByte(float: CGFloat) -> Byte {
            let f2 = max(0.0, min(1.0, float))
            let byte = floor(f2 == 1.0 ? 255 : f2 * 256.0)
            return Byte(byte)
        }
        
        static func checkSum(packet: Packet) -> Packet {
            var packet = packet
            
            let theSum: Byte = packet.reduce(0, &+)
            packet.append(theSum)
            return packet
        }
    }
}








