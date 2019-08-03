//
//  YoutubeAPI.swift
//  Mac3am
//
//  Created by 박지훈 on 03/08/2019.
//  Copyright © 2019 Mac3am. All rights reserved.
//

import Cocoa
import GTMAppAuth

class YoutubeAPI: NSObject {
    //OIDExternalUserAgent ???
    //
    let appDelegate = NSApp.delegate as! AppDelegate
    var authorization:GTMAppAuthFetcherAuthorization! = nil
    let configuration = GTMAppAuthFetcherAuthorization.configurationForGoogle()
    
    let kIssuer:NSURL = NSURL.init(string:"https://accounts.google.com")!
    
    let clientID = "777277797941-bicdoihorovtgs1eg57etbljrr515n22.apps.googleusercontent.com"
    let clientSecret = "iHqF9CISdaDcBw-wq7GrzbuZ"
    let kRedirectURI:URL = URL.init(string: "com.googleusercontent.apps.777277797941-bicdoihorovtgs1eg57etbljrr515n22:/oauthredirect")!
    let kExampleAuthorizerKey = "authorization"
    
    func authorize(window:NSWindow, id:String, password:String) -> Bool {
        let request = OIDAuthorizationRequest.init(configuration: configuration, clientId: clientID, scopes: [OIDScopeOpenID, OIDScopeProfile], redirectURL: kRedirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
        
        self.appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, externalUserAgent:window as! OIDExternalUserAgent , callback: { (authState, error) in
            if (authState != nil) {
                let authorization = GTMAppAuthFetcherAuthorization.init(authState: authState!)
                self.authorization = authorization
                print("success")
            }
            else {
                print("fail")
            }
        })
        
        return false;
    }
    
}
