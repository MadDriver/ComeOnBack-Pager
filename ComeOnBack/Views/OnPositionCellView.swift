import SwiftUI
import OSLog

struct OnPositionCellView: View {
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var performingTapGesture: Bool = false
    
    var controller: Controller
    
    var body: some View {
        ZStack { // ZStack for a tapGesture for the entire row
            HStack {
                Text("") // To get the underline all the way across the row
                Spacer()
                Text(controller.initials)
                Spacer()
                if performingTapGesture {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else {
                    Image(systemName: "arrowshape.right")
                        .disabled(performingTapGesture)
                }
            }
            .padding()
        }
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
