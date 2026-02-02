//
//  GridTypes.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

public enum GridError: Error, Equatable {
    case outOfBounds(position: GridPoint)
    case occupied(position: GridPoint)
    case invalidItemSize(size: GridSize, columns: Int)
}

public struct GridPoint: Equatable, Hashable {
    public var x: Int
    public var y: Int
    
    public static var zero: GridPoint {
        self.init(x: 0, y: 0)
    }
    
    public init(x: Int, y: Int) {
        precondition(x >= 0 && y >= 0, "x and y must be positive you tried to initilize with X: \(x) and Y: \(y)")
        self.x = x
        self.y = y
    }
}

extension GridPoint: Comparable {
    public static func < (lhs: GridPoint, rhs: GridPoint) -> Bool {
        if lhs.y == rhs.y {
            return lhs.x < rhs.x
        } else {
            return lhs.y < rhs.y
        }
    }
}

/// A structure that contains the width and height values in grid units.
///
/// # Overview
/// ``GridSize`` describes how much space an element occupies within the grid layout.
/// Instead of using pixel-based dimensions,
/// size is expressed in *grid units* which allows the layout to adapt automatically to different screen sizes and configurations.
///
public struct GridSize: Equatable, Hashable {
    /// The number of grid columns the element spans.
    public var width: Int
    /// The number of grid rows the element spans.
    public var height: Int
    
    /// Creates an instance with zero width and height.
    public static var standard: GridSize {
        self.init()
    }
    
    /// Creates a size where width and height are equal to the input.
    public static func square(with value: Int = 1) -> GridSize {
        return self.init(width: value, height: value)
    }
    
    public init(width: Int = 1, height: Int = 1) {
        precondition(width > 0 && height > 0, "width and height must be greater than 0 you tried to initilize with width: \(width) and height: \(height)")
        self.width = width
        self.height = height
    }
}

public struct GridRect {
    public var position: GridPoint
    public var size: GridSize
    
    public var minX: Int { position.x }
    public var minY: Int { position.y }
    public var maxX: Int { position.x + size.width - 1 }
    public var maxY: Int { position.y + size.height - 1 }
    
    public var positions: [GridPoint] {
        var result: [GridPoint] = []
        
        for yPosition in minY...maxY {
            for xPosition in minX...maxX {
                result.append(GridPoint(x: xPosition, y: yPosition))
            }
        }
        
        return result
    }
    
    public static var standard: GridRect {
        self.init()
    }
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.position = GridPoint(x: x, y: y)
        self.size = GridSize(width: width, height: height)
    }
    
    public init(position: GridPoint = .zero, size: GridSize = .square()) {
        self.position = position
        self.size = size
    }
}
