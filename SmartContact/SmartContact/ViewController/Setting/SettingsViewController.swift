//
//  SettingsViewController.swift
//  SmartContact
//
//  Created by Thanh Tran Van on 9/5/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import UIKit
import CustomizableActionSheet

class SettingsViewController: BaseTableViewController {
     var actionSheet: CustomizableActionSheet?
    @IBOutlet weak var updateThemeCell: UITableViewCell!
    @IBOutlet weak var firtNameBeforeLast: UISwitch!
    @IBOutlet weak var subtitleWithEmail: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        updateColorSwich()
        firtNameBeforeLast.isOn = UserDefaults.showFirstNameBeforeLast
        subtitleWithEmail.isOn = UserDefaults.subtitleWithEmail
        tableView.backgroundColor = UIColor(hexString: "0xE5E5E5", alpha: 1)
    }

    @IBAction func updateFirstNameBeforeLast(_ sender: UISwitch) {
        UserDefaults.showFirstNameBeforeLast = sender.isOn
    }
    
    @IBAction func updateSubtitleWithEmail(_ sender: UISwitch) {
        UserDefaults.subtitleWithEmail = sender.isOn
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        switch cell {
        case updateThemeCell:
            selectThemeColor()
        default: break
        }
    }
    
    func selectThemeColor() {
        var items = [CustomizableActionSheetItem]()
        
        // First view
        if let sampleView = UINib(nibName: "SampleView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? SampleView {
            sampleView.delegate = self
            let sampleViewItem = CustomizableActionSheetItem(type: .view, height: 100)
            sampleViewItem.view = sampleView
            items.append(sampleViewItem)
        }
        let closeItem = CustomizableActionSheetItem(type: .button)
        closeItem.label = "Close"
        closeItem.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        closeItem.selectAction = { (actionSheet: CustomizableActionSheet) -> Void in
            actionSheet.dismiss()
        }
        items.append(closeItem)
        
        let actionSheet = CustomizableActionSheet()
        self.actionSheet = actionSheet
        actionSheet.showInView(self.view, items: items)
    }
    
    func updateColorSwich() {
        guard let hexColor = UserDefaults.smartContactThemeColor else { return }
        let color = UIColor(hexString: hexColor)
        firtNameBeforeLast.onTintColor = color
        subtitleWithEmail.onTintColor = color
    }
}

extension SettingsViewController: SampleViewDelegate {
    func setColor(color: UIColor) {
        if let actionSheet = self.actionSheet {
            actionSheet.dismiss()
        }
        UserDefaults.smartContactThemeColor = color.hexString(false)
        navigationController?.navigationBar.barTintColor = color
        NotificationCenter.default.post(name: .colorThemeChanged, object: nil)
        updateColorSwich()
    }
}
