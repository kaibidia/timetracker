import SwiftUI
import TimeTrackerCore

/// Lightweight labelling surface for one period. Opened by tapping a period —
/// never automatically after a capture.
struct ActivityPickerSheet: View {
    let period: Period
    @Environment(TimelineStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewActivity = false

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    periodHeader

                    if !recents.isEmpty {
                        section("RECENT") {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(recents) { activity in
                                    chip(for: activity)
                                }
                            }
                        }
                    }

                    section("ALL ACTIVITIES") {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(store.activities) { activity in
                                chip(for: activity)
                            }
                            newActivityChip
                        }
                    }

                    if period.activity != nil {
                        Button(role: .destructive) {
                            try? store.setActivity(nil, for: period)
                            dismiss()
                        } label: {
                            Label("Mark unclassified", systemImage: "xmark.circle")
                        }
                        .font(.subheadline)
                    }
                }
                .padding(20)
            }
            .background(AutumnTheme.background)
            .navigationTitle("Label period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewActivity) {
                NewActivitySheet { activity in
                    try? store.setActivity(activity, for: period)
                    dismiss()
                }
                .environment(store)
            }
        }
    }

    private var recents: [Activity] {
        store.recentActivities().filter { $0.persistentModelID != period.activity?.persistentModelID }
    }

    private var periodHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Clock.time(period.startTime)) – \(period.isOpen ? "now" : Clock.time(period.endTime!))")
                .font(.headline)
                .foregroundStyle(AutumnTheme.primaryText)
            Text(DurationFormat.short(period.duration()))
                .font(.subheadline)
                .foregroundStyle(AutumnTheme.secondaryText)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .tracking(1.3)
                .foregroundStyle(AutumnTheme.secondaryText)
            content()
        }
    }

    private func chip(for activity: Activity) -> some View {
        let selected = activity.persistentModelID == period.activity?.persistentModelID
        return Button {
            Haptics.selection()
            try? store.setActivity(activity, for: period)
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: activity.iconSystemName)
                    .foregroundStyle(activity.color)
                Text(activity.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AutumnTheme.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? activity.color.opacity(0.18) : AutumnTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? activity.color : AutumnTheme.hairline, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var newActivityChip: some View {
        Button {
            showingNewActivity = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("New activity")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundStyle(AutumnTheme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(AutumnTheme.surface))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AutumnTheme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
        .buttonStyle(.plain)
    }
}
