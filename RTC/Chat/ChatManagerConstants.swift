//
//  ChatManagerConstants.swift
//  RTC
//
//  Created by king on 24/6/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation

extension ChatManager {
    enum Role: Int {
        case admin = 0
        case member = 1
    }
    
    struct User {
        var userId: String
        var role: Role
        
        func toDict() -> [String : Any] {
            return { [userId : role.rawValue] }()
        }
    }
    
    struct Constants {
        static let keyChatrooms = "chatrooms"
        static let keyUsers = "users"
        static let keyRole = "role"
        static let keyRoles = "roles"
        static let keyUsersId = "users_id"
        static let keyUserId = "user_id"
        static let keyTitle = "title"
        static let keyImageUrl = "image_url"
        static let keyModifiedDate = "modified_date"
        static let keyMessages = "messages"
        static let keyContent = "content"
        static let keySenderId = "sender_id"
        static let keyOnline = "online"
        static let keyRoomThumbnails = "room_thumbnails"
    }

}
