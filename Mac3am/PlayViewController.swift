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
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var userInfoTextField: NSTextField!
    let tableViewData = ["Ballad", "R&B", "ROCK", "HIPHOP"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    override func viewWillAppear() {
        botton_View.layer?.backgroundColor = NSColor.cyan.cgColor
        self.tableView.reloadData()
    }


}

extension PlayViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "playList"
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (tableViewData.count)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellIdentifier: String = ""
        
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = CellIdentifiers.NameCell
        }
        
        // 3
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = tableViewData[row]
            return cell
        }
        return nil
    }
    
}
