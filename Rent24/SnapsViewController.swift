//
//  SnapsViewController.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 28/04/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit

class SnapsViewController: UIViewController {

    @IBOutlet weak var snapTypeControl: UISegmentedControl!
    @IBOutlet weak var snapsGrid: UICollectionView!
    @IBOutlet weak var contentLoadingView: UIActivityIndicatorView!
    @IBOutlet var addReceiptButton: UIBarButtonItem!
    @IBOutlet weak var firstNavigationItem: UINavigationItem!

    private var descriptionText: String = ""
    private var amount: Double = 0.0
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        return URLSession(configuration: configuration)
    }()
    private var token = ""
    private var dataSource: SnapsCellDataSource?
    private var cacheSnaps: SnapsSuccess?
    private var receiptImage: UIImage?
    private var receiptImageUrl: NSURL?

    @IBAction func snapValueChangeListener(_ sender: UISegmentedControl) {
        addReceiptButton(sender.selectedSegmentIndex)
        requestSnaps(for: sender.selectedSegmentIndex)
    }

    @IBAction func addReceiptButtonClickListener(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            self.showImagePicker()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentLoadingView.startAnimating()
        addReceiptButton(snapTypeControl.selectedSegmentIndex)
        token = getTokenFromKeychain()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        requestSnaps(for: snapTypeControl.selectedSegmentIndex)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    private func addReceiptButton(_ index: Int) {
        if 2 != index {
            firstNavigationItem.setRightBarButton(nil, animated: true)
        } else {
            firstNavigationItem.setRightBarButton(addReceiptButton, animated: true)
        }
    }

    private func createAddReceiptAlert() -> UIAlertController {
        let alert = UIAlertController(title: "Add Receipt", message: "Type receipt description and amount", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: {_ in
            guard let descriptionField = alert.textFields?.first,
            let amountField = alert.textFields?[1] else {
                return
            }
            if descriptionField.hasText,
                amountField.hasText,
                let dText = descriptionField.text,
                let aText = amountField.text {
                self.descriptionText = dText
                self.amount = Double(aText)!
                let imageData = self.receiptImage?.pngData()!
                var request = URLRequest(url: URL(string: "http://www.technidersolutions.com/sandbox/rmc/public/api/job/status")!)
                request.httpMethod = "POST"
                let boundary = "Boundary-\(UUID.init().uuidString)"
                request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")

                var body = "--\(boundary)\r\n".data(using: .utf8)!
                let filename = self.receiptImageUrl?.lastPathComponent!
                body.append("Content-Disposition:form-data; name=\"snap[]\"; filename=\"\(filename!)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/*\r\n\r\n".data(using: .utf8)!)
                body.append(imageData!)
                body.append("\r\n".data(using: .utf8)!)

                let formDataPairs = [
                    "status": "receipt",
                    "title": dText,
                    "amount": String(self.amount),
                    "jobid": "24"
                ]
                var formData = Data()
                for (k, v) in formDataPairs {
                    formData.append("--\(boundary)\r\n".data(using: .utf8)!)
                    formData.append("Content-Disposition: form-data; name=\"\(k)\"\r\n\r\n".data(using: .utf8)!)
                    formData.append("\(v)\r\n".data(using: .utf8)!)
                }

                body.append(formData)
                body.append("--\(boundary)--\r\n".data(using: .utf8)!)

                request.httpBody = body

                let task = self.session.dataTask(with: request) { data, response, error in
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
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let responseJson = try? decoder.decode(StatusResponse.self, from: data)
                        print("data", responseJson?.success)
                    }
                }
                task.resume()
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: {_ in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Enter description:"
            textField.keyboardType = .default
        })
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Enter amount:"
            textField.keyboardType = .decimalPad
        })
        return alert
    }

    private func showImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }

    private func getTokenFromKeychain() -> String {
        let searchQuery: [CFString:Any] = [kSecClass: kSecClassGenericPassword,
                                           kSecAttrGeneric: "com.rent24.driver.identifier".data(using: .utf8)!,
                                           kSecAttrAccount: "driver".data(using: .utf8)!,
                                           kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                           kSecReturnAttributes: kCFBooleanTrue!,
                                           kSecMatchLimit: kSecMatchLimitOne,
                                           kSecReturnData: kCFBooleanTrue!]
        var item: CFTypeRef?
        let searchStatus = SecItemCopyMatching(searchQuery as CFDictionary, &item)
        if errSecSuccess == searchStatus {
            guard let foundItem = item as? [String:Any],
                let tokenData = foundItem[kSecValueData as String] as? Data,
                let token = String(data: tokenData, encoding: .utf8)
                else {
                    dismiss(animated: true, completion: nil)
                    return ""
            }
            return token
        }
        return ""
    }

    private func requestSnaps(for type: Int) {
        contentLoadingView.startAnimating()
        if nil != cacheSnaps {
            loadData(for: type)
            snapsGrid.dataSource = dataSource
            snapsGrid.reloadData()
        }
        var url = URLComponents(string: "http://www.technidersolutions.com/sandbox/rmc/public/api/job/snaps")!
        url.queryItems = [
            URLQueryItem(name: "jobid", value: "24")
        ]
        var request = URLRequest(url: url.url!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let task = session.dataTask(with: request) { data, response, error in
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
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let responseJson = try? decoder.decode(SnapsResponse.self, from: data)
                self.cacheSnaps = responseJson?.success
                self.loadData(for: type)
                DispatchQueue.main.async {
                    self.snapsGrid.dataSource = self.dataSource
                    self.snapsGrid.reloadData()
                }
            }
            DispatchQueue.main.async {
                self.contentLoadingView.stopAnimating()
            }
        }
        task.resume()
    }

    private func loadData(for type: Int) {
        switch type {
        case 0:
            dataSource = SnapsCellDataSource(snaps: cacheSnaps!.pickup)
        case 1:
            dataSource = SnapsCellDataSource(snaps: cacheSnaps!.dropoff)
        case 2:
            dataSource = SnapsCellDataSource(snaps: cacheSnaps!.receipt)
        default:
            dataSource = SnapsCellDataSource(snaps: [])
        }
    }
}

extension SnapsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        if #available(iOS 11.0, *) {
            receiptImageUrl = (info[.imageURL] as! NSURL)
        } else {
            // Fallback on earlier versions
            receiptImageUrl = (info[.referenceURL] as! NSURL)
        }
        receiptImage = image
        dismiss(animated: true, completion: nil)
        let alert = createAddReceiptAlert()
        present(alert, animated: true, completion: nil)
    }
}
