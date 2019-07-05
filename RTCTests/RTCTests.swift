//
//  RTCTests.swift
//  RTCTests
//
//  Created by king on 29/4/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import XCTest
@testable import RTC
import WebRTC

class RTCTests: XCTestCase {
    var rtc: RTCManager?

    override func setUp() {
        rtc = RTCManager()
    }

    override func tearDown() {
        rtc = nil
    }

    func testCreate() {
        rtc?.setup()
    }
}
