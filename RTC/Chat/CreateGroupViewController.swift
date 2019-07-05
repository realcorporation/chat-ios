//
//  CreateGroupViewController.swift
//  RTC
//
//  Created by king on 4/7/2019.
//  Copyright © 2019 Real. All rights reserved.
//

import Foundation
import Firebase

class CreateGroupViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var groupImage: UIImageView!
    
    var usersId = [String]()
    
    private let storage = Storage.storage().reference()
    private let pickCtrl = UIImagePickerController()
    private var app = UIApplication.shared.delegate as? AppDelegate
    
    @IBAction func createGroup() {
        guard let image = groupImage.image, let chatManager = app?.chatManager, let title = groupNameTextField.text, usersId.count > 0 else {
            return
        }
        
        chatManager.uploadGroupThumbnail(image: image) { [weak self] (thumbnailUrl) in
            guard let `self` = self else {
                return
            }
            
            chatManager.createChatroom(users: self.usersId, title: title, imageUrl: thumbnailUrl, completionHandler: { [weak self] (roomId) in
                guard let _ = roomId else {
                    return
                }
                
                self?.navigationController?.popToRootViewController(animated: true)
            })
        }
    }
    
    @IBAction func selectPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            pickCtrl.delegate = self
            pickCtrl.sourceType = .savedPhotosAlbum
            present(pickCtrl, animated: true, completion: nil)
        }
    }
}

extension CreateGroupViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        groupImage.image = info[.originalImage] as? UIImage
    }
}
