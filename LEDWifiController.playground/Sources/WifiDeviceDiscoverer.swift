//
//  WifiDeviceDiscoverer.swift
//  LEDWifiController
//
//  Created by Christian Hatch on 12/20/16.
//  Copyright © 2016 Christian Hatch. All rights reserved.
//

import Foundation
import CocoaAsyncSocket



/// This class will scan the local network for WifiDevices. 
public class WifiDeviceDiscoverer: NSObject {
    public enum DiscoveryResult {
        case devices([WifiDevice])
        case error(Error?)
        
        public typealias Handler = (DiscoveryResult) -> Void
    }

    fileprivate static let discoveryString = "HF-A11ASSISTHREAD"
    fileprivate static let port: UInt16 = 48899
    
    
    fileprivate let socket = GCDAsyncUdpSocket()
    fileprivate let timeout: TimeInterval
    
    fileprivate var completion: DiscoveryResult.Handler?
    fileprivate var discoveredDevices: [WifiDevice] = []
    
    
    public init(timeout: TimeInterval) {
        self.timeout = timeout
        super.init()
        
        self.socket.synchronouslySetDelegate(self, delegateQueue: DispatchQueue(label: "WifiControllerUDP"))
        
        do {
            try socket.bind(toPort: WifiDeviceDiscoverer.port)
        } catch {
            print(#function, error)
        }
    }
}


//MARK: - Public API

extension WifiDeviceDiscoverer  {
    
    public func discover(completion: @escaping DiscoveryResult.Handler) {
        self.completion = completion
        startDiscovery()
        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(self.callCompletion), userInfo: nil, repeats: false)
    }
    
    private func startDiscovery() {
        let broadcastHost = "255.255.255.255"
        
        do {
            try socket.beginReceiving()
            try socket.enableBroadcast(true)
        } catch {
            self.completion?(.error(error))
            return
        }
        
        let data = WifiDeviceDiscoverer.discoveryString.data(using: .utf8)!
        socket.send(data, toHost: broadcastHost, port: WifiDeviceDiscoverer.port, withTimeout: timeout, tag: 2)
    }
    
    @objc fileprivate func callCompletion() {
        completion?(.devices(discoveredDevices))
        socket.close()
    }
}


//MARK: - UDP Delegate

extension WifiDeviceDiscoverer: GCDAsyncUdpSocketDelegate {
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
//        print(#function, tag)
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
//        print(#function, tag, error)
        completion?(.error(error))
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
//        print(#function, data, address, filterContext)
        
        guard let string = String(data: data, encoding: .utf8),
            string != WifiDeviceDiscoverer.discoveryString
        else { return }
        
        let device = WifiDevice(discoveredString: string)
        discoveredDevices.append(device)
    }

    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
//        print(#function, error)
    }
    
}








