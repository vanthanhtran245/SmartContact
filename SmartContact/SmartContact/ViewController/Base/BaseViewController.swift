//
//  BaseViewController.swift
//  SmartContact
//
//  Created by Thanh Tran Van on 9/5/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation
import SwipeCellKit
import ContactsUI
import Contacts
import SwiftyContacts

class BaseViewController: UIViewController {
    var defaultOptions = SwipeOptions()
    var isSwipeRightEnabled = true
    var buttonDisplayMode: ButtonDisplayMode = .imageOnly
    var buttonStyle: ButtonStyle = .backgroundColor
    var usesTallCells = false
    
    var emptyView:UIViewController? {
        if(_emptyView == nil) {
            _emptyView = UIStoryboard.main?.instantiateViewController(withIdentifier: "EmptyView")
        }
        return _emptyView
    }
    
    var _emptyView:UIViewController?

    
    func disPlayEmptyView(isShow: Bool) {
        if isShow {
            guard let emptyVC = emptyView else { return }
            view.addSubview(emptyVC.view)
            emptyVC.view.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalToSuperview()
                make.width.equalToSuperview()
            }
        } else {
            emptyView?.removeFromParentViewController()
            emptyView?.view.removeFromSuperview()
            _emptyView = nil
        }
        view.setNeedsLayout()
        guard let superView = view as? UITableView else { return }
        superView.separatorColor = isShow ? .clear : .lightGray
        superView.bounces = !isShow
    }
    
    func allowedContactKeys() -> [CNKeyDescriptor] {
        //We have to provide only the keys which we have to access. We should avoid unnecessary keys when fetching the contact. Reducing the keys means faster the access.
        return [CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactImageDataAvailableKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupThemeColor()
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(forName: .colorThemeChanged, object: nil, queue: nil, using: { _ in
            self.setupThemeColor()
        })
    }
    
    func setupThemeColor() {
        guard let hexColor = UserDefaults.smartContactThemeColor else { return }
        let color = UIColor(hexString: hexColor)
        self.navigationController?.navigationBar.barTintColor = color
        self.tabBarController?.tabBar.tintColor = color
    }
    
    
    func makeCallWithContact(selectedContact: Contact) {
        selectPhoneNumberWithActionSheet(selectedContact: selectedContact) { (phoneNumber, index) in
            guard let indexSelect = index else { return }
            makeCall(CNPhoneNumber: selectedContact.cnPhoneNumbers[indexSelect])
        }
    }
    
    func selectPhoneNumberWithActionSheet(selectedContact: Contact, completion:  @escaping SelectPhoneNumberCallBack) {
        if selectedContact.phoneNumbers.count > 1 {
            let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            selectedContact.phoneNumbers.enumerated().forEach { (arg) in
                let (index, item) = arg
                controller.addAction(title: item.phoneNumber, style: .default, isEnabled: true, handler: { _ in
                    completion(item.phoneNumber, index)
                })
            }
            controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(controller, animated: true, completion: nil)
        } else if selectedContact.phoneNumbers.count == 1 {
            completion(selectedContact.phoneNumbers[0].phoneNumber, 0)
        } else {
            completion(nil, nil)
        }
    }
}

class BaseTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupThemeColor()
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(forName: .colorThemeChanged, object: nil, queue: nil, using: { _ in
            self.setupThemeColor()
        })
    }
    
    func setupThemeColor() {
        guard let hexColor = UserDefaults.smartContactThemeColor else { return }
        let color = UIColor(hexString: hexColor)
        self.navigationController?.navigationBar.barTintColor = color
        self.tabBarController?.tabBar.tintColor = color
    }
}
