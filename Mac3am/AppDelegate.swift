//
//  AppDelegate.swift
//  Mac3am
//
//  Created by JihoonPark on 11/05/2019.
//  Copyright © 2019 Mac3am. All rights reserved.
//

import Cocoa
import AppAuth

@NSApplicationMain


class AppDelegate: NSObject, NSApplicationDelegate{
    
    weak var currentAuthorizationFlow:OIDExternalUserAgentSession!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    

}

