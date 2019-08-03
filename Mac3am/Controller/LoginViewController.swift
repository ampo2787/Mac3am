//
//  ViewController.swift
//  Mac3am
//
//  Created by JihoonPark on 11/05/2019.
//  Copyright © 2019 Mac3am. All rights reserved.
//

import Cocoa

class LoginViewController: NSViewController {
    
    @IBOutlet weak var idField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        let vcStores = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("player"))
           as! PlayViewController
        
        let youtubeAPI : YoutubeAPI = YoutubeAPI()
        let authorizeTrue = youtubeAPI.authorize(window: self.view.window!, id: idField.stringValue, password: passwordField.stringValue)
        
        if authorizeTrue {
            //let vcStores = PlayViewController()
            self.view.window?.contentViewController = vcStores
            self.view.window?.contentView = vcStores.view
            self.view.window?.contentView?.display()        }
        else {
            //authorize fail.
        }
        
        
    }
    
}

