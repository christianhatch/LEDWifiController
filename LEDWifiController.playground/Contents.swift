//
//  LEDWifiController.playground
//  LEDWifiController
//

import XCPlayground
import PlaygroundSupport
import CocoaAsyncSocket

PlaygroundPage.current.needsIndefiniteExecution = true



var controllers: [LEDWifiControllerAPI] = []

func runFunction(closure: (LEDWifiControllerAPI) -> Void) {
    controllers.forEach(closure)
}



func afterDiscover() {
    runFunction { (controller) in
        controller.on()
//        device.on()
//        device.off()
//        device.setColor(UIColor(hue: 10, saturation: 1.0, brightness: 1.0, alpha: 1))
//        device.setColor(.blue)
    }
}




let discover = WifiDeviceDiscoverer(timeout: 1)
discover.discover { (result) in
    switch result {
    case .devices(let devices):
        controllers = devices.map{LEDWifiControllerAPI(ipAddress: $0.info.ipAddress)}
        afterDiscover()
        
    case .error(let error):
        print(error as Any)
    }
}



