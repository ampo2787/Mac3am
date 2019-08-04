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
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let appleEventManager = NSAppleEventManager.shared()
        
        appleEventManager.setEventHandler(self, andSelector:#selector(handleGetURLEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }
    
    @objc func handleGetURLEvent(event:NSAppleEventDescriptor, replyEvent:NSAppleEventDescriptor) {
        let URLString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue
        let URL = NSURL.init(string: URLString!)
        currentAuthorizationFlow!.resumeExternalUserAgentFlow(with: URL as URL?)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    

}

