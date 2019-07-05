//
//  CallManager.swift
//  RTC
//
//  Created by king on 3/7/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation

class CallManager {
    private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient
    private var signalingConnected = false
    
    init(signalClient: SignalingClient, webRTCClient: WebRTCClient) {
        self.signalClient = signalClient
        self.webRTCClient = webRTCClient
        self.signalClient.delegate = self
    }
}

extension CallManager: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        self.signalingConnected = false
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        
    }
}
