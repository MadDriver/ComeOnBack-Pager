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
            guard let lhsTime = lhs.beBack?.time, let rhsTime = rhs.beBack?.time else {
                logger.error("Trying to sort controllers without beBacks defined. \(lhs)-\(rhs)")
                return false
            }
            return lhsTime < rhsTime
        })
    }
    
    func signIn(controller: Controller) async throws {
        logger.info("Signing in \(controller)")
        try await API().signIn(initials: controller.initials)
        let controller = Controller.newControllerFrom(controller, withStatus: .AVAILABLE)
        await MainActor.run {
            onBreak.append(controller)
        }
    }
    
    func signOut(controller: Controller) async throws {
        logger.info("Signing out \(controller)")
        try await API().signOut(initials: controller.initials)
        await MainActor.run {
            onBreak.removeAll(where: { $0.initials == controller.initials })
            pagedBack.removeAll(where: { $0.initials == controller.initials })
            onPosition.removeAll(where: { $0.initials == controller.initials })
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
            self.logger.info("onPositionn count: \(self.onPosition.count)")
            self.logger.info("pagedBack count: \(self.pagedBack.count)")
            self.logger.info("onBreak count: \(self.onBreak.count)")
        }
    }
    
    @MainActor
    func processBeBack(_ beBack: BeBack) {
        logger.info("processBeBack: \(beBack)")
        guard var controller = getController(withInitials: beBack.initials) else {
            logger.error("Could not find conotroller with initials \(beBack.initials)")
            return
        }
        controller.status = .PAGED_BACK
        controller.beBack = beBack
        onBreak.removeAll(where: { $0.initials == beBack.initials })
        pagedBack.removeAll(where: { $0.initials == beBack.initials })
        pagedBack.append(controller)
        sortPagedBack()
    }
    
    func createAndSubmitBeBack(forController controller: Controller, time: Time, forPosition: String?) async throws {
        let beBack = try await API().submitBeBack(initials: controller.initials,
                                                  time: time,
                                                  forPosition: forPosition)
        await processBeBack(beBack)
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
    
    let positions = [
        "DR1", "DR2", "DR3", "DR4", "AR1", "AR2", "AR3", "AR4", "FR1", "FR2", "FR3", "FR4", "SR1", "SR2", "SR4", "FDCD", "MO1", "MO2", "MO3", "CI", "GJT", "PUB", "TBD"
        
    ]
    
    let beBackTimes = [
        "10", "15", "30", "45"
    ]
    
    let positionRows = [
        GridItem(), GridItem(), GridItem(), GridItem()
    ]
    
    let beBackTimeRows = [
        GridItem(), GridItem()
    ]
    
    var beBackTimeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    func getBeBackTime(minute: String) -> String {
        let calendar = Calendar.current
        let timeToAdd = Int(minute)!
        let dateToEdit = calendar.date(byAdding: .minute, value: timeToAdd, to: Date())!
        let m = calendar.component(.minute, from: dateToEdit)
        
        if m % 5 != 0 {
            let r = 5 - (m % 5)
            let minuteToAdd = timeToAdd + r
            let actualDate = calendar.date(byAdding: .minute, value: minuteToAdd, to: Date())!
            return beBackTimeFormat.string(from: actualDate)
        } else {
            return beBackTimeFormat.string(from: dateToEdit)
        }
    }
    
    func customBeBackTimeChanged(time: Int) -> String {
        let calendar = Calendar.current
        let dateOne = calendar.date(bySetting: .minute, value: time, of: Date())!
        let dateString = beBackTimeFormat.string(from: dateOne)
        return dateString
    }
    
}
