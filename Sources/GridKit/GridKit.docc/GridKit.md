# ``GridKit``
A flexible, grid layout system that allows elements of varying sizes to flow seamlessly into a clean, adaptive interface.

## Overview
``GridKit`` provides a felxible, widget-style gird layout system for SwiftUI. It allows you to place elements of diffrent sizes into a structured grid without manually calculating positions or coordinates. Each item defines the amount of space it occupies using grid untis, and the layout addapts automatically to the available area.

At the core of ``GridKit`` are two types:

- ``GridItem`` describes a single item and the view it displays.
- ``GridSize`` defines how much horizontal and vertical space the item occupies.

These elements are displayed using ``GridView``, which arranges items in sequence based on the number of columns you specify. The grid automatically aligns items to maintain a clear and consistent layout, even when items differ in scale or shape.

On top of the core grid system, ``GridWidget`` provides a widget layer. Widgets can support multiple sizes (for example 1x1 or 2x1) and render different views depending on their active size. Use ``WidgetGridView`` to display widgets in the same grid engine.

``GridKit`` is designed for interfaces wher visual structure matters, such as dashboards, customizable layoutsm or widget-like surfaces. By woking in grid units rather than raw pixel values, the layout remains adaptable across screen sizes and device enviroments.
