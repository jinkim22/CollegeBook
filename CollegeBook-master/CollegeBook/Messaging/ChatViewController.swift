/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView
import Photos

final class ChatViewController: MessagesViewController {

    var channel: Channel
    private var messages: [Message] = []
    private var messageListener: ListenerRegistration?
    private let db = Firestore.firestore()
    private var reference: CollectionReference?
    let school = UserDefaults.standard.string(forKey: "School") ?? ""
    
    private let storage = Storage.storage().reference()
    
    deinit {
        messageListener?.remove()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            if let vc = self as? MessagesTableViewController {
                print("YOYO")
            }
        }
    }
    
    init(channel: Channel) {
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
        
        title = channel.otherUser.name
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let id = channel.channelID
                
        reference = db.collection(["Schools", school.concatenated, "Channels", id, "thread"].joined(separator: "/"))
        
        messageListener = reference?.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            
            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change)
            }
        }
        
        navigationItem.largeTitleDisplayMode = .never
        
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        messageInputBar.sendButton.setTitleColor(.blue, for: .normal)
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        //         1
        let cameraItem = InputBarButtonItem(type: .system)
        cameraItem.tintColor = .black
        cameraItem.image = #imageLiteral(resourceName: "camera")
        
        // 2
        cameraItem.addTarget(
            self,
            action: #selector(cameraButtonPressed),
            for: .primaryActionTriggered
        )
        cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
        
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        
        //3
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
        
    }
    
    // MARK: - Actions
    @objc private func cameraButtonPressed() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    private func uploadImage(_ image: UIImage, to channel: Channel, completion: @escaping (URL?) -> Void) {
        let imageName = UUID().uuidString
        writeImageToDatabase(image: image, name: imageName, channelID: channel.channelID)
    }
    
    private func writeImageToDatabase(image: UIImage, name: String, channelID: String) {
        let storageRef = Storage.storage().reference()
        let data = image.jpegData(compressionQuality: CGFloat(0.5))!
        let imageRef = storageRef.child("Schools/\(school.concatenated)/Channels/\(channelID)/\(name).jpg")
        
        imageRef.putData(data, metadata: nil) { (metadata, error) in
            imageRef.downloadURL { (url, error) in
                if let downloadURL = url {
                    print(downloadURL)
                }
            }
        }
    }
    
    private func sendPhoto(_ image: UIImage) {
        // isSendingPhoto = true
        
        let imageName = UUID().uuidString
        
        let storageRef = Storage.storage().reference()
        let data = image.jpegData(compressionQuality: CGFloat(0.5))!
        let imageRef = storageRef.child("Schools/\(school.concatenated)/Channels/\(channel.channelID)/\(imageName).jpg")
        
        imageRef.putData(data, metadata: nil) { (metadata, error) in
            imageRef.downloadURL { (url, error) in
                var message = Message(user: self.channel.currentUser, otherUser: self.channel.otherUser, image: image)
                message.downloadURL = url
                self.save(message)
                self.messagesCollectionView.scrollToBottom()
            }
        }
    }
    
    private func save(_ message: Message) {
        reference?.addDocument(data: message.representation) { error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
            
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    
    private func insertNewMessage(_ message: Message) {
        guard !messages.contains(message) else {
            return
        }
        
        messages.append(message)
        messages.sort()
        
        // let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
        let shouldScrollToBottom = true
        // messagesCollectionView.isAtBottom && isLatestMessage
        
        messagesCollectionView.reloadData()
        
        if shouldScrollToBottom {
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        guard var message = Message(document: change.document) else {
            return
        }
        
        switch change.type {
        case .added:
            if let url = message.downloadURL {
                downloadImage(at: url) { [weak self] image in
                    guard let self = self else {
                        return
                    }
                    guard let image = image else {
                        return
                    }
                    
                    message.image = image
                    self.insertNewMessage(message)
                }
            } else {
                insertNewMessage(message)
            }
        default:
            break
        }
    }
}

private func downloadImage(at url: URL, completion: @escaping (UIImage?) -> Void) {
    let ref = Storage.storage().reference(forURL: url.absoluteString)
    let megaByte = Int64(1 * 1024 * 1024)
    
    ref.getData(maxSize: megaByte) { data, error in
        guard let imageData = data else {
            completion(nil)
            return
        }
        
        completion(UIImage(data: imageData))
    }
    
}


// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
    
    //    func avatarSize(for message: MessageType, at indexPath: IndexPath,
    //                    in messagesCollectionView: MessagesCollectionView) -> CGSize {
    //
    //        // 1
    //        return .zero
    //    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if isFromCurrentSender(message: message) {
            ImageCache.getImage(with: "Schools/\(school.concatenated)/UserImages/\(channel.currentUser.uid).jpg") { image in
                avatarView.image = image
            }
        } else {
            ImageCache.getImage(with: "Schools/\(school.concatenated)/UserImages/\(channel.otherUser.uid).jpg") { image in
                avatarView.image = image
            }
        }
    }
    
    //  func footerViewSize(for message: MessageType, at indexPath: IndexPath,
    //                      in messagesCollectionView: MessagesCollectionView) -> CGSize {
    //
    //    // 2
    //    return CGSize(width: 0, height: 0)
    //  }
    
    //    func heightForLocation(message: MessageType, at indexPath: IndexPath,
    //                           with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    //
    //        // 3
    //        return 0
    //    }
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
    
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        // 1
        return isFromCurrentSender(message: message) ? .blue : .green
    }
    
    func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) -> Bool {
        
        // 2
        return false
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        
        // 3
        return .bubbleTail(corner, .curved)
    }
    
}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // 1
    func currentSender() -> SenderType {
        return Sender(senderId: channel.currentUser.uid, displayName: channel.currentUser.name)
    }
    
    // 3
    func messageForItem(at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
    }
    
    // 4
    //  func cellTopLabelAttributedText(for message: MessageType,
    //                                  at indexPath: IndexPath) -> NSAttributedString? {
    //
    //    let name = message.sender.displayName
    //    return NSAttributedString(
    //      string: name,
    //      attributes: [
    //        .font: UIFont.preferredFont(forTextStyle: .caption1),
    //        .foregroundColor: UIColor(white: 0.3, alpha: 1)
    //      ]
    //    )
    //  }
}
// MARK: - MessageInputBarDelegate



extension ChatViewController: MessageInputBarDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        // 1
        let message = Message(user: channel.currentUser, otherUser: channel.otherUser, content: text)
        
        // 2
        save(message)
        
        // 3
        inputBar.inputTextView.text = ""
    }
    
}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        // 1
        if let asset = info[.phAsset] as? PHAsset {
            let size = CGSize(width: 500, height: 500)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFit,
                options: nil) { result, info in
                    
                    guard let image = result else {
                        return
                    }
                    
                    print("about to send the photo!!")
                    self.sendPhoto(image)
            }
            
            // 2
        } else if let image = info[.editedImage] as? UIImage {
            sendPhoto(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
