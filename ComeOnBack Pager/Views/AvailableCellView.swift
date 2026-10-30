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

            ControllerLabel(initials: controller.initials, name: controller.name)
                .controllerColumn()

            ZStack {
                if let beBack = controller.beBack { Text(beBack.stringValue) }
            }
            .font(.title3.weight(.semibold).monospacedDigit())
            .frame(width: BoardColumns.time)

            ZStack {
                if let forPosition = controller.beBack?.forPosition { Text(forPosition) }
            }
            .font(.body.weight(.semibold))
            .frame(width: BoardColumns.position)

            ZStack {
                if let plan { PlanBadge(position: plan.position) }
            }
            .frame(width: BoardColumns.plan, alignment: .leading)

            ZStack { statusColumn }
                .frame(width: BoardColumns.status)

            Spacer(minLength: 0)
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
            // A real Button, like `moveButton`: an `.onTapGesture` here lost the tap to
            // the row's NavigationLink, so ack-by-phone never fired.
            Button(action: ackByPhone) {
                Group {
                    if processingPhoneTap {
                        ProgressView()
                    } else {
                        Image(systemName: "phone.fill")
                            .foregroundColor(phoneColor).fontWeight(.semibold)
                    }
                }
                .frame(width: BoardColumns.status, height: BoardColumns.rowHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // Nothing to acknowledge until they've been paged (gray phone).
            .disabled(controller.beBack == nil || processingPhoneTap)
        }
    }

    /// Acknowledge the be-back on behalf of a controller who was reached by phone.
    private func ackByPhone() {
        processingPhoneTap = true
        Task {
            do {
                logger.debug("Processing phone tap ack")
                try await pagingVM.ackBeBack(forController: controller)
            } catch {
                logger.error("Error ackBeBack \(error)")
            }
            processingPhoneTap = false
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
