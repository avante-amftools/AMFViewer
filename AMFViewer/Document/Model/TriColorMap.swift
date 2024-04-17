//
//  TriColorMap.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/4/23.
//

import Foundation

import RealityKit
import CoreGraphics

struct TriColor : Comparable, Hashable
{
    let colors : [simd_packed_uchar4]
        
    init(colors: [simd_packed_uchar4])
    {
        assert(colors.count == 3)
        
        self.colors = colors.sorted(by: {
            lhs, rhs in
            return lhs.x < rhs.x ? true :
            lhs.y < rhs.y ? true :
            lhs.z < rhs.z ? true :
            lhs.w < rhs.w
        })
    }
    
    func indexOf(color: simd_packed_uchar4) -> Int
    {
        // This code assumes that the color you're looking
        //  for is actually in the array.
        
        assert(colors.contains(color))
        
        return (color < self.colors[1] ? 0 :
                color == self.colors[1] ? 1 : 2)
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
    // Creates a texture map which will be used to
    //  color a mesh according to its vertex and face colors.
    //
    // Each triangle in the texture map is arranged as a
    //  2x2 group of pixels with the following layout
    //      c[0] c[1]
    //      c[2] c[2]
    //  c[2] is repeated so that the coordinates given for
    //      a triangle's vertex can be arranged as an equilateral triangle
    //      with the center of the triangle at the center of the group
    //      of pixels.
    
    var sceneVertexColors: UnsafeBufferPointer<simd_packed_char4>
    var sceneTriangleTriIndices: UnsafeBufferPointer<TriIndex>
    
    init(_ sceneVertexColors: UnsafeBufferPointer<simd_packed_char4>,
         _ sceneTriangleTriIndices: UnsafeBufferPointer<TriIndex>)
    {
        self.sceneVertexColors = sceneVertexColors
        self.sceneTriangleTriIndices = sceneTriangleTriIndices
    }
    
    // Dictionary for mapping TriColors.
    //  Given the vertex colors for a triangle,
    //  determine their texture index.
    
    private lazy var colorMap : [TriColor : Int] =
    {
        var result : [TriColor : Int] = [:]
                
        for triIndex in sceneTriangleTriIndices
        {
            #if false
            let colors = [sceneVertexColors[Int(triIndex.indices.0)],
                          sceneVertexColors[Int(triIndex.indices.1)],
                          sceneVertexColors[Int(triIndex.indices.2)]]
            #else
            let colors = [simd_packed_char4(x: -1, y: -1, z: -1, w: -1),
                          simd_packed_char4(x: -1, y: -1, z: -1, w: -1),
                          simd_packed_char4(x: -1, y: -1, z: -1, w: -1)]
            #endif
            let triColor = TriColor(colors: colors)
            
            if result.index(forKey: triColor) == nil
            {
                result[triColor] = result.count
            }
            else
            {
                print("key exists")
            }
        }
        
        print("colorMap.count: ", result.count)
        
        return result
    }()
    
    private lazy var size : simd_float2 =
    {
        return simd_float2(x: Float(self.colorMap.count * 2),
                           y: 2)
    }()
        
    private lazy var pixels : [simd_packed_char4] =
    {
        // Create a 2x2 grouping of pixels for each TriColor in
        //  colorMap.
        
        let width = self.colorMap.count * 2
        let height = 2
        
        var result: [simd_packed_char4] = Array(repeating: simd_packed_char4(repeating: 0),
                                                count: width * height)
        
        for mapping in colorMap
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
    
    private lazy var image : CGImage =
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
        
        let provider = CGDataProvider(data: NSData(bytesNoCopy: &self.pixels,
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
        
        print ("image width: ", width)
        print ("image height: ", height)
        
        print ("image data: ", self.pixels)

        return result
    }()
    
    @MainActor lazy var triColorTexture: TextureResource =
    {
        return try! TextureResource.generate(from: self.image,
                                             options: .init(semantic: .color))
    }()
    
    
    private lazy var textureCoordinates1: [simd_float2] =
    {
        let s = Float(1.0 / 3.0)

        return [simd_float2(x: 1 + 0.866025403784439 * s, y: 1 - 0.5 * s),
     simd_float2(x: 1 - 0.866025403784439 * s, y: 1 - 0.5 * s),
     simd_float2(x: 1 + 0.0 * s, y: 1 + 1.0 * s)]
    }()
    
    private lazy var textureCoordinates: [simd_float2] =
    {
        let s = Float(1.0 / 3.0)
        
        let x60 = sin(Float.pi / 3.0) * s
        let y60 = cos(Float.pi / 3.0) * s
        let x180 = 0.0 * s
        let y180 = 1.0 * s
        
        print("x60 = ", x60)
        print("y60 = ", y60)

        print("x180 = ", x180)
        print("y180 = ", y180)

        return [simd_float2(x: (1 - x60),
                            y: 1 + y60),
                simd_float2(x: 1 + x60,
                            y: 1 + y60),
                simd_float2(x: 1 + x180,
                            y: 1 - y180)]
    }()

    func coordinateOf(triColorIndex: Int, vertexIndex: Int) -> simd_float2
    {
        let size = self.size
        var result = textureCoordinates[vertexIndex]
        result.x += Float(triColorIndex * 2)
        result /= size
        
        return result
    }
    
    func coordinateOf(triColor: TriColor,
                      vertexColor: simd_packed_char4) -> simd_float2
    {
        return self.coordinateOf(triColorIndex: colorMap[triColor]!,
                                 vertexIndex: triColor.indexOf(color: vertexColor))
    }
}

