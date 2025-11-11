//
//  Grid.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 10/31/2025.
//


import SwiftUI

struct GridConfig {
    var isEditing: Bool = false
    var showAnimations: Bool = false
    var dragAndDrop: Bool = true
 
    var deletionButtonAlignment: Alignment = .topLeading
    var deletionButtonLabel: AnyView = AnyView(Image(systemName: "minus"))
}

struct GridMap {
    let width: Int
    var maxHeight: Int = 2
    
    private(set) var cells: [Bool]
    
    init(width: Int) {
        self.width = width
        
        self.cells = Array(repeating: false, count: width * maxHeight)
    }
    
    mutating func place(elements: [GridElement], dragElement: GridElement? = nil) throws -> [GridElement] {
        self.freeAll()
        var result: [GridElement] = []
        
        var rect: GridRect = .standard
        var draggingPlaced: Bool = false
        for element in elements {
            while true {
                rect.size = element.size
                //print("Try Placing Element at: \(rect.position) with size: \(rect.size)")
                
                if let dragging = dragElement,
                   rect.positions.contains(where: dragging.rect.positions.contains),
                   !draggingPlaced {
                    
                    //print("Placing dragging...")
                    
                    if rect.position == dragging.position {
                        try occupy(for: dragging.rect)
                        result.append(dragging)
                        draggingPlaced = true
                        
                        rect.position = nextStep(position: dragging.position, steps: dragging.size.width)
                        //print("✅ Dragging Placed. New placing position at: \(rect.position)")
                    } else {
                        rect.position = nextStep(position: rect.position)
                        //print("⚠️ Element cant be placed because it would collide with dragging. New palcing position at: \(rect.position)")
                    }
                } else {
                    do {
                        try occupy(for: rect)
                        
                        var newElement: GridElement = element
                        newElement.position = rect.position
                        result.append(newElement)
                        
                        rect.position = nextStep(position: rect.position, steps: rect.size.width)
                        //print("Element Placed. New placing position at: \(rect.position)")
                        break
                    } catch GridError.occupied(_) {
                        //print("Position: \(rect.position) is already occupied.")
                        rect.position = nextStep(position: rect.position)
                    } catch GridError.outOfBounds(let position) {
                        if rect.maxX >= width {
                            rect.position = GridPoint(x: 0, y: rect.position.y + 1)
                            //print("\(position) - Out of bounds. New Placing Position at: \(rect.position)")
                        } else {
                            self.cells += Array(repeating: false, count: width * (position.y + 1 - maxHeight))
                            maxHeight = position.y + 1
                            //print("Max Height changed to: \(maxHeight)")
                        }
                    } catch {
                        throw error
                    }
                }
            }
        }

        if !draggingPlaced,
           let dragging = dragElement {
            if dragging.rect.maxY >= maxHeight {
                maxHeight += dragging.size.height
                self.cells += Array(repeating: false, count: width * dragging.size.height)
                
            }
            try occupy(for: dragging.rect)
            result.append(dragging)
        }
        maxHeight = (result.last?.rect.maxY ?? 0) + 1
        
        return result
    }
    
    mutating func place(element: GridElement) throws -> GridElement {
        let size: GridSize = element.size
        var resultDimension: GridRect = GridRect(size: size)
        
        for y in (0...(maxHeight - size.height)) {
            for x in (0...width - size.width) {
                let position: GridPoint = GridPoint(x: x, y: y)
                resultDimension.position = position
                
                do {
                    try occupy(for: resultDimension)
                    var newElement: GridElement = element
                    newElement.position = position
                    
                    return newElement
                } catch GridError.occupied(position: position) {
                    continue
                } catch {
                    throw error
                }
            }
        }
        throw GridError.unknown
    }
    
    private func nextStep(position: GridPoint, steps: Int = 1) -> GridPoint {
        var newPosition: GridPoint = position
        
        newPosition.x += steps
        if newPosition.x >= width {
            newPosition.x = 0
            newPosition.y += 1
        }
        
        return newPosition
    }
    
    private mutating func occupy(x: Int, y: Int) throws {
        try self.occupy(for: GridPoint(x: x, y: y))
    }
    
    private mutating func occupy(for position: GridPoint) throws {
        guard try isFree(position: position) else { throw GridError.unknown }
        cells[cellIndex(for: position)] = true
    }
    
    private mutating func occupy(for rect: GridRect) throws {
        guard try isFree(for: rect) else { throw GridError.unknown }
        
        for position in rect.positions {
            cells[cellIndex(for: position)] = true
        }
    }
    
    private mutating func free(x: Int, y: Int) throws {
        try self.free(for: GridPoint(x: x, y: y))
    }
    
    private mutating func free(for position: GridPoint) throws {
        _ = try isValid(position: position)
        cells[cellIndex(for: position)] = false
    }
    
    private mutating func free(for rect: GridRect) throws {
        _ = try isValid(for: rect)
        
        for position in rect.positions {
            cells[cellIndex(for: position)] = false
        }
    }
    
    private mutating func freeAll() {
        cells = Array(repeating: false, count: width * maxHeight)
    }
    
    private func isFree(x: Int, y: Int) throws -> Bool {
        return try self.isFree(position: GridPoint(x: x, y: y))
    }
    
    private func isFree(position: GridPoint) throws -> Bool {
        _ = try isValid(position: position)
        if cells[cellIndex(for: position)] { throw GridError.occupied(position: position) }
        
        return true
    }
    
    private func isFree(for rect: GridRect) throws -> Bool {
        _ = try isValid(for: rect)
        
        for position in rect.positions {
            if cells[cellIndex(for: position)] { throw GridError.occupied(position: position) }
        }
        
        return true
    }
    
    private func isValid(x: Int, y: Int) throws -> Bool {
        if (x < width && y < maxHeight) {
            return true
        } else {
            throw GridError.outOfBounds(position: GridPoint(x: x, y: y))
        }
    }
    
    private func isValid(position: GridPoint) throws -> Bool {
        return try self.isValid(x: position.x, y: position.y)
    }
    
    private func isValid(for rect: GridRect) throws -> Bool {
        return try self.isValid(x: rect.maxX, y: rect.maxY)
    }
    
    private func cellIndex(x: Int, y: Int) -> Int {
        return y * width + x
    }
    
    private func cellIndex(for position: GridPoint) -> Int {
        return self.cellIndex(x: position.x, y: position.y)
    }
}

extension GridMap {
    init(width: CGFloat) {
        self.init(width: Int(width))
    }
}
