
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
    static func ModelMicroservice_CheckStatus(modeMicroservicelURL: String) -> String {
        let sessionConfig = URLSessionConfiguration.default
        let semaphore = DispatchSemaphore (value: 0)
        var jsonArray = ["1"]
        sessionConfig.timeoutIntervalForRequest = 1.5
        sessionConfig.timeoutIntervalForResource = 1.5
        sessionConfig.waitsForConnectivity = false
        let session = URLSession(configuration: sessionConfig)
        let url = URL(string:modeMicroservicelURL)!
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data {
                let returnData = String(data: data, encoding: .utf8)!
                print(returnData)
                jsonArray.append("available")
                semaphore.signal()
                return
            } else {
                print(String(describing: error))
                jsonArray.append("error")
                semaphore.signal()
                return
          }
        }
        task.resume()
        semaphore.wait()
        if jsonArray[1] == "error" {
            task.cancel()
        }
        return jsonArray[1]
    }
    //#############################################################################
    //#############################################################################
    static func ModelMicroservice_HTTPRequest_GET(modeMicroservicelURL: String) -> String {
        let sessionConfig = URLSessionConfiguration.default
        let semaphore = DispatchSemaphore (value: 0)
        var jsonArray = ["1"]
        sessionConfig.timeoutIntervalForRequest = 35.0
        sessionConfig.timeoutIntervalForResource = 35.0
        sessionConfig.waitsForConnectivity = false
        let session = URLSession(configuration: sessionConfig)
        let url = URL(string:modeMicroservicelURL)!
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data {
                let returnData = String(data: data, encoding: .utf8)!
                print(returnData)
                jsonArray.append(String(data: data, encoding: .utf8)!)
                semaphore.signal()
                return
            } else {
                print(String(describing: error))
                jsonArray.append("error")
                semaphore.signal()
                return
          }
        }
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
            print("JetSetLog:"+"#######################################################################################")
            print("JetSetLog:"+"Compute Rank Order is running in an altered configuration")
            print("JetSetLog:"+"This means that the local device DID show reason(s) to deprioritize local compute.")
            print("JetSetLog:"+"Determined Best Compute Rank Order: JetEngine > Cloud > Local")
            print("JetSetLog:"+"The compute rank alteration reason(s) are in the next print statement.")
            for x in computeRankReasons {
                print("JetSetLog:"+"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                print("JetSetLog:"+"Compute Rank Altertation Reason:"+x)
            }
            print("JetSetLog:"+"#######################################################################################")
            print(computeRankReasons)
            return computeBestRank
        } else {
            print("JetSetLog:"+"#######################################################################################")
            let computeBestRank = ["local","jetengine","cloud"]
            print("JetSetLog:"+"Compute Rank Order is running at the default configuration")
            print("JetSetLog:"+"This means that the local device doesn't show any reasons to deprioritize local compute.")
            print("JetSetLog:"+"Determined Best Compute Rank Order: Local > JetEngine > Cloud")
            print("JetSetLog:"+"#######################################################################################")
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
            print("JetSetLog:"+"#######################################################################################")
            print("JetSetLog:"+"Local compute has been disabled in the JetSet config, and no attempt will be made on this resource.")
            computeSiftArray.append("local")
        }
        //****************************************************************
        //****************************************************************
        if attemptJetEngine as! Bool == false {
            print("JetSetLog:"+"#######################################################################################")
            print("JetSetLog:"+"JetEngine compute has been disabled in the JetSet config, and no attempt will be made on this resource.")
            computeSiftArray.append("jetengine")
        }
        //****************************************************************
        //****************************************************************
        if attemptCloud as! Bool == false {
            print("JetSetLog:"+"#######################################################################################")
            print("JetSetLog:"+"Cloud compute has been disabled in the JetSet config, and no attempt will be made on this resource.")
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
    public static func OCR_Demo_EasyOCR() -> String{
        print("This is cray")
        let finalComputeList = ComputeSift(JetsonConfig: JetSetConfig, computeBestRank: ComputeRanker(JetsonConfig: JetSetConfig))
        
        let modelMicroserviceURL_JetEngine_Status = "http://ubuntu.local/easyocr-jet-engine-x86/status"
        let modelMicroserviceURL_JetEngine_Compute = "http://ubuntu.local/easyocr-jet-engine-x86/api/v1/test"
        let modelMicroserviceURL_Cloud_Status = "http://mesharound.com/easyocr-jet-engine-x86/status"
        let modelMicroserviceURL_Cloud_Compute = "http://mesharound.com/easyocr-jet-engine-x86/api/v1/test"

        for x in finalComputeList {
            //****************************************************************
            //****************************************************************
            if x == "local" {
                //****************************************************************
                if (JetSetConfig["attempt_local"] != nil) == false {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Local Option Not Yet Enabled, Skipping...")
                    continue
                }
                //****************************************************************
                if ModelMicroservice_CheckStatus(modeMicroservicelURL: modelMicroserviceURL_JetEngine_Status) != "available" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Local Resource Is not available, Skipping...")
                    continue
                }
                //****************************************************************
                let computeAttempt = ModelMicroservice_HTTPRequest_GET(modeMicroservicelURL: modelMicroserviceURL_JetEngine_Compute)
                if computeAttempt != "error" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Successfully Computed on Local")
                    return computeAttempt
                } else {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"local Compute Attempt Failed.")
                    print("JetSetLog:"+"Moving To Next Best Computing Option...")
                }
                //****************************************************************
            }
            //****************************************************************
            //****************************************************************
            if x == "jetengine" {
                //****************************************************************
                if (JetSetConfig["attempt_jetengine"] != nil) == false {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"JetEngine Option Not Yet Enabled, Skipping...")
                    continue
                }
                //****************************************************************
                if ModelMicroservice_CheckStatus(modeMicroservicelURL: modelMicroserviceURL_JetEngine_Status) != "available" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"JetEngine Resource Is not available, Skipping...")
                    continue
                }
                //****************************************************************
                let computeAttempt = ModelMicroservice_HTTPRequest_GET(modeMicroservicelURL: modelMicroserviceURL_JetEngine_Compute)
                if computeAttempt != "error" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Successfully Computed on JetEngine")
                    return computeAttempt
                } else {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"JetEngine Compute Attempt Failed.")
                    print("JetSetLog:"+"Moving To Next Best Computing Option...")
                }
            }
            //****************************************************************
            //****************************************************************
            if x == "cloud" {
                //****************************************************************
                if (JetSetConfig["attempt_cloud"] != nil) == false {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Cloud Option Not Yet Enabled, Skipping...")
                    continue
                }
                //****************************************************************
                if ModelMicroservice_CheckStatus(modeMicroservicelURL: modelMicroserviceURL_Cloud_Status) != "available" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Cloud Resource Is not available, Skipping...")
                    continue
                }
                //****************************************************************
                let computeAttempt = ModelMicroservice_HTTPRequest_GET(modeMicroservicelURL: modelMicroserviceURL_Cloud_Compute)
                if computeAttempt != "error" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Successfully Computed on Cloud")
                    return computeAttempt
                } else {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Cloud Compute Attempt Failed.")
                    print("JetSetLog:"+"Moving To Next Best Computing Option...")
                }
            }
            //****************************************************************
            //****************************************************************
        }
        return "WTF"
    }
    //#############################################################################
    //#############################################################################
    public static func OCR_Demo_Kraken() -> String{
        print("This is cray")
        let finalComputeList = ComputeSift(JetsonConfig: JetSetConfig, computeBestRank: ComputeRanker(JetsonConfig: JetSetConfig))
        let modelMicroserviceURL_JetEngine_Status = "http://ubuntu.local/kraken-jet-engine-arm/status"
        let modelMicroserviceURL_JetEngine_Compute = "http://ubuntu.local/kraken-jet-engine-arm/api/v1/test_get"
        let modelMicroserviceURL_Cloud_Status = "http://mesharound.com/kraken-jet-engine-x86/status"
        let modelMicroserviceURL_Cloud_Compute = "http://mesharound.com/kraken-jet-engine-x86/api/v1/test_get"

        for x in finalComputeList {
            //****************************************************************
            //****************************************************************
            if x == "local" {
                //****************************************************************
                if (JetSetConfig["attempt_local"] != nil) == false {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Local Option Not Yet Enabled, Skipping...")
                    continue
                }
                //****************************************************************
                if ModelMicroservice_CheckStatus(modeMicroservicelURL: modelMicroserviceURL_JetEngine_Status) != "available" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Local Resource Is not available, Skipping...")
                    continue
                }
                //****************************************************************
                let computeAttempt = ModelMicroservice_HTTPRequest_GET(modeMicroservicelURL: modelMicroserviceURL_JetEngine_Compute)
                if computeAttempt != "error" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Successfully Computed on Local")
                    return computeAttempt
                } else {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"local Compute Attempt Failed.")
                    print("JetSetLog:"+"Moving To Next Best Computing Option...")
                }
                //****************************************************************
            }
            //****************************************************************
            //****************************************************************
            if x == "jetengine" {
                //****************************************************************
                if (JetSetConfig["attempt_jetengine"] != nil) == false {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"JetEngine Option Not Yet Enabled, Skipping...")
                    continue
                }
                //****************************************************************
                if ModelMicroservice_CheckStatus(modeMicroservicelURL: modelMicroserviceURL_JetEngine_Status) != "available" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"JetEngine Resource Is not available, Skipping...")
                    continue
                }
                //****************************************************************
                let computeAttempt = ModelMicroservice_HTTPRequest_GET(modeMicroservicelURL: modelMicroserviceURL_JetEngine_Compute)
                if computeAttempt != "error" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Successfully Computed on JetEngine")
                    return computeAttempt
                } else {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"JetEngine Compute Attempt Failed.")
                    print("JetSetLog:"+"Moving To Next Best Computing Option...")
                }
            }
            //****************************************************************
            //****************************************************************
            if x == "cloud" {
                //****************************************************************
                if (JetSetConfig["attempt_cloud"] != nil) == false {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Cloud Option Not Yet Enabled, Skipping...")
                    continue
                }
                //****************************************************************
                if ModelMicroservice_CheckStatus(modeMicroservicelURL: modelMicroserviceURL_Cloud_Status) != "available" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Cloud Resource Is not available, Skipping...")
                    continue
                }
                //****************************************************************
                let computeAttempt = ModelMicroservice_HTTPRequest_GET(modeMicroservicelURL: modelMicroserviceURL_Cloud_Compute)
                if computeAttempt != "error" {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Successfully Computed on Cloud")
                    return computeAttempt
                } else {
                    print("JetSetLog:"+"#######################################################################################")
                    print("JetSetLog:"+"Cloud Compute Attempt Failed.")
                    print("JetSetLog:"+"Moving To Next Best Computing Option...")
                }
            }
            //****************************************************************
            //****************************************************************
        }
        return "WTF"
    }
    //#############################################################################
    //#############################################################################
}
