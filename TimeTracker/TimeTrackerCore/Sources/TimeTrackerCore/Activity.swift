import Foundation
import SwiftData

/// A reusable label the user can attach to a period of time.
///
/// An activity is fundamentally *name + icon + color*. Built-in and custom
/// activities use this same model; `isBuiltIn` only affects default ordering
/// and is not otherwise privileged.
@Model
public final class Activity {
    public private(set) var id: UUID
    public var name: String
    /// SF Symbol name.
    public var iconSystemName: String
    /// Hex string like `#C96F3F`, resolved to a `Color` in the UI layer.
    public var colorHex: String
    public private(set) var createdAt: Date
    public var isArchived: Bool
    public private(set) var isBuiltIn: Bool
    /// Ascending display order in pickers and lists.
    public var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Period.activity)
    public var periods: [Period] = []

    public init(
        id: UUID = UUID(),
        name: String,
        iconSystemName: String,
        colorHex: String,
        createdAt: Date = .now,
        isArchived: Bool = false,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}
