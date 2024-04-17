//
//  FrameOverlay.swift
//  Starfish
//
//  Created by Ron Aldrich on 12/30/22.
//

import SwiftUI

extension View
{
    func frameOverlay() -> some View
    {
        #if true
        modifier(FrameOverlay())
        #else
        return self
        #endif
    }
}

private struct FrameOverlay: ViewModifier
{
    static let color = Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 0.1)
    
    func body(content: Content) -> some View
    {
        content.overlay(GeometryReader(content: overlay(for:)))
    }
    
    func overlay(for geometry: GeometryProxy) -> some View
    {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top))
        {
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundColor(FrameOverlay.color)
        }
    }
}
