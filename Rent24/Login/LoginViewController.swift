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
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        return URLSession(configuration: configuration)
    }()
    weak var delegate: LoginViewControllerDelegate?

    @IBAction func performSignin(_ sender: Any) {
        loadingView.startAnimating()
        signin.isEnabled = false
        email.isEnabled = false
        password.isEnabled = false

        let url = URL(string: "http://www.technidersolutions.com/sandbox/rmc/public/api/login")!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody = LoginRequest(email: email.text!, password: password.text!, device_token: "ios")
        let encoder = JSONEncoder()
        let body = try? encoder.encode(requestBody)
        request.httpBody = body!
        request.httpMethod = "POST"
        let task: URLSessionTask = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("error occured", error.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
                else {
                    print("response error", response.debugDescription)
                    return
            }
            if let data = data {
                let decoder = JSONDecoder()
                let responseJson = try? decoder.decode(LoginResponse.self, from: data)
                let searchQuery: [CFString:Any] = [kSecClass: kSecClassGenericPassword,
                                           kSecAttrGeneric: "com.rent24.driver.identifier".data(using: .utf8)!,
                                           kSecAttrAccount: "driver".data(using: .utf8)!,
                                           kSecValueData: responseJson!.success!.token!.data(using: .utf8)!,
                                           kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
                let searchStatus = SecItemAdd(searchQuery as CFDictionary, nil)
                if searchStatus != errSecSuccess {
                    DispatchQueue.main.async {
                        self.emailError.text = "Error occurred, try again!"
                        self.signin.isEnabled = true
                        self.email.isEnabled = true
                        self.password.isEnabled = true
                        self.loadingView.stopAnimating()
                        self.delegate?.update(true)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: nil)
                        self.delegate?.update(false)
                    }
                }
            }
        }
        task.resume()
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if email.hasText, password.hasText, isValidEmail(testStr: email.text!) {
            signin.isEnabled = true
        } else {
            signin.isEnabled = false
        }
        return true
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

protocol LoginViewControllerDelegate: AnyObject {
    func update(_ login: Bool)
}
