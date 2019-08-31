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
    @IBOutlet weak var faceView: NSView!
    
    let fileManager = FileManager.default
    var dataPath :URL! = URL.init(string: "/Users/\(NSUserName())/Documents/Mac3am Music")
    var musicList:[String]! = []
    var currentMusicIndex = 0
    var currentMusicPlayer = player
    var queue = DispatchQueue.init(label: "progress")
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    var context:NSManagedObjectContext! = nil
    var entity:NSEntityDescription! = nil
    
    //video
    var captureSession: AVCaptureSession!
    var videoOutput: AVCaptureVideoDataOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var stillImageOutput = AVCaptureStillImageOutput()
    var saveCGImage:CGImage! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.playBtn.isEnabled = false
        self.playTimeIndicator.usesThreadedAnimation = true
        
        //core Data Setting
        context = appDelegate.persistentContainer.viewContext
        entity = NSEntityDescription.entity(forEntityName: "Entity", in: context)
        
        /* open power box and select folder code
         
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                //Do what you will
                //If there's only one URL, surely 'openPanel.URL'
                //but otherwise a for loop works
                let selectedPath = openPanel.url!.path
            }
            openPanel.close()
        }
        */
        dataPath = URL.init(fileURLWithPath: "/Users/\(NSUserName())/Documents/Mac3am Music")
        
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
    
    override func viewDidAppear() {
        view.window!.styleMask.insert(.resizable)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        guard let webCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else{
                print("Unable to access camera!")
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: webCamera)
            
            videoOutput = AVCaptureVideoDataOutput()
            stillImageOutput = AVCaptureStillImageOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(videoOutput) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(videoOutput)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
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
        
        //coreData Setting
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Entity")
        var thisUser:NSManagedObject! = nil
        var thisIsNewSong = true
        var skipTime = 0
        //request.predicate = NSPredicate(format: "age = %@", "12")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "name") as! String)
                if((data.value(forKey: "name") as! String) == musicList[currentMusicIndex]) {
                    thisUser = data
                    thisIsNewSong = false
                    skipTime = data.value(forKey: "skip") as! Int
                }
            }
        } catch {
            print("Failed")
        }
        
        if thisIsNewSong {
            thisUser = NSManagedObject(entity: entity!, insertInto: context)
            thisUser.setValue(musicList[currentMusicIndex], forKey: "name")
            thisUser.setValue(1, forKey: "skip")
            thisUser.setValue("testEmotion", forKey: "emotion")
        }
        else {
            thisUser.setValue(skipTime + 1, forKey: "skip")
            thisUser.setValue("testEmotion2", forKey: "emotion")
        }
        
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
        //capture image
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)
                let myimage = NSImage.init(data: imageData!)
                
                if let image = myimage {
                    var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                    self.saveCGImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)!
                }
            }
        }
        
        //next Music
        currentMusicIndex += 1
        if currentMusicIndex == musicList.count {
            currentMusicIndex = 0
        }
        let url = self.dataPath.appendingPathComponent(musicList[currentMusicIndex])
        load_Play_Music(url: url)
    }
    
    //video setup
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .portrait
        faceView.layer?.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.faceView.bounds
            }
        }
    }
    
    //play music
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
