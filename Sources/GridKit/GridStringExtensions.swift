//
//  GridStringExtensions.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

extension GridElement: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "Grid Element(x: \(position.x), y: \(position.y), width: \(size.width), height: \(size.height))"
    }
    
    public var debugDescription: String {
        "Grid Element(x: \(position.x), y: \(position.y), width: \(size.width), height: \(size.height))"
    }
}

extension GridError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .outOfBounds(position):
            return "⛔️ Position \(position) out of bounds."
        case let .occupied(position):
            return "⛔️ Cell \(position) is already occupied."
        case .unknown:
            return "⛔️ Unknown Error occured."
        }
    }
}

extension GridPoint: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "(\(x), \(y))"
    }
    
    public var debugDescription: String {
        return "(\(x), \(y))"
    }
}

extension GridSize: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "[\(width)x\(height)]"
    }
    
    public var debugDescription: String {
        return "[\(width)x\(height)]"
    }
}

extension GridMap: CustomStringConvertible {
    var description: String {
        var result = "Grid:\n  |"
        
        var column: Int = 0
        for cell in cells {
            if column >= width {
                column = 0
                result += "\n  |"
            }
            result += cell ? "🟩|" : "⬜️|"
            column += 1
        }
        return result
    }
}
