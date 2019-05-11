//
//  MainViewController.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 01/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var contentLoadingView: UIActivityIndicatorView!

    var needToLogin = true

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        contentLoadingView.startAnimating()
    }

    override func viewDidAppear(_ animated: Bool) {
        if needToLogin {
            var searchQuery: [CFString:Any] = [kSecClass: kSecClassGenericPassword,
                                               kSecAttrGeneric: "com.rent24.driver.identifier".data(using: .utf8)!,
                                               kSecAttrAccount: "driver".data(using: .utf8)!,
                                               kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
            // TODO: part of development, should remove once app is ready
            SecItemDelete(searchQuery as CFDictionary)
            searchQuery[kSecReturnAttributes] = kCFBooleanTrue!
            searchQuery[kSecMatchLimit] = kSecMatchLimitOne
            var item: CFTypeRef?
            let searchStatus = SecItemCopyMatching(searchQuery as CFDictionary, &item)
            if errSecSuccess != searchStatus {
                performSegue(withIdentifier: "showLoginScene", sender: self)
            } else {
                performSegue(withIdentifier: "gotoHomeScene", sender: self)
            }
        } else {
            contentLoadingView.stopAnimating()
            performSegue(withIdentifier: "gotoHomeScene", sender: self)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        guard let loginController = segue.destination as? LoginViewController
            else {
                return
        }
        loginController.delegate = self
    }
}

extension MainViewController: LoginViewControllerDelegate {
    func update(_ login: Bool) {
        self.needToLogin = login
    }
}
