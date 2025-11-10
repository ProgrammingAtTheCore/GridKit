//
//  GridView.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

/// A ``GridView`` arranges a collection of ``GridElement`` into a structured, adaptive layout.
///
/// # Overview
/// ``GridView`` displays a set of ``GridElement`` values in a flexible,
/// grid-based layout. Each element defines its own size in grid units,
/// and the view places them according to the number of available columns with the spacing you provide.
///
/// The grid automatically arranges elements to fill available space while remaining the order given in the set,
/// adjusting the layout as elements change in order.
/// This makes ``GridView`` well suited for widget-style interfaces, customizable dashboards,
/// and other layouts where items vary in shape.
///
/// ## Example
///
/// ```swift
/// @State var items: [GridElement] = [
/// GridElement(width: 2, height: 2, content: { simpleView(number: 1) }),
/// GridElement(width: 2, height: 1, content: { simpleView(number: 2) }),
/// GridElement(width: 1, height: 1, content: { simpleView(number: 3) }),
/// GridElement(width: 1, height: 1, content: { simpleView(number: 4) })
/// ]
///
/// GridView(columns: 4, spacing: 8, items: $items)
/// ```
/// - Important: The Order of the Elements defines the Order of the Elements in the Grid.
///
/// ![A Simple Example of the Grid View](GridExample)
///
/// - Warning: Ensure that the width and height of each element do not exceed the grid's capacity. Elements that extend beyond the number of columns will lead to undefined behaviour.
public struct GridView: View {
    
    /// Defines how many columns the grid has.
    ///
    /// It is labled as `CGFloat` but it must represent positive even values.
    public let columns: CGFloat
    
    /// Defines the spacing between elements in pixel values.
    public let spacing: CGFloat
    
    /// The items which should be shown by the ``GridView``.
    ///
    /// - Important: ``GridView`` lays out elements in sequence and does not modify their order during placement.
    @Binding public var items: [GridElement]
    
    private var isEditing: Bool = false
    
    private var showAnimations: Bool = true
    private var dragAndDrop: Bool = true
    
    public init(columns: Int, spacing: Int, items: Binding<[GridElement]>) {
        self.columns = CGFloat(columns)
        self.spacing = CGFloat(spacing)
        self._items = items
    }
    
    private init(columns: CGFloat, spacing: CGFloat, items: Binding<[GridElement]>, isEditing: Bool, showAnimations: Bool, dragAndDrop: Bool) {
        self.columns = columns
        self.spacing = spacing
        self._items = items
        self.isEditing = isEditing
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
                    
                    let xPosition: CGFloat = (cellDimensions.width + spacing) * item.cgFloatX
                    let yPosition: CGFloat = (cellDimensions.height + spacing) * item.cgFloatY
                    
                    item.content
                        .frame(width: width, height: height)
                        .position(
                            x: width / 2 + xPosition,
                            y: height / 2 + yPosition
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
                    
                    if isEditing {
                        Button(action: {
                            withAnimation {
                                items.removeAll(where: { $0.id == item.id })
                                items = try! grid.place(elements: items)
                            }
                        }, label: {
                            Text("-")
                        })
                        .buttonStyle(.borderedProminent)
                        .position(
                            x: xPosition,
                            y: yPosition
                        )
                    }
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
            /*
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
            */
        }
        .frame(height: (cellDimensions.height + spacing) * CGFloat(grid.maxHeight))
    }
    
    /// Use this function to disable animations.
    public func animate(_ value: Bool = false) -> GridView {
        return GridView(columns: columns, spacing: spacing, items: $items, isEditing: isEditing, showAnimations: value, dragAndDrop: dragAndDrop)
    }
    
    /// Use this function to disable drag and drop.
    public func dragAndDrop(_ value: Bool = false) -> GridView {
        return GridView(columns: columns, spacing: spacing, items: $items, isEditing: isEditing, showAnimations: showAnimations, dragAndDrop: value)
    }
    
    public func edittingMode(_ value: Bool) -> GridView {
        return GridView(columns: columns, spacing: spacing, items: $items, isEditing: value, showAnimations: showAnimations, dragAndDrop: dragAndDrop)
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
    @Previewable @State var items: [GridElement] = [
        GridElement(width: 2, height: 2, content: { simpleView(number: 1) }),
        GridElement(width: 3, height: 1, content: { simpleView(number: 2) }),
        GridElement(width: 1, height: 1, content: { simpleView(number: 3) }),
        GridElement(width: 1, height: 1, content: { simpleView(number: 4) })
    ]
    
    VStack {
        GridView(columns: 4, spacing: 8, items: $items)
            .edittingMode(true)
            .padding()
        
        Spacer()
    }
}
