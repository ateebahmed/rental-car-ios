//
//  SnapCellDataSource.swift

//
//  Created by Ateeb Ahmed on 19/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit
import Kingfisher

class SnapsCellDataSource: NSObject {
    let snaps: [String]

    init(snaps: [String]) {
        self.snaps = snaps
    }
}

extension SnapsCellDataSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return snaps.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SnapsCollectionViewCell.self), for: indexPath) as! SnapsCollectionViewCell
        cell.imageCell.kf.setImage(with: URL(string: snaps[indexPath.item]))
        return cell
    }
}
