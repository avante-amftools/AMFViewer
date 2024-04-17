//
//  TriColor.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/27/23.
//
//  Because RealityKit doesn't support per-triangle or per-vertex colors, we
//  have to use a texture map to emulate those concepts.
//
//  This module creates the texture map, and provides U, V coordinates within
//  the map for vertices in the mesh.

import Foundation

import RealityKit
import CoreGraphics

struct TriColor : Comparable, Hashable
{
    let colors : [simd_packed_uchar4]
    
    init(colors: [simd_packed_uchar4])
    {
        assert(colors.count == 3)
        
        self.colors = colors
    }
    
    func indexOf(color: simd_packed_uchar4) -> Int
    {
        // This code assumes that the color you're looking
        //  for is actually in the array.
        
        assert(colors.contains(color))

        for result in 0...2
        {
            if colors[result] == color
            {
                return result
            }
        }
        
        return 0
    }
    
    static func < (lhs: TriColor, rhs: TriColor) -> Bool {
        assert(lhs.colors.count == rhs.colors.count)
        for i in 0..<lhs.colors.count
        {
            if lhs.colors[i] < rhs.colors[i]
            {
                return true
            }
        }
        return false
    }
    
    static func == (lhs: TriColor,
                    rhs: TriColor) -> Bool
    {
        return (lhs.colors[0] == rhs.colors[0] &&
                lhs.colors[1] == rhs.colors[1] &&
                lhs.colors[2] == rhs.colors[2])
    }
    
    func hash(into hasher: inout Hasher)
    {
        for color in self.colors
        {
            hasher.combine(color)
        }
    }
}

class TriColorMap
{
    var colorMap : [TriColor : Int] = [:]
    
    func addTriColor(triColor: TriColor)
    {
        if colorMap.index(forKey: triColor) == nil
        {
            colorMap[triColor] = colorMap.count
        }
    }

    @MainActor lazy var textureResource: TextureResource =
    {
        return try! TextureResource.generate(from: self.textureImage,
                                             options: .init(semantic: .color))
    }()
    
    func coordinateOf(triColorIndex: Int,
                      cornerIndex: Int) -> simd_float2
    {
        let size = simd_float2(x: Float(self.colorMap.count * 2),
                               y: 2)
        var result = textureCoordinates[cornerIndex]
        result.x += Float(triColorIndex * 2)
        result /= size
        
        return result
    }
    
    func coordinateOf(triColor: TriColor,
                      cornerIndex: Int) -> simd_float2
    {
        let triColorIndex = colorMap[triColor]!
        
        let result = self.coordinateOf(triColorIndex: triColorIndex,
                                       cornerIndex: cornerIndex)
        
        let color = self.colorAt(coordinate: result)

        assert(triColor.colors[cornerIndex] == color)
        
        #if false
        print(color)
        #endif
        
        return result
    }
    
    func coordinateOf(triColor: TriColor,
                      cornerColor: simd_packed_uchar4) -> simd_float2
    {
        return self.coordinateOf(triColorIndex: colorMap[triColor]!,
                                 cornerIndex: triColor.indexOf(color: cornerColor))
    }
    
    func colorAt(coordinate: simd_float2) -> simd_packed_uchar4
    {
        let width = self.colorMap.count * 2
        
        let x = Int(coordinate.x * Float(width))
        let y = Int((1 - coordinate.y) * 2)
                
        return texturePixels[x+(y*width)]
    }
    
    private lazy var textureImage: CGImage =
    {
        let width = self.colorMap.count * 2
        let height = 2
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        let bytesPerPixel = MemoryLayout<simd_packed_char4>.size
        let bytesPerRow = width * bytesPerPixel
        let bitmapInfo = (CGImageAlphaInfo.last.rawValue |              // non-premultiplied RGBA
                          CGImageByteOrderInfo.orderDefault.rawValue |  // shouldn't matter for 8 bit data.
                          CGImagePixelFormatInfo.packed.rawValue)
        
        let provider = CGDataProvider(data: NSData(bytesNoCopy: &self.texturePixels,
                                                   length: height * bytesPerRow,
                                                   freeWhenDone: false))!
        
        let result = CGImage(width: width,
                             height: height,
                             bitsPerComponent: bitsPerComponent,
                             bitsPerPixel: bitsPerPixel,
                             bytesPerRow: bytesPerRow,
                             space: CGColorSpaceCreateDeviceRGB(),
                             bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                             provider: provider,
                             decode: nil,
                             shouldInterpolate: false,
                             intent: CGColorRenderingIntent.defaultIntent)!
        
        #if false
        print ("image width: ", width)
        print ("image height: ", height)
        
        print ("image data: ", self.texturePixels)
        #endif
        
        return result
    }()
    
    private lazy var texturePixels : [simd_packed_uchar4] =
    {
        // Create a 2x2 grouping of pixels for each TriColor in
        //  colorMap.
        
        let width = self.colorMap.count * 2
        let height = 2
        
        var result: [simd_packed_uchar4] = Array(repeating: simd_packed_uchar4(repeating: 0),
                                                 count: width * height)
        
        for mapping in self.colorMap
        {
            let triColor = mapping.key
            let cellIndex = mapping.value * 2
            
            result[cellIndex] = triColor.colors[0]
            result[cellIndex + 1] = triColor.colors[1]
            result[cellIndex + width] = triColor.colors[2]
            result[cellIndex + width + 1] = triColor.colors[2]
        }
        
        return result
    }()
    
    private func toEightBitColor(_ value: simd_double4) -> simd_packed_uchar4
    {
        return simd_packed_uchar4(x: UInt8(value.x * 255.0),
                                  y: UInt8(value.y * 255.0),
                                  z: UInt8(value.z * 255.0),
                                  w: UInt8(value.w * 255.0))
    }
    
    private lazy var textureCoordinates: [simd_float2] =
    {
        let s = Float(1.0 / 1.5)
        
        let x60 = sin(Float.pi / 3.0) * s
        let y60 = cos(Float.pi / 3.0) * s
        let x180 = 0.0 * s
        let y180 = 1.0 * s
                
        let result = [simd_float2(x: (1 - x60),
                                  y: 1 + y60),
                      simd_float2(x: 1 + x60,
                                  y: 1 + y60),
                      simd_float2(x: 1 + x180,
                                  y: 1 - y180)]
        
        #if false
        print("textureCoordinates:")
        
        for coordinate in result
        {
            print(coordinate)
        }
        #endif
        
        return result
    }()
}

