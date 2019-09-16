//
//  OnboardingClientSetupViewController.swift
//  Baby Monitor
//

import UIKit

final class OnboardingClientSetupViewController: TypedViewController<OnboardingSpinnerView> {
    
    private let viewModel: ClientSetupOnboardingViewModel
    
    init(viewModel: ClientSetupOnboardingViewModel) {
        self.viewModel = viewModel
        super.init(viewMaker: OnboardingSpinnerView())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.startDiscovering(withTimeout: 5.0)
    }
    
    private func setup() {
        navigationItem.leftBarButtonItem = customView.cancelButtonItem
        customView.update(title: viewModel.title)
        customView.update(mainDescription: viewModel.description)
        customView.update(image: viewModel.image)
        viewModel.attachInput(cancelButtonTap: customView.rx.cancelTap.asObservable())
    }
}
