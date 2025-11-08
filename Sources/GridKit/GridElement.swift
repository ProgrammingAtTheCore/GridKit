//
//  GridElement.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

import SwiftUI

///
/// A structure that defines the visual appearance and size of an item within the ``GridView``.
///
/// # Overview
/// A ``GridElement`` represents a single item within the ``GridView``.
/// Each element defines its own size in terms of grid units (``GridSize``),
/// along with the view content it renders.
/// By combining multiple elements of diffrent sizes,
/// you can create adaptive, widget-like layouts similar to a home screen or dahboard interface.
///
/// ``GridElement`` works closely with ``GridView``.
/// The grid uses the dimensions you provide to place each item in an available position,
/// ensuring that elements align consistently and maintain a balanced visual structure.
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
/// - Warning: Ensure that the width and height of each element do not exceed the grid's capacity.
/// Elements that extend beyond the number of columns will lead to undefined behaviour.
///
public struct GridElement: Identifiable {
    public let id: UUID
    var position: GridPoint
    
    /// Defines the size of this element in grid units.
    ///
    /// # Overview
    /// The width and height values determine how much space the element occupies within the grid layout.
    public var size: GridSize
    
    /// Represents the views content.
    ///
    /// # Overview
    /// The ``GridElement/content`` property provides the view that represents the element within the grid.
    public var content: AnyView
    
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
