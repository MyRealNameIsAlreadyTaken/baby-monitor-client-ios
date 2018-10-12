//
//  RootCoordinator.swift
//  Baby Monitor
//


import UIKit

final class RootCoordinator: RootCoordinatorProtocol {

    var childCoordinators: [Coordinator] = []
    private let navigationController = UINavigationController()
    
    var onEnding: (() -> Void)?

    var window: UIWindow

    init(_ window: UIWindow) {
        self.window = window

        setup()
    }

    func start() {
        childCoordinators.first?.start()
    }

    // MARK: - private functions
    private func setup() {
        window.rootViewController = navigationController

        let onboardingCoordinator = OnboardingCoordinator(navigationController)
        childCoordinators.append(onboardingCoordinator)
        
        let tabBarCoordinator = TabBarCoordinator(navigationController)
        childCoordinators.append(tabBarCoordinator)

        onboardingCoordinator.onEnding = { [weak self] in
            self?.navigationController.setViewControllers([], animated: false)
            tabBarCoordinator.start()
        }
    }
}
