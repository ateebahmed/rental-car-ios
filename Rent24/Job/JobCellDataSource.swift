//
//  JobCellDataSource.swift
//  
//
//  Created by Ateeb Ahmed on 13/05/2019.
//

import UIKit

class JobCellDataSource: NSObject {
    let trips: [JobTrip]

    init(trips: [JobTrip]) {
        self.trips = trips
    }
}

extension JobCellDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: JobTableViewCell.self)) as! JobTableViewCell
        let trip = trips[indexPath.row]
        cell.from = trip.pickupLocation
        cell.to = trip.dropoffLocation
        cell.when = trip.startTime
        cell.type = trip.jobType
        return cell
    }
}
