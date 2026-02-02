//
//  GridStringExtensions.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

extension GridItem: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "Grid Item(id: \(id) x: \(position.x), y: \(position.y), width: \(size.width), height: \(size.height))"
    }
    
    public var debugDescription: String {
        "Grid Item(x: \(position.x), y: \(position.y), width: \(size.width), height: \(size.height))"
    }
}

extension GridWidget: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "Grid Widget(id: \(id) x: \(position.x), y: \(position.y), width: \(size.width), height: \(size.height))"
    }
    
    public var debugDescription: String {
        "Grid Widget(x: \(position.x), y: \(position.y), width: \(size.width), height: \(size.height))"
    }
}

extension GridError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .outOfBounds(position):
            return "⛔️ Position \(position) out of bounds."
        case let .occupied(position):
            return "⛔️ Cell \(position) is already occupied."
        case let .invalidItemSize(size, columns):
            return "⛔️ Item size \(size) exceeds grid columns (\(columns))."
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

extension GridLayout: CustomStringConvertible {
    public var description: String {
        var result = "Grid:\n  |"
        
        var column: Int = 0
        for cell in cells {
            if column >= columns {
                column = 0
                result += "\n  |"
            }
            result += cell ? "🟩|" : "⬜️|"
            column += 1
        }
        return result
    }
}
