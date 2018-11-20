//
//  WebrtcManager.swift
//  ConnectedColors
//
//  Created by Mahabali on 4/8/16.
//  Copyright © 2016 Ralf Ebert. All rights reserved.
//

import Foundation
import AVFoundation
import WebRTC
import RxSwift
import RxCocoa

public class WebRtcClientManager: NSObject, WebRtcClientManagerProtocol {

    private var peerConnection: PeerConnectionProtocol?
    private var localSdp: SessionDescriptionProtocol?
    private var remoteSdp: SessionDescriptionProtocol?

    var sdpOffer: Observable<SessionDescriptionProtocol> {
        return sdpOfferPublisher.asObservable()
    }
    let sdpOfferPublisher = PublishRelay<SessionDescriptionProtocol>()

    var iceCandidate: Observable<IceCandidateProtocol> {
        return iceCandidatePublisher.asObservable()
    }
    let iceCandidatePublisher = PublishRelay<IceCandidateProtocol>()

    var mediaStream: Observable<RTCMediaStream> {
        return mediaStreamPublisher.asObservable()
    }
    let mediaStreamPublisher = PublishRelay<RTCMediaStream>()

    init(peerConnection: PeerConnectionProtocol) {
        self.peerConnection = peerConnection
    }

    func setAnswerSDP(sdp: SessionDescriptionProtocol) {
        remoteSdp = sdp
        peerConnection?.setRemoteDescription(sdp, completionHandler: { _ in })
    }

    func setICECandidates(iceCandidate: IceCandidateProtocol) {
        peerConnection?.add(iceCandidate)
    }

    func disconnect() {
        peerConnection?.close()
    }

    func startWebRtcConnection() {
        createOffer()
    }

    private func createOffer() {
        let offerContratints = createConstraints()
        peerConnection?.createOffer(for: offerContratints, completionHandler: { [weak self] sdp, _ in
            guard let sdp = sdp else {
                return
            }
            self?.localSdp = sdp
            self?.peerConnection?.setLocalDescription(sdp, completionHandler: { _ in })
            self?.sdpOfferPublisher.accept(sdp)
        })
    }
  
    private func createConstraints() -> RTCMediaConstraints {
        let peerConnectionConstraints = RTCMediaConstraints(mandatoryConstraints: [WebRtcConstraintKey.offerToReceiveVideo.rawValue: "true", WebRtcConstraintKey.offerToReceiveAudio.rawValue: "true"], optionalConstraints: [WebRtcConstraintKey.dtlsSrtpKeyAgreement.rawValue: "true"])
        return peerConnectionConstraints
    }
}

extension WebRtcClientManager: RTCPeerConnectionDelegate {
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        mediaStreamPublisher.accept(stream)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        iceCandidatePublisher.accept(candidate)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}

    public func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
