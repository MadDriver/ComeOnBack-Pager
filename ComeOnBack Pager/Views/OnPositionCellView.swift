import SwiftUI
import OSLog

struct OnPositionCellView: View {
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var performingTapGesture: Bool = false
    
    var controller: Controller
    
    var body: some View {
        ZStack { // ZStack for a tapGesture for the entire row
            HStack {
                Text(" \(controller.atTime?.relative() ?? "")")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(controller.initials)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                if performingTapGesture {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Image(systemName: "arrowshape.right")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
        }
        .frame(height: 40)
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
            ForEach(Controller.mock_data, id: \.initials) { controller in
                OnPositionCellView(controller: controller)
            }
        }
    }
}
