//import AppIntents
//import AWSCore
//import AWSIoT
//
//struct AddLightOnShortcutIntent: AppIntent {
//    
//    static let title: LocalizedStringResource = "Turn On Light"
//    static var description = IntentDescription("Fetches all homes, rooms, devices, and their button details.")
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        // 1. Fetch all homes
//        let homes = await withCheckedContinuation { continuation in
//            SkromanIsraDatabaseHelper.shared.fetchAllHomes { fetchedHomes in
//                continuation.resume(returning: fetchedHomes)
//            }
//        }
//
//        if homes.isEmpty {
//            return .result(dialog: IntentDialog("No homes found."))
//        }
//
//        var fullList: [String] = []
//
//        // 2. Loop over homes
//        for home in homes {
//            let homeName = home.homeName ?? "Unnamed Home"
//            let homeId = home.homeServerId ?? ""
//
//            // 3. Fetch rooms by home ID
//            let rooms = await withCheckedContinuation { continuation in
//                SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in
//                    continuation.resume(returning: fetchedRooms)
//                }
//            }
//
//            if rooms.isEmpty {
//                fullList.append("🏠 \(homeName): No rooms.")
//                continue
//            }
//
//            for room in rooms {
//                let roomName = room.roomName ?? "Unnamed Room"
//                let roomId = room.roomId ?? ""
//
//                // 4. Fetch devices by room ID
//                let devices = await withCheckedContinuation { continuation in
//                    SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { fetchedDevices in
//                        continuation.resume(returning: fetchedDevices)
//                    }
//                }
//
//                if devices.isEmpty {
//                    fullList.append("\(homeName) > \(roomName): No devices.")
//                    continue
//                }
//
//                for device in devices {
//                    let deviceUid = device.uniqueId ?? ""
//
//                  
//                    var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: deviceUid)
//                    print("buttonDetails at siri\(buttonDetails)")
//
//                    // Sort and filter
//                    buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                    let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                    buttonDetails = buttonDetails.filter { item in
//                        guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                        return !invalidFirstChars.contains(firstChar)
//                        
//                        
//                        
//                    }
//
//                    if buttonDetails.isEmpty {
//                        fullList.append("\(homeName)  \(roomName) > No valid buttons.")
//                    } else {
//                        for button in buttonDetails {
//                            let buttonName = button.buttonName
//                            fullList.append(" \(roomName)  \(buttonName)")
//                        }
//                    }
//                    
//                
//                    for button in buttonDetails {
//                        let buttonName = button.buttonName
//                        fullList.append("\(homeName)  \(roomName)  \(buttonName)")
//                        if button.buttonControlName == "L"{
//                            publish_button(
//                                control: button.buttonControlName,
//                                no: button.buttonNo,
//                                state: 1,
//                                speed: 0,
//                                topic: button.uniqueId
//                            )
//                            
//                            // Add 200ms delay
//                            try? await Task.sleep(nanoseconds: 500_000_000)
//                        }
//                    }
//
//                    
//                }
//            }
//        }
//
//        let finalMessage = fullList.isEmpty ? "No devices or buttons found." : "Ok Turning on the lights"
//        return .result(dialog: IntentDialog(stringLiteral: finalMessage))
//    }
//    
//    
//    func publish_button(control: String, no: Int, state: Int, speed: Int, topic : String) {
//
//        DevicePublisher.publish(control: control, no: no, state: state, speed: speed, topic: topic)
//
//        
//    }
//
//}
//
//
//struct AddLightOffShortcutIntent: AppIntent {
//    
//    static let title: LocalizedStringResource = "Turn off lights"
//    static var description = IntentDescription("Fetches all homes, rooms, devices, and their button details.")
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        // 1. Fetch all homes
//        let homes = await withCheckedContinuation { continuation in
//            SkromanIsraDatabaseHelper.shared.fetchAllHomes { fetchedHomes in
//                continuation.resume(returning: fetchedHomes)
//            }
//        }
//
//        if homes.isEmpty {
//            return .result(dialog: IntentDialog("No homes found."))
//        }
//
//        var fullList: [String] = []
//
//        // 2. Loop over homes
//        for home in homes {
//            let homeName = home.homeName ?? "Unnamed Home"
//            let homeId = home.homeServerId ?? ""
//
//            // 3. Fetch rooms by home ID
//            let rooms = await withCheckedContinuation { continuation in
//                SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in
//                    continuation.resume(returning: fetchedRooms)
//                }
//            }
//
//            if rooms.isEmpty {
//                fullList.append("🏠 \(homeName): No rooms.")
//                continue
//            }
//
//            for room in rooms {
//                let roomName = room.roomName ?? "Unnamed Room"
//                let roomId = room.roomId ?? ""
//
//                // 4. Fetch devices by room ID
//                let devices = await withCheckedContinuation { continuation in
//                    SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { fetchedDevices in
//                        continuation.resume(returning: fetchedDevices)
//                    }
//                }
//
//                if devices.isEmpty {
//                    fullList.append("\(homeName) > \(roomName): No devices.")
//                    continue
//                }
//
//                for device in devices {
//                    let deviceUid = device.uniqueId ?? ""
//
//                  
//                    var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: deviceUid)
//                    print("buttonDetails at siri\(buttonDetails)")
//
//                    // Sort and filter
//                    buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                    let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                    buttonDetails = buttonDetails.filter { item in
//                        guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                        return !invalidFirstChars.contains(firstChar)
//                        
//                        
//                        
//                    }
//
//                    if buttonDetails.isEmpty {
//                        fullList.append("\(homeName)  \(roomName) > No valid buttons.")
//                    } else {
//                        for button in buttonDetails {
//                            let buttonName = button.buttonName
//                            fullList.append(" \(roomName)  \(buttonName)")
//                        }
//                    }
//                    
//                
//                    for button in buttonDetails {
//                        let buttonName = button.buttonName
//                        fullList.append("\(homeName)  \(roomName)  \(buttonName)")
//                        if button.buttonControlName == "L"{
//                            publish_button(
//                                control: button.buttonControlName,
//                                no: button.buttonNo,
//                                state: 0,
//                                speed: 0,
//                                topic: button.uniqueId
//                            )
//                            
//                            // Add 200ms delay
//                            try? await Task.sleep(nanoseconds: 500_000_000)
//                        }
//                    }
//
//
//                    
//                }
//            }
//        }
//
//        let finalMessage = fullList.isEmpty ? "No devices or buttons found." : "Ok Turning off the lights"
//        return .result(dialog: IntentDialog(stringLiteral: finalMessage))
//    }
//    
//    
//    func publish_button(control: String, no: Int, state: Int, speed: Int, topic : String) {
//
//        DevicePublisher.publish(control: control, no: no, state: state, speed: speed, topic: topic)
//
//        
//    }
//
//}
//
//
//struct AddFanOnShortcutIntent: AppIntent {
//    
//    static let title: LocalizedStringResource = "Turn on fans"
//    static var description = IntentDescription("Fetches all homes, rooms, devices, and their button details.")
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        // 1. Fetch all homes
//        let homes = await withCheckedContinuation { continuation in
//            SkromanIsraDatabaseHelper.shared.fetchAllHomes { fetchedHomes in
//                continuation.resume(returning: fetchedHomes)
//            }
//        }
//
//        if homes.isEmpty {
//            return .result(dialog: IntentDialog("No homes found."))
//        }
//
//        var fullList: [String] = []
//
//        // 2. Loop over homes
//        for home in homes {
//            let homeName = home.homeName ?? "Unnamed Home"
//            let homeId = home.homeServerId ?? ""
//
//            // 3. Fetch rooms by home ID
//            let rooms = await withCheckedContinuation { continuation in
//                SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in
//                    continuation.resume(returning: fetchedRooms)
//                }
//            }
//
//            if rooms.isEmpty {
//                fullList.append("🏠 \(homeName): No rooms.")
//                continue
//            }
//
//            for room in rooms {
//                let roomName = room.roomName ?? "Unnamed Room"
//                let roomId = room.roomId ?? ""
//
//                // 4. Fetch devices by room ID
//                let devices = await withCheckedContinuation { continuation in
//                    SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { fetchedDevices in
//                        continuation.resume(returning: fetchedDevices)
//                    }
//                }
//
//                if devices.isEmpty {
//                    fullList.append("\(homeName) > \(roomName): No devices.")
//                    continue
//                }
//
//                for device in devices {
//                    let deviceUid = device.uniqueId ?? ""
//
//                  
//                    var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: deviceUid)
//                    print("buttonDetails at siri\(buttonDetails)")
//
//                    // Sort and filter
//                    buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                    let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                    buttonDetails = buttonDetails.filter { item in
//                        guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                        return !invalidFirstChars.contains(firstChar)
//                        
//                        
//                        
//                    }
//
//                    if buttonDetails.isEmpty {
//                        fullList.append("\(homeName)  \(roomName) > No valid buttons.")
//                    } else {
//                        for button in buttonDetails {
//                            let buttonName = button.buttonName
//                            fullList.append(" \(roomName)  \(buttonName)")
//                        }
//                    }
//                    
//                
//                    for button in buttonDetails {
//                        let buttonName = button.buttonName
//                        fullList.append("\(homeName)  \(roomName)  \(buttonName)")
//                        if button.buttonControlName == "F"{
//                            publish_button(
//                                control: button.buttonControlName,
//                                no: 1,
//                                state: 1,
//                                speed: 1,
//                                topic: button.uniqueId
//                            )
//                            
//                            // Add 200ms delay
//                            try? await Task.sleep(nanoseconds: 500_000_000)
//                        }
//                    }
//
//
//                    
//                }
//            }
//        }
//
//        let finalMessage = fullList.isEmpty ? "No devices or buttons found." : "Ok Turning on the fan at speed 1"
//        return .result(dialog: IntentDialog(stringLiteral: finalMessage))
//    }
//    
//    
//    func publish_button(control: String, no: Int, state: Int, speed: Int, topic : String) {
//
//        DevicePublisher.publish(control: control, no: no, state: state, speed: speed, topic: topic)
//
//        
//    }
//
//}
//
//
//struct AddFanOffShortcutIntent: AppIntent {
//    
//    static let title: LocalizedStringResource = "Turn off fan"
//    static var description = IntentDescription("Fetches all homes, rooms, devices, and their button details.")
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        // 1. Fetch all homes
//        let homes = await withCheckedContinuation { continuation in
//            SkromanIsraDatabaseHelper.shared.fetchAllHomes { fetchedHomes in
//                continuation.resume(returning: fetchedHomes)
//            }
//        }
//
//        if homes.isEmpty {
//            return .result(dialog: IntentDialog("No homes found."))
//        }
//
//        var fullList: [String] = []
//
//        // 2. Loop over homes
//        for home in homes {
//            let homeName = home.homeName ?? "Unnamed Home"
//            let homeId = home.homeServerId ?? ""
//
//            // 3. Fetch rooms by home ID
//            let rooms = await withCheckedContinuation { continuation in
//                SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in
//                    continuation.resume(returning: fetchedRooms)
//                }
//            }
//
//            if rooms.isEmpty {
//                fullList.append("🏠 \(homeName): No rooms.")
//                continue
//            }
//
//            for room in rooms {
//                let roomName = room.roomName ?? "Unnamed Room"
//                let roomId = room.roomId ?? ""
//
//                // 4. Fetch devices by room ID
//                let devices = await withCheckedContinuation { continuation in
//                    SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { fetchedDevices in
//                        continuation.resume(returning: fetchedDevices)
//                    }
//                }
//
//                if devices.isEmpty {
//                    fullList.append("\(homeName) > \(roomName): No devices.")
//                    continue
//                }
//
//                for device in devices {
//                    let deviceUid = device.uniqueId ?? ""
//
//                  
//                    var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: deviceUid)
//                    print("buttonDetails at siri\(buttonDetails)")
//
//                    // Sort and filter
//                    buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                    let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                    buttonDetails = buttonDetails.filter { item in
//                        guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                        return !invalidFirstChars.contains(firstChar)
//                        
//                        
//                        
//                    }
//
//                    if buttonDetails.isEmpty {
//                        fullList.append("\(homeName)  \(roomName) > No valid buttons.")
//                    } else {
//                        for button in buttonDetails {
//                            let buttonName = button.buttonName
//                            fullList.append(" \(roomName)  \(buttonName)")
//                        }
//                    }
//                    
//                
//                    for button in buttonDetails {
//                        let buttonName = button.buttonName
//                        fullList.append("\(homeName)  \(roomName)  \(buttonName)")
//                        if button.buttonControlName == "F"{
//                            publish_button(
//                                control: button.buttonControlName,
//                                no: 1,
//                                state: 0,
//                                speed: 0,
//                                topic: button.uniqueId
//                            )
//                            
//                            // Add 200ms delay
//                            try? await Task.sleep(nanoseconds: 500_000_000)
//                        }
//                    }
//
//
//                    
//                }
//            }
//        }
//
//        let finalMessage = fullList.isEmpty ? "No devices or buttons found." : "Ok Turning off the fan"
//        return .result(dialog: IntentDialog(stringLiteral: finalMessage))
//    }
//    
//    
//    func publish_button(control: String, no: Int, state: Int, speed: Int, topic : String) {
//
//        DevicePublisher.publish(control: control, no: no, state: state, speed: speed, topic: topic)
//
//        
//    }
//
//}
//
//
//
//
//
//class DevicePublisher {
//    static func publish(control: String, no: Int, state: Int, speed: Int, topic: String) {
//        let fetch_all_params: [String: Any] = [
//            "control": control,
//            "no": no,
//            "state": state,
//            "speed": speed,
//            "from": "X",
//            "topic": topic
//        ]
//
//        print("Publishing with params at siri : \(fetch_all_params)")
//
//        if let theJSONData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []),
//           let theJSONText = String(data: theJSONData, encoding: .ascii) {
//
//            print("JSON String to Publish: \(theJSONText)")
//
//            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
//            iotDataManager.publishString(theJSONText, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
//        }
//    }
//    
//    
//
//}
//
//
//
//
//
//struct LightShortcutIntent: AppIntent {
//
//    static let title: LocalizedStringResource = "Turn On room Light"
//    static var description = IntentDescription("Turns on lights for the selected room.")
//
//    @Parameter(title: "Room Name")
//    var roomName: String
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let homes = await withCheckedContinuation { continuation in
//            SkromanIsraDatabaseHelper.shared.fetchAllHomes { fetchedHomes in
//                continuation.resume(returning: fetchedHomes)
//            }
//        }
//
//        if homes.isEmpty {
//            return .result(dialog: IntentDialog("No homes found."))
//        }
//
//        for home in homes {
//            let homeId = home.homeServerId ?? ""
//
//            let rooms = await withCheckedContinuation { continuation in
//                SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in
//                    continuation.resume(returning: fetchedRooms)
//                }
//            }
//
//            for room in rooms {
//                if room.roomName.lowercased() == roomName.lowercased() {
//                    let roomId = room.roomId ?? ""
//
//                    let devices = await withCheckedContinuation { continuation in
//                        SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { fetchedDevices in
//                            continuation.resume(returning: fetchedDevices)
//                        }
//                    }
//
//                    for device in devices {
//                        let deviceUid = device.uniqueId ?? ""
//                        var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: deviceUid)
//
//                        buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                        let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                        buttonDetails = buttonDetails.filter { item in
//                            guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                            return !invalidFirstChars.contains(firstChar)
//                        }
//
//                        for button in buttonDetails {
//                            if button.buttonControlName == "L" {
//                                publish_button(
//                                    control: button.buttonControlName,
//                                    no: button.buttonNo,
//                                    state: 1,
//                                    speed: 0,
//                                    topic: button.uniqueId
//                                )
//
//                                try? await Task.sleep(nanoseconds: 500_000_000)
//                            }
//                        }
//                    }
//
//                    return .result(dialog: IntentDialog("Turned on lights in \(roomName)."))
//                }
//            }
//        }
//
//        return .result(dialog: IntentDialog("No room named \(roomName) found."))
//    }
//
//    func publish_button(control: String, no: Int, state: Int, speed: Int, topic: String) {
//        DevicePublisher.publish(control: control, no: no, state: state, speed: speed, topic: topic)
//    }
//}
//
//
//
//
//struct AddTaskSiriShortCut: AppShortcutsProvider {
//    static var appShortcuts: [AppShortcut] {
//        return [
//            AppShortcut(
//                intent: AddLightOnShortcutIntent(),
//                phrases: [
//                    "Turn on light \(.applicationName)",
//                    "Turn on lights \(.applicationName)",
//                    "Lights on \(.applicationName)",
//                    "Switch on my light \(.applicationName)",
//                    "Control my room \(.applicationName)",
//                    "Control my lights",
//                ],
//                shortTitle: "Turn On Light",
//                systemImageName: "lightbulb"
//            ),
//            AppShortcut(
//                intent: AddLightOffShortcutIntent(),
//                phrases: [
//                    "Turn off light \(.applicationName)",
//                    "Turn off lights \(.applicationName)",
//                   
//                    "Lights off \(.applicationName)",
//                    "Switch off my light \(.applicationName)",
//                    "Shutdown light \(.applicationName)",
//                    "Turn off lights",
//                ],
//                shortTitle: "Turn Off Light",
//                systemImageName: "lightbulb"
//            ),
//            AppShortcut(
//                intent: AddFanOnShortcutIntent(),
//                phrases: [
//                    "Turn on fan \(.applicationName)",
//                    "Turn on fans \(.applicationName)",
//                   
//                    "Fan on \(.applicationName)",
//                    "Switch on my fans \(.applicationName)",
//                    "Shutdown fans \(.applicationName)",
//                    "Turn on fans",
//                ],
//                shortTitle: "Turn On fan",
//                systemImageName: "lightbulb"
//            ),
//            AppShortcut(
//                intent: AddFanOffShortcutIntent(),
//                phrases: [
//                    "Turn off fan \(.applicationName)",
//                   
//                    "Fan off \(.applicationName)",
//                    "Switch off my fan \(.applicationName)",
//                    "Shutdown fans \(.applicationName)",
//                    "Turn off fan",
//                ],
//                shortTitle: "Turn Off fant",
//                systemImageName: "lightbulb"
//            ),
//            AppShortcut(
//                intent: LightShortcutIntent(),
//                phrases: [
//                    "Turn on room light \(.applicationName)",
//                   
//                    "Fan off \(.applicationName)",
//                    "Switch off my fan \(.applicationName)",
//                    "Shutdown fans \(.applicationName)",
//                    "Turn off fan",
//                ],
//                shortTitle: "Turn Off fant",
//                systemImageName: "lightbulb"
//            )
//            
//            
//        ]
//    }
//}
//
