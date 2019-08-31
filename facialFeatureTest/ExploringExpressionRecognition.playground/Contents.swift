//: Playground - noun: a place where people can play

import UIKit
import Vision
import CoreML
import PlaygroundSupport

// Required to run tasks in the background
PlaygroundPage.current.needsIndefiniteExecution = true


guard let currentImage = UIImage(named:"images/6.PNG") // 이미지 불러오기
    else{ fatalError("Failed to extract features") }

let faceDetectionRequest = VNDetectFaceRectanglesRequest() // 얼굴 인식 요청을 하는 Request
let faceDetectionRequestHandler = VNSequenceRequestHandler() // 얼굴 인식 요청을 처리 하는 handler


try? faceDetectionRequestHandler.perform(
    [faceDetectionRequest], // 핸들러는 faceDetectionRequest의 요청들을 처리한다
    on: currentImage.cgImage!,// 우리가 처리하고 싶은 이미지
    orientation: CGImagePropertyOrientation(currentImage.imageOrientation))

if let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation]{ // 핸들러가 처리한 결과를 얻음
    for face in faceDetectionResults{ // 결과들
            let bbox = face.boundingBox // 결과의 바운딩 박스
        
            // 바운딩 박스 설정
            let faceRect = CGRect(
                x: bbox.origin.x * currentImage.size.width,
                y: currentImage.size.height - (bbox.origin.y * currentImage.size.height + bbox.height * currentImage.size.height),
                width: bbox.width * currentImage.size.width,
                height: bbox.height * currentImage.size.height)
            
            // 이미지 자르기
            if let  cgImage = currentImage.cgImage{
                if let imageRef = cgImage.cropping(to: faceRect){
                    let cropImage = UIImage(cgImage: imageRef, scale: currentImage.scale, orientation: currentImage.imageOrientation)
                }
            }
    }
}


