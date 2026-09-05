//
//  PagingView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/11/23.
//
//  The page modal. Works on a `PageTarget` — a single controller or a whole training
//  team (R2). The time picker (clock / ASAP / SOON) and position grid are shared; the
//  submit routes to the controller or team endpoint, and teams gain move-on/off +
//  split affordances. After a direct page whose position matches an unassigned plan,
//  the §9.2 reconciliation prompt offers to associate or delete that plan.
//

import SwiftUI
import OSLog

/// What a page acts on: one controller, or a training team (paged in lockstep).
enum PageTarget: Hashable {
    case controller(Controller)
    case team(TeamUnit)
}

enum TimeASAPPicker: CaseIterable, Identifiable {
    case normal
    case asap
    case soon

    var id: Self { self }

    var description: String {
        switch self {
        case .normal:
            return "Normal"
        case .asap:
            return "ASAP"
        case .soon:
            return "SOON"
        }
    }
}

struct PagingView: View {
    let beBackMinutes = [
        "10", "15", "30", "40"
    ]

    private let logger = Logger(subsystem: Logger.subsystem, category: "PagingView")

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel

    // The current selected time/position
    @State var beBackTimeString: String?
    @State var beBackPosition: String?

    // Handle the two sources of user input
    @State var clockBeBackMinutes: Int?
    @State var selectedBeBackMinutes: String?
    @State var timePicker: TimeASAPPicker = .normal

    @State var pageButtonPresssed: Bool = false
    /// Set after a direct page whose position matches an unassigned plan (§9.2); drives
    /// the reconciliation prompt instead of an immediate dismiss.
    @State private var adoptPlan: PlannedPosition?
    @State private var teamActionInFlight = false

    var target: PageTarget

    /// The controller whose state drives the picker — the OJTI for a team (both members
    /// share the be-back / status).
    private var lead: Controller {
        switch target {
        case .controller(let controller): return controller
        case .team(let unit): return unit.ojti
        }
    }
    private var isTeam: Bool { if case .team = target { return true }; return false }
    /// Teams always "page" (both members are rostered/registered-agnostic); a lone
    /// unregistered controller is "assigned" and alerted by phone.
    private var registered: Bool { isTeam ? true : lead.registered }
    private var label: String {
        switch target {
        case .controller(let controller): return controller.initials
        case .team(let unit): return unit.label
        }
    }

    var isSubmittable: Bool {
        !pageButtonPresssed &&
        beBackTimeString != nil
    }
    var beBackText: String {
        let verb = registered ? "Page" : "Assign"
        guard let time = beBackTimeString else { return "\(verb) \(label)" }
        // "at" reads right only for clock times — sentinels flow directly
        // ("Page BB ASAP", not "Page BB at ASAP").
        let timePhrase = (try? BasicTime(time)) != nil ? "at \(time)" : time
        guard let position = beBackPosition else {
            return "\(verb) \(label) \(timePhrase)"
        }
        return "\(verb) \(label) \(timePhrase) for \(position)"
    }

    var body: some View {
        Group {
            if lead.status == .ON_POSITION {
                teamOnPositionView
            } else {
                pagingBody
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .confirmationDialog(
            adoptPromptTitle,
            isPresented: Binding(get: { adoptPlan != nil }, set: { if !$0 { adoptPlan = nil; dismiss() } }),
            titleVisibility: .visible
        ) {
            if !isTeam {
                // assign_team has no adopt path — associate is single-controller only.
                Button("Associate this page with the plan") { reconcile(adopt: true) }
            }
            Button("Delete the unassigned plan", role: .destructive) { reconcile(adopt: false) }
            Button("Keep both", role: .cancel) { adoptPlan = nil; dismiss() }
        } message: {
            Text(adoptPromptMessage)
        }
    }

    @ViewBuilder
    private var pagingBody: some View {
        VStack(spacing: Spacing.lg) {
            Text(beBackText)
                .font(.title2).bold()
                .lineLimit(2).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: Spacing.xl) {
                positionGrid
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(spacing: Spacing.md) {
                    Picker("Time Picker type", selection: $timePicker) {
                        ForEach(TimeASAPPicker.allCases) { option in
                            Text(option.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    switch timePicker {
                    case .normal:
                        rightClockView
                    case .asap:
                        asapView
                    case .soon:
                        soonView
                    }
                    Spacer(minLength: 0)
                } // VStack
                .frame(maxWidth: .infinity)
            } // HStack

            pageButton

            if isTeam {
                teamSecondaryActions
            } else if !registered {
                Label("\(label) is not registered — page them via the phone system.",
                      systemImage: "phone.fill")
                    .foregroundColor(.pendingOrange)
                    .font(.callout)
            }
        } // VStack
        .onChange(of: timePicker) { _ in
            switch timePicker {
            case .normal:
                newMinuteSelected(minute: lead.beBack?.atTime?.minutes)
            case .asap:
                beBackTimeString = "ASAP"
            case .soon:
                beBackTimeString = "SOON"
            }
        }
        .onAppear {
            beBackTimeString = lead.beBack?.stringValue
            beBackPosition = lead.beBack?.forPosition
            if beBackTimeString == "ASAP" {
                timePicker = .asap
            } else if beBackTimeString == "SOON" {
                timePicker = .soon
            } else {
                clockBeBackMinutes = lead.beBack?.atTime?.minutes
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if lead.status == .PAGED_BACK {
                Button(role: .destructive, action: cancelPage) {
                    Label("Cancel page", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
    }

    private var pageButton: some View {
        Button(action: pageBack) {
            Text(registered ? "Page" : "Assign")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!isSubmittable)
    }

    /// Teams-only: move on position (with the selected position) and split, alongside
    /// the primary page button.
    @ViewBuilder
    private var teamSecondaryActions: some View {
        HStack(spacing: Spacing.xl) {
            Button {
                runTeamAction { unit in try await pagingVM.moveTeamOnPosition(unit, position: beBackPosition) }
            } label: {
                Label("Move on position", systemImage: "arrowshape.left")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(teamActionInFlight)

            Button(role: .destructive) {
                runTeamAction { unit in try await pagingVM.splitTeam(unit) }
            } label: {
                Label("Split team", systemImage: "person.2.slash")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(teamActionInFlight)
        }
    }

    /// Teams-only: shown when the team is plugged in together — move off / split.
    @ViewBuilder
    private var teamOnPositionView: some View {
        VStack(spacing: Spacing.xl) {
            Text(label)
                .font(.largeTitle).bold()
            Text("On position\(lead.position.map { " \($0)" } ?? "")")
                .font(.title2)
                .foregroundStyle(.secondary)
            Button {
                runTeamAction { unit in try await pagingVM.moveTeamOffPosition(unit) }
            } label: {
                Text("Move off position")
                    .font(.title3.bold())
                    .frame(maxWidth: 400, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(teamActionInFlight)
            Button(role: .destructive) {
                runTeamAction { unit in try await pagingVM.splitTeam(unit) }
            } label: {
                Label("Split team", systemImage: "person.2.slash")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(teamActionInFlight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var adoptPromptTitle: String {
        "Plan exists for \(adoptPlan?.position ?? "")"
    }
    private var adoptPromptMessage: String {
        guard let plan = adoptPlan else { return "" }
        return "\(label) was just paged for \(plan.position), and an unassigned plan for "
            + "\(plan.position) @ \(plan.time) exists. What should happen to the plan?"
    }

    @ViewBuilder
    private var asapView: some View {
        sentinelCircle(text: "ASAP", fill: .red)
    }

    @ViewBuilder
    private var soonView: some View {
        sentinelCircle(text: "SOON", fill: .pendingOrange)
    }

    private func sentinelCircle(text: String, fill: Color) -> some View {
        ZStack {
            Circle().fill(fill)
            Text(text).font(.title).bold().foregroundColor(.white)
        }
        .frame(maxWidth: 220)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.sm)
    }

    @ViewBuilder
    private var rightClockView: some View {
        ClockView(selectedMinute: clockBeBackMinutes, onMinuteSelected: newMinuteSelected)
            .frame(maxWidth: 360)
            .aspectRatio(1, contentMode: .fit)

        HStack(spacing: Spacing.sm) {
            ForEach(beBackMinutes, id: \.self) { minute in
                Button {
                    guard let minutesAsInt = Int(minute) else { return }
                    newMinuteSelected(minute: pagingVM.roundUpToNext5Minutes(minutes: minutesAsInt))
                    self.selectedBeBackMinutes = minute
                } label: {
                    SelectableChip(label: "\(minute) min", selected: selectedBeBackMinutes == minute, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// The position picker — an adaptive grid of chips that grows to fit instead of
    /// the old fixed 4-row grid clipped at 250pt.
    @ViewBuilder
    private var positionGrid: some View {
        if let facility = pagingVM.facility,
           let area = facility.getArea(forController: lead)
        {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader("Position")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: Spacing.sm)], spacing: Spacing.sm) {
                    ForEach(area.positions.compactMap { $0 }, id: \.self) { position in
                        Button {
                            beBackPosition = (beBackPosition == position) ? nil : position
                        } label: {
                            SelectableChip(label: position, selected: beBackPosition == position)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } // if let facility, area
    }
}

// MARK: Functions

extension PagingView {

    func newMinuteSelected(minute: Int?) {
        logger.debug("newTimeSelected \(String(describing:minute))")
        if let minutes = minute,
           let newDate = Calendar.current.date(bySetting: .minute, value: minutes, of: Date()) {
            let beBackTime = BasicTime(fromDate: newDate)
            self.clockBeBackMinutes = minutes
            self.selectedBeBackMinutes = nil
            self.beBackTimeString = beBackTime?.stringValue
        } else {
            self.clockBeBackMinutes = nil
            self.selectedBeBackMinutes = nil
            self.beBackTimeString = nil
        }
    }

    func cancelPage() {
        Task {
            do {
                switch target {
                case .controller(let controller):
                    try await pagingVM.removeBeBack(forController: controller)
                case .team(let unit):
                    try await pagingVM.cancelTeamPage(unit)
                }
            } catch {
                logger.error("cancelPage \(label): \(error)")
            }
            await MainActor.run { dismiss() }
        }
    }

    func pageBack() {
        guard let beBackTime = beBackTimeString else {
            logger.error("beBackTimeString must be defined before calling submitBeBack()")
            return
        }

        pageButtonPresssed = true
        Task {
            do {
                let beBack = BeBack(timeString: beBackTime, forPosition: beBackPosition)
                switch target {
                case .controller(let controller):
                    try await pagingVM.submitBeBack(beBack, forController: controller)
                case .team(let unit):
                    try await pagingVM.pageTeam(unit, beBack: beBack)
                }
                // §9.2: a direct page for a position that has an unassigned plan →
                // prompt to reconcile; otherwise close.
                await MainActor.run {
                    if let plan = pagingVM.matchingUnassignedPlan(forPosition: beBackPosition) {
                        adoptPlan = plan
                    } else {
                        dismiss()
                    }
                }
            } catch {
                logger.error("pageBack \(label): \(error)")
            }
            await MainActor.run { pageButtonPresssed = false }
        }
    }

    /// Resolve the §9.2 prompt: adopt the direct page into the plan, or delete the plan.
    private func reconcile(adopt: Bool) {
        guard let plan = adoptPlan else { return }
        Task {
            do {
                if adopt, case .controller(let controller) = target {
                    try await pagingVM.assignPlanned(
                        plan, controllerInitials: controller.initials, adoptExistingBeBack: true
                    )
                } else {
                    try await pagingVM.cancelPlanned(plan)
                }
            } catch {
                logger.error("reconcile plan \(plan.position): \(error)")
            }
            await MainActor.run { adoptPlan = nil; dismiss() }
        }
    }

    /// Run a team write with an in-flight guard, then close the modal.
    private func runTeamAction(_ action: @escaping (TeamUnit) async throws -> Void) {
        guard case .team(let unit) = target, !teamActionInFlight else { return }
        teamActionInFlight = true
        Task {
            do {
                try await action(unit)
            } catch {
                logger.error("team action \(label): \(error)")
            }
            await MainActor.run { teamActionInFlight = false; dismiss() }
        }
    }
}

#if DEBUG
struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        PagingView(target: .controller(Controller.mock_data[0]))
            .environmentObject(PagingViewModel.preview)
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice("iPad (10th generation)")
        PagingView(target: .controller(Controller.mock_data[1]))
            .environmentObject(PagingViewModel.preview)
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice("iPad (10th generation)")
            .previewDisplayName("Not Registered")
    }
}
#endif
