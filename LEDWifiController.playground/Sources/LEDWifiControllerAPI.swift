//
//  WifiDevice.swift
//  LEDWifiController
//
//  Created by Christian Hatch on 12/20/16.
//  Copyright © 2016 Christian Hatch. All rights reserved.
//


import Foundation
import CocoaAsyncSocket


typealias Byte = UInt8
fileprivate typealias Packet = [Byte]


public class LEDWifiControllerAPI: NSObject {
    fileprivate static let port: UInt16 = 5577
    
    fileprivate let socket = GCDAsyncSocket()
    fileprivate let ipAddress: String

    public init(ipAddress: String) {
        self.ipAddress = ipAddress
        super.init()
        socket.synchronouslySetDelegate(self, delegateQueue: DispatchQueue(label: "LEDWifiControllerAPITCP"))
    }
}

//MARK: - Public API

public extension LEDWifiControllerAPI {
    
    func on() {
        send(packet: PacketFactory.on)
    }
    
    func off() {
        send(packet: PacketFactory.off)
    }
    
    func setColor(_ color: UIColor, persist: Bool = true) {
        send(packet: PacketFactory.color(color: color, persist: persist))
    }
    
    func getStatus(completion: ((WifiDevice.Status) -> Void)?) {
        send(packet: PacketFactory.status, tag: LEDWifiControllerAPI.statusTag)
    }
}



//MARK: - Private Implementation

fileprivate extension LEDWifiControllerAPI {
    
    fileprivate func send(packet: Packet, tag: Int? = nil) {
        if !socket.isConnected {
            connect()
        }
        
        let data = Data(bytes: packet)
        self.write(data: data, tag: tag)
    }
    
    
    private func connect() {
        do {
            try socket.connect(toHost: ipAddress, onPort: LEDWifiControllerAPI.port, withTimeout: 5)
        } catch {
            print(#function, error)
        }
    }

    private func write(data: Data, tag: Int? = nil) {
        print(Date(), #function, data)
        socket.write(data, withTimeout: 0.5, tag: tag ?? 1)
    }
}


//MARK: - TCP Delegate

extension LEDWifiControllerAPI: GCDAsyncSocketDelegate {
    
    //MARK: - Connecting

    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
//        print(#function, err)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print(#function, host, port)
    }
    
    
    //MARK: - Writing Data

    public func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        print(#function, partialLength, tag)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print(#function, tag)
    }
    
    
    //MARK: - Reading Data
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print(#function, data, tag)
        
        if tag == LEDWifiControllerAPI.statusTag {
            guard let string = String(data: data, encoding: .utf8) else { return }
            print(#function, "status = ", string)
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        print(#function, partialLength, tag)
    }
}



extension LEDWifiControllerAPI {
    
    fileprivate static let statusTag: Int = 99
    
    fileprivate struct PacketFactory {
        
        private static let local: Byte = 0x0f
        private static let power: Byte = 0x71
        private static let colorPersisted: Byte = 0x31
        private static let colorTemporary: Byte = 0x41
        
        
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

        static var status: Packet {
            let off: Byte = 0x24
            return checkSum(packet: [power, off, local])
        }
        
        
        
        //MARK: - Helpers 
        
        private static func toByte(float: CGFloat) -> Byte {
            let f2 = max(0.0, min(1.0, float))
            let byte = floor(f2 == 1.0 ? 255 : f2 * 256.0)
            return Byte(byte)
        }
        
        private static func checkSum(packet: Packet) -> Packet {
            var packet = packet
            
            let theSum: Byte = packet.reduce(0, &+)
            packet.append(theSum)
            return packet
        }
    }
}







