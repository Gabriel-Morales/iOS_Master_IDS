//
//  MasterCoordinator.swift
//  AW_Master_Node_Test Watch App
//
//  Created by Gabriel Morales on 10/30/22.
//

import Foundation
import Network


class MasterCoordinator: ObservableObject {
    
    
    private let MAX_COMPUTE_NODE_ENTRIES = 50
    private let MAX_COMPUTE_NODE_EVIDENCE_MALICIOUS_THRESHOLD = 10
    private let MAX_COMPUTE_NODE_EVIDENCE_BENIGN_THRESHOLD = 26

    private let MAX_MASTER_NODE_ENTRIES = 50
    private let MAX_MASTER_NODE_EVIDENCE_MALICIOUS_THRESHOLD = 2
    private let MAX_MASTER_NODE_EVIDENCE_BENIGN_THRESHOLD = 20
    
    private let multicastQueueListen = DispatchQueue(label: "mcqueuel", qos: .userInteractive)
    private let multicastQueueConn = DispatchQueue(label: "mcqueuec", qos: .userInteractive)

    private let apqueue = DispatchQueue(label: "apqueue", qos: .userInteractive)
    private let connqueue = DispatchQueue(label: "connqueue", qos: .userInteractive)
    
    private var serverQueue = [(String,String)]()
    private let serverSem = DispatchSemaphore(value: 1)
    private let seqSync = DispatchSemaphore(value: 1)
    
    private var connectionGroupglob: NWConnectionGroup?
    private var tcpconn: NWConnection?
    
    private var serversConnectedTo = [String:Bool]()
    private var tcpconnections = [NWConnection]()
    
    @Published
    var macs = [InfObject]()
    
    @Published
    var totalMalReports = "0"
    
    @Published
    var connectionStatus: ConnStat = .NotConnected
    
    var maliciousData = [MalCountsData]()
    var benignData =  [BenCountsData]()
    
    private var cancellation = false
    private var doneCancellingListen = DispatchSemaphore(value: 0)
    private var doneCancellingResults = DispatchSemaphore(value: 0)
    
    init() {
        
        // create a multicast listener
        // create a socket connection
        
        
        // self.discoverServices()
        
        multicastQueueConn.async {
            self.connectToClients()
        }
        
        multicastQueueListen.async {
            self.listen_to_client()
        }
        
        
    
    }
    
    func cancel_all_tasks() -> Void {
        cancellation = true
        
        for connection in tcpconnections {
            connection.cancel()
        }
        
        connectionGroupglob?.cancel()
        
        doneCancellingListen.wait()
        doneCancellingResults.wait()
        
        
        self.tcpconnections = [NWConnection]()
        self.serversConnectedTo = [String:Bool]()
        self.serverQueue = [(String,String)]()
        
        connectionStatus = .NotConnected
        cancellation = false
        
        multicastQueueConn.async {
            self.connectToClients()
        }
        
        multicastQueueListen.async {
            self.listen_to_client()
        }
        
        doneCancellingListen = DispatchSemaphore(value: 0)
        doneCancellingResults = DispatchSemaphore(value: 0)
        
    }
    
    
    func listen_to_client() -> Void {
        
        // await long running operations
        // these should be asyncsequences
        let decoder = JSONDecoder()
        
        
        // published methods properties are available on the main view updated.
        var evidenceBuffer = [String:[Int:Int]]()
       // var priorEvidenceBufferLength = 0
        
        while !cancellation {
            
            //seqSync.wait()
            
            serverSem.wait()
            let servers = tcpconnections
            serverSem.signal()
            
            for tcpconnection in servers {
                
                tcpconnection.receive(minimumIncompleteLength: 0, maximumLength: 2046, completion: {
                    dat, cn, tf, er in
                    
                    
                    if let dat = dat {
                        let msg: MasterMsg?
                        do {
                            msg = try decoder.decode(MasterMsg.self, from: dat)
                        } catch {
                            print("ERROR: Json Decoding error.")
                            return
                        }
                        let mac = msg!.mac
                        let encoding: Int = Int(msg!.encode)!
                        let evidenceCnt: Int = Int(msg!.evidence)!
                        
                        if mac == "0" {
                            return
                        }
                        
                        var newMac: InfObject? = nil
                        var newMacIndex: Array<InfObject>.Index? = nil
                        
                        if evidenceBuffer[mac] == nil {
                            // 0 = benign, 1 = malicious
                            evidenceBuffer[mac] = [0 : 0, 1: 0]
                            newMac = InfObject(withMac: mac)
                            DispatchQueue.main.async {
                                self.macs.append(newMac!)
                            }
                        } else {
                            evidenceBuffer[mac]![encoding]! += evidenceCnt
                            newMacIndex = self.macs.firstIndex(where: { a in
                                return a.getMac() == mac
                            })
                            if let arrInd = newMacIndex {
                                newMac = self.macs[arrInd]
                            }
                            
                            if encoding == 0 {
                                newMac!.updateBenCnt(byAmount: evidenceCnt)
                            } else {
                                newMac!.updateMalCnt(byAmount: evidenceCnt)
                                DispatchQueue.main.async {
                                    self.totalMalReports = String(Int(self.totalMalReports)! + evidenceCnt)
                                }
                            }
                            
                            let mal = MalCountsData(cnt: newMac!.getMaliciousCnt(), time: Date.now.formatted(date: .omitted, time: .standard))
                            let ben = BenCountsData(cnt: newMac!.getBenignCnt(), time: Date.now.formatted(date:.omitted, time: .standard))
                            
                            self.maliciousData.append(mal)
                            self.benignData.append(ben)
                            
                            DispatchQueue.main.async {
                                if let arrInd = newMacIndex {
                                    self.macs[arrInd] = newMac!
                                }
                                self.macs.sort(by: { a,b in

                                    return a.getMaliciousCnt() > b.getMaliciousCnt()

                                })
                            }
                            
                        }
                        
                        if evidenceBuffer[mac]![0]! >= self.MAX_MASTER_NODE_EVIDENCE_BENIGN_THRESHOLD {
//                            DispatchQueue.main.async {
//                                newMac!.setBenCount(toAmt: Int(Double(newMac!.getBenignCnt()) / 2))
//                                if let arrInd = newMacIndex {
//                                    self.macs[arrInd] = newMac!
//                                }
//                                //self.outs.append("[! \(Date.now.formatted(date: .omitted, time: .shortened)) !] \(mac) benign.")
//                            }
                            evidenceBuffer[mac]![0]! = evidenceBuffer[mac]![0]! / 2
                        }
                        
                        if evidenceBuffer[mac]![1]! >= self.MAX_MASTER_NODE_EVIDENCE_MALICIOUS_THRESHOLD {
//                            DispatchQueue.main.async {
//                                newMac!.setMalCount(toAmt: 0)
//                                if let arrInd = newMacIndex {
//                                    self.macs[arrInd] = newMac!
//                                }
//                                self.macs.sort(by: { a,b in
//
//                                    return a.getMaliciousCnt() > b.getMaliciousCnt()
//
//                                })
//                                //self.outs.append("[! \(Date.now.formatted(date: .omitted, time: .shortened)) !] \(mac) suspicious.")
//
//                            }
                            evidenceBuffer[mac]![1]! = 0
                        }
                        
                        if evidenceBuffer.count >= self.MAX_MASTER_NODE_ENTRIES {
                            evidenceBuffer.removeAll()
                        }
                        
                    }
                })
                
                sleep(1)
            }
            
            //seqSync.signal()
            
        }
        doneCancellingListen.signal()
        print("Done with listen.")
    }
    
    
    func connectToClients() -> Void {
        
        while !cancellation {
            
            //seqSync.wait()
          
            serverSem.wait()
            let servers = serverQueue
            serverSem.signal()
            
            for server in servers {
                
                let ip = server.0
                let port = server.1
                
                let combo = "\(ip):\(port)"
                
                if serversConnectedTo[combo] == true {
                    continue
                }
                
                if let sPort = NWEndpoint.Port(port) {
                    //outs.append("[*] Attempting connection to \(combo)")
                    let tcpConnect = NWConnection(host: NWEndpoint.Host(ip), port: sPort, using: .tcp)
                    
                    serverSem.wait()
                    tcpconnections.append(tcpConnect)
                    serverSem.signal()
                    serversConnectedTo[combo] = true
                    tcpConnect.start(queue: connqueue)
                    tcpConnect.stateUpdateHandler = { state in
                        if state != .ready && state != .preparing && state != .setup {
                            self.serversConnectedTo[combo] = false
                            tcpConnect.forceCancel()
                        }
                    
                        
                        if state == .ready {
                            DispatchQueue.main.async {
                                self.connectionStatus = .Connected
                            }
                        }

                    }
                    
                }
            }
            
           // seqSync.signal()
            
        }
        doneCancellingResults.signal()
    }
    
    func discoverServices() -> Void {
        print("Discovering services...")
        
        //let MAX_BUFFER_SIZE = 20046
        let BROADCAST_PORT = NWEndpoint.Port("5882") //something not likely used by other things on the system
        let BROADCAST_GROUP = NWEndpoint.Host("224.0.1.119") //multicasting subnet
        let SERVICE_MAGIC = "n1d5mlm4gk" //service magic
        var serviceAddresses = [String:Int]()
        
        
        guard let nwport = BROADCAST_PORT else {
            connectionStatus = .NotConnected
            print("Error: Multicast port error.")
            return
        }
        
        do {
            let udpSocketGroupDescriptor = try NWMulticastGroup(for: [.hostPort(host: BROADCAST_GROUP, port: nwport)])
            let connectionGroup = NWConnectionGroup(with: udpSocketGroupDescriptor, using: .udp)
            self.connectionGroupglob = connectionGroup
            connectionGroup.setReceiveHandler(handler: { msg, dat, tf in
                if let rData = dat, let received = String(data: rData , encoding: .ascii) {
                    let tokens = received.split(separator: ":")
                    
                    let addrTokens = (msg.remoteEndpoint?.debugDescription)!.split(separator: ":")
                    let addr = String(addrTokens[0])
                    //let port = String(addrTokens[1])
                    
                    let proposed_magic = tokens[0]
                    let extra_info = tokens[1]
                    let server_port = String(tokens[2])

                    if (proposed_magic == SERVICE_MAGIC) && (extra_info == "ids_service"){
                        
                        if serviceAddresses[addr] == nil {
                            serviceAddresses[addr] = 1
                            //SERVER_QUEUE.put((addr[0], int(server_port)))
                            self.serverSem.wait()
                            self.serverQueue.append((addr, server_port))
                            self.serverSem.signal()
//                            DispatchQueue.main.async {
//                                //self.outs.append("[!] IDS Service Detected: \(addr)")
//                            }
                            
                        }
                    }
                }
            })
            connectionGroup.start(queue: apqueue)
            
        } catch {
            DispatchQueue.main.async {
                self.connectionStatus = .NotConnected
            }
            print("Error: Multicast group not connected to.")
        }
        
    }

    
}
