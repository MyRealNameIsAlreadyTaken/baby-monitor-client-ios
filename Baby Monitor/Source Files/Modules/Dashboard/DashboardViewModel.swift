//
//  DashboardViewModel.swift
//  Baby Monitor
//

import Foundation
import RxCocoa
import RxSwift

final class DashboardViewModel {

    private let babyModelController: BabyModelControllerProtocol
    private(set) var bag = DisposeBag()

    // MARK: - Coordinator callback
    private(set) var liveCameraPreview: Observable<Void>?
    private(set) var activityLogTap: Observable<Void>?
    private(set) var settingsTap: Observable<Void>?
    
    private let dismissImagePickerSubject = PublishRelay<Void>()
    
    lazy var baby: Observable<Baby> = babyModelController.babyUpdateObservable
    lazy var connectionStatus: Observable<ConnectionStatus> = connectionChecker.connectionStatus

    // MARK: - Private properties
    private let connectionChecker: ConnectionChecker

    init(connectionChecker: ConnectionChecker, babyModelController: BabyModelControllerProtocol) {
        self.connectionChecker = connectionChecker
        self.babyModelController = babyModelController
        setup()
    }

    deinit {
        connectionChecker.stop()
    }
    
    func attachInput(liveCameraTap: Observable<Void>, activityLogTap: Observable<Void>, settingsTap: Observable<Void>) {
        liveCameraPreview = liveCameraTap
        self.activityLogTap = activityLogTap
        self.settingsTap = settingsTap
    }

    /// Sets a new photo for the current baby.
    ///
    /// - Parameter photo: A new photo for baby.
    func updatePhoto(_ photo: UIImage) {
        babyModelController.updatePhoto(photo)
    }
    
    // MARK: - Private functions
    private func setup() {
        connectionChecker.start()
    }
}
