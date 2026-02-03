//
//  WidgetGridView.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 02/02/2026.
//

import SwiftUI

/// A widget-focused wrapper around ``GridView``.
public struct WidgetGridView: View {
    public let columns: Int
    public let spacing: CGFloat
    
    @Binding public var widgets: [GridWidget]
    
    //private var config: GridConfig = GridConfig()
    
    public init(columns: Int, spacing: CGFloat, widgets: Binding<[GridWidget]>) {
        precondition(columns > 0, "columns must be greater than 0")
        self.columns = columns
        self.spacing = spacing
        self._widgets = widgets
    }
    
    public var body: some View {
        EmptyView()
    }
}
