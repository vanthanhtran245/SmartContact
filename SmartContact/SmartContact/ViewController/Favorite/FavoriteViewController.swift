//
//  FavoriteViewController.swift
//  SmartContact
//
//  Created by Sunflower on 9/4/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import UIKit
import ContactsUI
import Contacts
import SwipeCellKit
import Messages
import MessageUI

class FavoriteViewController: BaseViewController {
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    var contacts:[Contact] = []
}

//MARK: Systems override
extension FavoriteViewController {
    open override func loadView() {
        self.view = tableView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        registerContactCell()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let result = FavoriteHelper.shared.favoriteContacts
        let cnContact = result.map({ $0.cnContact })
        let
        
        contacts = cnContact.compactMap({ item in
            guard let ctmutable = item as? CNMutableContact,
                let ct = ctmutable.copy() as? CNContact else { return nil }
            return Contact(contact: ct)
        })
        tableView.reloadData()
        updateEmptyState()
    }
}

extension FavoriteViewController {
    private func registerContactCell() {
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: GlobalConstants.Strings.bundleIdentifier, withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                let cellNib = UINib(nibName: GlobalConstants.Strings.cellNibIdentifier, bundle: bundle)
                tableView.register(cellNib, forCellReuseIdentifier: "Cell")
            }
            else {
                assertionFailure("Could not load bundle")
            }
        } else {
            let cellNib = UINib(nibName: GlobalConstants.Strings.cellNibIdentifier, bundle: podBundle)
            tableView.register(cellNib, forCellReuseIdentifier: "Cell")
        }
    }
    
    @IBAction func addNewContactFavorite(_ sender: Any) {
        let alert = UIAlertController(style: .actionSheet)
        alert.addContactsPicker(contacts: contacts, selection: { contacts in
            let contactFromModel = Set(contacts.map({ $0.value }))
            let currentContact = self.contacts.map({ $0.contacts?.copy() as! CNContact })
            let receivedContacts = contactFromModel.symmetricDifference(currentContact)
            receivedContacts.forEach({ item in
                let contact = Contact(contact: item)
                FavoriteHelper.shared.updateFavorite(contact: contact)
                self.contacts.append(Contact(contact: item))
            })
            self.tableView.reloadData()
            self.updateEmptyState()
        })
        alert.addAction(title: "Cancel", style: .cancel)
        alert.show()
    }
    
    func updateEmptyState() {
        disPlayEmptyView(isShow: contacts.count == 0)
    }
}

//MARK Delegate
extension FavoriteViewController: UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    // MARK: - Table View Delegates
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ContactCell
        //Convert CNContact to Contact
        let contact = contacts[indexPath.row]
        cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: .phoneNumber)
        cell.delegate = self
        return cell
    }
    
    public func visibleRect(for tableView: UITableView) -> CGRect? {
        if usesTallCells == false { return nil }
        if #available(iOS 11.0, *) {
            return tableView.safeAreaLayoutGuide.layoutFrame
        } else {
            let topInset = navigationController?.navigationBar.frame.height ?? 0
            let bottomInset = navigationController?.toolbar?.frame.height ?? 0
            let bounds = tableView.bounds
            return CGRect(x: bounds.origin.x, y: bounds.origin.y + topInset, width: bounds.width, height: bounds.height - bottomInset)
        }
    }
    
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = contacts[indexPath.row]
        makeCallWithContact(selectedContact: contact)
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

extension FavoriteViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let cell = tableView.cellForRow(at: indexPath) as! ContactCell
        let selectedContact =  cell.contact!
        if orientation == .left {
            guard isSwipeRightEnabled else { return nil }
            let message = SwipeAction(style: .default, title: nil) { action, indexPath in
                self.selectPhoneNumberWithActionSheet(selectedContact: selectedContact, completion: { (phoneNumber, index) in
                    guard let number = phoneNumber, MFMessageComposeViewController.canSendText() else { return }
                    let composeVC = MFMessageComposeViewController()
                    composeVC.messageComposeDelegate = self
                    composeVC.recipients = [number]
                    composeVC.body = ""
                    self.present(composeVC, animated: true, completion: nil)
                })
            }
            configure(action: message, with: .message)
            let actions = [message]
            actions.forEach({ $0.hidesWhenSelected = true })
            return actions
        } else {
            let delete = SwipeAction(style: .default, title: nil) { action, indexPath in
                self.showAlert(title: "Message", message: "Do you want to delete contact into favorite", buttonTitles: ["OK", "Cancel"], highlightedButtonIndex: 1, completion: { index in
                    if index == 0 {
                        FavoriteHelper.shared.updateFavorite(contact: selectedContact)
                        self.contacts.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        self.updateEmptyState()
                    } else {
                        cell.hideSwipe(animated: true)
                    }
                })
            }
            configure(action: delete, with: .trash)
            let actions = [delete]
            actions.forEach({ $0.hidesWhenSelected = true })
            return actions
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeTableOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        switch buttonStyle {
        case .backgroundColor:
            options.buttonSpacing = 5
        case .circular:
            options.buttonSpacing = 4
            options.backgroundColor = #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1)
        }
        return options
    }
    
    func configure(action: SwipeAction, with descriptor: ActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }
}

extension FavoriteViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
