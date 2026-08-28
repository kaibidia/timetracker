import SwiftUI
import TimeTrackerCore

/// Manual correction for one period: move its shared boundaries, split it, or
/// merge it with a neighbour. All edits go through `TimelineStore`, which keeps
/// the timeline continuous.
struct PeriodEditorSheet: View {
    let period: Period
    @Environment(TimelineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingSplit = false
    @State private var splitDate = Date.now
    @State private var mergeRequest: MergeRequest?

    private struct MergeRequest: Identifiable {
        let id = UUID()
        let earlier: Period
        let earlierName: String
        let laterName: String
    }

    private var previous: Period? { store.periodImmediatelyBefore(period) }
    private var next: Period? { store.periodImmediatelyAfter(period) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Period") {
                    LabeledContent("Start", value: Clock.time(period.startTime))
                    LabeledContent("End", value: period.isOpen ? "now" : Clock.time(period.endTime!))
                    LabeledContent("Duration", value: DurationFormat.short(period.duration()))
                    LabeledContent("Activity", value: period.activity?.name ?? "Unclassified")
                }

                if let startRange {
                    Section("Move start boundary") {
                        DatePicker(
                            "Start time",
                            selection: startBinding,
                            in: startRange,
                            displayedComponents: [.hourAndMinute]
                        )
                        Text("Also moves the end of the previous period.")
                            .font(.footnote)
                            .foregroundStyle(AutumnTheme.secondaryText)
                    }
                }

                if let endRange {
                    Section("Move end boundary") {
                        DatePicker(
                            "End time",
                            selection: endBinding,
                            in: endRange,
                            displayedComponents: [.hourAndMinute]
                        )
                        Text("Also moves the start of the next period.")
                            .font(.footnote)
                            .foregroundStyle(AutumnTheme.secondaryText)
                    }
                }

                if let splitRange {
                    Section("Split period") {
                        if showingSplit {
                            DatePicker("At", selection: $splitDate, in: splitRange, displayedComponents: [.hourAndMinute])
                            Button("Split here") {
                                try? store.insertBoundary(in: period, at: splitDate)
                                dismiss()
                            }
                        } else {
                            Button("Split this period…") {
                                splitDate = splitRange.lowerBound.addingTimeInterval(
                                    splitRange.upperBound.timeIntervalSince(splitRange.lowerBound) / 2
                                )
                                showingSplit = true
                            }
                        }
                    }
                }

                Section("Merge") {
                    if previous != nil {
                        Button("Merge with previous period") { requestMerge(after: previous!) }
                    }
                    if next != nil {
                        Button("Merge with next period") { requestMerge(after: period) }
                    }
                    if previous == nil && next == nil {
                        Text("No adjacent period to merge with.")
                            .font(.footnote)
                            .foregroundStyle(AutumnTheme.secondaryText)
                    }
                }
            }
            .navigationTitle("Edit times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "These periods have different activities",
                isPresented: mergeDialogPresented,
                presenting: mergeRequest
            ) { request in
                Button("Keep \(request.earlierName)") { performMerge(request, .keepEarlier) }
                Button("Keep \(request.laterName)") { performMerge(request, .keepLater) }
                Button("Leave unclassified") { performMerge(request, .unclassified) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Boundary ranges & bindings

    /// Range for the start boundary: strictly between the previous period's start
    /// and this period's end (or now).
    private var startRange: ClosedRange<Date>? {
        guard let previous else { return nil }
        let lower = previous.startTime.addingTimeInterval(60)
        let upper = (period.endTime ?? .now).addingTimeInterval(-60)
        return lower < upper ? lower...upper : nil
    }

    private var endRange: ClosedRange<Date>? {
        guard let next, !period.isOpen else { return nil }
        let lower = period.startTime.addingTimeInterval(60)
        let upper = (next.endTime ?? .now).addingTimeInterval(-60)
        return lower < upper ? lower...upper : nil
    }

    private var splitRange: ClosedRange<Date>? {
        let lower = period.startTime.addingTimeInterval(60)
        let upper = (period.endTime ?? .now).addingTimeInterval(-60)
        return lower < upper ? lower...upper : nil
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: { period.startTime },
            set: { newValue in
                guard let previous else { return }
                try? store.moveBoundary(after: previous, to: newValue)
            }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { period.endTime ?? .now },
            set: { newValue in try? store.moveBoundary(after: period, to: newValue) }
        )
    }

    // MARK: - Merge

    private var mergeDialogPresented: Binding<Bool> {
        Binding(
            get: { mergeRequest != nil },
            set: { if !$0 { mergeRequest = nil } }
        )
    }

    private func requestMerge(after earlier: Period) {
        if store.boundaryDeleteNeedsResolution(after: earlier) {
            let later = store.periodImmediatelyAfter(earlier)
            mergeRequest = MergeRequest(
                earlier: earlier,
                earlierName: earlier.activity?.name ?? "Unclassified",
                laterName: later?.activity?.name ?? "Unclassified"
            )
        } else {
            try? store.deleteBoundary(after: earlier)
            dismiss()
        }
    }

    private func performMerge(_ request: MergeRequest, _ resolution: MergeResolution) {
        try? store.deleteBoundary(after: request.earlier, resolution: resolution)
        mergeRequest = nil
        dismiss()
    }
}
