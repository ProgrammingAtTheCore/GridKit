# GridKit

GridKit is a flexible and lightweight grid layout system for SwiftUI.
It allows you to arrange views of varying sizes in a structured, widget-like grid while keeping the layout code clear and easy to maintain.
Additionally, GridKit includes built-in Drag & Drop support, enabling users to rearrange items directly within the grid.

## Features

- Configurable grid layout with a custom number of columns
- Items can define their own width and height in grid units
- Automatic placement based on item order
- Built-in Drag & Drop repositioning

## Example

```swift
@State var items: [GridItem] = [
    GridItem(width: 2, height: 2) { simpleView(number: 1) },
    GridItem(width: 2, height: 1) { simpleView(number: 2) },
    GridItem(width: 1, height: 1) { simpleView(number: 3) },
    GridItem(width: 1, height: 1) { simpleView(number: 4) }
]

var body: some View {
    GridView(columns: 4, spacing: 8, items: $items)
        .padding()
}
```

This example generates a layout sonsistin of:
- One larger element (2x2)
- One wide element (2x1)
- Two smaller square elements (1x1 each)

All arranged within a 4-column grid.

## Widgets
GridKit also provides a widget layer that supports multiple sizes per widget.

```swift
@State var widgets: [GridWidget] = [
    GridWidget(supportedSizes: [.square(with: 1), GridSize(width: 2, height: 1)]) { size in
        widgetView(size: size)
    }
]

var body: some View {
    WidgetGridView(columns: 4, spacing: 8, widgets: $widgets)
}
```

## Installation
### Swift Package Manager
1. In XCode open:
    File -> Add Packages
2. Enter the repository URL:
```
https://github.com/ProgrammingAtTheCore/GridKit.git
```
3. Add the package to your project.

## Getting Started
For usage guidance, examples, and best pratices, see the DocC documentation, on Xcode
