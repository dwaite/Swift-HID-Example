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
    let vendorId = 0x04D8
    let productId = 0xF848
    let reportSize = 64//Device specific
    static let singleton = BusyLight()
    var device : IOHIDDevice? = nil
    
    
    func input(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        let message = Data(bytes: UnsafePointer<UInt8>(report), count: reportLength)
        print("Input received: \(message)")
    }
    
    func output(_ data: Data) {
        if (data.count > reportSize) {
            print("output data too large for USB report")
            return
        }
        let reportId : CFIndex = 0
        if let busylight = device {
            print("Senting output: \(data)")
            IOHIDDeviceSetReport(busylight, kIOHIDReportTypeOutput, reportId, (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), data.count);
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
        
        //Turn on light to demonstrate sending a command
        let sound : UInt8 = 0
        let r : UInt8 = 0
        let g : UInt8 = 0xff
        let b : UInt8 = 0
        let bytes : [UInt8] = [0, 0, r, g, b, 0, 0, sound, 0, 0, 0, 0, 0, 0]
        
        self.output(Data(bytes: UnsafePointer<UInt8>(bytes), count:bytes.count))
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
