//
//  main.swift
//  KuandoSwift
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import AppKit

let blink1 = Blink1.singleton
var daemon = Thread(target: blink1, selector:#selector(Blink1.initUsb), object: nil)

daemon.start()
RunLoop.current.run()

