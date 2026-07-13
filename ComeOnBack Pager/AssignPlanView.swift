//
//  AssignPlanView.swift
//  ComeOnBack Pager
//
//  Fill an unassigned planned position: pick a controller or a team — one action, the
//  assignment pages them for the plan's position/time. Also offers cancelling the
//  plan. Teamed controllers are paged through their team, so they're kept out of the
//  single list. Mirrors the web console's `AssignPlanModal.svelte`.
//

import SwiftUI
import OSLog

struct AssignPlanView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "AssignPlanView")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel

    var plan: PlannedPosition

    @State private var pickedController: String?
    @State private var pickedTeam: Int?
    @State private var working = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 90))]

    private var singles: [Controller] {
        pagingVM.signedIn
            .filter { pagingVM.team(forInitials: $0.initials) == nil }
            .sorted { $0.initials < $1.initials }
    }

    private var canAssign: Bool { !working && (pickedController != nil || pickedTeam != nil) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Assigning pages them for \(plan.position) at \(displayTime(plan.time)).")
                    .foregroundColor(.secondary)

                if !pagingVM.teamUnits.isEmpty {
                    Text("TEAMS").fontWeight(.heavy)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 12) {
                        ForEach(pagingVM.teamUnits) { unit in
                            Button {
                                pickedTeam = (pickedTeam == unit.team.id) ? nil : unit.team.id
                                pickedController = nil
                            } label: {
                                Text(unit.label).bold()
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(pickedTeam == unit.team.id ? Color.blue.opacity(0.6) : Color.primary.opacity(0.12))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("CONTROLLERS").fontWeight(.heavy)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(singles) { controller in
                        let selected = pickedController == controller.initials
                        Button {
                            pickedController = selected ? nil : controller.initials
                            pickedTeam = nil
                        } label: {
                            Text(controller.initials).bold()
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(selected ? Color.blue.opacity(0.6) : Color.primary.opacity(0.12))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }

                HStack(spacing: 16) {
                    Button(action: assign) {
                        HStack {
                            if working { ProgressView().tint(.white) }
                            Text("ASSIGN & PAGE")
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canAssign)

                    Button(role: .destructive, action: cancelPlan) {
                        Text("Cancel Plan").frame(minHeight: 56).padding(.horizontal)
                    }
                    .buttonStyle(.bordered)
                    .disabled(working)
                }
            }
            .padding()
        }
        .navigationTitle("Fill \(plan.position) @ \(displayTime(plan.time))")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func assign() {
        working = true
        errorMessage = nil
        Task {
            do {
                try await pagingVM.assignPlanned(
                    plan, controllerInitials: pickedController, teamId: pickedTeam
                )
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run { errorMessage = "Assignment failed." }
                logger.error("assignPlanned: \(error)")
            }
            await MainActor.run { working = false }
        }
    }

    private func cancelPlan() {
        working = true
        errorMessage = nil
        Task {
            do {
                try await pagingVM.cancelPlanned(plan)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run { errorMessage = "Couldn't cancel the plan." }
                logger.error("cancelPlanned: \(error)")
            }
            await MainActor.run { working = false }
        }
    }
}

#if DEBUG
struct AssignPlanView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AssignPlanView(plan: PlannedPosition(
                id: 1, position: "LC2", time: "09:40",
                status: "planned", controllerInitials: nil, teamId: nil
            ))
            .environmentObject(PagingViewModel.preview)
        }
    }
}
#endif
