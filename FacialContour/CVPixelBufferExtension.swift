//
//  CVPixelBufferExtension.swift
//  FacialContour
//
//  Created by Vamshi Krishna on 18/12/17.
//  Copyright © 2017 Vamshi Krishna. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        
        var pixelBuffer : CVPixelBuffer?
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32ARGB, attributes as CFDictionary, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let imageBuffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let imageData =  CVPixelBufferGetBaseAddress(imageBuffer)
        
        guard let context = CGContext(data: imageData, width: Int(width), height:Int(height),
                                      bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                                        return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x:0, y:0, width: width, height: height) )
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return imageBuffer
        
    }
    
}
