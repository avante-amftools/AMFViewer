//
//  OutlineView.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 6/24/23.
//

import SwiftUI

struct OutlineView: View {
    @Binding var document: AMFViewerDocument
    
    var body: some View
    {
        List([$document.outline], selection: $document.selection)
        {
            $item in
            
            Toggle(isOn: $document.compressed) {
                Text("Compressed")
            }.toggleStyle(.switch)
            
            DisclosureGroup("\(item.description)",isExpanded: $item.isExpanded)
            {
                if let children = item.children
                {
                    OutlineGroup(children, children: \.children)
                    {
                        child in
                        Text(child.description)
                    }
                }
            }
        }
    }
}
