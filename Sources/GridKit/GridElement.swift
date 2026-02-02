//
//  GridElement.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

public protocol GridContentItem: GridLayoutItem {
    var content: AnyView { get }
}

/// A structure that defines the visual appearance and size of an item within the ``GridView``.
///
/// # Overview
/// A ``GridItem`` represents a single item within the ``GridView``.
/// Each item defines its own size in terms of grid units (``GridSize``),
/// along with the view content it renders.
public struct GridItem: GridContentItem, Equatable {
    public let id: UUID
    public var position: GridPoint
    public var size: GridSize
    public var content: AnyView
    
    public init<Content: View>(id: UUID = UUID(), width: Int, height: Int, @ViewBuilder content: () -> Content) {
        self.id = id
        self.position = .zero
        self.size = GridSize(width: width, height: height)
        self.content = AnyView(content())
    }
    
    public init<Content: View>(id: UUID = UUID(), size: GridSize, @ViewBuilder content: () -> Content) {
        self.id = id
        self.position = .zero
        self.size = size
        self.content = AnyView(content())
    }
    
    public init(id: UUID = UUID(), size: GridSize, content: AnyView) {
        self.id = id
        self.position = .zero
        self.size = size
        self.content = content
    }
    
    public static func == (lhs: GridItem, rhs: GridItem) -> Bool {
        lhs.id == rhs.id && lhs.position == rhs.position && lhs.size == rhs.size
    }
}

/// A widget that can render different layouts depending on its active size.
///
/// Widgets advertise multiple supported sizes and pick one active size to render.
public struct GridWidget: GridContentItem, Equatable {
    public let id: UUID
    public var position: GridPoint
    public var size: GridSize
    public let supportedSizes: [GridSize]
    
    private let renderer: (GridSize) -> AnyView
    
    public var content: AnyView {
        renderer(size)
    }
    
    public init<Content: View>(
        id: UUID = UUID(),
        supportedSizes: [GridSize],
        size: GridSize? = nil,
        @ViewBuilder content: @escaping (GridSize) -> Content
    ) {
        precondition(!supportedSizes.isEmpty, "supportedSizes must not be empty")
        self.id = id
        self.position = .zero
        self.supportedSizes = supportedSizes
        let resolvedSize = size ?? supportedSizes[0]
        self.size = supportedSizes.contains(resolvedSize) ? resolvedSize : supportedSizes[0]
        self.renderer = { AnyView(content($0)) }
    }
    
    public mutating func setSize(_ size: GridSize) {
        guard supportedSizes.contains(size) else {
            self.size = supportedSizes[0]
            return
        }
        self.size = size
    }
    
    public func isSizeSupported(_ size: GridSize) -> Bool {
        supportedSizes.contains(size)
    }
    
    public static func == (lhs: GridWidget, rhs: GridWidget) -> Bool {
        lhs.id == rhs.id && lhs.position == rhs.position && lhs.size == rhs.size && lhs.supportedSizes == rhs.supportedSizes
    }
}

@available(*, deprecated, message: "Use GridItem")
public typealias GridElement = GridItem
