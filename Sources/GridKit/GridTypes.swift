//
//  GridTypes.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

public enum GridError: Error {
    case outOfBounds(rect: GridRect)
    case occupied(rect: GridRect)
    case invalidItemSize(size: GridSize, columns: Int)
}

public struct GridPoint: Equatable, Sendable, Comparable {
    public var x: Int
    public var y: Int
    
    public static var zero: GridPoint {
        self.init(x: 0, y: 0)
    }
    
    public init(x: Int, y: Int) {
        precondition(x >= 0 && y >= 0, "x and y must be positive you tried to intilaize with X: \(x) and Y: \(y)")
        self.x = x
        self.y = y
    }
    
    public static func < (lhs: GridPoint, rhs: GridPoint) -> Bool {
        if lhs.y == rhs.y {
            return lhs.x < rhs.x
        } else {
            return lhs.y < rhs.y
        }
    }
}

public struct GridSize: Equatable, Sendable {
    public var width: Int
    public var height: Int
    
    public static var standard: GridSize {
        self.init(width: 1, height: 1)
    }
    
    public init(width: Int, height: Int) {
        precondition(width > 0 && height > 0, "width and height must be greater than 0 you tried to initilize with width: \(width) and height: \(height)")
        self.width = width
        self.height = height
    }
}

public struct GridRect : Sendable {
    public var position: GridPoint
    public var size: GridSize
    
    public var minX: Int { position.x }
    public var minY: Int { position.y }
    public var maxX: Int { position.x + size.width - 1 }
    public var maxY: Int { position.y + size.height - 1 }
    
    public var occupied: [GridPoint] {
        var result: [GridPoint] = []
        for yPosition in minY...maxY {
            for xPosition in minX...maxX {
                result.append(GridPoint(x: xPosition, y: yPosition))
            }
        }
        return result
    }
    
    public static var standard: GridRect {
        self.init(position: .zero, size: .standard)
    }
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.position = GridPoint(x: x, y: y)
        self.size = GridSize(width: width, height: height)
    }
    
    public init(position: GridPoint, size: GridSize) {
        self.position = position
        self.size = size
    }
}
