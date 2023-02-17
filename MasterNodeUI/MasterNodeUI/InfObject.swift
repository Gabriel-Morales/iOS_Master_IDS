//
//  InfObject.swift
//  MasterNodeUI
//
//  Created by Gabriel Morales on 12/15/22.
//

import Foundation


struct InfObject: Hashable, Identifiable {
    var id: UUID = UUID()
    public let macAddress: String
    private var benignCnt: Int
    private var malCnt: Int
    
    init(withMac mac: String) {
        self.macAddress = mac
        self.benignCnt = 0
        self.malCnt = 0
    }
    
    public mutating func updateMalCnt(byAmount amt: Int) -> Void {
        self.malCnt += amt
    }
    
    public mutating func updateBenCnt(byAmount amt: Int) -> Void {
        self.benignCnt += amt
    }
    
    public mutating func setMalCount(toAmt amt: Int) -> Void {
        self.malCnt = amt
    }
    
    public mutating func setBenCount(toAmt amt: Int) -> Void {
        self.benignCnt = amt
    }
    
    
    public func getMaliciousCnt() -> Int {
        return self.malCnt
    }
    
    public func getBenignCnt() -> Int {
        return self.benignCnt
    }
    
    public func getMac() -> String {
        return self.macAddress
    }
    
}
