//
//  FirstViewController.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 27/04/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit
import UserNotifications

class JobViewController: UIViewController {

    @IBOutlet weak var contentLoadingView: UIActivityIndicatorView!
    @IBOutlet weak var jobTableView: UITableView!
    @IBOutlet weak var selectedJobType: UISegmentedControl!

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        return URLSession(configuration: configuration)
    }()
    private var token = ""
    var dataSource: JobCellDataSource?

    @IBAction func jobTypeValueChange(_ sender: UISegmentedControl) {
        loadJobList(for: sender.selectedSegmentIndex)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        contentLoadingView.startAnimating()

        jobTableView.estimatedRowHeight = 80
        jobTableView.rowHeight = UITableView.automaticDimension

        jobTableView.delegate = self

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
                    return
            }
            self.token = token
        }
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        loadJobList(for: selectedJobType.selectedSegmentIndex)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let detailViewController = segue.destination as? JobDetailViewController,
        let index = jobTableView.indexPathForSelectedRow?.row
            else {
                return
        }
        detailViewController.trip = dataSource?.trips[index]
    }

    private func loadJobList(for type: Int) {
        contentLoadingView.startAnimating()

        var jobType = ""
        switch type {
        case 0:
            jobType = "schedule"
        case 1:
            jobType = "history"
        default:
            jobType = ""
        }
        let url = URL(string: "http://www.technidersolutions.com/sandbox/rmc/public/api/job/\(jobType)")!
        var request = URLRequest(url: url)
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
                let responseJson = try? decoder.decode(JobResponse.self, from: data)
                if let jobResponse = responseJson {
                    self.dataSource = JobCellDataSource(trips: jobResponse.success)
                    if let trip = jobResponse.success.compactMap({trip in trip}).filter({trip in 3 ... 4 ~= trip.statusInt!}).first {
                        if let date = trip.startTimeDate {
                            let currentDate = Date()
                            
                        }
                    } else if let trip = jobResponse.success.compactMap({trip in trip}).filter({trip in 2 == trip.statusInt}).first {
                        
                    }
                }

                let title = "Rent 24 Job Alert"
                let body = "A new job has started"
                if #available(iOS 10.0, *) {
                    let notification = UNMutableNotificationContent()
                    notification.title = title
                    notification.body = body
                    notification.sound = UNNotificationSound.default

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: trigger)
                    DispatchQueue.main.async {
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: {error in print(error.debugDescription, error)})
                    }
                } else {
                    let notification = UILocalNotification()
                    notification.fireDate = try? Date(timeIntervalSinceNow: 1)
                    notification.alertBody = "Testing notification from local"
                    notification.timeZone = TimeZone.current
                    notification.userInfo = ["Key":"Value"]
                    notification.soundName = UILocalNotificationDefaultSoundName
                    notification.category = "jobReminder"
                    notification.applicationIconBadgeNumber = 1
                    DispatchQueue.main.async {
                        UIApplication.shared.scheduleLocalNotification(notification)
                    }
                }

                DispatchQueue.main.async {
                    self.jobTableView.dataSource = self.dataSource
                    self.jobTableView.reloadData()
                    self.contentLoadingView.stopAnimating()
                }
            }
        }
        task.resume()
    }
}

extension JobViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showJobDetail", sender: self)
    }
}
