//
//  GridView.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

struct WiggleModifier: ViewModifier {
    var isEditing: Bool
    
    var rotateAmount: Double = 2.5
    var bounceAmount: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: isEditing ? rotateAmount : 0), anchor: .center)
            .offset(y: isEditing ? -bounceAmount : 0)
            .animation(
                isEditing ? Animation.easeInOut(duration: 0.12).repeatForever(autoreverses: true).delay(Double.random(in: 0...0.2)) : .default,
                value: isEditing
            )
    }
}

struct FlashingModifier: ViewModifier {
    var isEditing: Bool
    
    var color: Color = .primary.opacity(0.2)
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEditing ? color : .clear, lineWidth: 2)
            )
            .animation(isEditing ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: isEditing)
    }
}

extension View {
    func wiggling(isEditing: Bool) -> some View {
        self.modifier(WiggleModifier(isEditing: isEditing))
    }
    
    func wiggling(isEditing: Bool, rotateDegree: Double) -> some View {
        self.modifier(WiggleModifier(isEditing: isEditing, rotateAmount: rotateDegree))
    }
    
    func flashModifier(isEditing: Bool) -> some View {
        self.modifier(FlashingModifier(isEditing: isEditing))
    }
}

struct GridConfig {
    var showAnimations: Bool = true
    var dragAndDrop: Bool = true
    var allowGaps: Bool = false
    
    var deletionButtonSettings: DeletionButtonSettings = .standard
    var widgetSettings: WidgetSettings = .init()
    
    struct DeletionButtonSettings  {
        var alignment: Alignment
        var label: AnyView
        
        init<Content: View>(alignment: Alignment, @ViewBuilder label: () -> Content) {
            self.alignment = alignment
            self.label = AnyView(label())
        }
    
        static var standard: DeletionButtonSettings {
            self.init(alignment: .topLeading, label: {
                Image(systemName: "minus")
                    .padding(4)
            })
        }
    }
    
    struct WidgetSettings {
        var background: AnyView? = nil
    }
}

public struct FlexGrid<Item: GridLayoutItem>: View {
    public let columns: Int
    public let spacing: CGFloat
    
    @Binding public var items: [Item]
    @Binding public var isEditing: Bool
    
    private var config: GridConfig = GridConfig()

    @State private var cellDimensions: CGSize = .zero
    @State private var grid: GridMap
    @State private var draggingItem: Item? = nil
    @State private var lastLocation: GridPoint? = nil
    @State private var isDragging: Bool = false
    @State private var isLayingOut: Bool = false
    
    @State private var sizeingItem: Item? = nil
    
    private var totalHeight: CGFloat {
        let rows = max(1, grid.rows)
        return cellDimensions.height * CGFloat(rows) + spacing * CGFloat(max(0, rows - 1))
    }
    
    public init(columns: Int, spacing: CGFloat, items: Binding<[Item]>, isEditing: Binding<Bool>) {
        precondition(columns > 0, "columns must be greater than 0")
        self.columns = columns
        self.spacing = spacing
        self._items = items
        self._isEditing = isEditing
        _grid = State(initialValue: GridMap(columns: columns, initialRows: 1))
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let drag = DragGesture()
                .onChanged { value in
                    guard let dragging = draggingItem else { return }
                    isDragging = true
                    if config.showAnimations {
                        withAnimation {
                            isEditing = true
                        }
                    } else {
                        isEditing = true
                    }
                    placeDragging(dragging: dragging, position: value.location)
                }
                .onEnded { _ in
                    draggingItem = nil
                    lastLocation = nil
                    isDragging = false
                    items.sort(by: { $0.position < $1.position })
                    calcPosition()
                }
            
            let sizeing = DragGesture()
                .onChanged { value in
                    guard let dragging = draggingItem else { return }
                    isDragging = true
                    if config.showAnimations { isEditing = true }
                    else { isEditing = true }
                    
                    resizeItem(sizeing: dragging, position: value.location)
                }
                .onEnded { _ in
                    sizeingItem = nil
                    isDragging = false
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
                        //.wiggling(isEditing: isEditing, rotateDegree: 0.75 * (Double(columns + 1) - Double(item.size.width)))
                        .flashModifier(isEditing: isEditing)
                        .background {
                            if let background = config.widgetSettings.background {
                                background
                            }
                        }
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
                    if isEditing {
                        if #available(iOS 26.0, *) {
                            Button(action: {
                                withAnimation {
                                    items.removeAll(where: { $0.id == item.id })
                                    do {
                                        items = try grid.layout(items: items, allowGaps: config.allowGaps)
                                    } catch {
                                        assertionFailure("Grid layout failed after deletion: \(error)")
                                    }
                                }
                            }, label: {
                                config.deletionButtonSettings.label
                            })
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .position(calcButtonLocation(position: position, size: size, alignment: config.deletionButtonSettings.alignment))
                            
                            if let sizeableItem = item as? SizeableLayoutItem {
                                let position = calcButtonLocation(position: position, size: size, alignment: .bottomTrailing)
                                Circle()
                                    .trim(from: 0.0, to: 0.25)
                                    .stroke(.ultraThinMaterial, style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                                    .foregroundStyle(.clear)
                                    .frame(width: 48, height: 48)
                                    .position(
                                        x: position.x - 24,
                                        y: position.y - 24
                                    )
                                    .gesture(
                                        LongPressGesture(minimumDuration: 0.01)
                                            .onEnded({ _ in
                                                draggingItem = item
                                            })
                                            .sequenced(before: sizeing)
                                    )
                            }
                        } else {
                            Button(action: {
                                withAnimation {
                                    items.removeAll(where: { $0.id == item.id })
                                    do {
                                        items = try grid.layout(items: items, allowGaps: config.allowGaps)
                                    } catch {
                                        assertionFailure("Grid layout failed after deletion: \(error)")
                                    }
                                }
                            }, label: {
                                config.deletionButtonSettings.label
                            })
                            .buttonStyle(.plain)
                            .position(calcButtonLocation(position: position, size: size, alignment: config.deletionButtonSettings.alignment))
                        }
                    }
                }
            }
            .onChange(of: geometry.size.width, {
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
            .onChange(of: items) {
                calcPosition()
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
    
    public func deletionButtonStyle(
        alignment: Alignment = .topLeading,
        @ViewBuilder label: () -> any View = { Image(systemName: "minus").padding(4) }
    ) -> FlexGrid {
        var copy = self
        copy.config.deletionButtonSettings.alignment = alignment
        copy.config.deletionButtonSettings.label = AnyView(label())
        return copy
    }
    
    public func widgetBackground<V: View>(@ViewBuilder _ background: () -> V) -> FlexGrid {
        var copy = self
        copy.config.widgetSettings.background = AnyView(background())
        return copy
    }
    
    private func resizeItem(sizeing: Item, position: CGPoint) {
        var newPosition = CGPoint(
            x: position.x,
            y: position.y
        )
        let newLocation = getGridLocation(for: 1, at: newPosition)
        guard newLocation != lastLocation else { return }
        lastLocation = newLocation
        
        if let newSizeing = sizeing as? SizeableLayoutItem {
            var updatedSizeing = newSizeing
            updatedSizeing.size.width = max(1, newLocation.x - updatedSizeing.position.x + 1)
            updatedSizeing.size.height = max(1, newLocation.y - updatedSizeing.position.y + 1)
            updatedSizeing.size = updatedSizeing.supportedSizes.closestMatch(for: updatedSizeing.size) ?? newSizeing.size
            calcPosition(for: updatedSizeing as! Item)
        }
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
        return getGridLocation(for: dragging.size.width, at: position)
    }
    
    private func getGridLocation(for width: Int, at position: CGPoint) -> GridPoint {
        let rawPoint = GridPoint(
            x: Int(position.x / (cellDimensions.width + spacing)),
            y: Int(position.y / (cellDimensions.height + spacing))
        )
        
        let clampedPoint = GridPoint(
            x: min(max(rawPoint.x, 0), max(0, columns - width)),
            y: max(rawPoint.y, 0)
        )
        
        return clampedPoint
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
    
    @Previewable @State var isEditing: Bool = false
    
    ScrollView {
        VStack {
            FlexGrid(columns: 4, spacing: 8, items: $items, isEditing: $isEditing)
                .animate(true)
                .allowGaps(false)
                .padding()
        }
    }
}
