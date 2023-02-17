//
//  BenCountsData.swift
//  MasterNodeUI
//
//  Created by Gabriel Morales on 12/18/22.
//

import Foundation


class BenCountsData: Identifiable {
    var id: UUID = UUID()
    var cnt: Int
    var time: String
    
    init(cnt: Int, time: String) {
        self.cnt = cnt
        self.time = time
    }
}
