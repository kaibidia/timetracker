import Foundation

/// The small starter set seeded on first launch. Not authoritative — the user
/// can archive any of these and create their own.
public enum DefaultActivities {
    public struct Spec: Sendable {
        public let name: String
        public let icon: String
        public let colorHex: String
    }

    public static let all: [Spec] = [
        Spec(name: "Work", icon: "laptopcomputer", colorHex: "#B5643C"),
        Spec(name: "Food", icon: "fork.knife", colorHex: "#E67C3C"),
        Spec(name: "Dog / Pet", icon: "pawprint.fill", colorHex: "#9B4D3A"),
        Spec(name: "Exercise", icon: "figure.run", colorHex: "#C25E3A"),
        Spec(name: "Social", icon: "person.2.fill", colorHex: "#C77D5A"),
        Spec(name: "Commute", icon: "car.fill", colorHex: "#8C5A3C"),
        Spec(name: "Personal Care", icon: "drop.fill", colorHex: "#D98A4E"),
        Spec(name: "Housework", icon: "house.fill", colorHex: "#A34A5E"),
        Spec(name: "Learning", icon: "book.fill", colorHex: "#6D3A4E"),
        Spec(name: "Entertainment", icon: "tv.fill", colorHex: "#E0A15C"),
        Spec(name: "Phone / Social Media", icon: "iphone", colorHex: "#7A4A5C"),
        Spec(name: "Sleep", icon: "bed.double.fill", colorHex: "#5E4A6B")
    ]
}
