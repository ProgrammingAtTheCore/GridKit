//
//  GridElement.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

public struct GridElement: Identifiable {
    public let id: UUID
    var position: GridPoint
    public var size: GridSize
    
    var cgFloatX: CGFloat {
        CGFloat(position.x)
    }
    var cgFloatY: CGFloat {
        CGFloat(position.y)
    }
    var cgFloatWidth: CGFloat {
        CGFloat(size.width)
    }
    var cgFloatHeight: CGFloat {
        CGFloat(size.height)
    }
    
    var rect: GridRect {
        GridRect(position: position, size: size)
    }
    
    public var content: AnyView
    
    public init<Content: View>(width: Int, height: Int, @ViewBuilder content: () -> Content) {
        self.id = UUID()
        self.position = .zero
        self.size = GridSize(width: width, height: height)
        self.content = AnyView(content())
    }
    
    public init<Content: View>(size: GridSize, @ViewBuilder content: () -> Content) {
        self.id = UUID()
        self.position = .zero
        self.size = size
        self.content = AnyView(content())
    }
    
    public init(size: GridSize, content: AnyView) {
        self.id = UUID()
        self.position = .zero
        self.size = size
        self.content = content
    }
}

extension GridElement: Equatable {
    public static func == (lhs: GridElement, rhs: GridElement) -> Bool {
        if lhs.id == rhs.id,
           lhs.size == rhs.size {
            return true
        } else {
            return false
        }
    }
    
    
}
