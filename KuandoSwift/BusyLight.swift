	//
//  BusyLight.swift
//  KuandoSwift
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import IOKit.hid

class BusyLight : NSObject {
    let vendorId = 0x27B8
    let productId = 0x01ED
    let reportSize = 8 //Device specific
    static let singleton = BusyLight()
    var device : IOHIDDevice? = nil
    
    
    func input(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        let message = Data(bytes: report, count: reportLength)
        print("Input received: \(message)")
    }
    
    func output(_ data: Data) {
        if (data.count > reportSize) {
            print("output data too large for USB report")
            return
        }
        let reportId : CFIndex = CFIndex(data[0])
        if let busylight = device {
            print("Senting output: \([UInt8](data))")
            IOHIDDeviceSetReport(busylight, kIOHIDReportTypeFeature, reportId, [UInt8](data), data.count)
        }
    }
    
    func connected(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        print("Device connected")
        // It would be better to look up the report size and create a chunk of memory of that size
        let report = UnsafeMutablePointer<UInt8>.allocate(capacity: reportSize)        
        device = inIOHIDDeviceRef
        
        let inputCallback : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
            let this : BusyLight = unsafeBitCast(inContext, to: BusyLight.self)
            this.input(inResult, inSender: inSender!, type: type, reportId: reportId, report: report, reportLength: reportLength)
        }
        
        //Hook up inputcallback
        IOHIDDeviceRegisterInputReportCallback(device!, report, reportSize, inputCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self));
        
        /* https://github.com/todbot/blink1/blob/master/docs/blink1-hid-commands.md
         - byte 0 = report_id (0x01)
         - byte 1 = command action ('c' = fade to rgb, 'v' get firmware version, etc.)
         - byte 2 = cmd arg 0 (e.g. red)
         - byte 3 = cmd arg 1 (e.g. green)
         - byte 4 = cmd arg 2 (e.g. blue)
         */
        
        //Turn on light to demonstrate sending a command
        let reportId : UInt8 = 1
        let command : UInt8 = UInt8(ascii: "n")
        let r : UInt8 = 0
        let g : UInt8 = 0xFF
        let b : UInt8 = 0
        let bytes : [UInt8] = [reportId, command, r, g, b]
        
        self.output(Data(bytes))
    }
    
    func removed(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        print("Device removed")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceDisconnected"), object: nil, userInfo: ["class": NSStringFromClass(type(of: self))])
    }

    
    @objc func initUsb() {
        let deviceMatch = [kIOHIDProductIDKey: productId, kIOHIDVendorIDKey: vendorId]
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        IOHIDManagerSetDeviceMatching(managerRef, deviceMatch as CFDictionary?)
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue);
        IOHIDManagerOpen(managerRef, 0);
        
        let matchingCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : BusyLight = unsafeBitCast(inContext, to: BusyLight.self)
            this.connected(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        let removalCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : BusyLight = unsafeBitCast(inContext, to: BusyLight.self)
            this.removed(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, matchingCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, removalCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        
        RunLoop.current.run();
    }

}
