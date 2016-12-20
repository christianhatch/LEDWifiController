//
//  LEDWifiController.playground
//  LEDWifiController
//

import XCPlayground
import PlaygroundSupport
import CocoaAsyncSocket

PlaygroundPage.current.needsIndefiniteExecution = true



var devices: [WifiDevice] = []

func runFunction(closure: (WifiDevice) -> Void) {
    devices.forEach(closure)
}



func afterDiscover() {
    runFunction { (device) in
//        device.on()
        device.setColor(UIColor(hue: 10, saturation: 1.0, brightness: 1.0, alpha: 1))
    }
}




let discover = WifiDeviceDiscoverer(timeout: 1)
discover.discover { (result) in
    switch result {
    case .devices(let theDevices):
        devices = theDevices
        afterDiscover()
        
    case .error(let error):
        print(error as Any)
    }
}



