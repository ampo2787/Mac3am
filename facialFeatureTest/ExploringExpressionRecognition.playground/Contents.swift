//: Playground - noun: a place where people can play

import UIKit
import Vision
import CoreML
import PlaygroundSupport

// Required to run tasks in the background
PlaygroundPage.current.needsIndefiniteExecution = true

var images = [UIImage]()
    guard let image = UIImage(named:"images/2019.png") // 이미지 불러오기
        else{ fatalError("Failed to extract features") }
    images.append(image) // images에 추가

let faceIdx = 0
let imageView = UIImageView(image: images[faceIdx]) // images에 있는 첫번째 이미지 UIImageView로 캐스팅
imageView.contentMode = .scaleAspectFit // 이미지의 비율을 유지하며 뷰에 맞춤

let faceDetectionRequest = VNDetectFaceRectanglesRequest() // 얼굴 인식 요청을 하는 Request
let faceDetectionRequestHandler = VNSequenceRequestHandler() // 얼굴 인식 요청을 처리 하는 handler


try? faceDetectionRequestHandler.perform(
    [faceDetectionRequest], // 핸들러는 faceDetectionRequest의 요청들을 처리한다
    on: images[faceIdx].cgImage!,// 우리가 처리하고 싶은 이미지
    orientation: CGImagePropertyOrientation(images[faceIdx].imageOrientation))

if let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation]{ // 핸들러가 처리한 결과를 얻음
    for face in faceDetectionResults{ // 결과들
        if let currentImage = imageView.image{ // 만들었던 imageView의 이미지
            let bbox = face.boundingBox // 결과의 바운딩 박스
            let imageSize = CGSize( // 이미지 사이즈 설정
                width:currentImage.size.width,
                height: currentImage.size.height)
            
            // 바운딩 박스 설정
            let w = bbox.width * imageSize.width
            let h = bbox.height * imageSize.height
            let x = bbox.origin.x * imageSize.width
            let y = bbox.origin.y * imageSize.height
            
            let faceRect = CGRect(
                x: x,
                y: y,
                width: w,
                height: h)
            
            let invertedY = imageSize.height - (faceRect.origin.y + faceRect.height)
            let invertedFaceRect = CGRect(
                x: x,
                y: invertedY,
                width: w,
                height: h)
            
            // 이미지 자르기
            if let  cgImage = currentImage.cgImage{
                let imageRef = cgImage.cropping(to: invertedFaceRect)
                if let imageRef = imageRef{
                    let cropImage = UIImage(cgImage: imageRef, scale: currentImage.scale, orientation: currentImage.imageOrientation)
                    
                }
            }
            
            
        }
    }
}


