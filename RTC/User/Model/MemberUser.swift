//
//  MemberUser.swift
//  RTC
//
//  Created by king on 2/7/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation
import Firebase

struct MemberUser {
    var userId: String
    var online: Bool
    
    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        self.userId = document.documentID
        self.online = data[ChatManager.Constants.keyOnline] as? Bool ?? false
    }
}

extension MemberUser: Comparable {
    static func == (lhs: MemberUser, rhs: MemberUser) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    static func < (lhs: MemberUser, rhs: MemberUser) -> Bool {
        return lhs.userId < rhs.userId
    }
}
