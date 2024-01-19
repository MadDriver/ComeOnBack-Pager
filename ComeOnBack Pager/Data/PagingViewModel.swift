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
    @Published var signedIn: [Controller] = []
    
    func getController(withInitials initials: String) -> Controller? {
        return allControllers.first { $0.initials == initials}
    }
    
    var notSignedIn: [Controller] {
        allControllers.filter { allController in
            !signedIn.contains { $0.initials == allController.initials}
        }
    }
    
    var pagedBack: [Controller] {
        signedIn
            .filter { controller in
                controller.status == .PAGED_BACK
            }
            .sorted { lhs, rhs in
                guard let lhsBeBack = lhs.beBack, let rhsBeBack = rhs.beBack else {
                    logger.error("Trying to sort controllers without beBacks defined. \(lhs)-\(rhs)")
                    return false
                }
                return lhsBeBack < rhsBeBack
            }
    }
    
    var newelySignedIn: [Controller] {
        signedIn.filter { controller in
            controller.status == .SIGNED_IN
        }.sorted()
    }
    
    var onBreak: [Controller] {
        pagedBack +
        signedIn.filter { controller in
            controller.status == .AVAILABLE
        }.sorted()
    }
    
    var onPosition: [Controller] {
        signedIn.filter { controller in
            controller.status == .ON_POSITION
        }.sorted()
    }
    
    @MainActor
    func shortPoll() async throws {
        logger.info("shortPoll()")
        signedIn = try await API().getSignedInControllers()
    }
    
    @MainActor
    func updateController(_ controller: Controller) async {
        signedIn.removeAll { $0.initials == controller.initials}
        signedIn.append(controller)
    }
    
    func signIn(controllers: [Controller]) async throws {
        for controller in controllers {
            logger.info("Signing in \(controller)")
            let controller = try await API().signIn(initials: controller.initials)
            await updateController(controller)
        }
    }
    
    func signOut(controllers: [Controller]) async throws {
        for controller in controllers {
            logger.info("Signing out \(controller)")
            try await API().signOut(initials: controller.initials)
            await MainActor.run {
                signedIn.removeAll { $0.initials == controller.initials }
            }
        }
    }
    
    func submitBeBack(_ beBack: BeBack, forController controller: Controller) async throws {
        let controller = try await API().submit(
            beBack: beBack,
            forController: controller
        )
        await updateController(controller)
    }
    
    func moveControllerToOnPosition(_ controller: Controller) async throws {
        let controller = try await API().moveOnPosition(initials: controller.initials)
        await updateController(controller)
    }
    
    func moveControllerToOnBreak(_ controller: Controller) async throws {
        let controller = try await API().moveOffPosition(initials: controller.initials)
        await updateController(controller)
    }
    
    func removeBeBack(forController controller: Controller) async throws {
        let controller = try await API().removeBeBack(initials: controller.initials)
        await updateController(controller)
    }
    
    func ackBeBack(forController controller: Controller) async throws {
        try await API().ackBeBack(forController: controller)
        var controller = controller
        controller.beBack?.acknowledged = true
        await updateController(controller)
    }
    
    let DRpositions = [
        "DR1", "DR2", "DR3", "DR4", "SR1", "SR2", "SR3", "SR4"
    ]
    
    let ARPositions = [
        "AR1", "AR2", "AR3", "AR4", "GJT", "PUB"
    ]
    
    let commonPositions = [
        "FR1", "FR2", "FR3", "FR4", "FDCD", "MO1", "MO2", "MO3", "CI"
    ]
    
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
