//
//  PlayViewController.swift
//  Mac3am
//
//  Created by Jakeone Im on 25/05/2019.
//  Copyright © 2019 Mac3am. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreML
import Vision

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
    
    //ML - Face Detect
    let shapeLayer = CAShapeLayer()

    let faceDetectionRequest = VNDetectFaceRectanglesRequest() // 얼굴 인식 요청을 하는 Request
    let faceDetectionRequestHandler = VNSequenceRequestHandler() // 얼굴 인식 요청을 처리 하는 handler
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    
    //video
    var captureSession: AVCaptureSession!
    var videoOutput: AVCaptureVideoDataOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var stillImageOutput = AVCaptureStillImageOutput()
    var currentImage:CGImage! = nil
    var cropImage:CGImage! = nil
    
    //csv file
    let fileName = "FaceDot.csv"
    var csvPath:URL? = nil
    var csvText:String? = ""
    
    //ML - My Model
    let myModel = your_model_name()
    
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
        
        //csv file
        csvPath = URL.init(fileURLWithPath: "/Users/\(NSUserName())/Documents/\(self.fileName)")
        do {
            // 디렉토리 생성
            try fileManager.createDirectory(atPath: dataPath.path, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print("Error create directory: \(error), 아마 이미 생성되어 있을 것")
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
                    self.currentImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)!
                    
                    self.detectFace(on: CIImage.init(cgImage: self.currentImage))
/*
                    try? self.faceDetectionRequestHandler.perform(
                        [self.faceDetectionRequest], // 핸들러는 faceDetectionRequest의 요청들을 처리한다
                        on: self.currentImage)// 우리가 처리하고 싶은 이미지
                    
                    if let faceDetectionResults = self.faceDetectionRequest.results as? [VNFaceObservation]{ // 핸들러가 처리한 결과를 얻음
                        for face in faceDetectionResults{ // 결과들
                            let bbox = face.boundingBox // 결과의 바운딩 박스
                            let floatWidth = CGFloat(self.currentImage.width)
                            let floatHeight = CGFloat(self.currentImage.height)
                            // 바운딩 박스 설정
                            let faceRect = CGRect(
                                x: bbox.origin.x * floatWidth,
                                y: floatHeight - (bbox.origin.y * floatHeight + bbox.height * floatHeight),
                                width: bbox.width * floatWidth,
                                height: bbox.height * floatHeight)
                            
                            // 이미지 자르기
                            if let  cgImage = self.currentImage{
                                if let imageRef = cgImage.cropping(to: faceRect){
                                    self.cropImage = imageRef
                                }
                            }
                        }
                    }
                    */
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
        
        shapeLayer.strokeColor = NSColor.red.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: -1))
        videoPreviewLayer.addSublayer(shapeLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.faceView.bounds
                self.shapeLayer.frame = self.faceView.bounds
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
//                        print(self.playTimeIndicator.doubleValue)
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
    
    //Face dot action
    func detectFace(on image: CIImage) {
        try? faceDetectionRequestHandler.perform([faceDetectionRequest], on: image)
        if let results = faceDetectionRequest.results as? [VNFaceObservation] {
            if !results.isEmpty {
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
                
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                }
            }
        }
    }
    
    func detectLandmarks(on image: CIImage) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            for observation in landmarksResults {
                DispatchQueue.main.async {
                    if let boundingBox = self.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                        let faceBoundingBox = boundingBox.scaled(to: self.faceView.bounds.size)
                        
                        //different types of landmarks
                        let faceContour = observation.landmarks?.faceContour
                        self.convertPointsForFace(faceContour, faceBoundingBox, "faceContour")
                        
                        let leftEye = observation.landmarks?.leftEye
                        self.convertPointsForFace(leftEye, faceBoundingBox, "leftEye")
                        
                        let rightEye = observation.landmarks?.rightEye
                        self.convertPointsForFace(rightEye, faceBoundingBox, "rightEye")
                        
                        let nose = observation.landmarks?.nose
                        self.convertPointsForFace(nose, faceBoundingBox, "nose")
                        
                        let lips = observation.landmarks?.innerLips
                        self.convertPointsForFace(lips, faceBoundingBox, "lips")
                        
                        let leftEyebrow = observation.landmarks?.leftEyebrow
                        self.convertPointsForFace(leftEyebrow, faceBoundingBox, "leftEyebrow")
                        
                        let rightEyebrow = observation.landmarks?.rightEyebrow
                        self.convertPointsForFace(rightEyebrow, faceBoundingBox, "rightEyebrow")
                        
                        let noseCrest = observation.landmarks?.noseCrest
                        self.convertPointsForFace(noseCrest, faceBoundingBox, "noseCrest")
                        
                        let outerLips = observation.landmarks?.outerLips
                        self.convertPointsForFace(outerLips, faceBoundingBox, "outerLips")
                        
                        //csv 파일 생성
                        do {
                            self.calculateEmotion(emotionText: self.csvText!)
                            //try self.csvText!.write(to: self.csvPath!, atomically: true, encoding: String.Encoding.utf8)
                            print("Success Create")
                        } catch {
                            print("fail To create CSV File")
                            print("\(error)")
                        }
                   }
                }
            }
        }
    }
    
    func convertPointsForFace(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect, _ thisType:String) {
        var csvLine = thisType
        
        if let points = landmark?.normalizedPoints, let _ = landmark?.pointCount {
            let faceLandmarkPoints = points.map { (point: CGPoint) -> (x: CGFloat, y: CGFloat) in
                //size.height - (self.origin.y * size.height + self.size.height * size.height)
                // 바운딩 박스 설정
                /*
                 let faceRect = CGRect(
                 x: bbox.origin.x * floatWidth,
                 y: floatHeight - (bbox.origin.y * floatHeight + bbox.height * floatHeight),
                 width: bbox.width * floatWidth,
                 height: bbox.height * floatHeight)
                 */
                
                let pointX = point.x * boundingBox.width + boundingBox.origin.x
                let pointY = boundingBox.origin.y + boundingBox.height - (point.y * boundingBox.height)
                csvLine.append(", \(pointX) * \(pointY)")
                return (x: pointX, y: pointY)
            }
            self.csvText?.append(csvLine + "\n")

            DispatchQueue.main.async {
                self.draw(points: faceLandmarkPoints)
            }
        }
    }
    
    func calculateEmotion(emotionText : String) {
        let df = emotionText.components(separatedBy: "\n")
        var tempArray:[Double] = []
        
        let leftEye = shape(start: String(String(df[1]).split(separator: ",")[1]), end: String(String(df[1]).split(separator: ",")[5]), middleTop: String(String(df[1]).split(separator: ",")[7]), middleBottom: String(String(df[1]).split(separator: ",")[3]))
        let rightEye = shape(start: String(String(df[2]).split(separator: ",")[1]), end: String(String(df[2]).split(separator: ",")[5]), middleTop: String(String(df[2]).split(separator: ",")[7]), middleBottom: String(String(df[2]).split(separator: ",")[3]))
        let outerLip = shape(start: String(String(df[8]).split(separator: ",")[1]), end: String(String(df[8]).split(separator: ",")[6]), middleTop: String(String(df[8]).split(separator: ",")[8]), middleBottom: String(String(df[8]).split(separator: ",")[3]))
        let leftEyeBrow = eyebrowShape(middle: String(String(df[5]).split(separator: ",")[2]), end: String(String(df[5]).split(separator: ",")[4]))
        let rightEyeBrow = eyebrowShape(middle: String(String(df[6]).split(separator: ",")[2]), end: String(String(df[6]).split(separator: ",")[4]))
        
        tempArray.append(leftEye)
        tempArray.append(rightEye)
        tempArray.append(outerLip)
        tempArray.append(leftEyeBrow)
        tempArray.append(rightEyeBrow)
        
        let myMLArray = try? MLMultiArray.init(shape: [5], dataType: MLMultiArrayDataType.float32)
        for i in 0...tempArray.count-1 {
            myMLArray?[i] = NSNumber(value: tempArray[i])
        }
        
        guard let myModelOutput = try? myModel.prediction(input1: myMLArray!) else {
            fatalError("Unexpected runtime error.")
        }
        
        print(myModelOutput.output1)

    }
    
    func shape(start: String, end: String, middleTop : String, middleBottom:String) -> Double {
        let startY:Double! = Double(start.trimmingCharacters(in: .whitespaces).components(separatedBy: " * ")[1])
        let endY:Double! = Double(end.trimmingCharacters(in: .whitespaces).components(separatedBy: " * ")[1])
        let bothEndY =  ( startY / endY ) / 2
        let middleBottomY:Double! = Double(middleBottom.trimmingCharacters(in: .whitespaces).components(separatedBy: " * ")[1])
        let middleTopY:Double! = Double(middleTop.trimmingCharacters(in: .whitespaces).components(separatedBy: " * ")[1])
        return abs(bothEndY - middleBottomY)/abs(middleTopY - middleBottomY)
    }
    
    func eyebrowShape(middle:String, end: String) -> Double{
        let middleX:Double! = Double(middle.trimmingCharacters(in: .whitespaces).components(separatedBy: " * ")[0])
        let middleY:Double! = Double(middle.trimmingCharacters(in: .whitespaces).components(separatedBy: " * ")[1])
        let endX:Double! = Double(end.trimmingCharacters(in: .whitespaces).components(separatedBy: " * ")[0])
        let endY:Double! = Double(end.trimmingCharacters(in: .whitespaces).components(separatedBy: " * ")[1])
        return (middleY-endY)/(middleX-endX)
    }
    
    func draw(points: [(x: CGFloat, y: CGFloat)]) {
        let newLayer = CAShapeLayer()
        newLayer.strokeColor = NSColor.red.cgColor
        newLayer.lineWidth = 2
        newLayer.frame = self.faceView.bounds
        newLayer.fillRule = CAShapeLayerFillRule.evenOdd

        let path = CGMutablePath()
        //path.move(to: CGPoint(x: points[0].x, y: points[0].y))
        for i in 0..<points.count - 1 {
            //let point = CGPoint(x: points[i].x, y: points[i].y)
            let rect = CGRect(x: points[i].x, y: points[i].y, width: 0.3, height: 0.3)
            path.addEllipse(in: rect)
            //path.move(to: point)
        }
        //path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
        newLayer.path = path
        shapeLayer.addSublayer(newLayer)
    }
    
    
    func convert(_ points: UnsafePointer<vector_float2>, with count: Int) -> [(x: CGFloat, y: CGFloat)] {
        var convertedPoints = [(x: CGFloat, y: CGFloat)]()
        for i in 0...count {
            convertedPoints.append((CGFloat(points[i].x), CGFloat(points[i].y)))
        }
        
        return convertedPoints
    }

}

extension PlayViewController: NSTableViewDataSource, NSTableViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
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

