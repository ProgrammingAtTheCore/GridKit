//
//  GridView.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

struct GridConfig {
    var isEditing: Bool = false
    var showAnimations: Bool = true
    var dragAndDrop: Bool = true
    var allowGaps: Bool = false
}

public struct FlexGrid<Item: GridLayoutItem>: View {
    public let columns: Int
    public let spacing: CGFloat
    
    @Binding public var items: [Item]
    
    private var config: GridConfig = GridConfig()
    
    @State private var cellDimensions: CGSize = .zero
    @State private var grid: GridMap
    @State private var draggingItem: Item? = nil
    @State private var lastLocation: GridPoint? = nil
    @State private var isDragging: Bool = false
    @State private var isLayingOut: Bool = false
    
    private var totalHeight: CGFloat {
        let rows = max(1, grid.rows)
        return cellDimensions.height * CGFloat(rows) + spacing * CGFloat(max(0, rows - 1))
    }
    
    public init(columns: Int, spacing: CGFloat, items: Binding<[Item]>) {
        precondition(columns > 0, "columns must be greater than 0")
        self.columns = columns
        self.spacing = spacing
        self._items = items
        _grid = State(initialValue: GridMap(columns: columns, initialRows: 1))
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let drag = DragGesture()
                .onChanged { value in
                    guard let dragging = draggingItem else { return }
                    isDragging = true
                    placeDragging(dragging: dragging, position: value.location)
                }
                .onEnded { _ in
                    draggingItem = nil
                    lastLocation = nil
                    isDragging = false
                    items.sort(by: { $0.position < $1.position })
                    calcPosition()
                }
            
            ZStack {
                ForEach(items) { (item: Item) in
                    let size = CGSize(
                        width: cellDimensions.width * CGFloat(item.size.width) + spacing * CGFloat(item.size.width - 1),
                        height: cellDimensions.height * CGFloat(item.size.height) + spacing * CGFloat(item.size.height - 1)
                    )
                    
                    let position = CGPoint(
                        x: (cellDimensions.width + spacing) * CGFloat(item.position.x),
                        y: (cellDimensions.height + spacing) * CGFloat(item.position.y)
                    )
                    
                    item.content
                        .frame(width: size.width, height: size.height)
                        .position(
                            x: size.width / 2 + position.x,
                            y: size.height / 2 + position.y
                        )
                        .gesture(
                            config.dragAndDrop ?
                            LongPressGesture(minimumDuration: 0.2)
                                .onEnded({ _ in
                                    draggingItem = item
                                })
                                .sequenced(before: drag)
                            : nil
                        )
                }
            }
            .onChange(of: geometry.size.width, { _, _ in
                if geometry.size.width > 0 {
                    calcDimensions(geometry: geometry)
                    calcPosition()
                }
            })
            .onAppear {
                if geometry.size.width > 0 {
                    calcDimensions(geometry: geometry)
                    calcPosition()
                }
            }
        }
        .frame(height: totalHeight)
    }
    
    private func calcDimensions(geometry: GeometryProxy) {
        guard geometry.size.width > 0 else { return }
        
        let cellSize = (geometry.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        cellDimensions = CGSize(width: cellSize, height: cellSize)
    }
    
    private func calcPosition(for dragging: Item? = nil) {
        if dragging == nil {
            guard !isDragging else { return }
        }
        guard !isLayingOut else { return }
        
        isLayingOut = true
        defer { isLayingOut = false }
        
        do {
            if config.showAnimations {
                withAnimation {
                    do {
                        items = try grid.layout(items: items, dragging: dragging, allowGaps: config.allowGaps)
                    } catch {
                        assertionFailure("Grid layout failed: \(error)")
                    }
                }
            }
            items = try grid.layout(items: items, dragging: dragging, allowGaps: config.allowGaps)
        } catch {
            assertionFailure("Grid layout failed: \(error)")
        }
    }
    
    public func animate(_ value: Bool = false) -> FlexGrid {
        var copy = self
        copy.config.showAnimations = value
        return copy
    }
    
    public func dragAndDrop(_ value: Bool = false) -> FlexGrid {
        var copy = self
        copy.config.dragAndDrop = value
        return copy
    }
    
    public func allowGaps(_ value: Bool = false) -> FlexGrid {
        var copy = self
        copy.config.allowGaps = value
        return copy
    }
    
    public func editingMode(_ value: Bool = false) -> FlexGrid {
        var copy = self
        copy.config.isEditing = value
        return copy
    }
    
    private func placeDragging(dragging: Item, position: CGPoint) {
        let newLocation = getGridLocation(for: dragging, at: position)
        guard newLocation != lastLocation else { return }
        lastLocation = newLocation
        
        var updateDragging = dragging
        updateDragging.position = newLocation
        draggingItem = updateDragging
        
        calcPosition(for: updateDragging)
    }
    
    private func getGridLocation(for dragging: Item, at position: CGPoint) -> GridPoint {
        let rawPoint = GridPoint(
            x: Int(position.x / (cellDimensions.width + spacing)),
            y: Int(position.y / (cellDimensions.height + spacing))
        )
        
        let clampedPoint = GridPoint(
            x: min(max(rawPoint.x, 0), max(0, columns - dragging.size.width)),
            y: max(rawPoint.y, 0)
        )
        
        return clampedPoint
    }
}

struct simpleView: View {
    let number: Int
    
    var body: some View {
        Text(number, format: .number)
            .font(.headline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(.quinary)
            }
    }
}

#Preview {
    @Previewable @State var items: [GridItem] = [
        GridItem(width: 2, height: 2, content: { simpleView(number: 1) }),
        GridItem(width: 3, height: 1, content: { simpleView(number: 2) }),
        GridItem(width: 4, height: 2, content: { simpleView(number: 3) }),
        GridItem(width: 1, height: 1, content: { simpleView(number: 4) }),
        GridItem(width: 1, height: 1, content: { simpleView(number: 5) }),
        GridItem(width: 1, height: 1, content: { simpleView(number: 6) })
    ]
    
    ScrollView {
        VStack {
            FlexGrid(columns: 4, spacing: 8, items: $items)
                .animate(true)
                .allowGaps(false)
                .padding()
        }
    }
}
