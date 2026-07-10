import SwiftUI
import OSLog

struct AvailableCellView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "AvailableCellView")
    @EnvironmentObject var pagingVM: PagingViewModel
    @State private var movingController: Bool = false
    @State private var processingPhoneTap = false

    var controller: Controller
    /// The planned position this be-back fills, if any — shown as a "plan:" badge.
    var plan: PlannedPosition? = nil

    /// Green when acknowledged, orange (pending) otherwise, gray with no be-back.
    private var phoneColor: Color {
        if let beBack = controller.beBack {
            return beBack.acknowledged ? .ackGreen : .pendingOrange
        }
        return .gray
    }

    var body: some View {
        HStack(spacing: BoardColumns.spacing) {
            moveButton
                .frame(width: BoardColumns.action)

            Text(controller.initials)
                .fontWeight(.semibold)
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if let beBack = controller.beBack { Text(beBack.stringValue) }
            }
            .font(.body.monospacedDigit())
            .frame(width: BoardColumns.time)

            Group {
                if let forPosition = controller.beBack?.forPosition { Text(forPosition) }
            }
            .frame(width: BoardColumns.position)

            Group {
                if let plan { PlanBadge(position: plan.position) }
            }
            .frame(width: BoardColumns.plan, alignment: .leading)

            statusColumn
                .frame(width: BoardColumns.status)
        }
        .frame(height: BoardColumns.rowHeight)
    }

    @ViewBuilder
    private var moveButton: some View {
        Button {
            if movingController { return }
            movingController = true
            Task {
                do {
                    try await pagingVM.moveControllerToOnPosition(controller)
                    await MainActor.run { movingController = false }
                } catch {
                    await MainActor.run { movingController = false }
                    logger.error("With controller \(controller): \(error)")
                }
            }
        } label: {
            if movingController {
                ProgressView().tint(.accentColor)
            } else {
                Image(systemName: "arrowshape.left")
            }
        }
        .buttonStyle(.plain)
        .disabled(movingController)
    }

    /// Ack indicator for registered controllers; a tappable phone (ack-by-phone) for
    /// unregistered ones.
    @ViewBuilder
    private var statusColumn: some View {
        if let beBack = controller.beBack, controller.registered {
            AckIcon(acknowledged: beBack.acknowledged == true)
        } else if !controller.registered {
            if processingPhoneTap {
                ProgressView()
            } else {
                Image(systemName: "phone.fill")
                    .foregroundColor(phoneColor).fontWeight(.semibold)
                    .onTapGesture {
                        guard controller.beBack != nil else { return }
                        processingPhoneTap = true
                        Task {
                            do {
                                logger.debug("Processing phone tap ack")
                                try await pagingVM.ackBeBack(forController: controller)
                                processingPhoneTap = false
                            } catch {
                                processingPhoneTap = false
                                logger.error("Error ackBeBack \(error)")
                            }
                        }
                    }
            }
        }
    }
}

struct StripView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AvailableCellView(controller: Controller.mock_data[0])
            AvailableCellView(controller: Controller.mock_data[1])
        }
        .environmentObject(PagingViewModel.preview)
    }
}
