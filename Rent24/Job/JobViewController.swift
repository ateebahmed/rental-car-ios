//
//  FirstViewController.swift

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
    let twoHoursInterval = 2 * 60 * 60
    let offset = 5.0

    @IBAction func jobTypeValueChange(_ sender: UISegmentedControl) {
        loadJobList(for: sender.selectedSegmentIndex)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        contentLoadingView.startAnimating()

        jobTableView.estimatedRowHeight = 100
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
                if let responseJson = try? decoder.decode(JobResponse.self, from: data) {
                    self.dataSource = JobCellDataSource(trips: responseJson.success)
                    if 0 == type {
                        if let trip = responseJson.success.compactMap({trip in trip}).filter({trip in 2 ... 4 ~= trip.statusInt!}).first {
                            self.sendNotification(for: trip)
                        }
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

    private func sendNotification(for trip: JobTrip) {
        if let date = trip.startTimeDate {
            var pickupDate = Date(timeInterval: TimeInterval(-self.twoHoursInterval), since: date)
            if pickupDate < Date() {
                pickupDate = Date(timeIntervalSinceNow: self.offset)
            }
            sendNotifcation(on: pickupDate, with: trip)
        }
    }

    private func sendNotifcation(on date: Date, with trip: JobTrip) {
        let title = "Job Alert"
        let body = "A new job has started"
        let identifier = "jobReminder"
        DispatchQueue.main.async {
            if let settings = UIApplication.shared.currentUserNotificationSettings {
                if !(settings.types.intersection([.alert, .badge, .sound]).isEmpty) {
                    let notification = UILocalNotification()
                    notification.fireDate = date
                    if #available(iOS 8.2, *) {
                        notification.alertTitle = title
                    }
                    notification.alertBody = body
                    notification.timeZone = TimeZone.current
                    notification.userInfo = [
                        "type": "ACIVE_JOB_MAP_REQUEST",
                        "pickupLat": trip.pickupLat!,
                        "pickupLong": trip.pickupLong!,
                        "dropOffLat": trip.dropoffLat!,
                        "dropOffLong": trip.dropoffLong!,
                        "jobId": trip.id
                    ]
                    notification.soundName = UILocalNotificationDefaultSoundName
                    notification.category = identifier
                    notification.applicationIconBadgeNumber = 1
                    UIApplication.shared.scheduleLocalNotification(notification)
                }
            }
        }
    }
}

extension JobViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showJobDetail", sender: self)
    }
}
