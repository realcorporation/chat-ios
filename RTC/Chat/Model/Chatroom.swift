//
//  Chatroom.swift
//  RTC
//
//  Created by king on 26/6/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation
import Firebase

struct Chatroom {
    var id: String
    var users: [User]
    var title: String?
    var imageUrl: String?
    var modifiedDate: Date?
    
    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        self.id = document.documentID
        
        self.users = [User]()
        if let roomUsersId = data[ChatManager.Constants.keyUsersId] as? [String] {
            for roomUserId in roomUsersId {
                self.users.append(User(userId: roomUserId))
            }
        }
        
        self.title = data[ChatManager.Constants.keyTitle] as? String
        self.imageUrl = data[ChatManager.Constants.keyImageUrl] as? String
        if let modifiedTime = data[ChatManager.Constants.keyModifiedDate] as? Timestamp {
            self.modifiedDate = Date(timeIntervalSince1970: TimeInterval(modifiedTime.seconds))
        }
    }
}

extension Chatroom: Comparable {
    
    static func == (lhs: Chatroom, rhs: Chatroom) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: Chatroom, rhs: Chatroom) -> Bool {
        guard let lhsDate = lhs.modifiedDate, let rhsDate = rhs.modifiedDate else {
            return lhs.id < rhs.id
        }
        
        return lhsDate > rhsDate
    }
    
}
