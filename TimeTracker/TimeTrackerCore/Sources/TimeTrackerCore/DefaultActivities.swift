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
        Spec(name: "Food", icon: "fork.knife", colorHex: "#D08C34"),
        Spec(name: "Dog / Pet", icon: "pawprint.fill", colorHex: "#9C6B3F"),
        Spec(name: "Exercise", icon: "figure.run", colorHex: "#C6522E"),
        Spec(name: "Social", icon: "person.2.fill", colorHex: "#C98A5B"),
        Spec(name: "Commute", icon: "car.fill", colorHex: "#8A6A55"),
        Spec(name: "Personal Care", icon: "drop.fill", colorHex: "#B98B6B"),
        Spec(name: "Housework", icon: "house.fill", colorHex: "#A9743E"),
        Spec(name: "Learning", icon: "book.fill", colorHex: "#8C5A3C"),
        Spec(name: "Entertainment", icon: "tv.fill", colorHex: "#BE7A45"),
        Spec(name: "Phone / Social Media", icon: "iphone", colorHex: "#9E8558"),
        Spec(name: "Sleep", icon: "bed.double.fill", colorHex: "#6F5B7A")
    ]
}
