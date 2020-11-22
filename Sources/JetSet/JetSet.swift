
//
//  ContentView.swift
//  jetengine-demo
//
//  Created by preston on 11/14/20.
//
import SwiftUI
import SwiftyJSON
import SystemConfiguration.CaptiveNetwork
import Network
public struct JetSet {
    //#############################################################################
    //#############################################################################
    static let JetSetConfig = [
        "attempt_local": false,
        "attempt_jetengine": true,
        "attempt_cloud": true,
        "jetengine_priority_over_local": true,
        "jetengine_priority_over_cloud": true
    ] as [String: Any]
    //#############################################################################
    //#############################################################################
    static func ModelMicroservice_HTTPRequest(modeMicroservicelURL: String) -> String {
        let sessionConfig = URLSessionConfiguration.default
        let semaphore = DispatchSemaphore (value: 0)
        var jsonArray = ["1"]
        sessionConfig.timeoutIntervalForRequest = 10.0
        sessionConfig.timeoutIntervalForResource = 10.0
        sessionConfig.waitsForConnectivity = false
        let session = URLSession(configuration: sessionConfig)
        let url = URL(string:modeMicroservicelURL)!
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let returnData = String(data: data, encoding: .utf8)!
                print(returnData)
                jsonArray.append(String(data: data, encoding: .utf8)!)
                semaphore.signal()
                return
            } else {
                print(String(describing: error))
                semaphore.signal()
                return
          }
            //semaphore.signal()
        }
        /*
        // Create the HTTP request
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                // Handle HTTP request error
                print(error)
                jsonArray.append("error")
            } else if let data = data {
                jsonArray.append(String(data: data, encoding: .utf8)!)
                semaphore.signal()
            } else {
                // Handle unexpected error
                jsonArray.append("error")
                //jsonArray.append("An Error Occured When Making Ai request.")
            }
        }
        */
        task.resume()
        semaphore.wait()
        if jsonArray[1] == "error" {
            task.cancel()
        }
        return jsonArray[1]
    }
    //#############################################################################
    //#############################################################################
    static func GetNetworkInfo() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            print(interfaces)
            for interface in interfaces {
                print(CNCopyCurrentNetworkInfo)
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    print(interfaceInfo.allKeys)
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    print(ssid as Any)
                    //break
                }
            }
        }
        return ssid
    }
    //#############################################################################
    //#############################################################################
    static func GetBatteryStats() -> Dictionary<String, Any> {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let lowPowerModeIsEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        let batteryState = UIDevice.current.batteryState.rawValue
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryData = [
            "low_power_mode_is_enabled": lowPowerModeIsEnabled,
            "battery_state": batteryState,
            "battery_level": batteryLevel
        ] as [String : Any]
        return batteryData
    }
    //#############################################################################
    //#############################################################################
    static func GetSystemStats() -> Dictionary<String, Any> {
        let thermalState = ProcessInfo.processInfo.thermalState.rawValue
        let cpuCoreCountTotal = ProcessInfo.processInfo.processorCount
        let cpuCoreCountActive = ProcessInfo.processInfo.activeProcessorCount
        let physicalMemoryTotal = ProcessInfo.processInfo.physicalMemory
        let operatingSystemVersion = UIDevice.current.systemVersion
        let systemData = [
            "thermal_state": thermalState,
            "cpu_core_count_total": cpuCoreCountTotal,
            "cpu_core_count_active": cpuCoreCountActive,
            "physical_memory_total": physicalMemoryTotal,
            "operating_system_version": operatingSystemVersion
        ] as [String : Any]
        return systemData
    }
    //#############################################################################
    //#############################################################################
    static func ComputeRanker(JetsonConfig: [String: Any]) -> Array<String> {
        let JetSetStats = [
            "jetset_settings": JetSetConfig,
            "system_stats": GetSystemStats(),
            "battery_stats": GetBatteryStats()
        ]

        var  computeRankReasons = [String]()
        
        //****************************************************************
        //****************************************************************
        if JetSetStats["battery_stats"]!["low_power_mode_is_enabled"] as! Bool == true {
            let rankMessage = "Low Power Mode Is Enabled"
            computeRankReasons.append(rankMessage)
        }
        //****************************************************************
        //****************************************************************
        if  0.20 >= JetSetStats["battery_stats"]!["battery_level"] as! Float {
            let rankMessage = "Battery Is Below 20%"
            computeRankReasons.append(rankMessage)
        }
        //****************************************************************
        //****************************************************************
        if  JetSetStats["system_stats"]!["thermal_state"] as! Int >= 3 {
            let rankMessage = "Device is in unsafe thermal state rank \(JetSetStats["system_stats"]!["thermal_state"] as! Int)"
            computeRankReasons.append(rankMessage)
        }
        //****************************************************************
        //****************************************************************
        if  3 > JetSetStats["system_stats"]!["cpu_core_count_active"] as! Int {
            let rankMessage = "Device does not have enough free cores, free core count: \(JetSetStats["system_stats"]!["cpu_core_count_active"] as! Int)"
            computeRankReasons.append(rankMessage)
        }
        //****************************************************************
        //****************************************************************
        let osVersionString = JetSetStats["system_stats"]!["operating_system_version"] as! String
        let osVersionMajorString = osVersionString.split(separator: ".")[0]
        let osVersionMajorInt = Int(osVersionMajorString) ?? 10
        if  11 > osVersionMajorInt {
            let rankMessage = "Device OS is too low for Core ML, current OS version: \(osVersionString)"
            computeRankReasons.append(rankMessage)
        }
        //****************************************************************
        //****************************************************************
        if  computeRankReasons.count > 0 {
            let computeBestRank = ["jetengine","cloud","local"]
            print(computeRankReasons)
            return computeBestRank
        } else {
            let computeBestRank = ["local","jetengine","cloud"]
            return computeBestRank
        }
    }
    //#############################################################################
    //#############################################################################
    static func ComputeSift(JetsonConfig: [String: Any], computeBestRank: [String]) -> [String]{
        let attemptLocal = JetsonConfig["attempt_local"]
        let attemptJetEngine = JetsonConfig["attempt_jetengine"]
        let attemptCloud = JetsonConfig["attempt_cloud"]
        var computeSiftArray = [String]()
        var computeFilteredArray = [String]()
        //****************************************************************
        //****************************************************************
        if attemptLocal as! Bool == false {
            computeSiftArray.append("local")
        }
        //****************************************************************
        //****************************************************************
        if attemptJetEngine as! Bool == false {
            computeSiftArray.append("jetengine")
        }
        //****************************************************************
        //****************************************************************
        if attemptCloud as! Bool == false {
            computeSiftArray.append("cloud")
        }
        //****************************************************************
        //****************************************************************
        for x in computeBestRank {
            if computeSiftArray.contains(x) {
                continue
            } else {
                computeFilteredArray.append(x)
            }
        }
        print(computeSiftArray)
        print(computeFilteredArray)
        return computeFilteredArray
    }
    //#############################################################################
    //#############################################################################
    public static func OCR_EasyOCR() -> String{
        print("This is cray")
        let finalComputeList = ComputeSift(JetsonConfig: JetSetConfig, computeBestRank: ComputeRanker(JetsonConfig: JetSetConfig))
        let modelMicroserviceURL_JetEngine = "http://ubuntu.local/easyocr-jet-engine-x86/api/v1/test"
        let modelMicroserviceURL_Cloud = "http://192.168.1.247/easyocr-jet-engine-x86/api/v1/test"

        for x in finalComputeList {
            if x == "local" {
                do {
                    print("Local Option Not Yet Enabled.")
                    //return try ModelMicroservice_HTTPRequest(modeMicroservicelURL: modelMicroserviceURL_JetEngine)
                } catch {
                    print("local Compute Attempt Failed.")
                    print("Moving To Next Best Computing Option...")
                }
            }
            if x == "jetengine" {
                do {
                    
                    try print(ModelMicroservice_HTTPRequest(modeMicroservicelURL: modelMicroserviceURL_JetEngine))
                } catch {
                    print("jetengine Compute Attempt Failed.")
                    print("Moving To Next Best Computing Option...")
                }
            }
            if x == "cloud" {
                do {
                    let returnData = try ModelMicroservice_HTTPRequest(modeMicroservicelURL: modelMicroserviceURL_Cloud)
                    return returnData
                } catch {
                    print("cloud Compute Attempt Failed.")
                    print("Moving To Next Best Computing Option...")
                }
            }
        }
        return "WTF"
    }
    //#############################################################################
    //#############################################################################
    public static func OCR_Kraken_Arm_Compute() -> String{
        print("This is cray")
        let finalComputeList = ComputeSift(JetsonConfig: JetSetConfig, computeBestRank: ComputeRanker(JetsonConfig: JetSetConfig))
        let modelMicroserviceURL_JetEngine = "http://ubuntu.local/kraken-jet-engine-arm/api/v1/test_get"
        let modelMicroserviceURL_Cloud = "http://192.168.1.247/kraken-jet-engine-x86/api/v1/test_get"

        for x in finalComputeList {
            if x == "local" {
                do {
                    print("Local Option Not Yet Enabled.")
                    //return try ModelMicroservice_HTTPRequest(modeMicroservicelURL: modelMicroserviceURL)
                } catch {
                    print("local Compute Attempt Failed.")
                    print("Moving To Next Best Computing Option...")
                }
            }
            if x == "jetengine" {
                do {
                    return try ModelMicroservice_HTTPRequest(modeMicroservicelURL: modelMicroserviceURL_JetEngine)
                } catch {
                    print("jetengine Compute Attempt Failed.")
                    print("Moving To Next Best Computing Option...")
                }
            }
            if x == "cloud" {
                do {
                    return try ModelMicroservice_HTTPRequest(modeMicroservicelURL: modelMicroserviceURL_Cloud)
                } catch {
                    print("cloud Compute Attempt Failed.")
                    print("Moving To Next Best Computing Option...")
                }
            }
        }
        return "WTF"
    }
    //#############################################################################
    //#############################################################################
}
