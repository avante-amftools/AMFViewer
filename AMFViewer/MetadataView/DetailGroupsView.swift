//
//  MetadataView.swift
//  AMFViewer
//
//  Created by Ron Aldrich on 8/4/23.
//

import SwiftUI

struct DetailGroupsView: View
{
    @Binding var document: AMFViewerDocument
        
    var body: some View
    {
        let selectedNodes = document.selectedNodes
        
        List(selectedNodes)
        {
            item in
            
            Text(item.description)
            
            Table(item.details)
            {
                TableColumn("Type")
                {
                    detail in
                    Text(detail.type)
                }
                
                TableColumn("Value")
                {
                    detail in
                    switch detail
                    {
                    case is AttributeDetail:
                        AttributeDetailView(detail: detail as! AttributeDetail)

                    case is ColorDetail:
                        ColorDetailView(detail: detail as! ColorDetail)

                    case is MetadataDetail:
                        MetadataDetailView(detail: detail as! MetadataDetail)

                    default:
                        Text("Unrecognized class")
                    }
                }
            }   .border(Color.pink)
                .frame(idealHeight: 200)
                .border(Color.blue)
        }
    }
}
