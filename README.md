# Swift HID Example (Formerly 'KuandoSwift')

How to use pure Swift to talk to a USB HID device
Since it was a pain in the ass to get Swift to work with HID without resorting to inline objective-c or bindings, I thought it would be good to publish the solution I found.  I hope its of use to others.

Originally this used an output report type to talk to a Kuando busylight, but I replace that device with a ThingM blink(1), which uses a feature report type.

Topics:
 * IOHIDDeviceCallback
 * IOHIDDevice
 * UnsafeMutablePointer
 * unsafeBitCast
