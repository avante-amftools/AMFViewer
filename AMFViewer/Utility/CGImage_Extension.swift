//
//  CGImage_Extension.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 6/28/23.
//

import Foundation
import CoreGraphics

extension CGImage
{
    static let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    
    public func imageFromData(data: NSData,
                              width: Int,
                              height: Int) -> CGImage
    {
        let bitsPerComponent: Int = 8
        let bitsPerPixel: Int = 32
        let bytesPerPixel: Int = MemoryLayout<simd_packed_char4>.size
        let bytesPerRow: Int = width * bytesPerPixel
        let bitmapInfo = (CGImageAlphaInfo.last.rawValue |              // non-premultiplied RGBA
                          CGImageByteOrderInfo.orderDefault.rawValue |  // shouldn't matter for 8 bit data.
                          CGImagePixelFormatInfo.packed.rawValue)
        
        assert(data.length == bytesPerRow * height)
        
        guard let provider = CGDataProvider(data: data)
            else { fatalError("CGImage.imageFromData failed [1]") }
        
        guard let result = CGImage(width: width,
                                   height: height,
                                   bitsPerComponent: bitsPerComponent,
                                   bitsPerPixel: bitsPerPixel,
                                   bytesPerRow: bytesPerRow,
                                   space: CGImage.rgbColorSpace,
                                   bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                                   provider: provider,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: CGColorRenderingIntent.defaultIntent)
            else { fatalError("CGImage.imageFromData failed [2]") }
        
        return result
    }    
}
