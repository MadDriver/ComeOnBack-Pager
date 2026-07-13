//
//  PlanView.swift
//  ComeOnBack Pager
//
//  Create a planned position ("split LC2 @ 0940") — pick a position + a time
//  (clock / ASAP / SOON). One plan per position: a 409 surfaces an "Overwrite?"
//  confirm that retries with `overwrite: true`. Mirrors `PlanModal.svelte`.
//

import SwiftUI
import OSLog

struct PlanView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "PlanView")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel

    @State private var position: String?
    @State private var timeString: String?
    @State private var clockMinutes: Int?
    @State private var selectedPreset: String?
    @State private var timePicker: TimeASAPPicker = .normal

    @State private var working = false
    @State private var overwritePrompt = false
    @State private var errorMessage: String?

    private let beBackMinutes = ["10", "15", "30", "40"]
    private let positionColumns = [GridItem(.adaptive(minimum: 90))]

    /// Every position defined across the facility's areas (deduped, order-preserving).
    private var knownPositions: [String] {
        var seen = Set<String>()
        return (pagingVM.facility?.areas ?? [])
            .flatMap { $0.positions.compactMap { $0 } }
            .filter { seen.insert($0).inserted }
    }

    private var existingPlan: PlannedPosition? {
        guard let position else { return nil }
        return pagingVM.plannedPositions.first { $0.position.uppercased() == position.uppercased() }
    }

    private var isSubmittable: Bool { !working && position != nil && timeString != nil }

    var body: some View {
        NavigationStack {
            Group {
                if overwritePrompt {
                    overwriteConfirm
                } else {
                    form
                }
            }
            .navigationTitle("Plan a Position")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("POSITION").fontWeight(.heavy)
                LazyVGrid(columns: positionColumns, spacing: 12) {
                    ForEach(knownPositions, id: \.self) { pos in
                        Button {
                            position = (position == pos) ? nil : pos
                        } label: {
                            Text(pos).bold()
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(position == pos ? Color.yellow : Color.red.opacity(0.4))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("TIME").fontWeight(.heavy)
                Picker("Time", selection: $timePicker) {
                    ForEach(TimeASAPPicker.allCases) { Text($0.description) }
                }
                .pickerStyle(.segmented)
                .onChange(of: timePicker) { _ in
                    switch timePicker {
                    case .normal: minuteSelected(clockMinutes)
                    case .asap: timeString = "ASAP"
                    case .soon: timeString = "SOON"
                    }
                }

                if timePicker == .normal {
                    HStack {
                        ClockView(selectedMinute: clockMinutes, onMinuteSelected: minuteSelected)
                            .frame(width: 320, height: 320)
                        VStack {
                            ForEach(beBackMinutes, id: \.self) { minute in
                                Text("\(minute) mins").fontWeight(.bold)
                                    .frame(width: 100, height: 44)
                                    .background(selectedPreset == minute ? Color.yellow : Color.blue.opacity(0.5))
                                    .onTapGesture {
                                        guard let mins = Int(minute) else { return }
                                        minuteSelected(pagingVM.roundUpToNext5Minutes(minutes: mins))
                                        selectedPreset = minute
                                    }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text(timePicker.description).font(.largeTitle).bold()
                        .frame(maxWidth: .infinity).padding()
                }

                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }

                Button(action: { create(overwrite: false) }) {
                    HStack {
                        if working { ProgressView().tint(.white) }
                        Text("CREATE PLAN")
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isSubmittable)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var overwriteConfirm: some View {
        VStack(spacing: 20) {
            Text("A plan for \(position ?? "") already exists"
                 + (existingPlan.map { " (@ \(displayTime($0.time))\($0.status == "paged" ? ", already paged" : ""))" } ?? "")
                 + ". Overwrite it?")
                .multilineTextAlignment(.center)
            if existingPlan?.status == "paged" {
                Text("The outstanding page it created will be cancelled.")
                    .font(.caption).foregroundColor(.secondary)
            }
            HStack(spacing: 24) {
                Button("Back") { overwritePrompt = false }
                    .buttonStyle(.bordered)
                Button("Overwrite", role: .destructive) { create(overwrite: true) }
                    .buttonStyle(.borderedProminent)
                    .disabled(working)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func minuteSelected(_ minute: Int?) {
        if let minute, let date = Calendar.current.date(bySetting: .minute, value: minute, of: Date()) {
            clockMinutes = minute
            selectedPreset = nil
            timeString = BasicTime(fromDate: date)?.stringValue
        } else {
            clockMinutes = nil
            selectedPreset = nil
            timeString = nil
        }
    }

    private func create(overwrite: Bool) {
        guard let position, let timeString else { return }
        working = true
        errorMessage = nil
        Task {
            do {
                try await pagingVM.createPlanned(position: position, time: timeString, overwrite: overwrite)
                await MainActor.run { dismiss() }
            } catch APIError.conflict {
                await MainActor.run { overwritePrompt = true }
            } catch {
                await MainActor.run { errorMessage = "Couldn't create the plan." }
                logger.error("createPlanned: \(error)")
            }
            await MainActor.run { working = false }
        }
    }
}

#if DEBUG
struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView().environmentObject(PagingViewModel.preview)
    }
}
#endif
