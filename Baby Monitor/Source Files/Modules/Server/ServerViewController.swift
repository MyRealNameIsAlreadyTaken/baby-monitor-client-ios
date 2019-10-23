//
//  ServerViewController.swift
//  Baby Monitor
//

import UIKit
import PocketSocket
import RxSwift
import WebRTC

final class ServerViewController: BaseViewController {
    
    private var localVideoTrack: RTCVideoTrack?
    private lazy var pulseView: UIView = {
        let view = UIView()
        view.backgroundColor = .babyMonitorLightGreen
        return view
    }()
    private lazy var rotateCameraButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.setImage(#imageLiteral(resourceName: "switchCamera"), for: .normal)
        view.isHidden = true // TODO: remove when this functionality gets implemented
        return view
    }()
    private lazy var nightModeButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.setImage(#imageLiteral(resourceName: "nightMode"), for: .normal)
        return view
    }()
    private lazy var nightModeOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.isHidden = true
        return view
    }()
    private lazy var buttonsStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [rotateCameraButton, nightModeButton])
        view.distribution = .fillEqually
        view.spacing = 32
        return view
    }()
    
    private let settingsBarButtonItem = UIBarButtonItem(
        image: #imageLiteral(resourceName: "settings"),
        style: .plain,
        target: nil,
        action: nil)
    private var timer: Timer?
    /// A timer for hiding video stream from view.
    private var videoTimer: Observable<Int>?
    private let babyNavigationItemView = BabyNavigationItemView(mode: .baby)
    private let localView = StreamVideoView(contentTransform: .none)
    private let disabledVideoView = DisabledVideoView()
    private let viewModel: ServerViewModel
    private let bag = DisposeBag()
    
    init(viewModel: ServerViewModel) {
        self.viewModel = viewModel
        super.init()
        setupView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        viewModel.settingsTap = settingsBarButtonItem.rx.tap.asObservable()
        navigationController?.setNavigationBarHidden(false, animated: false)
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true, block: { [weak self] _ in
            self?.babyNavigationItemView.firePulse()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.timer?.fire()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func setupView() {
        [disabledVideoView, localView, buttonsStackView, nightModeOverlay].forEach(view.addSubview)
        localView.addConstraints { $0.equalEdges() }
        nightModeOverlay.addConstraints { $0.equalEdges() }

        navigationItem.titleView = babyNavigationItemView
        navigationItem.rightBarButtonItem = settingsBarButtonItem
        buttonsStackView.addConstraints {[
            $0.equal(.safeAreaBottom, constant: -52),
            $0.equal(.centerX)
        ]
        }
        view.bringSubviewToFront(nightModeOverlay)
        view.bringSubviewToFront(buttonsStackView)
    }
    
    private func setupBindings() {
        viewModel.stream
            .subscribe(onNext: { [unowned self] stream in
                self.attach(stream: stream)
            })
            .disposed(by: bag)
        viewModel.startStreaming()
        fireVideoTimer()
        videoTimer?.subscribe(onNext: { [weak self] _ in
            self?.localView.isHidden = true
            self?.videoTimer = nil
        })
        .disposed(by: bag)
        nightModeButton.rx.tap.asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.nightModeOverlay.isHidden.toggle()
        })
        .disposed(by: bag)
        disabledVideoView.tapGestureRecognizer
            .rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.localView.isHidden = false
                self?.fireVideoTimer()
        })
        .disposed(by: bag)
    }
    
    private func attach(stream: MediaStream) {
        guard let stream = stream as? RTCMediaStream else {
            return
        }
        localVideoTrack?.remove(localView)
        localVideoTrack = stream.videoTracks[0]
        localVideoTrack?.add(localView)
    }

    private func fireVideoTimer() {
        videoTimer = Observable<Int>.interval(Constants.videoStreamVisibilityTimeLimit,
                                              scheduler: MainScheduler.instance)
    }
}
