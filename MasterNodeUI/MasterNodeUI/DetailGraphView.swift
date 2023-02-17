//
//  SwiftUIView.swift
//  MasterNodeUI
//
//  Created by Gabriel Morales on 12/18/22.
//

import SwiftUI
import Charts

struct DetailGraphView: View {
    
    var maliciousReports: [MalCountsData]
    var benignReports: [BenCountsData]
    
    var body: some View {
        NavigationStack {
 
                Chart {
                    ForEach(maliciousReports) { item in
                        LineMark(
                            x: .value("Time", item.time),
                            y: .value("Mal. Reports", item.cnt)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .symbol(Circle())
                        .foregroundStyle(Color.red)
                        AreaMark(
                            x: .value("Time", item.time),
                            y: .value("Mal. Reports", item.cnt)
                        )
                        .foregroundStyle(LinearGradient(colors: [Color.red.opacity(0.99), Color.red.opacity(0.25)], startPoint: .top, endPoint: .bottom))
                    }
                }
                .frame(width: 350, height: 300)
                .navigationTitle("Traffic Trends")
                .frame(alignment: .center)
        }
        
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        
        let time1 = Date.now.advanced(by: 10).formatted(date:.omitted, time: .shortened)
        let time2 = Date.now.advanced(by: 60).formatted(date:.omitted, time: .shortened)
        let time3 = Date.now.advanced(by: 90).formatted(date:.omitted, time: .shortened)
        let time4 = Date.now.advanced(by: 1000).formatted(date:.omitted, time: .shortened)
        
        DetailGraphView(maliciousReports: [MalCountsData(cnt: 50, time: time1), MalCountsData(cnt: 100, time: time2), MalCountsData(cnt: 50, time: time4)], benignReports: [BenCountsData(cnt: 30, time: time3), BenCountsData(cnt: 20, time: time4)])
        
    }
}
