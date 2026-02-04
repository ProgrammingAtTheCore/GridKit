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

public protocol WidgetView: View {
    var size: GridSize { get set }
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

public struct GridWidget: GridLayoutItem, Equatable {
    public let id: UUID
    public var position: GridPoint
    public var size: GridSize
    public let supportedSizes: [GridSize]
    
    private let renderer: (GridSize) -> AnyView
    
    public var content: AnyView {
        renderer(size)
    }
    
    public init<Content: WidgetView>(id: UUID = UUID(), supportedSizes: [GridSize], width: Int? = nil, height: Int? = nil, @ViewBuilder content: @escaping (GridSize) -> Content) {
        if let width = width,
           let height = height {
            self.init(id: id, supportedSizes: supportedSizes, size: GridSize(width: width, height: height), content: content)
        } else {
            self.init(id: id, supportedSizes: supportedSizes, content: content)
        }
    }
    
    public init<Content: WidgetView>(id: UUID = UUID(), supportedSizes: [GridSize], size: GridSize? = nil, @ViewBuilder content: @escaping (GridSize) -> Content) {
        self.id = id
        self.position = .zero
        self.supportedSizes = supportedSizes
        let resolvedSize = size ?? supportedSizes[0]
        self.size = supportedSizes.contains(resolvedSize) ? resolvedSize : supportedSizes[0]
        self.renderer = { AnyView(content($0)) }
    }
    
    public mutating func setSize(_ size: GridSize) {
        guard supportedSizes.contains(size) else { return }
        self.size = size
    }
    
    public func isSizeSupported(_ size: GridSize) -> Bool {
        supportedSizes.contains(size)
    }
    
    public static func == (lhs: GridWidget, rhs: GridWidget) -> Bool {
        lhs.id == rhs.id && lhs.position == rhs.position && lhs.size == rhs.size && lhs.supportedSizes == rhs.supportedSizes
    }
}
