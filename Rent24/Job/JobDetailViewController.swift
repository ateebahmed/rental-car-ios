//
//  JobDetailNavigationController.swift

//
//  Created by Ateeb Ahmed on 17/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit

class JobDetailViewController: UITableViewController {

    @IBOutlet weak var rcmIdLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var whenLabel: UILabel!
    @IBOutlet weak var clientLabel: UILabel!
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var taskLabel: UILabel!
    
    var trip: JobTrip?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        rcmIdLabel.text = trip?.rcmId
        fromLabel.text = trip?.pickupLocation
        toLabel.text = trip?.dropoffLocation
        whenLabel.text = trip?.startTime
        typeLabel.text = trip?.jobType
        taskLabel.text = trip?.task
    }
}
