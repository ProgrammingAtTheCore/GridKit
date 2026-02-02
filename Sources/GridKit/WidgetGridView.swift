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
    
    private var config: GridConfig = GridConfig()
    
    public init(columns: Int, spacing: CGFloat, widgets: Binding<[GridWidget]>) {
        precondition(columns > 0, "columns must be greater than 0")
        self.columns = columns
        self.spacing = spacing
        self._widgets = widgets
    }
    
    public var body: some View {
        GridView(columns: columns, spacing: spacing, items: $widgets)
            .animate(config.showAnimations)
            .dragAndDrop(config.dragAndDrop)
            .editingMode(config.isEditing)
            .deletionButtonStyle(alignment: config.deletionButtonAlignment, label: {
                config.deletionButtonLabel
            })
    }
    
    /// Use this function to enable or disable animations.
    public func animate(_ value: Bool = false) -> WidgetGridView {
        var copy = self
        copy.config.showAnimations = value
        return copy
    }
    
    /// Use this function to enable or disable drag and drop.
    public func dragAndDrop(_ value: Bool = false) -> WidgetGridView {
        var copy = self
        copy.config.dragAndDrop = value
        return copy
    }
    
    /// Use this function to toggle between normal mode and editing mode.
    public func editingMode(_ value: Bool) -> WidgetGridView {
        var copy = self
        copy.config.isEditing = value
        return copy
    }

    @available(*, deprecated, message: "Use editingMode(_:) instead.")
    public func edittingMode(_ value: Bool) -> WidgetGridView {
        editingMode(value)
    }
    
    /// Design and arrange the deletion button wherever you prefer.
    public func deletionButtonStyle(alignment: Alignment = .topLeading, @ViewBuilder label: () -> any View = { Image(systemName: "minus") }) -> WidgetGridView {
        var copy = self
        copy.config.deletionButtonAlignment = alignment
        copy.config.deletionButtonLabel = AnyView(label())
        return copy
    }
}
