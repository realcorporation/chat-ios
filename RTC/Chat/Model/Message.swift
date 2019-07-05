//
//  Message.swift
//  RTC
//
//  Created by king on 2/7/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation
import Firebase

struct Message {
    var id: String
    var content: String?
    var senderId: String?
    var modifiedDate: Date?
    
    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        self.id = document.documentID
        
        self.content = data[ChatManager.Constants.keyContent] as? String
        self.senderId = data[ChatManager.Constants.keySenderId] as? String
        if let modifiedTime = data[ChatManager.Constants.keyModifiedDate] as? Timestamp {
            self.modifiedDate = Date(timeIntervalSince1970: TimeInterval(modifiedTime.seconds))
        }
    }
}

extension Message: Comparable {
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        guard let lhsDate = lhs.modifiedDate, let rhsDate = rhs.modifiedDate else {
            return lhs.id < rhs.id
        }
        
        return lhsDate < rhsDate
    }
    
}
