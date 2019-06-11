//
//  CarDetailTableViewController.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 02/06/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit
import NohanaImagePicker
import Photos

class CarDetailTableViewController: UITableViewController {

    @IBOutlet weak var condition: UIPickerView!
    @IBOutlet weak var fuelRangeTextField: UITextField!
    @IBOutlet weak var odometerTextField: UITextField!
    @IBOutlet weak var damageTextView: UITextView!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    private var options: [String]!
    private var picker: NohanaImagePickerController!
    private var pickedImageUrlsAndData: [NSURL: Data]!
    var status: String!
    var jobId: Int!
    weak var delegate: CarDetailStatusUpdateDelegate?
    var location: CLLocation!

    @IBAction func onCancelClickListener(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onSubmitClickListener(_ sender: UIBarButtonItem) {
        let token = getTokenFromKeychain()

        var request = URLRequest(url: URL(string: "http://www.technidersolutions.com/sandbox/rmc/public/api/job/status")!)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID.init().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()
        for (url, data) in pickedImageUrlsAndData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            let filename = url.lastPathComponent!
            body.append("Content-Disposition:form-data; name=\"snap[]\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/*\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        let formDataPairs: [String: String] = [
            "status": status,
            "jobid": String(jobId),
            "fuelrange": fuelRangeTextField.text!,
            "odometer": odometerTextField.text!,
            "condition": options[condition.selectedRow(inComponent: 0)],
            "damage": damageTextView.text!,
            "notes": notesTextView.text!,
            "latitude": String(location.coordinate.latitude),
            "longitude": String(location.coordinate.longitude)
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

        let configuration = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        let session = URLSession(configuration: configuration)
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
                let responseJson = try? decoder.decode(StatusResponse.self, from: data)
                print("data", responseJson?.success ?? false)
                DispatchQueue.main.async {
                    self.delegate?.update("4")
                }
                if MapViewController.dropOff == self.status {
                    let url = URL(string: "http://www.technidersolutions.com/sandbox/rmc/public/api/job/status")!
                    var request = URLRequest(url: url)
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    let body = JobStatusRequest(jobId: self.jobId, status: "finish")
                    let encoder = JSONEncoder()
                    request.httpBody = try? encoder.encode(body)
                    request.httpMethod = "POST"
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
                        if let data = data,
                            let responseJson = try? decoder.decode(StatusResponse.self, from: data) {
                            DispatchQueue.main.async {
                                self.delegate?.removePlaces()
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeTabController") as! UITabBarController
                                homeVC.selectedIndex = 0
                                self.present(homeVC, animated: true, completion: {
                                    self.dismiss(animated: true, completion: nil)
                                })
                            }
                            print("response data", responseJson)
                        }
                    }
                    task.resume()
                }
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        task.resume()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        submitButton.isEnabled = false
        picker = NohanaImagePickerController()
        picker.delegate = self
        present(picker, animated: true, completion: nil)

        condition.dataSource = self
        condition.delegate = self

        fuelRangeTextField.delegate = self
        odometerTextField.delegate = self

        options = ["Clean", "Dirty"]
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
                    return ""
            }
            return token
        }
        return ""
    }

    // MARK: - Table view data source

    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    */

    /*
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    */

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CarDetailTableViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
}

extension CarDetailTableViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
}

extension CarDetailTableViewController: NohanaImagePickerControllerDelegate {
    func nohanaImagePickerDidCancel(_ picker: NohanaImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func nohanaImagePicker(_ picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts: [PHAsset]) {
        pickedImageUrlsAndData = [NSURL:Data]()
        pickedAssts.filter({asset in PHAssetMediaType.image == asset.mediaType}).forEach({body in
            PHImageManager.default().requestImageData(for: body, options: PHImageRequestOptions(), resultHandler: { data, string, orientation, dict in
                if let info = dict,
                    info.keys.contains("PHImageFileURLKey"),
                    let imageUrl = info["PHImageFileURLKey"] as? NSURL,
                    let data = data,
                    let image = UIImage(data: data) {
                    let png = UIImagePNGRepresentation(image)
                    self.pickedImageUrlsAndData[imageUrl] = png
                }
            })
        })
        picker.dismiss(animated: true, completion: nil)
    }
}

extension CarDetailTableViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if fuelRangeTextField.hasText,
            odometerTextField.hasText {
            submitButton.isEnabled = true
        }
        return true
    }
}

protocol CarDetailStatusUpdateDelegate: AnyObject {
    func update(_ status: String)

    func removePlaces()
}
