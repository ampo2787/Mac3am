//
//  PlayViewController.swift
//  Mac3am
//
//  Created by Jakeone Im on 25/05/2019.
//  Copyright © 2019 Mac3am. All rights reserved.
//

import Cocoa
import AVFoundation

var player: AVAudioPlayer?

class PlayViewController: NSViewController {
    
    @IBOutlet weak var albumArtView: NSImageView!
    @IBOutlet weak var botton_View: NSView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var userInfoTextField: NSTextField!
    @IBOutlet weak var playBtn: NSButton!
    @IBOutlet weak var previousBtn: NSButton!
    @IBOutlet weak var skipBtn: NSButton!
    @IBOutlet weak var playTimeIndicator: NSProgressIndicator!
    
    let fileManager = FileManager.default
    var dataPath :URL! = URL.init(string: "")
    var musicList:[String]! = []
    var currentMusicIndex = 0
    var currentMusicPlayer = player
    var queue = DispatchQueue.init(label: "progress")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.playBtn.isEnabled = false
        self.playTimeIndicator.usesThreadedAnimation = true
        
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        dataPath = documentsDirectory.appendingPathComponent("Mac3am Music")
        
        do {
            // 디렉토리 생성
            try fileManager.createDirectory(atPath: dataPath.path, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print("Error create directory: \(error), 아마 이미 생성되어 있을 것")
        }
        
        do {
            // 디렉토리의 음악 불러오기.
            self.musicList = try fileManager.contentsOfDirectory(atPath: dataPath.path)
        } catch let error as NSError {
            print("Error access directory: \(error)")
        }
        
    }
    
    override func viewWillAppear() {
        botton_View.layer?.backgroundColor = NSColor.cyan.cgColor
        self.tableView.reloadData()
    }
    
    @IBAction func playBtnTouched(_ sender: NSButton) {
        if let player = player {
            if player.isPlaying {
                player.pause()
                self.playBtn.image = NSImage(named: "play-2")
            }
            else {
                player.play()
                self.playBtn.image = NSImage(named: "pause-2")
            }
        }
    }
    
    @IBAction func previousBtnTouched(_ sender: NSButton) {
        player?.stop()
        currentMusicIndex -= 1
        if currentMusicIndex < 0 {
            currentMusicIndex = musicList.count - 1
        }
        let url = self.dataPath.appendingPathComponent(musicList[currentMusicIndex])
        load_Play_Music(url: url)
    }
    
    @IBAction func skipBtnTouched(_ sender: NSButton) {
        player?.stop()
        currentMusicIndex += 1
        if currentMusicIndex == musicList.count {
            currentMusicIndex = 0
        }
        let url = self.dataPath.appendingPathComponent(musicList[currentMusicIndex])
        load_Play_Music(url: url)
    }
    
    func load_Play_Music(url:URL) {
        do {
            //선택된 음악 재생.
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = player else { return }
            currentMusicPlayer = player
            player.play()
            
            //재생 버튼 일시정지 버튼으로 교체.
            self.playBtn.image = NSImage(named: "pause-2")
            
            //오른쪽 테이블뷰에서 선택된 곡 현재 곡으로 교체.
            tableView.selectRowIndexes(IndexSet.init(integer: currentMusicIndex), byExtendingSelection: false)
            
            //indicator start
            self.playTimeIndicator.isIndeterminate = false
            self.playTimeIndicator.maxValue = player.duration
            
            queue.async {
                while(true){
                    DispatchQueue.main.async {
                        self.playTimeIndicator.doubleValue = (self.currentMusicPlayer?.currentTime)!
                        print(self.playTimeIndicator.doubleValue)
                    }
                    sleep(1)
                }
            }
            
            //앨범 아트 교체.
            let playerItem = AVPlayerItem(url: url)
            let metadataList = playerItem.asset.metadata
            
            for item in metadataList {
                let itemKey = item.commonKey?.rawValue
                if itemKey == "artwork" {
                    if let audioImage = NSImage(data: item.value as! Data) {
                        self.albumArtView.image = audioImage
                    }
                }
            }
            
        }catch let error {
            print(error.localizedDescription)
        }
    }

}

extension PlayViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "playList"
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return musicList.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellIdentifier: String = ""
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = CellIdentifiers.NameCell
        }
        
        // 3
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = musicList[row]
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        //현재 선택된 음악 플레이.
        player?.stop()
        let table = notification.object as! NSTableView
        currentMusicIndex = table.selectedRow
        let url = self.dataPath.appendingPathComponent(musicList[currentMusicIndex])
        self.playBtn.isEnabled = true
        load_Play_Music(url: url)
    }
    
}
