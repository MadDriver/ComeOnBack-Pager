//
//  PairTeamView.swift
//  ComeOnBack Pager
//
//  Pair an OJTI with a trainee into a training team, and split existing teams. Both
//  members must be signed in and un-teamed (the server 409s otherwise; the pickers
//  pre-filter). Mirrors the web console's `PairTeamModal.svelte`.
//

import SwiftUI
import OSLog

struct PairTeamView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "PairTeamView")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel

    @State private var ojti: String?
    @State private var trainee: String?
    @State private var working = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 90))]

    /// Signed-in controllers not already on a team — the only valid pairing candidates.
    private var unteamed: [Controller] {
        pagingVM.signedIn
            .filter { pagingVM.team(forInitials: $0.initials) == nil }
            .sorted { $0.initials < $1.initials }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if unteamed.count < 2 {
                        ContentUnavailableFallback(text: "Need at least two signed-in, un-teamed controllers to pair a team.")
                    } else {
                        section(title: "OJTI", pool: unteamed, selection: $ojti, exclude: trainee)
                        section(title: "TRAINEE", pool: unteamed, selection: $trainee, exclude: ojti)

                        if let errorMessage {
                            Text(errorMessage).foregroundColor(.red).padding(.horizontal)
                        }

                        Button(action: pair) {
                            HStack {
                                if working { ProgressView().tint(.white) }
                                Text("PAIR \(ojti ?? "—") + \(trainee ?? "—")")
                            }
                            .frame(maxWidth: .infinity, minHeight: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(working || ojti == nil || trainee == nil)
                        .padding(.horizontal)
                    }

                    if !pagingVM.teamUnits.isEmpty {
                        Divider().padding(.vertical)
                        Text("CURRENT TEAMS").fontWeight(.heavy).padding(.horizontal)
                        ForEach(pagingVM.teamUnits) { unit in
                            HStack {
                                Text(unit.label).bold()
                                Spacer()
                                Button(role: .destructive) { split(unit) } label: {
                                    Label("Split", systemImage: "person.2.slash")
                                }
                                .disabled(working)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Training Teams")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func section(title: String, pool: [Controller], selection: Binding<String?>, exclude: String?) -> some View {
        Text(title).fontWeight(.heavy).padding(.horizontal)
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(pool.filter { $0.initials != exclude }) { controller in
                let selected = selection.wrappedValue == controller.initials
                Button {
                    selection.wrappedValue = selected ? nil : controller.initials
                } label: {
                    Text(controller.initials).bold()
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(selected ? Color.blue.opacity(0.6) : Color.primary.opacity(0.12))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private func pair() {
        guard let ojtiInitials = ojti, let traineeInitials = trainee,
              let ojtiController = pagingVM.getController(withInitials: ojtiInitials),
              let traineeController = pagingVM.getController(withInitials: traineeInitials) else { return }
        working = true
        errorMessage = nil
        Task {
            do {
                try await pagingVM.createTeam(ojti: ojtiController, trainee: traineeController)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run { errorMessage = "Pairing failed. Both must be signed in and un-teamed." }
                logger.error("createTeam: \(error)")
            }
            await MainActor.run { working = false }
        }
    }

    private func split(_ unit: TeamUnit) {
        working = true
        errorMessage = nil
        Task {
            do {
                try await pagingVM.splitTeam(unit)
            } catch {
                await MainActor.run { errorMessage = "Split failed." }
                logger.error("splitTeam: \(error)")
            }
            await MainActor.run { working = false }
        }
    }
}

struct PairTeamView_Previews: PreviewProvider {
    static var previews: some View {
        PairTeamView().environmentObject(PagingViewModel.preview)
    }
}
