//
//  AMFNode.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 6/21/23.
//

import Foundation

import RealityKit
import CoreGraphics

class Detail : Identifiable
{
    let type: String
    var value: String
    
    
    init(type: String, value: String) {
        self.type = type
        self.value = value
    }
    
}

class AttributeDetail : Detail
{
    let attributeNode: ModelAttributeWrapper
    
    init(attributeNode: ModelAttributeWrapper) {
        self.attributeNode = attributeNode
        super.init(type: attributeNode.identifier,
                   value: attributeNode.value)
    }
    
    override var value: String
    {
        get {
            return super.value
        }
        
        set {
            super.value = newValue
            attributeNode.value = newValue
        }
    }
    
}

class MetadataDetail : Detail
{
    let metadataNode: ModelMetadataWrapper
    
    init(metadataNode: ModelMetadataWrapper) {
        self.metadataNode = metadataNode
        super.init(type: metadataNode.type,
                   value: metadataNode.value)
    }
    
    override var value: String
    {
        get {
            return super.value
        }
        
        set {
            super.value = newValue
            metadataNode.value = newValue
        }
    }
}

class AMFNode: Identifiable {
    let elementNode : ModelElementWrapper?
        
    init()
    {
        self.elementNode = nil
        self.parent = nil
    }
    
    init(elementNode: ModelElementWrapper,
         parent: AMFNode?) {
        
        self.elementNode = elementNode
        self.parent = parent
        
        // We can't build the mesh resource here, because init will be called
        //  on a background thread, while MeshResource.generate methods must
        //  be called on the main thread.
        
        // This is called on a background thread, but MeshResource.generate methods must
        //  be called on the main thread.
        
        // self.meshResource = MeshResource.generateSphere(radius: 1.0)

        if parent != nil
        {
            parent!.addChild(self)
        }
        
        var details: [Detail] = []
        
        for attributeNode in elementNode.attributeNodes
        {
            let detail = AttributeDetail(attributeNode: attributeNode)
            details.append(detail)
        }
        
        for metadataNode in elementNode.metadataNodes
        {
            let detail = MetadataDetail(metadataNode: metadataNode)
            details.append(detail)
        }
        
        self.details = details
        
    }
    
    var name: String {
        if elementNode == nil
        {
            return "[none]"
        }
        
        return elementNode!.identifier
    }
    
    weak var parent: AMFNode?
    
    var children: [AMFNode]?
    
    var details: [Detail] =  []
    
    var isExpanded: Bool = false
    
    var description: String
    {
        let localName = NSLocalizedString(name.capitalized, tableName: "OutlineView", comment: "");
        
        let icon = (children == nil ?
                    "📄" : children!.isEmpty ?
                    "📁" : "📂")
        
        return String(format: "%@ %@", icon, localName)
    }
    
    func forEachNodeDo(_ doThis: (AMFNode) -> Void)
    {
        doThis(self)
        
        if (children != nil)
        {
            for child in children!
            {
                child.forEachNodeDo(doThis)
            }
        }
    }
    
    private func addChild(_ child: AMFNode)
    {
        if children == nil
        {
            children = []
        }
        self.children!.append(child)
    }
    
    @MainActor lazy var meshResource: MeshResource? =
    {
        guard let elementNode = self.elementNode else { return nil }
        
        let sceneVertexCount = elementNode.sceneVertexCount
        
        guard sceneVertexCount > 0 else { return nil }
        guard let sceneVertexCoordinates = elementNode.sceneVertexCoordinates else { return nil }
        
        guard let sceneVertexNormals = elementNode.sceneVertexNormals else { return nil }
        
        guard let sceneVertexColors = elementNode.sceneVertexColors else { return nil }
        
        let sceneTriangleVertexCount = elementNode.sceneTriangleVertexCount
        
        guard sceneTriangleVertexCount > 0 else { return nil }
        guard let sceneTriangleVertexIndices = elementNode.sceneTriangleVertexIndices else { return nil }
        
        let unsafeCoordinates =
        UnsafeBufferPointer<simd_float3>(start: sceneVertexCoordinates,
                                         count: Int(sceneVertexCount))
        
        let unsafeNormals =
        UnsafeBufferPointer<simd_float3>(start: sceneVertexNormals,
                                         count: Int(sceneVertexCount))

        let unsafeVertexColors =
        UnsafeBufferPointer<simd_packed_char4>(start: sceneVertexColors,
                                               count: Int(sceneVertexCount))
        
        // Build a color map from the vertex colors.
        
        let unsafeTriangleVertexIndices =
        UnsafeBufferPointer<UInt32>(start: sceneTriangleVertexIndices,
                                    count: Int(sceneTriangleVertexCount))
        
        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffers.Positions(unsafeCoordinates)
        descriptor.normals = MeshBuffers.Normals(unsafeNormals)
        
        // The texture (color) coordinate indices are applied to the mesh, while
        //  the color map itself is applied to the material.
        
        // #warning("Finish this")
        
        var textureCoordinates: [simd_float2] = []
        
        for i in stride(from: 0, to: sceneTriangleVertexCount, by: 3)
        {
            // Each value in sceneTriangleVertexIndices gives an index
            // into sceneVertexColors, which should be used to get the vertex color.
            
            for vertexIndex in 0..2
            unsafeTriangleVertexIndices
            
            
            let colors = TriColor(colors: [sceneVertexColors[Int(i)],
                                           sceneVertexColors[Int(i+1)],
                                           sceneVertexColors[Int(i+2)]])
            
            for vertexIndex in 0...2
            {
                let vertexColor = unsafeVertexColors[Int(i) + vertexIndex]
                
                let coordinate = toPixel(triColor: colors,
                                         vertexColor: vertexColor)
                
                textureCoordinates.append(simd_float2(Float(coordinate.0),
                                                      Float(coordinate.1)))
            }
        }
        
        print(sceneTriangleVertexCount, textureCoordinates.count)
        
        for coordinate in textureCoordinates
        {
            print (coordinate.x, ", ", coordinate.y)
        }
        
        //descriptor.textureCoordinates = MeshBuffer(textureCoordinates)
                    
        /* indexOfColor no longer exists.
         * We need to build per-vertex coordinates based on the
         * triangle vertex indices.
         
        var indexOfColor = self.indexOfColor

        var textureCoordinates: [simd_float2] = []

        for color in unsafeVertexColors
        {
            textureCoordinates.append(simd_float2(Float(indexOfColor[color]!), 0.0))
        }

        descriptor.textureCoordinates = MeshBuffer(textureCoordinates)
        */
        
        descriptor.primitives = .triangles(Array(unsafeTriangleVertexIndices))
        
        let meshResource = try! MeshResource.generate(from: [descriptor])
                
        return meshResource
        
        /*
        @available(macOS 12.0, iOS 15.0, *)
        extension MeshBufferContainer {
            
            /// Positions of all the points.
            public var positions: MeshBuffers.Positions
            
            /// Buffer of normals, if any.
            public var normals: MeshBuffers.Normals?
            
            /// Buffer of tangents, if any.
            public var tangents: MeshBuffers.Tangents?
            
            /// Buffer of bitangents, if any.
            public var bitangents: MeshBuffers.Tangents?
            
            /// Buffer of texture coordinates, if any.
            public var textureCoordinates: MeshBuffers.TextureCoordinates?
        }
         */
    }()
        
    @MainActor lazy var colorMap: TextureResource? =
    {
        guard let triColorImage = self.triColorImage
        else { return nil }
        
        guard let result = try? TextureResource.generate(from: triColorImage,
                                                         options: .init(semantic: .color))
        else { return nil }
        
        return result
    }()
    
    private static let rgbColorSpace = CGColorSpaceCreateDeviceRGB()

    /*
    private lazy var colorImage: CGImage? =
    {
        let width: Int = self.colorOfIndex.count
        let height: Int = 1
        let bitsPerComponent: Int = 8
        let bitsPerPixel: Int = 32
        let bytesPerPixel: Int = MemoryLayout<simd_packed_char4>.size
        let bytesPerRow: Int = width * bytesPerPixel
        let bitmapInfo = (CGImageAlphaInfo.last.rawValue |              // non-premultiplied RGBA
                          CGImageByteOrderInfo.orderDefault.rawValue |  // shouldn't matter for 8 bit data.
                          CGImagePixelFormatInfo.packed.rawValue)

        guard let provider = CGDataProvider(data: NSData(bytes: &self.colorOfIndex,
                                                         length: bytesPerRow))
            else { return nil }

        guard let result = CGImage(width: width,
                                   height: height,
                                   bitsPerComponent: bitsPerComponent,
                                   bitsPerPixel: bitsPerPixel,
                                   bytesPerRow: bytesPerRow,
                                   space: AMFNode.rgbColorSpace,
                                   bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                                   provider: provider,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: CGColorRenderingIntent.defaultIntent)
            else { return nil }
        
        return result
    }()
     */
    
    // Triangle colors are implemented using a texture map,
    //  which uses 3 pixels for each uniquely colored triangle.
    //
    // The texture map is arranged as a n wide by 2 high CGImage
    //  with the following layout
    //  a0 a1 b2 ...
    //  a2 b1 b0 ...
    //  where a and b represent the first 2 triangles.

    private lazy var triColorPixels : [simd_packed_char4] =
    {
        let width = Int((Double(self.triColorMap.count * 3) / 2.0).rounded(.up))
        let height: Int = 2
        
        var result: [simd_packed_char4] = Array(repeating: simd_packed_char4(repeating: 0),
                                                count: width * height)

        for mapping in triColorMap
        {
            let triColor: TriColor = mapping.key
            let cellIndex: Int = mapping.value
            
            for vertexIndex in 0...2
            {
                let coordinate = toPixel(cellIndex: cellIndex,
                                         vertexIndex: vertexIndex)
                result[coordinate.0 + coordinate.1 * width] = triColor.colors[vertexIndex]
            }
        }
        
        return result
    }()
            
    private lazy var triColorImage : CGImage? =
    {
        let width = Int((Double(self.triColorMap.count * 3) / 2.0).rounded(.up))
        let height: Int = 2
        let bitsPerComponent: Int = 8
        let bitsPerPixel: Int = 32
        let bytesPerPixel: Int = MemoryLayout<simd_packed_char4>.size
        let bytesPerRow: Int = width * bytesPerPixel
        let bitmapInfo = (CGImageAlphaInfo.last.rawValue |              // non-premultiplied RGBA
                          CGImageByteOrderInfo.orderDefault.rawValue |  // shouldn't matter for 8 bit data.
                          CGImagePixelFormatInfo.packed.rawValue)
        
        // Assemble the CGImage.
        
        guard let provider = CGDataProvider(data: NSData(bytesNoCopy: &self.triColorPixels,
                                                       length: height * bytesPerRow,
                                                       freeWhenDone: false))
        else { return nil }
        
        guard let result = CGImage(width: width,
                                   height: height,
                                   bitsPerComponent: bitsPerComponent,
                                   bitsPerPixel: bitsPerPixel,
                                   bytesPerRow: bytesPerRow,
                                   space: AMFNode.rgbColorSpace,
                                   bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                                   provider: provider,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: CGColorRenderingIntent.defaultIntent)
        else { return nil }
        
        return result
    }()
    
    private static let __vertexPositions = [[0, 0], [1, 0], [0, 1]]

    // Given a cell index and a vertex index, compute pixel
    //  coordinates within the texture.
    
    func toPixel(cellIndex: Int, vertexIndex: Int) -> (Int, Int)
    {
        let cellX = Int((Double(cellIndex) * 1.5).rounded(.up))
        
        if cellIndex % 2 == 0
        {
            return (cellX + AMFNode.__vertexPositions[vertexIndex][0],
                    AMFNode.__vertexPositions[vertexIndex][1])
        }
        else
        {
            return (cellX - AMFNode.__vertexPositions[vertexIndex][0],
                    1 - AMFNode.__vertexPositions[vertexIndex][1])
        }
    }
    
    // Given a triColor and a vertex color, compute pixel
    //  coordinates within the texture.
    
    func toPixel(triColor: TriColor, vertexColor: simd_packed_char4) -> (Int, Int)
    {
        let cellIndex = triColorMap[triColor]
        assert(cellIndex != nil)
        
        let vertexIndex = triColor.indexOf(color: vertexColor)
        
        return toPixel(cellIndex: cellIndex!,
                       vertexIndex: vertexIndex)
    }

    // Dictionary for mapping TriColors.
    //  Given the vertex colors for a triangle, determine
    //  their texture index.
    
    private lazy var triColorMap : [TriColor : Int] =
    {
        var result : [TriColor : Int] = [:]
        
        guard let elementNode = self.elementNode
        else { return result }
        
        let sceneVertexCount = elementNode.sceneVertexCount
        
        guard sceneVertexCount > 0
        else { return result }

        guard let sceneVertexColors = elementNode.sceneVertexColors
        else { return result }
        
        let sceneTriangleVertexCount = elementNode.sceneTriangleVertexCount
        
        guard sceneTriangleVertexCount > 0
        else { return result }
        
        guard let sceneTriangleVertexIndices = elementNode.sceneTriangleVertexIndices
        else { return result }
        
        let unsafeVertexColors =
        UnsafeBufferPointer<simd_packed_char4>(start: sceneVertexColors,
                                               count: Int(sceneVertexCount))

        let unsafeTriangleVertexIndices =
        UnsafeBufferPointer<UInt32>(start: sceneTriangleVertexIndices,
                                    count: Int(sceneTriangleVertexCount))

        for i in stride(from: 0, to: sceneTriangleVertexCount, by: 3)
        {
            let colors = TriColor(colors: [sceneVertexColors[Int(i)],
                                            sceneVertexColors[Int(i+1)],
                                            sceneVertexColors[Int(i+2)]])
            if result.index(forKey: colors) == nil
            {
                result[colors] = result.count
            }
        }

        return result
    }()
    
    

    // Dictionary for mapping colors: Given a color, determine its index.
    
    /*
    private lazy var indexOfColor: [simd_packed_char4 : Int] =
    {
        // Index the vertex color array.

        var result: [simd_packed_char4 : Int] = [:]
        
        guard let elementNode = self.elementNode
            else { return result }

        let sceneVertexCount = elementNode.sceneVertexCount
        
        guard sceneVertexCount > 0
            else { return result }

        guard let sceneVertexColors = elementNode.sceneVertexColors
            else { return result }

        let unsafeVertexColors =
        UnsafeBufferPointer<simd_packed_char4>(start: sceneVertexColors,
                                               count: Int(sceneVertexCount))
        
        var index: Int = 0
        for color in unsafeVertexColors
        {
            if result.index(forKey: color) == nil
            {
                result[color] = index
                index += 1
            }
        }

        return result
    }()
    
    // Array for mapping colors: Given an index, determine its color.
    
    private lazy var colorOfIndex: [simd_packed_char4] =
    {
        var result: [simd_packed_char4] = Array(repeating: simd_packed_char4(repeating: 0),
                                                count: self.indexOfColor.count)
        
        for item in self.indexOfColor
        {
            result[item.value] = item.key
        }
        
        return result
    }()
     */
}
