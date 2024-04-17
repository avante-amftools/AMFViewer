//
//  ContentView.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 6/21/23.
//

import SwiftUI

struct AMFDocumentView: View {
    @Binding var document: AMFViewerDocument
        
    init(document: Binding<AMFViewerDocument>) {
        self._document = document
    }

    var body: some View
    {
        NavigationSplitView(sidebar: { },
                            content: {
            OutlineView(document: $document)
            .frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity)
        },
                            detail: {
            HSplitView
            {
                let realityView = document.realityView
                
                realityView
                    .frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity,
                           minHeight: 200, idealHeight: 200, maxHeight: .infinity)
                    .layoutPriority(1)
                    .frameOverlay()

                DetailGroupsView(document: $document)
                    .frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity)
            }
        })
        .frame(minWidth: 600, idealWidth: 600, maxWidth: .infinity)
    }
}
