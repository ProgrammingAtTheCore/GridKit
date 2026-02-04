//
//  GridPersistence.swift
//  GridKit
//
//  Created by ProgrammingAtTheCore on 02/04/2026.
//

import Foundation

public struct GridItemLayout: Codable, Equatable, Hashable {
    public let id: UUID
    public var position: GridPoint
    public var size: GridSize
    
    public init(id: UUID, position: GridPoint, size: GridSize) {
        self.id = id
        self.position = position
        self.size = size
    }
}

public struct GridWidgetLayout: Codable, Equatable, Hashable {
    public let id: UUID
    public var position: GridPoint
    public var size: GridSize
    
    public init(id: UUID, position: GridPoint, size: GridSize) {
        self.id = id
        self.position = position
        self.size = size
    }
}

public enum GridLayoutStoreError: Error, LocalizedError, Equatable {
    case invalidName(String)
    case layoutNotFound(name: String, kind: GridLayoutStore.Kind)
    
    public var errorDescription: String? {
        switch self {
        case let .invalidName(name):
            return "Layout name \"\(name)\" is not valid."
        case let .layoutNotFound(name, kind):
            return "No \(kind.rawValue) layout named \"\(name)\" was found."
        }
    }
}

public struct GridLayoutStore {
    public enum Kind: String, Codable, CaseIterable {
        case items
        case widgets
    }
    
    public static let defaultLayoutName = "Default"
    
    public static var defaultDirectory: URL {
        let fileManager = FileManager.default
        if let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return base
                .appendingPathComponent("GridKit", isDirectory: true)
                .appendingPathComponent("Layouts", isDirectory: true)
        }
        return fileManager.temporaryDirectory.appendingPathComponent("GridKitLayouts", isDirectory: true)
    }
    
    public let directory: URL
    
    public init(directory: URL = GridLayoutStore.defaultDirectory) {
        self.directory = directory
    }
    
    public func save(items: [GridItem], name: String = GridLayoutStore.defaultLayoutName) throws {
        let layouts = items.layoutSnapshot()
        try save(layouts: layouts, name: name, kind: .items)
    }
    
    public func save(widgets: [GridWidget], name: String = GridLayoutStore.defaultLayoutName) throws {
        let layouts = widgets.layoutSnapshot()
        try save(layouts: layouts, name: name, kind: .widgets)
    }
    
    public func loadItemLayouts(name: String = GridLayoutStore.defaultLayoutName) throws -> [GridItemLayout] {
        try load(layoutType: [GridItemLayout].self, name: name, kind: .items)
    }
    
    public func loadWidgetLayouts(name: String = GridLayoutStore.defaultLayoutName) throws -> [GridWidgetLayout] {
        try load(layoutType: [GridWidgetLayout].self, name: name, kind: .widgets)
    }
    
    private func save<Layout: Codable>(layouts: [Layout], name: String, kind: Kind) throws {
        let normalizedName = normalize(name)
        let url = try fileURL(for: normalizedName, kind: kind)
        try ensureDirectoryExists()
        
        let container = GridLayoutContainer(name: normalizedName, layouts: layouts)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(container)
        try data.write(to: url, options: [.atomic])
    }
    
    private func load<Layout: Codable>(layoutType: [Layout].Type, name: String, kind: Kind) throws -> [Layout] {
        let normalizedName = normalize(name)
        let url = try fileURL(for: normalizedName, kind: kind)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw GridLayoutStoreError.layoutNotFound(name: normalizedName, kind: kind)
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let container = try decoder.decode(GridLayoutContainer<Layout>.self, from: data)
        return container.layouts
    }
    
    private func ensureDirectoryExists() throws {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: directory.path) else { return }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    
    private func fileURL(for name: String, kind: Kind) throws -> URL {
        let safeName = sanitize(name)
        guard !safeName.isEmpty else {
            throw GridLayoutStoreError.invalidName(name)
        }
        return directory.appendingPathComponent("\(kind.rawValue)_\(safeName).json")
    }
    
    private func sanitize(_ name: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        let scalars = name.unicodeScalars.map { allowed.contains($0) ? $0 : "_" }
        return String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func normalize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? GridLayoutStore.defaultLayoutName : trimmed
    }
}

private struct GridLayoutContainer<Layout: Codable>: Codable {
    let name: String
    let layouts: [Layout]
}

public extension Array where Element == GridItem {
    func layoutSnapshot() -> [GridItemLayout] {
        map { GridItemLayout(id: $0.id, position: $0.position, size: $0.size) }
    }
    
    mutating func applyLayouts(_ layouts: [GridItemLayout]) {
        let lookup = Dictionary(uniqueKeysWithValues: layouts.map { ($0.id, $0) })
        for index in indices {
            guard let layout = lookup[self[index].id] else { continue }
            self[index].position = layout.position
            self[index].size = layout.size
        }
    }
    
    func applyingLayouts(_ layouts: [GridItemLayout]) -> [GridItem] {
        var copy = self
        copy.applyLayouts(layouts)
        return copy
    }
}

public extension Array where Element == GridWidget {
    func layoutSnapshot() -> [GridWidgetLayout] {
        map { GridWidgetLayout(id: $0.id, position: $0.position, size: $0.size) }
    }
    
    mutating func applyLayouts(_ layouts: [GridWidgetLayout]) {
        let lookup = Dictionary(uniqueKeysWithValues: layouts.map { ($0.id, $0) })
        for index in indices {
            guard let layout = lookup[self[index].id] else { continue }
            self[index].position = layout.position
            self[index].setSize(layout.size)
        }
    }
    
    func applyingLayouts(_ layouts: [GridWidgetLayout]) -> [GridWidget] {
        var copy = self
        copy.applyLayouts(layouts)
        return copy
    }
}
