//
//  CellReport.swift
//  MasterNodeUI
//
//  Created by Gabriel Morales on 12/12/22.
//

import SwiftUI

struct CellReport: View {
    
    var cellInfo: InfObject
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .frame(width: 45)
                    .foregroundColor(
                       (cellInfo.getMaliciousCnt() > cellInfo.getBenignCnt()) ? Color.red.opacity(0.5) : Color.green.opacity(0.5)
                    )
                    .overlay(Circle()
                        .stroke(
                            (cellInfo.getMaliciousCnt() > cellInfo.getBenignCnt()) ? Color.red : Color.green, lineWidth: 5))
                    
                Image(systemName: "shield.lefthalf.filled")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size:20))
                    .frame(alignment: .center)
            }
            Spacer().frame(maxWidth: 25)
            VStack(alignment: .leading) {
                Text("\(cellInfo.macAddress.uppercased())")
                    .foregroundColor(
                       (cellInfo.getMaliciousCnt() > cellInfo.getBenignCnt()) ? Color.red : Color.green
                    )
                    .font(.system(size: 23))
                    .bold()
                Spacer().frame(maxHeight: 5)
                HStack {
                    Text("Suspicious - \(cellInfo.getMaliciousCnt())")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    Spacer()
                        .frame(maxWidth: 25)
                    Text("Normal - \(cellInfo.getBenignCnt())")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
            }
        }
        
    }
}

struct CellReport_Previews: PreviewProvider {
    static var previews: some View {
        CellReport(cellInfo: InfObject(withMac: "AB:CD:EF:GH:IJ:KL"))
    }
}
