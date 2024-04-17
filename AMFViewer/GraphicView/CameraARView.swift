//
//  CameraARView.swift
//  Unreality
//
//  Created by Ron Aldrich on 1/13/24.
//

import SwiftUI
import RealityKit

@objc public class CameraARView : ARView, ObservableObject
{
    // The camera
    let camera = PerspectiveCamera()
        
    var cameraRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
    
    var cameraFocus = SIMD3<Float>.zero
    var cameraOrbit = Float(40)
    
    // Where the drag began, in view coordinates.
    
    var dragStart = SIMD2<Float>.zero
    
    // Where the drag is currently, in view coordinates.
    
    var dragCurrent = SIMD2<Float>.zero
    
    //var rotationStart = simd_quatf(angle: 0,
    //                               axis: SIMD3<Float>(1, 0, 0))
    
    //var rotationCurrent = simd_quatf(angle: 0,
    //                                 axis: SIMD3<Float>(1, 0, 0))
    
    //
    
    
    var worldAnchor: AnchorEntity
    {
        if (self.worldAnchor_ == nil)
        {
            let result = AnchorEntity()
            result.addChild(self.camera)
            self.worldAnchor_ = result
        }
        
        return self.worldAnchor_!
    }
    
    var worldAnchor_: AnchorEntity?
    
    var viewable: Entity?
    {
        set
        {
            if let oldScene = self._viewable
            {
                self.worldAnchor.removeChild(oldScene)
            }
            
            self._viewable = newValue
            
            if let newScene = self._viewable
            {
                self.worldAnchor.addChild(newScene)
                
                self.cameraFocus = self.centerOfViewable
                self.cameraOrbit = self.radiusOfViewable * 2
                                
                camera.look(at: self.cameraFocus,
                            from: SIMD3<Float>(0, 0, cameraOrbit) + self.cameraFocus,
                            relativeTo: nil)
                
                print(self.camera.transform.matrix)
                                
                _ = self.cameraMatrix
            }
        }
        
        get
        {
            return self._viewable
        }
    }
    
    var _viewable: Entity?
    
    var centerOfViewable: SIMD3<Float>
    {
        let boundsOfViewable = self.boundsOfViewable
        
        return SIMD3<Float>(boundsOfViewable.center)
    }
    
    var radiusOfViewable: Float
    {
        return self.boundsOfViewable.boundingRadius
    }
    
    var boundsOfViewable: BoundingBox
    {
        var bounds = BoundingBox()
        
        if let viewable = self.viewable
        {
            for entity in viewable.children
            {
                if let modelEntity = entity as? ModelEntity
                {
                    bounds.formUnion(modelEntity.model!.mesh.bounds)
                }
            }
        }
        
        return bounds
    }
    
    public required init(frame frameRect: CGRect)
    {
        super.init(frame: frameRect)
        
        self.scene.anchors.append(worldAnchor)
    }
    
    @available(*, unavailable)
    @MainActor dynamic required init?(coder _: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }
    
    // Arcball control
    
    // Camera
    
    // Arcball camera movement
    
    // Center of the arcball (i.e. center of the view)
    
    var arcCenter: SIMD2<Float>
    {
        let center = SIMD2<Float>(Float(self.frame.size.width / 2 + self.frame.origin.x),
                                  Float(self.frame.size.height / 2 + self.frame.origin.y))
        
        return center
    }
    
    // Radius of the arcball (i.e. half height or half width of the view, whichever is less)
    
    var arcRadius: Float
    {
        return Float(self.frame.width < self.frame.height ? self.frame.width / 2 : self.frame.height / 2)
    }
    
    // Convert view coordinates to arcball coordinates.
    
    func arcCoordsOf(_ viewCoords: SIMD2<Float>) -> SIMD2<Float>
    {
        let result = (viewCoords - arcCenter) / arcRadius
        
        // print("arcCoordsOf: ", viewCoords, " = ", result)
        
        return result
    }
    
    // Mouse events.
    
    func rotateArcball()
    {
        if (self.dragStart != self.dragCurrent)
        {
            let fromNDC = self.arcCoordsOf(self.dragStart)
            let toNDC = self.arcCoordsOf(self.dragCurrent)
            
            self.dragStart = self.dragCurrent
            
            self.cameraRotation = self.cameraRotation * Arcball.rotation(fromNDC: fromNDC,
                                                                         toNDC: toNDC)
            
            self.camera.transform.matrix = self.cameraMatrix
            
            /*
             print("rotation: ", self.rotation)
             
             print("rotation.angle: ", self.rotation.angle)
             print("rotation.axis: ", self.rotation.axis)
             */
            
            // Move the position of the camera according to self.rotation
            // Rotate the up angle of the camera according to self.rotation
        }
    }
    
    var cameraMatrix : float4x4
    {
        var result = float4x4(diagonal: SIMD4<Float>(repeating: 1))
                
        result += float4x4([SIMD4<Float>.zero,
                            SIMD4<Float>.zero,
                            SIMD4<Float>.zero,
                            SIMD4<Float>(0, 0, cameraOrbit, 0)])
                
        result = float4x4(cameraRotation) * result
        
        result = Transform(translation: self.cameraFocus).matrix * result

        return result
    }
    
    override open dynamic func mouseDown(with event: NSEvent)
    {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        
        self.dragStart = SIMD2<Float>(Float(locationInView.x),
                                      Float(locationInView.y))
    }
    
    override open dynamic func mouseDragged(with event: NSEvent)
    {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        
        self.dragCurrent = SIMD2<Float>(Float(locationInView.x),
                                        Float(locationInView.y))
        
        self.rotateArcball()
    }
    
    // Keystroke events.
    
    override open dynamic func keyDown(with event: NSEvent)
    {
        super.keyDown(with: event)
    }
    
    // Gesture events.
    
    override open dynamic func magnify(with event: NSEvent)
    {
        super.magnify(with: event)
    }
    
    override open dynamic func smartMagnify(with event: NSEvent)
    {
        super.smartMagnify(with: event)
    }
    
    override open dynamic func rotate(with event: NSEvent)
    {
        super.rotate(with: event)
    }
}
