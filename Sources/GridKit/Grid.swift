//
//  Grid.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

extension GridLayoutItem {
    var rect: GridRect {
        GridRect(position: self.position, size: self.size)
    }
}

public struct GridMap {
    public let columns: Int
    public private(set) var rows: Int
    
    private let initialRows: Int
    var cells: [Bool]
    
    public init(columns: Int, initialRows: Int) {
        precondition(columns > 0, "columns must be greater than 0")
        precondition(initialRows > 0, "initialRows must be greater than 0")
        
        self.columns = columns
        self.initialRows = initialRows
        
        self.rows = initialRows
        self.cells = Array(repeating: false, count: columns * initialRows)
    }
    
    mutating func expand<Item: GridLayoutItem>(item: Item) throws  -> Item {
        guard isExpandable(item: item) else { throw GridError.internalError }
        try free(for: item.rect)
        var newRect: GridRect = item.rect
        repeat {
            newRect = GridRect(
                x: newRect.position.x,
                y: newRect.position.y,
                width: newRect.size.width + 1,
                height: newRect.size.height
            )
        } while isExpandable(for: newRect)
        try occupy(for: newRect)
        var newItem = item
        newItem.position = newRect.position
        newItem.size = newRect.size
        return newItem
    }
    
    func isExpandable<Item: GridLayoutItem>(item: Item) -> Bool {
        return isExpandable(for: item.rect)
    }
    
    private func isExpandable(for rect: GridRect) -> Bool {
        for yIndex in (rect.minY...rect.maxY) {
            if !isFree(for: GridPoint(x: rect.maxX + 1, y: yIndex)) { return false }
        }
        return true
    }
    
    public mutating func resize<Item: SizeableLayoutItem>(items: [Item], sizeing: Item) throws -> [Item] {
        return []
    }
    
    public mutating func layout<Item: GridLayoutItem>(items: [Item], dragging: Item? = nil, allowGaps: Bool = false) throws -> [Item] {
        reset()
        let items = items.sorted { a, b in
            (a.position.y, a.position.x) < (b.position.y, b.position.x)
        }
        
        for item in items {
            try validate(item)
        }
        if let dragging {
            try validate(dragging)
        }
        
        var placements: [Item.ID: Item] = [:]
        if let dragging {
            try occupy(for: GridRect(position: dragging.position, size: dragging.size))
            placements[dragging.id] = dragging
        }
        
        if allowGaps {
            for item in items where item.id != dragging?.id {
                var placed = item
                let rect = GridRect(position: item.position, size: item.size)
                if canPlace(rect) {
                    try occupy(for: rect)
                } else {
                    placed = try place(item)
                }
                placements[placed.id] = placed
            }
        } else {
            for item in items where item.id != dragging?.id {
                let placed = try place(item)
                placements[placed.id] = placed
            }
        }
        
        var result: [Item] = []
        result.reserveCapacity(items.count)
        for item in items {
            if let placed = placements[item.id] {
                result.append(placed)
            } else {
                result.append(item)
            }
        }
        if let dragging, !items.contains(where: { $0.id == dragging.id }) {
            result.append(dragging)
        }
        
        rows = max(rows, (result.map({ $0.position.y + $0.size.height }).max() ?? 1))
        return result
    }
    
    public mutating func place<Item: GridLayoutItem>(_ item: Item) throws -> Item {
        try validate(item)
        
        var placed = item
        var row = 0
        
        while true {
            ensureRows(row + item.size.height)
            for column in 0...(columns - item.size.width) {
                let rect = GridRect(position: GridPoint(x: column, y: row), size: item.size)
                if isFree(for: rect) {
                    try occupy(for: rect)
                    placed.position = GridPoint(x: column, y: row)
                    return placed
                }
            }
            row += 1
        }
    }
    
    private mutating func reset() {
        rows = max(1, initialRows)
        cells = Array(repeating: false, count: columns * rows)
    }
    
    private func validate<Item: GridLayoutItem>(_ item: Item) throws {
        if item.size.width > columns {
            throw GridError.invalidItemSize(size: item.size, columns: columns)
        }
    }
    
    private mutating func ensureRows(_ requiredRows: Int) {
        guard requiredRows > rows else { return }
        let additionalRows = requiredRows - rows
        cells += Array(repeating: false, count: columns * additionalRows)
        rows = requiredRows
    }
    
    private mutating func canPlace(_ rect: GridRect) -> Bool {
        ensureRows(rect.maxY + 1)
        return isFree(for: rect)
    }
    
    private mutating func occupy(for rect: GridRect) throws {
        ensureRows(rect.maxY + 1)
        try validate(rect: rect)
        if !isFree(for: rect) {
            throw GridError.occupied(rect: rect)
        }
        for position in rect.occupied {
            cells[cellIndex(for: position)] = true
        }
    }
    
    private mutating func free(for rect: GridRect) throws {
        try validate(rect: rect)
        for position in rect.occupied {
            cells[cellIndex(for: position)] = false
        }
    }
    
    private func isFree(for point: GridPoint) -> Bool {
        guard ((try? validate(point: point)) != nil) else { return false }
        if cells[cellIndex(for: point)] { return false }
        return true
    }
    
    private mutating func isFree(for rect: GridRect) -> Bool {
        guard ((try? validate(rect: rect)) != nil) else { return false }
        ensureRows(rect.maxY + 1)
        for position in rect.occupied {
            if cells[cellIndex(for: position)] { return false }
        }
        return true
    }
    
    private func validate(rect: GridRect) throws {
        if rect.maxX >= columns {
            throw GridError.invalidItemSize(size: rect.size, columns: columns)
        }
        if rect.maxY >= rows {
            throw GridError.outOfBounds(rect: rect)
        }
    }
    
    private func validate(point: GridPoint) throws {
        if point.x >= columns {
            throw GridError.outOfBounds(rect: GridRect(x: point.x, y: point.y, width: 1, height: 1))
        }
        if point.y >= rows {
            throw GridError.outOfBounds(rect: GridRect(x: point.x, y: point.y, width: 1, height: 1))
        }
    }
    
    private func cellIndex(for position: GridPoint) -> Int {
        position.y * columns + position.x
    }
}
