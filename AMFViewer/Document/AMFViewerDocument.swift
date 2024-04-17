//
//  AMFViewerDocument.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 6/21/23.
//

import SwiftUI
import UniformTypeIdentifiers
import RealityKit

extension UTType {
    static var AMF: UTType { UTType(exportedAs: "com.avante-technology.uti.amf") }
    
    // I feel like STL needs to be an imported type.
    
    static var STL: UTType { UTType(importedAs: "public.standard-tesselated-geometry-format") }
}

extension Data {
    // Debugging aid. Allows viewing of a Data object as hex formatted text.
    
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
    
    var floatDescription: String {
        
        var result = String ()
        
        var byteOffset: Int = 0
        
        while byteOffset < self.count
        {
            let asFloat = withUnsafeBytes {
                $0.load(fromByteOffset: byteOffset, as: Float.self)
            }
            
            byteOffset += MemoryLayout<Float>.stride;
            
            result += asFloat.description + ", "
        }
        
        return result
    }
}

class AMFViewerDocument: RealityModel, FileDocument {
    
    // AMFCore wrapper.
    
    var modelRoot: ModelRootWrapper?
    
    // Viewable outline.
    
    lazy var outline = _outline
    
    private var _outline: AMFNode
    {
        var result: AMFNode
        
        if let rootElement = self.modelRoot
        {
            result = AMFNode(elementNode: rootElement,
                             parent: nil)
            
            for object in rootElement.objectNodes
            {
                // Object nodes
                
                let objectNode = AMFNode(elementNode: object,
                                         parent: result)
                
                // Object's mesh node (Always 1 per object)
                
                let amfMesh = object.meshNode
                let meshNode = AMFNode(elementNode: amfMesh,
                                       parent: objectNode)
                
                // Mesh's volume nodes.
                
                for volume in amfMesh.volumeNodes
                {
                    _ = AMFNode(elementNode: volume,
                                parent: meshNode)
                }
            }
            
            // Material nodes
            
            for material in rootElement.materialNodes
            {
                _ = AMFNode(elementNode: material,
                            parent: result)
            }
            
            for constellation in rootElement.constellationNodes
            {
                _ = AMFNode(elementNode: constellation,
                            parent: result)
            }
        }
        else
        {
            result = AMFNode()
        }
        
        return result
    }
        
        
    @Published var selection = Set<AMFNode.ID>()
    {
        didSet
        {
            self.updateViewable()
        }
    }
    
    //@Published var compressed // 818 678 0477
            
    private lazy var nodesByID = _nodesByID
    
    private var _nodesByID: [AMFNode.ID: AMFNode]
    {
        var result: [AMFNode.ID : AMFNode] = [:]
        self.outline.forEachNodeDo({ node in
            result[node.id] = node
        })
        return result
    }
    
    var selectedNodes: [AMFNode]
    {
        var result: [AMFNode] = []
        
        for id in selection
        {
            if let node = self.nodesByID[id]
            {
                result.append(node)
            }
        }
        
        if result.isEmpty
        {
            result = [self.outline]
        }
        
        return result
    }

            
    lazy var realityView: RealityView = {
        // print("Creating RealityView")
        return RealityView(model: self)
    }()
    
    // FileDocument implementation.
        
    static var readableContentTypes: [UTType] { [.AMF, .STL] }

    override init()
    {
        super.init()
    }

    required init(configuration: ReadConfiguration) throws
    {
        super.init()
        
        guard let data = configuration.file.regularFileContents
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        guard let fileType = configuration.contentType.preferredFilenameExtension
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let reader = DocumentReaderWrapper.documentReader(with: data,
                                                          fileType: fileType)
        
        self.modelRoot = reader.fromFile()
        
        self.compressed = self.modelRoot!.compressed;
        
        self.modelRoot!.debugShow()
        
        self.modelRoot!.debugShowDetails()
        
        let outline = self.makeOutline()
        
        // update self.outline
        // update self.nodesByID
        
        self.updateViewable()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
    {
        let fileType = configuration.contentType.preferredFilenameExtension!;
        
        if (configuration.existingFile != nil)
        {
            return configuration.existingFile!
        }
        
        self.modelRoot!.compressed = self.compressed

        let writer = DocumentWriterWrapper.documentWriter(withModelRoot: self.modelRoot!,
                                                          fileType: fileType)

        let data = writer.data
        
        let result = FileWrapper(regularFileWithContents: data)
        result.preferredFilename = "who knows"
        
        return result;
    }
    
    func nodeIsSelected(node: AMFNode) -> Bool
    {
        if self.selection.isEmpty && node.parent == nil
        {
            return true
        }
        
        return self.selection.contains(node.id)
    }
    
    func nodeOrParentIsSelected(node: AMFNode) -> Bool
    {
        var currentNode: AMFNode? = node
        
        while currentNode != nil
        {
            if (self.nodeIsSelected(node: currentNode!))
            {
                return true
            }
            currentNode = currentNode!.parent
        }
        
        return false
    }
    
    private func makeOutline() -> AMFNode?
    {
        var result: AMFNode?
        
        if let rootElement = self.modelRoot
        {
            result = AMFNode(elementNode: rootElement,
                             parent: nil)
            
            for object in rootElement.objectNodes
            {
                // Object nodes
                
                let objectNode = AMFNode(elementNode: object,
                                         parent: result)
                
                // Object's mesh node (Always 1 per object)
                
                let amfMesh = object.meshNode
                let meshNode = AMFNode(elementNode: amfMesh,
                                       parent: objectNode)
                
                // Mesh's volume nodes.
                
                for volume in amfMesh.volumeNodes
                {
                    _ = AMFNode(elementNode: volume,
                                parent: meshNode)
                }
            }
            
            // Material nodes
            
            for material in rootElement.materialNodes
            {
                _ = AMFNode(elementNode: material,
                            parent: result)
            }
            
            for constellation in rootElement.constellationNodes
            {
                _ = AMFNode(elementNode: constellation,
                            parent: result)
            }
        }
        
        return result
    }
    
    func updateViewable()
    {
        DispatchQueue.main.async
        {
            self._updateViewable()
        }
    }

    @MainActor private func _updateViewable()
    {
        if self.outline.children != nil
        {
            let viewable = Entity()
#if true
            outline.forEachNodeDo
            {
                node in
                if let meshResource = node.sceneMesh
                {
                    let alpha = nodeOrParentIsSelected(node: node) ? 1.0 : 0.25
                    
                    let tint = NSColor(red: 1, green: 1, blue: 1, alpha: alpha)
                    
                    var material = SimpleMaterial()
                    if let triColorTexture = node.sceneTexture
                    {
                        material.color = .init(tint: tint, texture: .init(triColorTexture))
                    }
                    else
                    {
                        material.color = .init(tint: tint)
                    }
                    material.roughness = .float(1.0)
                    material.metallic = .float(0.0)
                    
                    let entity = ModelEntity(mesh: meshResource,
                                             materials: [material])
                    
                    viewable.addChild(entity)
                }
            }
#else
            viewable.addChild(self.testViewable)
#endif
            
            self.viewable = viewable
        }
    }
    
    lazy var testViewable: Entity =
    {
        let red = simd_packed_char4(x: -1,
                                    y: 0,
                                    z: 0,
                                    w: -1)

        let green = simd_packed_char4(x: 0,
                                    y: -1,
                                    z: 0,
                                    w: -1)

        let blue = simd_packed_char4(x: 0,
                                    y: 0,
                                    z: -1,
                                    w: -1)
        
        let white = simd_packed_char4(x: -1,
                                      y: -1,
                                      z: -1,
                                      w: -1)

        let black = simd_packed_char4(x: 0,
                                      y: 0,
                                      z: 0,
                                      w: -1)

        // Vertex coordinates
        
        let vertexCoordinates : [simd_float3] = [simd_float3(x:  0.0, y:  0.0, z: 0.0),
                                                 simd_float3(x: 10.0, y:  0.0, z: 0.0),
                                                 simd_float3(x:  0.0, y: 10.0, z: 0.0)]

        let vertexColors: [NSColor] = [.red, .green, .blue]

        // Vertex texture coordinates

        let offset = Float(1.0 / 3.0)
        let textureCoordinates1 : [simd_float2] = [simd_float2(x: 1.0 + offset, y: 1.0 - offset),
                                                  simd_float2(x: 1.0 - offset, y: 1.0 - offset),
                                                  simd_float2(x: 1.0, y: 1.0 + offset)]
        
        print(textureCoordinates1)

        /*
        let s = Float(1.0 / 3.0)
        
        let textureCoordinates = [simd_float2(x: 1 + 0.866025403784439 * s, y: 1 - 0.5 * s),
                                  simd_float2(x: 1 - 0.866025403784439 * s, y: 1 - 0.5 * s),
                                  simd_float2(x: 1 + 0.0 * s, y: 1 + 1.0 * s)]
        */
        
        let s = Float(1.0/3.0)
        
        // Vertical is inverted.
        // Horizontal is not inverted
        
        print(sin(Float.pi / 3))
        print(cos(Float.pi / 3))
        
        print(sin(0.0))
        print(cos(0.0))
        
        let redCoord = simd_float2(x: (0.5 - sin(Float.pi / 3) * s) / 2.0, y: 0.5 + cos(Float.pi / 3) * s)
        let greenCoord = simd_float2(x: (0.5 + sin(Float.pi / 3) * s) / 2.0, y: 0.5 + cos(Float.pi / 3) * s)
        let blueCoord = simd_float2(x: (0.5 - sin(0.0) * s) / 2.0, y: 0.5 - cos(0.0) * s)
        
        let textureCoordinates = [simd_float2(redCoord),
                                  simd_float2(greenCoord),
                                  simd_float2(blueCoord)]

        print(textureCoordinates)

        // Triangle vertex indices
        
        let vertexIndices : [UInt32] = [0, 1, 2]

        // Texture pixels
        
        var texturePixels : [simd_packed_char4] = [red, green, red, green, blue, blue, blue, blue]

        // Texture image
        
        let width = 4
        let height = 2
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        let bytesPerPixel: Int = MemoryLayout<simd_packed_char4>.size
        let bytesPerRow = width * bytesPerPixel
        let bitmapInfo = (CGImageAlphaInfo.last.rawValue |              // non-premultiplied RGBA
                          CGImageByteOrderInfo.orderDefault.rawValue |  // shouldn't matter for 8 bit data.
                          CGImagePixelFormatInfo.packed.rawValue)

        let provider = CGDataProvider(data: NSData(bytes: &texturePixels,
                                                         length: height * bytesPerRow))
        assert(provider != nil)
        
        let textureImage = CGImage(width: width,
                                   height: height,
                                   bitsPerComponent: bitsPerComponent,
                                   bitsPerPixel: bitsPerPixel,
                                   bytesPerRow: bytesPerRow,
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                                   provider: provider!,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: CGColorRenderingIntent.defaultIntent)
        assert(textureImage != nil)
        
        let textureResource = try! TextureResource.generate(from: textureImage!,
                                                       options: .init(semantic: .color,
                                                                      mipmapsMode: .none))
        
        // Texture material
        
        var textureMaterial = SimpleMaterial()
        textureMaterial.color = .init(tint: .white,
                               texture: .init(textureResource))
        textureMaterial.roughness = .float(1.0)
        textureMaterial.metallic = .float(0.0)
        
        // Mesh resource
        
        var descriptor = MeshDescriptor()
        
        descriptor.positions = MeshBuffers.Positions(vertexCoordinates)
        
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(textureCoordinates)
        
        descriptor.primitives = .triangles(vertexIndices)
        
        let meshResource = try! MeshResource.generate(from: [descriptor])
        
        let meshEntity = ModelEntity(mesh: meshResource,
                                     materials: [textureMaterial])
        
        var result = Entity()
        
        result.addChild(meshEntity)
        
        let sphereMesh = MeshResource.generateSphere(radius: 1.0)
        
        for (coordinate, color) in zip(vertexCoordinates, vertexColors)
        {
            let sphereModel = ModelEntity(mesh: sphereMesh, materials: [SimpleMaterial(color: color, isMetallic: false)])
            sphereModel.position = coordinate
            result.addChild(sphereModel)
        }
        
        return result
    }()
    
    
}
