import SwiftUI
import OSLog

struct OnPositionCellView: View {
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var performingTapGesture: Bool = false
    
    var controller: Controller
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ControllerLabel(initials: controller.initials, name: controller.name)

            Spacer(minLength: Spacing.xs)

            VStack(alignment: .trailing, spacing: 0) {
                if let position = controller.position, !position.isEmpty {
                    Text(position).font(.body.weight(.semibold))
                }
                Text(controller.atTime?.relative() ?? "")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)

            Group {
                if performingTapGesture {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                } else {
                    Image(systemName: "arrowshape.right")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: BoardColumns.status)
        }
        .padding(.leading, Spacing.md)
        .frame(height: BoardColumns.rowHeight)
        .contentShape(Rectangle()) // the whole row is the move-off target
        .onTapGesture {
            if (performingTapGesture) { return }
            performingTapGesture = true
            
            Task {
                do {
                    try await pagingVM.moveControllerToOnBreak(controller)
                    await MainActor.run { performingTapGesture = false }
                } catch {
                    await MainActor.run { performingTapGesture = false }
                    Logger(subsystem: Logger.subsystem, category: "OnPositionCellView").error("With controller \(controller): \(error)")
                }
            }
        }
    }
}

struct OnPositionCellView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OnPositionCellView(controller: Controller.mock_data[0])
            OnPositionCellView(controller: Controller.mock_data[1])
            OnPositionCellView(controller: Controller.mock_data[2])
        }
    }
}
