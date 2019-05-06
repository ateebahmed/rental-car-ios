//
//  MainViewController.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 01/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var contentLoadingView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        contentLoadingView.startAnimating()
    }

    override func viewDidAppear(_ animated: Bool) {
        performSegue(withIdentifier: "showLoginScene", sender: self)
//        show home screen performSegue(withIdentifier: "gotoHomeScene", sender: self)
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
