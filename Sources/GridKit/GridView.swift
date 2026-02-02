//
//  GridView.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

struct GridConfig {
    var isEditing: Bool = false
    var showAnimations: Bool = false
    var dragAndDrop: Bool = true
    
    var deletionButtonAlignment: Alignment = .topLeading
    var deletionButtonLabel: AnyView = AnyView(Image(systemName: "minus"))
}

/// A ``GridView`` arranges a collection of items into a structured, adaptive layout.
///
/// ``GridView`` uses ``GridLayout`` internally to position items by their size,
/// and supports drag & drop plus optional edit mode.
public struct GridView<Item: GridContentItem>: View {
    public let columns: Int
    public let spacing: CGFloat
    
    @Binding public var items: [Item]
    
    private var config: GridConfig = GridConfig()
    
    @State private var cellDimensions: CGSize = .zero
    @State private var grid: GridLayout
    @State private var draggingItem: Item? = nil
    @State private var lastLocation: GridPoint? = nil
    @State private var isDragging: Bool = false
    @State private var isLayingOut: Bool = false
    
    public init(columns: Int, spacing: CGFloat, items: Binding<[Item]>) {
        precondition(columns > 0, "columns must be greater than 0")
        self.columns = columns
        self.spacing = spacing
        self._items = items
        _grid = State(initialValue: GridLayout(columns: columns))
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let drag = DragGesture()
                .onChanged { value in
                    guard let dragging = draggingItem else { return }
                    isDragging = true
                    placeDragging(dragging: dragging, translation: value.translation)
                }
                .onEnded { _ in
                    draggingItem = nil
                    lastLocation = nil
                    isDragging = false
                    items.sort { $0.position < $1.position }
                    if geometry.size.width > 0 {
                        calcPositions(geometry: geometry)
                    }
                }
            
            ZStack {
                ForEach(items) { item in
                    let size = CGSize(
                        width: cellDimensions.width * CGFloat(item.size.width) + spacing * CGFloat(item.size.width - 1),
                        height: cellDimensions.height * CGFloat(item.size.height) + spacing * CGFloat(item.size.height - 1)
                    )
                    
                    let stride = cellDimensions.width + spacing
                    let position = CGPoint(
                        x: stride * CGFloat(item.position.x),
                        y: stride * CGFloat(item.position.y)
                    )
                    
                    item.content
                        .frame(width: size.width, height: size.height)
                        .position(x: size.width / 2 + position.x, y: size.height / 2 + position.y)
                        .gesture(
                            config.dragAndDrop ?
                            LongPressGesture(minimumDuration: 0.2)
                                .onEnded { _ in
                                    draggingItem = item
                                }
                                .sequenced(before: drag)
                            : nil
                        )
                    
                    if config.isEditing {
                        Button(action: {
                            withAnimation {
                                items.removeAll(where: { $0.id == item.id })
                                do {
                                    items = try grid.layout(items: items)
                                } catch {
                                    assertionFailure("Grid layout failed after deletion: \(error)")
                                }
                            }
                        }, label: {
                            config.deletionButtonLabel
                        })
                        .position(calcButtonLocation(position: position, size: size, alignment: config.deletionButtonAlignment))
                    }
                }
            }
            .onChange(of: geometry.size.width) { _, _ in
                if geometry.size.width > 0 {
                    calcPositions(geometry: geometry)
                }
            }
            .onAppear {
                if geometry.size.width > 0 {
                    calcPositions(geometry: geometry)
                }
            }
            .onChange(of: items) { _, _ in
                if geometry.size.width > 0 {
                    calcPositions(geometry: geometry)
                }
            }
        }
        .frame(height: totalHeight)
    }
    
    private var totalHeight: CGFloat {
        let rows = max(1, grid.rows)
        return cellDimensions.height * CGFloat(rows) + spacing * CGFloat(max(0, rows - 1))
    }
    
    private func calcPositions(geometry: GeometryProxy) {
        guard !isDragging, !isLayingOut else { return }
        guard geometry.size.width > 0 else { return }
        
        isLayingOut = true
        defer { isLayingOut = false }
        
        let columnCount = max(1, columns)
        let cellSize = (geometry.size.width - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
        cellDimensions = CGSize(width: cellSize, height: cellSize)
        
        do {
            if config.showAnimations {
                withAnimation {
                    do {
                        items = try grid.layout(items: items)
                    } catch {
                        assertionFailure("Grid layout failed: \(error)")
                    }
                }
            } else {
                items = try grid.layout(items: items)
            }
        } catch {
            assertionFailure("Grid layout failed: \(error)")
        }
    }
    
    /// Use this function to enable or disable animations.
    public func animate(_ value: Bool = false) -> GridView {
        var copy = self
        copy.config.showAnimations = value
        return copy
    }
    
    /// Use this function to enable or disable drag and drop.
    public func dragAndDrop(_ value: Bool = false) -> GridView {
        var copy = self
        copy.config.dragAndDrop = value
        return copy
    }
    
    /// Use this function to toggle between normal mode and editing mode.
    public func editingMode(_ value: Bool) -> GridView {
        var copy = self
        copy.config.isEditing = value
        return copy
    }

    @available(*, deprecated, message: "Use editingMode(_:) instead.")
    public func edittingMode(_ value: Bool) -> GridView {
        editingMode(value)
    }
    
    /// Design and arrange the deletion button wherever you prefer.
    public func deletionButtonStyle(alignment: Alignment = .topLeading, @ViewBuilder label: () -> any View = { Image(systemName: "minus") }) -> GridView {
        var copy = self
        copy.config.deletionButtonAlignment = alignment
        copy.config.deletionButtonLabel = AnyView(label())
        return copy
    }
    
    private func placeDragging(dragging: Item, translation: CGSize) {
        let newLocation = getGridLocation(for: dragging, at: translation)
        guard newLocation != lastLocation else { return }
        lastLocation = newLocation
        
        var updatedDragging = dragging
        updatedDragging.position = newLocation
        draggingItem = updatedDragging
        
        do {
            if config.showAnimations {
                withAnimation {
                    do {
                        items = try grid.layout(items: items, dragging: updatedDragging)
                    } catch {
                        assertionFailure("Grid layout failed while dragging: \(error)")
                    }
                }
            } else {
                items = try grid.layout(items: items, dragging: updatedDragging)
            }
        } catch {
            assertionFailure("Grid layout failed while dragging: \(error)")
        }
    }
    
    private func getGridLocation(for dragging: Item, at translation: CGSize) -> GridPoint {
        let stride = cellDimensions.width + spacing
        let oldXPixel = stride * CGFloat(dragging.position.x) + cellDimensions.width / 2
        let oldYPixel = stride * CGFloat(dragging.position.y) + cellDimensions.height / 2
        
        let rawX = Int((oldXPixel + translation.width) / stride)
        let rawY = Int((oldYPixel + translation.height) / stride)
        
        let clampedX = min(max(rawX, 0), max(0, columns - dragging.size.width))
        let clampedY = max(rawY, 0)
        return GridPoint(x: clampedX, y: clampedY)
    }
    
    private func calcButtonLocation(position: CGPoint, size: CGSize, alignment: Alignment) -> CGPoint {
        var copy = position
        
        switch alignment.horizontal {
        case .leading: copy.x = position.x
        case .center: copy.x = position.x + size.width / 2
        case .trailing: copy.x = position.x + size.width
        default: copy.x = position.x
        }
        
        switch alignment.vertical {
        case .top: copy.y = position.y
        case .center: copy.y = position.y + size.height / 2
        case .bottom: copy.y = position.y + size.height
        default: copy.y = position.y
        }
        
        return copy
    }
}

struct simpleView: View {
    let number: Int
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.quinary)
            Text(number, format: .number)
        }
    }
}

#Preview {
    @Previewable @State var items: [GridItem] = [
        GridItem(width: 2, height: 2, content: { simpleView(number: 1) }),
        GridItem(width: 3, height: 1, content: { simpleView(number: 2) }),
        GridItem(width: 1, height: 1, content: { simpleView(number: 3) }),
        GridItem(width: 1, height: 1, content: { simpleView(number: 4) })
    ]
    
    VStack {
        GridView(columns: 4, spacing: 8, items: $items)
            .editingMode(true)
            .deletionButtonStyle(alignment: .topLeading, label: {
                Label("Deletion", systemImage: "minus")
                    .labelStyle(.iconOnly)
            })
            .padding()
        
        Spacer()
    }
}
