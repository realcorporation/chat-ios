//
//  ChatroomViewController.swift
//  RTC
//
//  Created by king on 29/4/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import UIKit
import Firebase

class ChatroomViewController: UIViewController {

    @IBOutlet var tableView: UITableView?
    
    private let chatroomCellIdentifier = "chatroomCell"
    
    private var app = UIApplication.shared.delegate as? AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        app?.chatManager?.chatroomDelegate = self
    }
    
    @IBAction func createChatRoom() {
        guard let _ = app?.chatManager?.uid else {
            return
        }
        
        let ctrl = UsersTableViewController()
        ctrl.delegate = self
        navigationController?.pushViewController(ctrl, animated: true)
    }
    
    @IBAction func queryChatRooms() {
        app?.chatManager?.queryAllChatrooms(completionHandler: { (rooms) in
            guard let rooms = rooms else {
                return
            }
            
            for document in rooms {
                print("\(document.documentID) => \(document.data())")
            }
        })
    }
    
    @IBAction func signIn() {
        guard app?.chatManager?.uid == nil else {
            return
        }
        
        let alert = UIAlertController(title: "Sign in by Mid", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert, weak self] (_) in
            guard let textField = alert?.textFields?.first, let mid = textField.text, mid.count > 0 else { return }
            self?.app?.chatManager?.signIn(mid: mid)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func signOut() {
        guard app?.chatManager?.uid != nil else {
            return
        }
        
        do {
            try app?.chatManager?.signOut()
        } catch {
            print("sign out error=\(error)")
        }
    }
    
    @IBAction func call() {
        guard let call = app?.buildMainViewController() else { return }
        
        navigationController?.pushViewController(call, animated: true)
    }
    
    @IBAction func allMessages() {
        app?.chatManager?.queryAllMessages()
    }
}

extension ChatroomViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return app?.chatManager?.chatrooms.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: chatroomCellIdentifier, for: indexPath) as? ChatroomCell,
        let chatManager = app?.chatManager else {
            return UITableViewCell()
        }
        
        let chatroom = chatManager.chatrooms[indexPath.row]
        cell.titleLabel.text = chatroom.id
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = chatroom.modifiedDate {
            cell.timeLabel.text = formatter.string(from: date)
        } else {
            cell.timeLabel.text = ""
        }
        
        return cell
    }

}

extension ChatroomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let chatroom = app?.chatManager?.chatrooms[indexPath.row] {
            let ctrl = MessageViewController(nibName: "MessageViewController", bundle: nil)
            ctrl.chatroom = chatroom
            navigationController?.pushViewController(ctrl, animated: true)
        }
    }
}

extension ChatroomViewController: ChatManagerChatroomDelegate {
    func chatroomDidChange() {
        tableView?.reloadData()
    }
}

extension ChatroomViewController: UsersTableViewControllerDelegate {
    func didSingleTap(users: [String]) {
        app?.chatManager?.createChatroom(users: users, title: nil, imageUrl: nil, completionHandler: { (roomId) in
            print(roomId ?? "createChatRoom error")
        })
    }
}
