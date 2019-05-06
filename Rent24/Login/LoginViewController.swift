//
//  LoginViewController.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 07/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var signin: UIButton!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var emailError: UILabel!
    @IBOutlet weak var passwordError: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    @IBAction func performSignin(_ sender: Any) {
        loadingView.startAnimating()
        signin.isEnabled = false
        email.isEnabled = false
        password.isEnabled = false

        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        signin.isEnabled = false
        email.delegate = self
        password.delegate = self
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LoginViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if email.tag == textField.tag {
            emailError.text = ""
        } else if password.tag == textField.tag {
            passwordError.text = ""
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if email.tag == textField.tag, email.hasText {
            if !isValidEmail(testStr: email.text!) {
                emailError.text = "Invalid email format"
            } else {
                emailError.text = ""
            }
        }
        if email.hasText, password.hasText, isValidEmail(testStr: email.text!) {
            signin.isEnabled = true
        } else {
            signin.isEnabled = false
        }
    }

    private func isValidEmail(testStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
