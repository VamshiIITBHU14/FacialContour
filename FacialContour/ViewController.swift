//
//  ViewController.swift
//  FacialContour
//
//  Created by Vamshi Krishna on 18/12/17.
//  Copyright © 2017 Vamshi Krishna. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController {

    @IBOutlet var resultLabel: UILabel!
    @IBOutlet weak var buttonOriginalImage: UIButton!
   
    
    var selectedImage : UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func pressedChoosePhoto(_ sender: Any) {
        self.chooseImage()
    }
    func myResultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            fatalError("could not get results from ML Vision request")
        }
        
        if let entry = results.first {
            self.resultLabel.text = "\(entry.identifier):\(entry.confidence)"
        } else {
            self.resultLabel.text = "no results."
        }
    }
    
    func processImage(image: UIImage) {
        //self.performRequestForFaceRectangle(image: image)
        self.performRequestForFaceLandmarks(image: image)
    }
    
    func performRequestForFaceRectangle(image: UIImage) {
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        self.resultLabel.text = "processing image..."
        do {
            selectedImage = image
            let request = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaceDetection)
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func performRequestForFaceLandmarks(image: UIImage) {
        selectedImage = image
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        self.resultLabel.text = "processing image..."
        do {
            let request = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceLandmarksDetection)
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func handleFaceLandmarksDetection(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("could not get results from request")
        }
        
        self.resultLabel.text = "found \(observations.count) faces"
        
        for vw in self.buttonOriginalImage.subviews where vw.tag == 10 {
            vw.removeFromSuperview()
        }
        
        var landmarkRegions : [VNFaceLandmarkRegion2D] = []
        for faceObservation in observations {
            //self.addFaceContour(forObservation: faceObservation, toView: self.buttonOriginalImage )
            
            landmarkRegions = self.addFaceFeatures(forObservation: faceObservation, toView: self.buttonOriginalImage )
            selectedImage = self.drawOnImage(source: selectedImage, boundingRect: faceObservation.boundingBox, faceLandmarkRegions: landmarkRegions )
        }
        self.buttonOriginalImage.setBackgroundImage(selectedImage, for: .normal)
        
        // we have all the landmark regions for all the faces in the image
        
        //drawOnImage( image , landmarks)
    }
    func drawOnImage(source: UIImage,
                     boundingRect: CGRect,
                     faceLandmarkRegions: [VNFaceLandmarkRegion2D]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.colorBurn)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let rectWidth = source.size.width * boundingRect.size.width
        let rectHeight = source.size.height * boundingRect.size.height
        
        //draw original image
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)
        
        //draw bound rect
        var fillColor = UIColor.blue
        fillColor.setFill()
        context.addRect(CGRect(x: boundingRect.origin.x * source.size.width, y:boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight))
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        //draw overlay
        fillColor = UIColor.blue
        fillColor.setStroke()
        context.setLineWidth(8.0)
        for faceLandmarkRegion in faceLandmarkRegions {
            var points: [CGPoint] = []
            for i in 0..<faceLandmarkRegion.pointCount {
                let point = faceLandmarkRegion.normalizedPoints[i]
                let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                points.append(p)
            }
            let mappedPoints = points.map { CGPoint(x: boundingRect.origin.x * source.size.width + $0.x * rectWidth, y: boundingRect.origin.y * source.size.height + $0.y * rectHeight) }
            context.addLines(between: mappedPoints)
            context.drawPath(using: CGPathDrawingMode.stroke)
        }
        
        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return coloredImg
    }
    
    
    func addFaceContour(forObservation face: VNFaceObservation, toView view :UIView) {
        let box1 = face.boundingBox // !!! the values are from 0 to 1 (unscaled)
        let box2 = view.bounds
        
        let w = box1.size.width * box2.width
        let h = box1.size.height * box2.height
        
        let x = box1.origin.x * box2.width
        let y =  abs((box1.origin.y * box2.height) - box2.height) - h
        
        let subview = UIView(frame: CGRect(x: x, y: y, width: w, height: h))
        subview.layer.borderColor = UIColor.green.cgColor
        subview.layer.borderWidth = 3.0
        subview.layer.cornerRadius = 5.0
        subview.tag = 10
        view.addSubview(subview)
    }
    
    func addFaceFeatures(forObservation face: VNFaceObservation, toView view :UIView) -> [VNFaceLandmarkRegion2D] {
        
        // get all the regions to draw to the images (eyes, lips, nose, etc...)
        // we draw these areas onto the image
        
        guard let landmarks = face.landmarks else {
            return []
        }
        
        var landmarkRegions: [VNFaceLandmarkRegion2D] = []
        
        if let faceContour = landmarks.faceContour {
            landmarkRegions.append(faceContour)
        }
        
        if let leftEye = landmarks.leftEye {
            landmarkRegions.append(leftEye)
        }
        if let rightEye = landmarks.rightEye {
            landmarkRegions.append(rightEye)
        }
        if let nose = landmarks.nose {
            landmarkRegions.append(nose)
        }
        if let noseCrest = landmarks.noseCrest {
            landmarkRegions.append(noseCrest)
        }
        if let medianLine = landmarks.medianLine {
            landmarkRegions.append(medianLine)
        }
        if let outerLips = landmarks.outerLips {
            landmarkRegions.append(outerLips)
        }
        if let leftEyebrow = landmarks.leftEyebrow {
            landmarkRegions.append(leftEyebrow)
        }
        if let rightEyebrow = landmarks.rightEyebrow {
            landmarkRegions.append(rightEyebrow)
        }
        
        if let innerLips = landmarks.innerLips {
            landmarkRegions.append(innerLips)
        }
        if let leftPupil = landmarks.leftPupil {
            landmarkRegions.append(leftPupil)
        }
        if let rightPupil = landmarks.rightPupil {
            landmarkRegions.append(rightPupil)
        }
        
        // we need to draw on the image (all the features)
        return landmarkRegions
    }
    func handleFaceDetection(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("unexpected results from VNDetectFaceRectanglesRequest")
        }
        self.resultLabel.text = "found \(observations.count) faces"
    }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let uiImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("no image selected")
        }
        self.buttonOriginalImage.setBackgroundImage(uiImage, for: .normal)
        self.processImage(image: uiImage)
    }
}
