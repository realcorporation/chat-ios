//
//  UsersTableViewController.swift
//  RTC
//
//  Created by king on 2/7/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation

protocol UsersTableViewControllerDelegate: NSObject {
    func didSingleTap(users: [String])
}

class UsersTableViewController: UITableViewController {
    var isMultiSelection = false
    weak var delegate: UsersTableViewControllerDelegate?
    
    private let cellIdentifier = "UserCell"
    
    private var usersList = [MemberUser]()
    private var selectedUsersId = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add chatroom", style: .plain, target: self, action: #selector(addChatroom))
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        guard let chatManager = delegate?.chatManager else {
            return
        }
        
        if !isMultiSelection {
            usersList = chatManager.memberUsers.filter{ $0.userId != chatManager.uid }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        let user = usersList[indexPath.row]
        cell.textLabel?.text = user.userId
        cell.detailTextLabel?.text = user.online ? "Online" : "Offline"
        
        if selectedUsersId.contains(user.userId) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = usersList[indexPath.row]
        let userId = user.userId
        
        if selectedUsersId.contains(userId) {
            selectedUsersId.remove(userId)
        } else {
            selectedUsersId.insert(userId)
        }
        
        tableView.reloadData()
    }
    
    @objc func addChatroom(sender: UIBarButtonItem) {
        guard selectedUsersId.count >= 1 else {
            return
        }
        
        if selectedUsersId.count == 1 {
            delegate?.didSingleTap(users: Array(selectedUsersId))
            navigationController?.popViewController(animated: true)
        } else {
            let createGroup = CreateGroupViewController(nibName: "CreateGroupViewController", bundle: nil)
            createGroup.usersId = Array(selectedUsersId)
            navigationController?.pushViewController(createGroup, animated: true)
        }
    }
}

extension UsersTableViewController: ChatManagerUserDelegate {
    func memberUserDidChange() {
        self.tableView.reloadData()
    }
}
