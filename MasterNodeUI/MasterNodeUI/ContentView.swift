import SwiftUI


struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject var mastercoord = MasterCoordinator()
    
    var body: some View {
        
        NavigationStack {
        
                Form {
                    Section {
                        HStack(alignment: .center) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 35))
                            Text("Total Malicious\nReports")
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                                .bold()
                            Spacer()
                            Text(mastercoord.totalMalReports)
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                                .bold()
                        } .frame(height: 100)

                        
                    }
                   
                    .listRowBackground(
                        Color(red: 237/255, green: 33/255, blue: 58/255)
                    )
                    Section("Access Point Activity (\(mastercoord.macs.count) Report\((mastercoord.macs.count > 1 || mastercoord.macs.count == 0) ? "s" : ""))") {
                        List{
                            ForEach(mastercoord.macs, id:\.id) { mac in
                                CellReport(cellInfo: mac)
                            }
                        }
                       
                    } .navigationTitle(mastercoord.connectionStatus == .Connected ?
                                       "Connected" : "Not Connected")
                }
                
                Button(action: {
                    if mastercoord.connectionStatus == .NotConnected {
                        mastercoord.discoverServices()
                    } else {
                        mastercoord.cancel_all_tasks()
                    }
                }) {
                    HStack {
                        
                        if mastercoord.connectionStatus == .NotConnected {
                            Image(systemName: "wifi.circle")
                                .font(.largeTitle)
                                .symbolRenderingMode(.palette)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .symbolRenderingMode(.multicolor)
                        }
                        
                        
                        Text(mastercoord.connectionStatus == .NotConnected ? "Search for IDS" : "Disconnect")
                            .bold()
                            .foregroundColor((self.colorScheme == .light) ? Color.black : Color.white)
                    }
                    .padding()
                }
                
            }
       
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
