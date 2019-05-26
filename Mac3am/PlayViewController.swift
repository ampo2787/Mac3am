//
//  PlayViewController.swift
//  Mac3am
//
//  Created by Jakeone Im on 25/05/2019.
//  Copyright © 2019 Mac3am. All rights reserved.
//

import Cocoa

class PlayViewController: NSViewController {
    @IBOutlet weak var botton_View: NSView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
    }
    
    override func viewWillAppear() {
        botton_View.layer?.backgroundColor = NSColor.cyan.cgColor
    }
    
}
