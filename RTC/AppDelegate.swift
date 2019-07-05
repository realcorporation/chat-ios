//
//  AppDelegate.swift
//  RTC
//
//  Created by king on 29/4/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import UIKit
import CoreData
import Firebase

// Give credit to Raywenderlich
// https://www.raywenderlich.com/5359-firebase-tutorial-real-time-chat

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var chatManager: ChatManager?
    
    var callManager: CallManager?
    
    private let config = Config.default
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        chatManager = ChatManager()
        
        let signalClient = SignalingClient(serverUrl: self.config.signalingServerUrl)
        let webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
        callManager = CallManager(signalClient: signalClient, webRTCClient: webRTCClient)
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        chatManager?.updateOnlineStatus(isOnline: false)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        chatManager?.updateOnlineStatus(isOnline: true)
    }
    
    func buildMainViewController() -> UIViewController {
        let signalClient = SignalingClient(serverUrl: self.config.signalingServerUrl)
        let webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
        let mainViewController = MainViewController(signalClient: signalClient,
                                                    webRTCClient: webRTCClient)
        return mainViewController
    }

}

