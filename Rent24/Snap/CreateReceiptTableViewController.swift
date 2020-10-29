//
//  CreateReceiptTableViewController.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 13/06/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit

class CreateReceiptTableViewController: UITableViewController {

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var descriptionPicker: UIPickerView!

    private var options: [String]!
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        return URLSession(configuration: configuration)
    }()
    private var receiptImage: UIImage?
    private var receiptImageUrl: NSURL?
    var token: String!
    var jobId: String!

    @IBAction func onDoneClickListener(_ sender: UIBarButtonItem) {

        if amountTextField.hasText,
            let aText = amountTextField.text {

            let dText = options[descriptionPicker.selectedRow(inComponent: 0)]
            let imageData = self.receiptImage!.pngData()
            var request = URLRequest(url: URL(string: "http://www.technidersolutions.com/sandbox/rmc/public/api/job/status")!)
            request.httpMethod = "POST"
            let boundary = "Boundary-\(UUID.init().uuidString)"
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            var body = "--\(boundary)\r\n".data(using: .utf8)!
            let filename = self.receiptImageUrl?.lastPathComponent!
            body.append("Content-Disposition:form-data; name=\"snap[]\"; filename=\"\(filename!)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/*\r\n\r\n".data(using: .utf8)!)
            body.append(imageData!)
            body.append("\r\n".data(using: .utf8)!)
            
            let formDataPairs = [
                "status": "receipt",
                "title": dText,
                "amount": String(aText),
                "jobid": jobId
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
                    print("data", responseJson?.success ?? false)
                }
            }
            task.resume()
        }
    }

    @IBAction func onCancelClickListener(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        showImagePicker()

        options = ["Fuel", "Car wash", "Oil change"]

        descriptionPicker.dataSource = self
        descriptionPicker.delegate = self

        amountTextField.delegate = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

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

    private func showImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }
}

extension CreateReceiptTableViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
}

extension CreateReceiptTableViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
}

extension CreateReceiptTableViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if amountTextField.hasText {
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = false
        }
        return true
    }
}

extension CreateReceiptTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let image = info["originalImage"] as! UIImage
        if #available(iOS 11.0, *) {
            receiptImageUrl = (info["imageUrl"] as! NSURL)
        } else {
            // Fallback on earlier versions
            receiptImageUrl = (info["referenceURL"] as! NSURL)
        }
        receiptImage = image
        dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
