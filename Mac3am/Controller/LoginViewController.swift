//
//  ViewController.swift
//  Mac3am
//
//  Created by JihoonPark on 11/05/2019.
//  Copyright © 2019 Mac3am. All rights reserved.
//

import Cocoa
import AppAuth

class LoginViewController: NSViewController, OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    
    @IBOutlet weak var idField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    
    var authState:OIDAuthState!

    let appDelegate = NSApp.delegate as! AppDelegate
    
    let kIssuer:NSURL = NSURL.init(string:"https://accounts.google.com")!
    let clientID = "777277797941-bicdoihorovtgs1eg57etbljrr515n22.apps.googleusercontent.com"
    let clientSecret = "iHqF9CISdaDcBw-wq7GrzbuZ"
    let kSuccessURLString = "http://openid.github.io/AppAuth-iOS/redirect/"
    var kRedirectURI:NSURL = NSURL.init(string: "com.googleusercontent.apps.777277797941-bicdoihorovtgs1eg57etbljrr515n22:/oauthredirect")!
    var redirectHTTPHandler:OIDRedirectHTTPHandler?
    let kAuthorizerKey = "authorization"
    
    func didChange(_ state: OIDAuthState) {
        do {
           let archivedAuthState = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: false)
            UserDefaults.standard.set(archivedAuthState, forKey: kAuthorizerKey)
            UserDefaults.standard.synchronize()
        } catch  {
            print("")
        }
        
    }
    
    func setAuthState(authState:OIDAuthState) {
        if self.authState == authState {
            return
        }
        self.authState = authState
        self.authState.stateChangeDelegate = self
        self.didChange(authState)
    }
    
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        print("error")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let successURL = NSURL.init(string: kSuccessURLString)
        self.redirectHTTPHandler = OIDRedirectHTTPHandler.init(successURL: successURL as URL?)
//        self.loadState()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        let vcStores = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("player"))
           as! PlayViewController
        
//        self.authorize()
//        let youtubeAPI : YoutubeAPI = YoutubeAPI()
//        let authorizeTrue = youtubeAPI.authorize(controller: self, id: idField.stringValue, password: passwordField.stringValue)
            self.view.window?.contentViewController = vcStores
            self.view.window?.contentView = vcStores.view
            self.view.window?.contentView?.display()
            //let vcStores = PlayViewController()
        
    }
    
    func loadState() {
        let archivedAuthState = UserDefaults.standard.object(forKey: "authState")
        let authState = NSKeyedUnarchiver.unarchiveObject(with: archivedAuthState as! Data)
        self.setAuthState(authState: authState as! OIDAuthState)
    }
    /*
    func authorize() {
        OIDAuthorizationService.discoverConfiguration(forIssuer: kIssuer as URL) { (configuration, error) in
            if configuration == nil {
                self.authState = nil
            }
            else {
                let redirectURL = self.redirectHTTPHandler?.startHTTPListener(nil)
                let request = OIDAuthorizationRequest.init(configuration: configuration!, clientId: self.clientID, scopes: [OIDScopeOpenID, OIDScopeProfile], redirectURL: redirectURL!, responseType: OIDResponseTypeCode, additionalParameters: nil)
                self.appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,  callback: { (authState, error) in
                
                    NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                
                    if let state = authState {
                        self.setAuthState(authState: state)
                        print("success, Access Token : " + (authState?.lastTokenResponse?.accessToken)!)
                    }
                    else {
                        print("fail")
                    }
                    self.authState = authState
                })
            }
        }
    }
 */
}

