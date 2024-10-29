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
    @Published var facility: Facility? = nil
    @Published var signedIn: [Controller] = []
    
    // MARK: - Lifecycle
    private var hourlyTimer: Timer?
    init() {
        // Run a timer every 5 minutes that updates the list of all controllers in this facility
        hourlyTimer = Timer.scheduledTimer(withTimeInterval: 60 * 5, repeats: true) { [weak self] _ in
            Task { [weak self] in
                try? await self?.updateAllControllers()
            }
        }
    }
    
    deinit {
        hourlyTimer?.invalidate()
    }
    
    // MARK: - Updaters
    @MainActor
    func updateAllControllers() async throws {
        facility = try await API().getFacility()
    }
    
    @MainActor
    func shortPoll() async throws {
        signedIn = try await API().getSignedInControllers()
    }
    
    // MARK: - Computed Properties
    var notSignedIn: [Controller] {
        guard let facility = facility else { return [] }
        return facility.allControllers.filter { allController in
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
    
    var newlySignedIn: [Controller] {
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
    
    // MARK: - Controller Functions
    func getController(withInitials initials: String) -> Controller? {
        return facility?.allControllers.first { $0.initials == initials}
    }
    
    func signIn(controllers: [Controller]) async throws {
        for controller in controllers {
            try await API().signIn(initials: controller.initials)
            try await self.shortPoll()
        }
    }
    
    func signOut(controllers: [Controller]) async throws {
        for controller in controllers {
            try await API().signOut(initials: controller.initials)
            try await self.shortPoll()
        }
    }
    
    func submitBeBack(_ beBack: BeBack, forController controller: Controller) async throws {
        try await API().submit(
            beBack: beBack,
            forController: controller
        )
        try await self.shortPoll()
    }
    
    func moveControllerToOnPosition(_ controller: Controller) async throws {
        try await API().moveOnPosition(initials: controller.initials)
        try await self.shortPoll()
    }
    
    func moveControllerToOnBreak(_ controller: Controller) async throws {
        try await API().moveOffPosition(initials: controller.initials)
        try await self.shortPoll()
    }
    
    func removeBeBack(forController controller: Controller) async throws {
        try await API().removeBeBack(initials: controller.initials)
        try await self.shortPoll()
    }
    
    func ackBeBack(forController controller: Controller) async throws {
        try await API().ackBeBack(forController: controller)
        try await self.shortPoll()
    }
    
    // MARK: - Utility Functions
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
