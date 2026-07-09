//
//  MessagesView.swift
//  ComeOnBack Pager
//
//  Send a canned message: pick one definition, pick recipients (signed-in
//  controllers), send, and show the per-recipient outcome. Unregistered recipients
//  are flagged "no app — alert by phone" (they'll come back `no_devices`). Mirrors the
//  web console's `CannedMessageModal.svelte`.
//

import SwiftUI
import OSLog

struct MessagesView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "MessagesView")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel

    @State private var messages: [CannedMessage]? = nil
    @State private var selectedMessage: CannedMessage?
    @State private var picked: Set<String> = []
    @State private var results: [SendResult]?
    @State private var sending = false
    @State private var loadError: String?
    @State private var sendError: String?

    private let columns = [GridItem(.adaptive(minimum: 90))]

    private var recipients: [Controller] {
        pagingVM.signedIn.sorted { $0.initials < $1.initials }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let results {
                    resultsView(results)
                } else if let messages {
                    picker(messages)
                } else if let loadError {
                    ContentUnavailableFallback(text: loadError)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Send Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task {
            do {
                messages = try await pagingVM.listMessages().sorted { $0.sortOrder < $1.sortOrder }
            } catch {
                loadError = "Couldn't load messages. Pull to retry."
                logger.error("listMessages: \(error)")
            }
        }
    }

    @ViewBuilder
    private func picker(_ messages: [CannedMessage]) -> some View {
        if messages.isEmpty {
            ContentUnavailableFallback(text: "No canned messages defined. A facility admin can add them.")
        } else {
            VStack(alignment: .leading) {
                Text("MESSAGE").fontWeight(.heavy).padding(.horizontal)
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { message in
                            Button {
                                selectedMessage = message
                            } label: {
                                HStack {
                                    Text(message.text)
                                    if let phone = message.phoneNumber {
                                        Text("📞 \(phone)").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedMessage?.id == message.id ? Color.blue.opacity(0.3) : Color.primary.opacity(0.08))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("RECIPIENTS").fontWeight(.heavy)
                        Spacer()
                        Button("All") { picked = Set(recipients.map { $0.initials }) }
                        Button("None") { picked = [] }
                    }
                    .padding([.horizontal, .top])

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(recipients) { controller in
                            recipientChip(controller)
                        }
                    }
                    .padding(.horizontal)
                }

                sendBar
            }
        }
    }

    private func recipientChip(_ controller: Controller) -> some View {
        let selected = picked.contains(controller.initials)
        return Button {
            if selected { picked.remove(controller.initials) } else { picked.insert(controller.initials) }
        } label: {
            VStack(spacing: 2) {
                Text(controller.initials).bold()
                if !controller.registered {
                    Image(systemName: "phone").font(.caption2).foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(selected ? Color.blue.opacity(0.6) : Color.primary.opacity(0.12))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var sendBar: some View {
        let unregisteredCount = recipients.filter { picked.contains($0.initials) && !$0.registered }.count
        VStack(spacing: 4) {
            if unregisteredCount > 0 {
                Label("\(unregisteredCount) recipient\(unregisteredCount == 1 ? "" : "s") have no app — alert by phone.",
                      systemImage: "phone")
                    .font(.caption).foregroundColor(.red)
            }
            if let sendError {
                Text(sendError).font(.caption).foregroundColor(.red)
            }
            Button {
                send()
            } label: {
                HStack {
                    if sending { ProgressView().tint(.white) }
                    Text("SEND (\(picked.count))")
                }
                .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .disabled(sending || selectedMessage == nil || picked.isEmpty)
        }
        .padding()
    }

    private func resultsView(_ results: [SendResult]) -> some View {
        VStack {
            Text("Sent \u{201C}\(selectedMessage?.text ?? "")\u{201D}")
                .font(.headline).padding()
            List(results) { result in
                HStack {
                    Text(result.initials).bold().frame(width: 50, alignment: .leading)
                    if result.delivered {
                        Label("sent", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                    } else {
                        Label("no app — alert by phone", systemImage: "phone").foregroundColor(.orange)
                    }
                }
            }
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding()
        }
    }

    private func send() {
        guard let message = selectedMessage, !picked.isEmpty else { return }
        sending = true
        sendError = nil
        Task {
            do {
                let outcomes = try await pagingVM.sendMessage(
                    messageId: message.id, initials: Array(picked)
                )
                await MainActor.run { results = outcomes.sorted { $0.initials < $1.initials } }
            } catch {
                await MainActor.run { sendError = "Send failed. Check recipients and try again." }
                logger.error("sendMessage: \(error)")
            }
            await MainActor.run { sending = false }
        }
    }
}

/// A small centered placeholder (iOS 16 has no `ContentUnavailableView`).
struct ContentUnavailableFallback: View {
    var text: String
    var body: some View {
        Text(text)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView().environmentObject(PagingViewModel.preview)
    }
}
