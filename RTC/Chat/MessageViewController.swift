//
//  MessageViewController.swift
//  RTC
//
//  Created by king on 2/7/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation
import Firebase

class MessageViewController: UIViewController {
    @IBOutlet var tableView: UITableView?
    @IBOutlet var textField: UITextField?
    
    private var chatroomId: String?
    var chatroom: Chatroom? {
        didSet {
            if let chatroom = chatroom {
                chatroomId = chatroom.id
            } else {
                chatroomId = nil
            }
        }
    }
    
    private var app = UIApplication.shared.delegate as? AppDelegate
    
    private var messageListeners = [ListenerRegistration]()
    
    private let db = Firestore.firestore()
    private(set) var messages = [Message]()
    
    private var lastCursor: QuerySnapshot?
    private var firstCursor: QuerySnapshot?
    private let pageSize = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previousPage()
    }
    
    deinit {
        for listener in messageListeners {
            listener.remove()
        }
    }
    
    @IBAction func previousPage() {
        guard let chatroomId = chatroomId else {
            return
        }
        
        if var last = firstCursor?.documents.last {
            
            if let cursorFromLast = lastCursor?.documents.last {
                last = cursorFromLast
            }
            
            let queryListener = db.collection(ChatManager.Constants.keyChatrooms)
                .document(chatroomId)
                .collection(ChatManager.Constants.keyMessages)
                .order(by: ChatManager.Constants.keyModifiedDate, descending: true)
                .limit(to: pageSize)
                .start(afterDocument: last)
                .addSnapshotListener({ [weak self] (documentSnapshot, error) in
                    guard let `self` = self else {
                        return
                    }
                    
                    guard error == nil else {
                        self.messages.removeAll()
                        self.tableView?.reloadData()
                        return
                    }
                    
                    self.lastCursor = documentSnapshot
                    
                    documentSnapshot?.documentChanges.forEach({ [weak self] (diff) in
                        guard let `self` = self else {
                            return
                        }
                        
                        let document = diff.document
                        let message = Message(document: document)
                        
                        switch diff.type {
                        case .added:
                            self.messages.append(message)
                            self.messages.sort()
                            
                            break
                        case .removed:
                            guard let index = self.messages.firstIndex(of: message) else {
                                return
                            }
                            
                            self.messages.remove(at: index)
                            break
                        case .modified:
                            guard let index = self.messages.firstIndex(of: message) else {
                                return
                            }
                            
                            self.messages[index] = message
                            break
                        default:
                            break
                        }
                    })
                    
                    self.tableView?.reloadData()
                })
            
            messageListeners.append(queryListener)
        } else {
            let queryListener = db.collection(ChatManager.Constants.keyChatrooms)
                .document(chatroomId)
                .collection(ChatManager.Constants.keyMessages)
                .order(by: ChatManager.Constants.keyModifiedDate, descending: true)
                .limit(to: pageSize)
                .addSnapshotListener({ [weak self] (documentSnapshot, error) in
                    guard let `self` = self else {
                        return
                    }
                    
                    guard error == nil else {
                        self.messages.removeAll()
                        self.tableView?.reloadData()
                        return
                    }
                    
                    if self.firstCursor == nil {
                        self.firstCursor = documentSnapshot
                        self.listenerForMiddleRecord()
                    } else {
                        self.firstCursor = documentSnapshot
                    }
                    
                    documentSnapshot?.documentChanges.forEach({ [weak self] (diff) in
                        guard let `self` = self else {
                            return
                        }
                        
                        let document = diff.document
                        let message = Message(document: document)
                        
                        switch diff.type {
                        case .added:
                            self.messages.append(message)
                            self.messages.sort()
                            
                            break
                        case .modified:
                            guard let index = self.messages.firstIndex(of: message) else {
                                return
                            }
                            
                            self.messages[index] = message
                            break
                        default:
                            break
                        }
                    })
                    
                    self.tableView?.reloadData()
                })
            
            messageListeners.append(queryListener)
        }
    }
    
    private func listenerForMiddleRecord() {
        guard let firstCursor = firstCursor, let last = firstCursor.documents.last, let chatroomId = chatroomId else {
            return
        }
        
        let queryForMiddle = db.collection(ChatManager.Constants.keyChatrooms)
            .document(chatroomId)
            .collection(ChatManager.Constants.keyMessages)
            .order(by: ChatManager.Constants.keyModifiedDate, descending: true)
            .end(atDocument: last)
            .addSnapshotListener({ [weak self] (documentSnapshot, error) in
                guard let `self` = self else {
                    return
                }
                
                guard error == nil else {
                    self.messages.removeAll()
                    self.tableView?.reloadData()
                    return
                }
                
                documentSnapshot?.documentChanges.forEach({ [weak self] (diff) in
                    guard let `self` = self else {
                        return
                    }
                    
                    let document = diff.document
                    let message = Message(document: document)
                    
                    switch diff.type {
                    case .modified:
                        guard let index = self.messages.firstIndex(of: message) else {
                            return
                        }
                        
                        self.messages[index] = message
                        break
                    default:
                        break
                    }
                })
                
                self.tableView?.reloadData()
            })
        
        messageListeners.append(queryForMiddle)
    }
    
    @IBAction func send() {
        guard let textField = textField, let text = textField.text, let chatroom = chatroom, let chatManager = app?.chatManager, let userId = chatManager.uid else {
            return
        }
        
        textField.resignFirstResponder()
        
        chatManager.createMessage(forRoom: chatroom, content: text, senderId: userId) { (messageId) in
            print("messageId=\(String(describing: messageId))")
        }
    }
    
    @IBAction func call() {
        guard let myUid = app?.chatManager?.uid else {
            return
        }
        
        guard let users = chatroom?.users, users.count == 2 else {
            return
        }
        
        let otherUsers = users.filter{ $0.userId != myUid }
        if let otherUser = otherUsers.first {
            let userId = otherUser.userId
        }
    }
}

extension MessageViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
}

extension MessageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        let message = messages[indexPath.row]
        
        cell.textLabel?.text = message.content
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = message.modifiedDate {
            cell.detailTextLabel?.text = formatter.string(from: date)
        } else {
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
}
