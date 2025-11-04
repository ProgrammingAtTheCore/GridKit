//
//  GridView.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

public struct UniversalGridView: View {
    public let columns: CGFloat
    public let spacing: CGFloat
    
    @Binding public var items: [GridElement]
    
    private var showAnimations: Bool = true
    private var dragAndDrop: Bool = true
    
    public init(columns: Int, spacing: Int, items: Binding<[GridElement]>) {
        self.columns = CGFloat(columns)
        self.spacing = CGFloat(spacing)
        self._items = items
    }
    
    private init(columns: CGFloat, spacing: CGFloat, items: Binding<[GridElement]>, showAnimations: Bool, dragAndDrop: Bool) {
        self.columns = columns
        self.spacing = spacing
        self._items = items
        self.showAnimations = showAnimations
        self.dragAndDrop = dragAndDrop
    }
    
    @State private var grid: GridMap = GridMap(width: 4)
    
    @State private var cellDimensions: CGSize = .zero
    
    @State private var draggingItem: GridElement? = nil
    @State private var lastLocation: GridPoint? = nil
    
    public var body: some View {
        GeometryReader { geometry in
            let drag = DragGesture()
                .onChanged { value in
                    guard let dragging = draggingItem else { return }
                    let newLocation: GridPoint = getGridLocation(for: dragging, at: value.translation)
                    if newLocation != lastLocation {
                        lastLocation = newLocation
                        
                        let itemIndex: Int = items.firstIndex(where: { dragging.id == $0.id })!
                        var item: GridElement = items[itemIndex]
                            
                        items.remove(at: itemIndex)
                        item.position = newLocation
                        
                        if showAnimations {
                            withAnimation {
                                do {
                                    items = try grid.place(elements: items, dragElement: item)
                                } catch {
                                    fatalError("\(error)")
                                }
                            }
                        } else {
                            do {
                                items = try grid.place(elements: items, dragElement: item)
                            } catch {
                                fatalError("\(error)")
                            }
                        }
                    }
                }
                .onEnded { _ in
                    draggingItem = nil
                    lastLocation = nil
                }
            
            ZStack {
                ForEach(items) { (item: GridElement) in
                    let width: CGFloat = cellDimensions.width * item.cgFloatWidth + spacing * (item.cgFloatWidth - 1)
                    let height: CGFloat = cellDimensions.height * item.cgFloatHeight + spacing * (item.cgFloatHeight - 1)
                        
                    item.content
                        .frame(width: width, height: height)
                        .position(
                            x: width / 2 + (cellDimensions.width + spacing) * item.cgFloatX,
                            y: height / 2 + (cellDimensions.height + spacing) * item.cgFloatY
                        )
                        .gesture(
                            dragAndDrop ?
                            LongPressGesture()
                                .onEnded { _ in
                                    draggingItem = item
                                }
                                .sequenced(before: drag)
                            : nil
                        )
                }
            }
            .onAppear {
                let cellSize = (geometry.size.width - spacing * (columns - 1)) / columns
                cellDimensions = CGSize(
                    width: cellSize,
                    height: cellSize
                )
                checkWidthOfItems()
                do {
                    items = try grid.place(elements: items)
                } catch {
                    fatalError("\(error)")
                }
            }
            .onChange(of: items) {
                checkWidthOfItems()
                do {
                    if showAnimations {
                        try withAnimation {
                            items = try grid.place(elements: items)
                        }
                    } else {
                        items = try grid.place(elements: items)
                    }
                } catch {
                    fatalError("\(error)")
                }
            }
        }
        .frame(height: (cellDimensions.height + spacing) * CGFloat(grid.maxHeight))
    }
    
    public func animate(_ value: Bool) -> UniversalGridView {
        return UniversalGridView(columns: columns, spacing: spacing, items: $items, showAnimations: value, dragAndDrop: dragAndDrop)
    }
    
    public func dragAndDrop(_ value: Bool) -> UniversalGridView {
        return UniversalGridView(columns: columns, spacing: spacing, items: $items, showAnimations: showAnimations, dragAndDrop: value)
    }
    
    private func getGridLocation(for dragging: GridElement, at translation: CGSize) -> GridPoint {
        let oldXPixel: CGFloat = cellDimensions.width * dragging.cgFloatX + cellDimensions.width / 2
        let oldYPixel: CGFloat = cellDimensions.height * dragging.cgFloatY + cellDimensions.height / 2
        
        var x: Int = Int((oldXPixel + translation.width) / cellDimensions.width)
        let y: Int = Int((oldYPixel + translation.height) / cellDimensions.height)
        
        if x > Int(columns) - dragging.size.width {
            x = Int(columns) - dragging.size.width
        }
        return GridPoint(x: x, y: y)
    }
    private func checkWidthOfItems() {
        for item in items {
            assert(item.size.width <= Int(columns), "Width of item is to wide. \(item) The width is: \(item.size.width) but max width is: \(columns)")
        }
    }
}
