//
//  SnapsViewController.swift

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

    @IBAction func snapValueChangeListener(_ sender: UISegmentedControl) {
        addReceiptButton(sender.selectedSegmentIndex)
        requestSnaps(for: sender.selectedSegmentIndex)
    }

    @IBAction func addReceiptButtonClickListener(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            performSegue(withIdentifier: "createReceiptDialog", sender: self)
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        guard let controller = segue.destination as? CreateReceiptTableViewController
            else {
                return
        }
        controller.token = token
    }

    private func addReceiptButton(_ index: Int) {
        if 2 != index {
            firstNavigationItem.setRightBarButton(nil, animated: true)
        } else {
            firstNavigationItem.setRightBarButton(addReceiptButton, animated: true)
        }
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
