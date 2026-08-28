import SwiftUI
import SwiftData
import TimeFlowCore

/// Stage 1 is a single screen: date, current period, capture control, today's
/// timeline. No bottom navigation yet.
struct TodayView: View {
    @Environment(TimelineStore.self) private var store

    @State private var labelingPeriodID: PersistentIdentifier?
    @State private var editingPeriodID: PersistentIdentifier?
    @State private var undoDismissTask: Task<Void, Never>?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
        .background(AutumnTheme.background)
        .sheet(item: labelingBinding) { period in
            ActivityPickerSheet(period: period)
                .environment(store)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: editingBinding) { period in
            PeriodEditorSheet(period: period)
                .environment(store)
        }
        .onChange(of: store.lastCapture?.at) { _, newValue in
            undoDismissTask?.cancel()
            guard newValue != nil else { return }
            undoDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(10))
                if !Task.isCancelled { store.clearUndo() }
            }
        }
    }

    private func content(now: Date) -> some View {
        VStack(spacing: 0) {
            header(now: now)

            // Summary + capture control stay outside the scroll view so the
            // press-and-hold gesture never competes with scrolling.
            VStack(spacing: 24) {
                currentSummary(now: now)

                CaptureControl(isTracking: store.isTracking) { timestamp in
                    do {
                        try store.capture(at: timestamp)
                    } catch {
                        // A capture that loses the ordering race is safely ignored.
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)

            ScrollView {
                timelineSection(now: now)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .bottom) {
            if store.lastCapture != nil {
                UndoPill {
                    _ = try? store.undoLastCapture()
                }
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.lastCapture?.at)
    }

    private func header(now: Date) -> some View {
        HStack {
            Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.headline)
                .foregroundStyle(AutumnTheme.primaryText)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func currentSummary(now: Date) -> some View {
        if let open = store.openPeriod {
            CurrentPeriodCard(period: open, now: now) {
                labelingPeriodID = open.persistentModelID
            }
        } else {
            VStack(spacing: 6) {
                Text("Ready when you are")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AutumnTheme.primaryText)
                Text("Start tracking to create your first point in time.")
                    .font(.subheadline)
                    .foregroundStyle(AutumnTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    @ViewBuilder
    private func timelineSection(now: Date) -> some View {
        let segments = DayTimeline.segments(for: store.periods, on: now, reference: now)
        if !segments.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("TODAY")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(AutumnTheme.secondaryText)
                    .padding(.bottom, 12)

                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    if let period = store.period(with: segment.period) {
                        TimelineRow(
                            segment: segment,
                            now: now,
                            isFirst: index == 0,
                            isLast: index == segments.count - 1
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { labelingPeriodID = period.persistentModelID }
                        .contextMenu {
                            Button("Label…") { labelingPeriodID = period.persistentModelID }
                            Button("Edit times…") { editingPeriodID = period.persistentModelID }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sheet bindings

    private var labelingBinding: Binding<Period?> {
        Binding(
            get: { labelingPeriodID.flatMap(store.period(with:)) },
            set: { labelingPeriodID = $0?.persistentModelID }
        )
    }

    private var editingBinding: Binding<Period?> {
        Binding(
            get: { editingPeriodID.flatMap(store.period(with:)) },
            set: { editingPeriodID = $0?.persistentModelID }
        )
    }
}
