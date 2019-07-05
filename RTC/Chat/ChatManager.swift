//
//  ChatManager.swift
//  RTC
//
//  Created by king on 24/6/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation
import Firebase

protocol ChatManagerChatroomDelegate: NSObject {
    func chatroomDidChange()
}

protocol ChatManagerUserDelegate: NSObject {
    func memberUserDidChange()
}

class ChatManager {
    weak var chatroomDelegate: ChatManagerChatroomDelegate?
    weak var userDelegate: ChatManagerUserDelegate?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private var chatroomListener: ListenerRegistration?
    private var usersListener: ListenerRegistration?
    
    private(set) var uid: String?
    private(set) var chatrooms = [Chatroom]()
    private(set) var memberUsers = [MemberUser]()
    
    init() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        
        db.settings = settings
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let `self` = self else {
                return
            }
            
            self.updateUser(uid: user?.uid)
            
            if user?.uid != nil {
                self.addChatroomListener()
                self.addUsersListener()
            } else {
                self.chatrooms.removeAll()
                self.chatroomDelegate?.chatroomDidChange()
                self.memberUsers.removeAll()
                self.userDelegate?.memberUserDidChange()
            }
        }
    }
    
    func signIn(mid: String) {
        let link = "\(defaultFirestoreServerUrl)?mid=\(mid)"
        guard let url = URL(string: link) else { return }
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            guard let str = String(data: data, encoding: String.Encoding.utf8) else {
                return
            }
            
            Auth.auth().signIn(withCustomToken: str) { (user, error) in
                guard error == nil, let user = user else {
                    print("error=\(String(describing: error))")
                    return
                }
                
                print("user=\(user)")
            }
        }
        task.resume()
    }
    
    func signOut() throws {
        updateOnlineStatus(isOnline: false)
        try Auth.auth().signOut()
    }
    
    func updateUser(uid: String?) {
        self.uid = uid
        
        if let uid = uid {
            updateOnlineStatus(uid: uid, isOnline: true)
        }
    }
    
    func updateOnlineStatus(uid: String, isOnline: Bool) {
        let userData = [Constants.keyOnline : isOnline]
        
        db.collection(Constants.keyUsers).document(uid).setData(userData) { err in
            
        }
    }
    
    func updateOnlineStatus(isOnline: Bool) {
        guard let myUid = uid else { return }
        
        updateOnlineStatus(uid: myUid, isOnline: isOnline)
    }
    
    func createSingleChatroom(user: User, completionHandler:@escaping (_ roomId: String?) -> Void) {
        createChatroom(users: [user], title: nil, imageUrl: nil, completionHandler: completionHandler)
    }
    
    func createChatroom(users: [String], title: String?, imageUrl: String?, completionHandler:@escaping (_ roomId: String?) -> Void) {
        guard let myUid = uid else {
            return
        }
        
        var members = [ChatManager.User]()
        
        let userAdmin = ChatManager.User(userId: myUid, role: ChatManager.Role.admin)
        members.append(userAdmin)
        
        for userId in users {
            let userMember = ChatManager.User(userId: userId, role: ChatManager.Role.member)
            members.append(userMember)
        }
        
        createChatroom(users: members, title: title, imageUrl: imageUrl, completionHandler: completionHandler)
    }
    
    private func createChatroom(users: [User], title: String?, imageUrl: String?, completionHandler:@escaping (_ roomId: String?) -> Void) {
        // Protection from single user
        guard users.count >= 2 else {
            completionHandler(nil)
            return
        }
        
        var data = [String : Any]()
        
        data[Constants.keyUsersId] = users.map{ $0.userId }
        
        var roles = [String : Any]()
        for user in users {
            roles[user.userId] = user.role.rawValue
        }
        data[Constants.keyRoles] = roles
        
        if let title = title {
            data[Constants.keyTitle] = title
        }
        
        if let imageUrl = imageUrl {
            data[Constants.keyImageUrl] = imageUrl
        }
        
        data[Constants.keyModifiedDate] = Date()
        
        var roomRef: DocumentReference? = nil
        
        roomRef = db.collection(Constants.keyChatrooms).addDocument(data: data) { error in
            guard error == nil, let roomId = roomRef?.documentID else {
                completionHandler(nil)
                return
            }
            
            completionHandler(roomId)
        }
    }
    
    func createMessage(forRoom room: Chatroom, content: String, senderId: String, completionHandler:@escaping (_ messageId: String?) -> Void) {
        var data = [String : Any]()
        data[Constants.keyContent] = content
        data[Constants.keySenderId] = senderId
        
        data[Constants.keyModifiedDate] = Date()
        data[Constants.keyUsersId] = room.users.map{ $0.userId }
        
        var messageRef: DocumentReference? = nil
        messageRef = db.collection(Constants.keyChatrooms).document(room.id).collection(Constants.keyMessages).addDocument(data: data, completion: { (error) in
            guard error == nil, let messageId = messageRef?.documentID else {
                completionHandler(nil)
                return
            }
            
            completionHandler(messageId)
        })
    }
    
    func queryAllChatrooms(completionHandler:@escaping (_ rooms: [QueryDocumentSnapshot]?) -> Void) {
        let _ = db.collection(Constants.keyChatrooms)
            .order(by: Constants.keyModifiedDate, descending: true)
            .getDocuments { (querySnapshot, err) in
            guard err == nil, let querySnapshot = querySnapshot else {
                completionHandler(nil)
                return
            }
            
            completionHandler(querySnapshot.documents)
        }
    }
    
    func uploadGroupThumbnail(image: UIImage, completionHandler: @escaping (_ url: String?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 1) else {
            completionHandler(nil)
            return
        }
        
        let imageName = "\(UUID().uuidString)_\(String(Date().timeIntervalSince1970)).jpg"
        let imageRef = storage.child(ChatManager.Constants.keyRoomThumbnails).child(imageName)
        
        imageRef.putData(data, metadata: nil) { (metadata, error) in
            imageRef.downloadURL(completion: { (url, error) in
                guard let downloadUrl = url, error == nil else {
                    completionHandler(nil)
                    return
                }
                
                completionHandler(downloadUrl.absoluteString)
            })
        }
    }
    
    // TODO The actual implementation is not ready
    func queryAllMessages() {
        guard let uid = uid else {
            return
        }
        
        db.collectionGroup(Constants.keyMessages)
            .whereField(Constants.keyUsersId, arrayContains: uid)
            .getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else {
                    return
                }
                for document in snapshot.documents {
                    let message = Message(document: document)
                    let roomDoc = document.reference.parent.parent
                    print("message=\(message); at room ID=\(String(describing: roomDoc?.documentID))")
                }
        }
    }
    
    private func addChatroomListener() {
        guard let uid = uid else {
            return
        }
        
        chatroomListener = db.collection(ChatManager.Constants.keyChatrooms)
            .whereField(Constants.keyUsersId, arrayContains: uid)
            .order(by: ChatManager.Constants.keyModifiedDate, descending: true)
            .addSnapshotListener { [weak self] (documentSnapshot, error) in
                guard let `self` = self else {
                    return
                }
                
                guard error == nil else {
                    self.chatrooms.removeAll()
                    self.chatroomDelegate?.chatroomDidChange()
                    return
                }
                
                documentSnapshot?.documentChanges.forEach({ [weak self] (diff) in
                    guard let `self` = self else {
                        return
                    }
                    
                    let document = diff.document
                    let chatroom = Chatroom(document: document)
                    
                    switch diff.type {
                    case .added:
                        self.chatrooms.append(chatroom)
                        self.chatrooms.sort()
                        break
                    case .removed:
                        guard let index = self.chatrooms.firstIndex(of: chatroom) else {
                            return
                        }
                        
                        self.chatrooms.remove(at: index)
                        break
                    case .modified:
                        guard let index = self.chatrooms.firstIndex(of: chatroom) else {
                            return
                        }
                        
                        self.chatrooms[index] = chatroom
                        self.chatrooms.sort()
                        break
                    default:
                        break
                    }
                })
                
                self.chatroomDelegate?.chatroomDidChange()
        }
    }
    
    private func addUsersListener() {
        guard let _ = uid else {
            return
        }
        
        usersListener = db.collection(ChatManager.Constants.keyUsers)
            .addSnapshotListener({ [weak self] (documentSnapshot, error) in
                documentSnapshot?.documentChanges.forEach({ [weak self] (diff) in
                    let document = diff.document
                    let member = MemberUser(document: document)
                    
                    switch diff.type {
                    case .added:
                        self?.memberUsers.append(member)
                        break
                    case .removed:
                        guard let index = self?.memberUsers.firstIndex(of: member) else {
                            return
                        }
                        
                        self?.memberUsers.remove(at: index)
                        break
                    case .modified:
                        guard let index = self?.memberUsers.firstIndex(of: member) else {
                            return
                        }
                        
                        self?.memberUsers[index] = member
                        break
                    default:
                        break
                    }
                })
                
                self?.userDelegate?.memberUserDidChange()
            })
    }
    
}
