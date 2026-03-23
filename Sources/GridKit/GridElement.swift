//
//  GridElement.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

public protocol GridLayoutItem: Identifiable, Equatable {
    var position: GridPoint { get set }
    var size: GridSize { get set }
    var content: AnyView { get }
}

public protocol SizeableLayoutItem: GridLayoutItem {
    var position: GridPoint { get set }
    var size: GridSize { get set }
    var supportedSizes: [GridSize] { get }
    var content: AnyView { get }
}

public protocol WidgetView: View, Sendable {
    static var title: String { get }
    static var description: String { get }
    
    static var widgetKey: String { get }
    static var supportedSizes: [GridSize] { get }
    static var supportedVariants: [GridSize] { get }
    
    var size: GridSize { get }
    init(size: GridSize, context: (any Sendable)?)
}

public struct GridItem: GridLayoutItem, Equatable {
    public let id: UUID
    public var position: GridPoint
    public var size: GridSize
    public var content: AnyView
    
    public init<Content: View>(id: UUID = UUID(), width: Int, height: Int, @ViewBuilder content: () -> Content) {
        self.init(id: id, size: GridSize(width: width, height: height), content: content)
    }
    
    public init<Content: View>(id: UUID = UUID(), size: GridSize, @ViewBuilder content: () -> Content) {
        self.id = id
        self.position = .zero
        self.size = size
        self.content = AnyView(content())
    }
    
    public static func == (lhs: GridItem, rhs: GridItem) -> Bool {
        lhs.id == rhs.id && lhs.position == rhs.position && lhs.size == rhs.size
    }
}

public struct GridWidget: SizeableLayoutItem, Equatable {
    public let id: UUID
    public let typeKey: String
    public var position: GridPoint
    public var size: GridSize
    public let supportedSizes: [GridSize]
    
    private let updateToken: UUID
    
    private let renderer: (GridSize) -> AnyView
    
    public var content: AnyView {
        renderer(size)
    }
    
    public init<V: WidgetView>(_ type: V.Type, id: UUID = UUID(), size: GridSize? = nil, context: (any Sendable)? = nil) {
        self.id = id
        self.typeKey = V.widgetKey
        self.position = .zero
        self.supportedSizes = V.supportedSizes
        let defaultSize = size ?? V.supportedSizes[0]
        self.size = V.supportedSizes.contains(defaultSize) ? defaultSize : V.supportedSizes[0]
        
        self.updateToken = UUID()
        self.renderer = { (size: GridSize) in
            AnyView(V(size: size, context: context))
        }
    }
    
    public mutating func setSize(_ size: GridSize) {
        guard supportedSizes.contains(size) else { return }
        self.size = size
    }
    
    public func isSizeSupported(_ size: GridSize) -> Bool {
        supportedSizes.contains(size)
    }
    
    public static func == (lhs: GridWidget, rhs: GridWidget) -> Bool {
        lhs.id == rhs.id && lhs.position == rhs.position && lhs.size == rhs.size && lhs.supportedSizes == rhs.supportedSizes && lhs.updateToken == rhs.updateToken
    }
}
