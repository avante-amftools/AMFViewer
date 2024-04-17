//
//  Detail.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 7/25/23.
//

import Foundation
import SwiftUI

class Detail : Identifiable
{
    let type: String
    
    init(type: String)
    {
        self.type = type
    }
}

class AttributeDetail : Detail
{
    let attributeNode: ModelAttributeWrapper
    
    init(attributeNode: ModelAttributeWrapper) {
        self.attributeNode = attributeNode
        super.init(type: attributeNode.identifier)
    }
    
    var value: String
    {
        get {
            return attributeNode.value
        }
        
        set {
            attributeNode.value = newValue
        }
    }
    
}

class ColorDetail : Detail
{
    let colorNode: ModelColorWrapper
    
    init(colorNode: ModelColorWrapper)
    {
        self.colorNode = colorNode
        super.init(type: colorNode.identifier)
    }
    
    var value: Color
    {
        get {
            let value = colorNode.color
            return Color(red: value.x, green: value.y, blue: value.z, opacity: value.w)
        }
        
        set {
            // To implement a setter for this, we're going to
            //  need to handle colorspaces.
        }
        
    }
}
    

class MetadataDetail : Detail
{
    let metadataNode: ModelMetadataWrapper
    
    init(metadataNode: ModelMetadataWrapper) {
        self.metadataNode = metadataNode
        super.init(type: metadataNode.type)
    }
    
    var value: String
    {
        get {
            return metadataNode.value
        }
        
        set {
            metadataNode.value = newValue
        }
    }
}
