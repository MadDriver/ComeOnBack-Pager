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

    let positionRows = [
        GridItem(), GridItem(), GridItem(), GridItem()
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
        .background(Color.black.opacity(0.1))
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "x.circle")
                    .font(.system(size: 48))
                    .padding()
            }
            .buttonStyle(.plain)
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
        VStack {
            HStack {
                VStack {
                    Text("\(beBackText)")
                        .font(.title).bold()
                        .padding(.bottom)
                    leftSideOfHStack
                }
                VStack {
                    Picker("Time Picker type", selection: $timePicker) {
                        ForEach(TimeASAPPicker.allCases) { option in
                            Text(option.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)

                    switch timePicker {
                    case .normal:
                        rightClockView
                    case .asap:
                        asapView
                    case .soon:
                        soonView
                    }
                } // VStack
                .frame(height: 500)

            } // HStack

            Button(action: pageBack) {
                Text(registered ? "PAGE" : "ASSIGN")
                    .foregroundColor(isSubmittable ? .black : .black.opacity(0.4))
                    .frame(width: 500, height: 100)
                    .font(.title).bold()
                    .background(isSubmittable ? Color.blue.opacity(0.8) : Color.gray)
                    .cornerRadius(20)
                    .padding()
            }
            .disabled(!isSubmittable)

            if isTeam {
                teamSecondaryActions
            } else if !registered {
                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.red).bold()
                    Text("\(label) is not registered. You must page them via the phone system.")
                    Image(systemName: "phone")
                        .foregroundColor(.red).bold()
                }
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
                    Label("Cancel Page", systemImage: "trash")
                }
                .padding()
            }
        }
    }

    /// Teams-only: move on position (with the selected position) and split, alongside
    /// the primary page button.
    @ViewBuilder
    private var teamSecondaryActions: some View {
        HStack(spacing: 40) {
            Button {
                runTeamAction { unit in try await pagingVM.moveTeamOnPosition(unit, position: beBackPosition) }
            } label: {
                Label("Move On Position", systemImage: "arrowshape.left")
            }
            .buttonStyle(.bordered)
            .disabled(teamActionInFlight)

            Button(role: .destructive) {
                runTeamAction { unit in try await pagingVM.splitTeam(unit) }
            } label: {
                Label("Split Team", systemImage: "person.2.slash")
            }
            .buttonStyle(.bordered)
            .disabled(teamActionInFlight)
        }
        .padding(.bottom)
    }

    /// Teams-only: shown when the team is plugged in together — move off / split.
    @ViewBuilder
    private var teamOnPositionView: some View {
        VStack(spacing: 30) {
            Text(label)
                .font(.largeTitle).bold()
            Text("On position\(lead.position.map { " \($0)" } ?? "")")
                .font(.title2)
            Button {
                runTeamAction { unit in try await pagingVM.moveTeamOffPosition(unit) }
            } label: {
                Text("MOVE OFF POSITION")
                    .frame(width: 400, height: 90)
                    .font(.title).bold()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.black)
                    .cornerRadius(20)
            }
            .disabled(teamActionInFlight)
            Button(role: .destructive) {
                runTeamAction { unit in try await pagingVM.splitTeam(unit) }
            } label: {
                Label("Split Team", systemImage: "person.2.slash")
            }
            .buttonStyle(.bordered)
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
        ZStack {
            Circle()
                .fill(.red)
            Text("ASAP")
                .font(.title).bold()
        }
        .padding()
    }

    @ViewBuilder
    private var soonView: some View {
        ZStack {
            Circle()
                .fill(.orange)
            Text("SOON")
                .font(.title).bold()
        }
        .padding()
    }

    @ViewBuilder
    private var rightClockView: some View {
        ClockView(selectedMinute: clockBeBackMinutes, onMinuteSelected: newMinuteSelected)
            .frame(width: 400, height: 400)

        HStack {
            ForEach(beBackMinutes, id: \.self) { minute in
                Text("\(minute) mins")
                    .fontWeight(.bold)
                    .frame(width: 100, height: 50)
                    .background(selectedBeBackMinutes == minute ? Color.yellow : Color.blue.opacity(0.5))
                    .border(Color.red, width: selectedBeBackMinutes == minute ? 2.5 : 0)
                    .onTapGesture {
                        guard let minutesAsInt = Int(minute) else { return }
                        newMinuteSelected(minute: pagingVM.roundUpToNext5Minutes(minutes: minutesAsInt))
                        self.selectedBeBackMinutes = minute
                    }
            }
        }
        .padding()
    }

    @ViewBuilder
    private var leftSideOfHStack: some View {
        if let facility = pagingVM.facility,
           let area = facility.getArea(forController: lead)
        {
            VStack {
                LazyHGrid(rows: positionRows, spacing: 20) {
                    ForEach(area.positions, id: \.self) { position in
                        if let position = position {
                            Text(position)
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 100, height: 50)
                                .background(beBackPosition == position ? Color.yellow : Color.red.opacity(0.5))
                                .border(Color.blue, width: beBackPosition == position ? 2.5 : 0)
                                .onTapGesture {
                                    if beBackPosition == position {
                                        beBackPosition = nil
                                    } else {
                                        beBackPosition = position
                                    }
                                }
                        } else {
                            // Position is nil, placeholder text box.
                            Text("")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height:250)


            } // VStack
            .padding(.top)
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
