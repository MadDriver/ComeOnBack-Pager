//
//  PagingViewModel.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/11/23.
//

import SwiftUI
import OSLog

final class PagingViewModel: ObservableObject {
    private let logger = Logger(subsystem: Logger.subsystem, category: "PagingViewModel")
    @Published var allControllers: [Controller] = []
    @Published var onPosition: [Controller] = []
    @Published var pagedBack: [Controller] = []
    @Published var onBreak: [Controller] = []
    
    var signedInDevs: [Controller] {
        let signedInControllers = onPosition + pagedBack + onBreak
        return signedInControllers.filter { $0.isDev == true }
    }
    
    var rightHandList: [Controller] {
        get {
            return pagedBack + onBreak
        }
    }
    
    func getController(withInitials initials: String) -> Controller? {
        return allControllers.first { $0.initials == initials}
    }
    
    func sortPagedBack() {
        pagedBack.sort(by: { lhs, rhs in
            guard let lhsBeBack = lhs.beBack, let rhsBeBack = rhs.beBack else {
                logger.error("Trying to sort controllers without beBacks defined. \(lhs)-\(rhs)")
                return false
            }
            return lhsBeBack < rhsBeBack
        })
    }
    
    func signIn(controllers: [Controller]) async throws {
        for controller in controllers {
            logger.info("Signing in \(controller)")
            let controller = try await API().signIn(initials: controller.initials)
            await MainActor.run {
                onBreak.append(controller)
            }
        }
    }
    
    func signOut(controllers: [Controller]) async throws {
        for controller in controllers {
            logger.info("Signing out \(controller)")
            try await API().signOut(initials: controller.initials)
            await MainActor.run {
                onBreak.removeAll(where: { $0.initials == controller.initials })
                pagedBack.removeAll(where: { $0.initials == controller.initials })
                onPosition.removeAll(where: { $0.initials == controller.initials })
            }
        }
    }
    
    func shortPoll() async throws {
        logger.info("shortPoll()")
        let controllers = try await API().getSignedInControllers()
        await MainActor.run {
            self.onPosition = controllers.filter { $0.status == .ON_POSITION }
            self.pagedBack = controllers.filter { $0.status == .PAGED_BACK }
            self.onBreak = controllers.filter { $0.status == .AVAILABLE }
            sortPagedBack()
        }
    }
    
    @MainActor
    func processBeBack(forController controller: Controller) {
        onBreak.removeAll(where: { $0.initials == controller.initials })
        pagedBack.removeAll(where: { $0.initials == controller.initials })
        pagedBack.append(controller)
        sortPagedBack()
    }
    
    func submitBeBack(_ beBack: BeBack, forController controller: Controller) async throws {
        var controller = controller
        
        // Determine if beBack should keep ack status
        var ack = false
        if controller.beBack?.stringValue == beBack.stringValue {
            ack = controller.beBack?.acknowledged ?? false
        }
        
        controller.status = .PAGED_BACK
        controller.beBack = beBack
        controller.beBack?.acknowledged = ack
        
        
        try await API().submitBeBack(forController: controller)
        await processBeBack(forController: controller)
    }
    
    func moveControllerToOnPosition(_ controller: Controller) async throws {
        let controller = Controller.newControllerFrom(controller, withStatus: .ON_POSITION)
        try await API().moveOnPosition(initials: controller.initials)
        await MainActor.run {
            pagedBack.removeAll(where: { $0.initials == controller.initials })
            onBreak.removeAll(where: { $0.initials == controller.initials })
            onPosition.append(controller)
        }
    }
    
    func moveControllerToOnBreak(_ controller: Controller) async throws {
        let controller = Controller.newControllerFrom(controller, withStatus: .AVAILABLE)
        try await API().moveOffPosition(initials: controller.initials)
        await MainActor.run {
            onPosition.removeAll(where: { $0.initials == controller.initials })
            onBreak.append(controller)
        }
    }
    
    func removeBeBack(forController controller: Controller) async throws {
        let controller = Controller.newControllerFrom(controller, withStatus: .AVAILABLE)
        try await API().removeBeBack(initials: controller.initials)
        await MainActor.run {
            pagedBack.removeAll(where: { $0.initials == controller.initials })
            onBreak.insert(controller, at: 0)
        }
    }
    
    func ackBeBack(forController controller: Controller) async throws {
        try await API().ackBeBack(forController: controller)
        var controller = controller
        controller.beBack?.acknowledged = true
        await processBeBack(forController: controller)
    }
    
    let beBackMinutes = [
        "10", "15", "30", "45"
    ]
    
    let positionRows = [
        GridItem(), GridItem(), GridItem(), GridItem()
    ]
    
    let beBackTimeRows = [
        GridItem(), GridItem()
    ]
    
    func roundUpToNext5Minutes(minutes: Int) -> Int? {
        let calendar = Calendar.current
        let dateToEdit = calendar.date(byAdding: .minute, value: minutes, to: Date())!
        let currentMinutes = calendar.component(.minute, from: dateToEdit)
        
        if currentMinutes % 5 != 0 {
            let r = 5 - (currentMinutes % 5)
            let minuteToAdd = minutes + r
            let actualDate = calendar.date(byAdding: .minute, value: minuteToAdd, to: Date())!
            return calendar.component(.minute, from: actualDate)
        } else {
            return calendar.component(.minute, from: dateToEdit)
        }
    }
}
