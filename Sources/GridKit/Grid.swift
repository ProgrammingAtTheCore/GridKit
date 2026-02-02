//
//  Grid.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//

public protocol GridLayoutItem: Identifiable {
    var position: GridPoint { get set }
    var size: GridSize { get set }
}

public struct GridLayout {
    public let columns: Int
    public private(set) var rows: Int
    
    private let initialRows: Int
    var cells: [Bool]
    
    public init(columns: Int, initialRows: Int = 1) {
        precondition(columns > 0, "columns must be greater than 0")
        precondition(initialRows > 0, "initialRows must be greater than 0")
        self.columns = columns
        self.initialRows = initialRows
        self.rows = initialRows
        self.cells = Array(repeating: false, count: columns * initialRows)
    }
    
    public mutating func layout<Item: GridLayoutItem>(items: [Item], dragging: Item? = nil) throws -> [Item] {
        reset()
        
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
        
        for item in items where item.id != dragging?.id {
            let placed = try place(item)
            placements[placed.id] = placed
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
        
        rows = max(rows, (result.map { $0.position.y + $0.size.height }.max() ?? 1))
        return result
    }
    
    public mutating func place<Item: GridLayoutItem>(_ item: Item) throws -> Item {
        try validate(item)
        
        var placed = item
        var row = 0
        
        while true {
            ensureRows(row + item.size.height)
            for column in 0...(columns - item.size.width) {
                let rect = GridRect(x: column, y: row, width: item.size.width, height: item.size.height)
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
    
    private mutating func occupy(for rect: GridRect) throws {
        ensureRows(rect.maxY + 1)
        try validate(rect: rect)
        if !isFree(for: rect) {
            throw GridError.occupied(position: rect.position)
        }
        for position in rect.positions {
            cells[cellIndex(for: position)] = true
        }
    }
    
    private func isFree(for rect: GridRect) -> Bool {
        guard rect.maxX < columns else { return false }
        for position in rect.positions {
            if cells[cellIndex(for: position)] { return false }
        }
        return true
    }
    
    private func validate(rect: GridRect) throws {
        if rect.maxX >= columns {
            throw GridError.invalidItemSize(size: rect.size, columns: columns)
        }
    }
    
    private func cellIndex(for position: GridPoint) -> Int {
        position.y * columns + position.x
    }
}
