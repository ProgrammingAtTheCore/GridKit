//
//  GridTypes.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

enum GridError: Error, Equatable {
    case outOfBounds(position: GridPoint)
    case occupied(position: GridPoint)
    case unknown
}

struct GridPoint: Equatable {
    var x: Int
    var y: Int
    
    static var zero: GridPoint {
        self.init(x: 0, y: 0)
    }
    
    init(x: Int, y: Int) {
        assert(x >= 0 && y >= 0, "x and y must be positive you tried to initilize with X: \(x) and Y: \(y)")
        self.x = x
        self.y = y
    }
}

extension GridPoint: Comparable {
    static func < (lhs: GridPoint, rhs: GridPoint) -> Bool {
        if lhs.y == rhs.y {
            return lhs.x < rhs.x
        } else {
            return lhs.y < rhs.y
        }
    }
}

public struct GridSize: Equatable {
    public var width: Int
    public var height: Int
    
    static func square(with value: Int = 1) -> GridSize {
        return self.init(width: value, height: value)
    }
    
    public init(width: Int, height: Int) {
        assert(width > 0 && height > 0, "width and height must be greater than 0 you tried to initilize with width: \(width) and height: \(height)")
        self.width = width
        self.height = height
    }
}

struct GridRect {
    var position: GridPoint
    var size: GridSize
    
    var minX: Int { position.x }
    var minY: Int { position.y }
    var maxX: Int { position.x + size.width - 1 }
    var maxY: Int { position.y + size.height - 1 }
    
    var positions: [GridPoint] {
        var result: [GridPoint] = []
        
        for yPosition in minY...maxY {
            for xPosition in minX...maxX {
                result.append(GridPoint(x: xPosition, y: yPosition))
            }
        }
        
        return result
    }
    
    static var standard: GridRect {
        self.init()
    }
    
    init(x: Int, y: Int, width: Int, height: Int) {
        self.position = GridPoint(x: x, y: y)
        self.size = GridSize(width: width, height: height)
    }
    
    init(position: GridPoint = .zero, size: GridSize = .square()) {
        self.position = position
        self.size = size
    }
}
