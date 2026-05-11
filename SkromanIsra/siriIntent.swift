//
//
//import AppIntents
//import AWSCore
//import AWSIoT
//
//struct AddLightOnShortcutIntent: AppIntent {
//    
//    static let title: LocalizedStringResource = "Turn on all home lights"
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
//      
//        for home in homes {
//            let homeName = home.homeName ?? "Unnamed Home"
//            let homeId = home.homeServerId ?? ""
//
//          
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
//        let finalMessage = fullList.isEmpty ? "No devices or buttons found." : "Ok Turning on all the lights"
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
//    static let title: LocalizedStringResource = "Turn off all home lights"
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
//        let finalMessage = fullList.isEmpty ? "No devices or buttons found." : "Ok Turning off all the lights"
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
//    static let title: LocalizedStringResource = "Turn on all home fans"
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
//        let finalMessage = fullList.isEmpty ? "No devices or buttons found." : "Ok Turning on the all fan at speed 1"
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
//    static let title: LocalizedStringResource = "Turn off all home fans"
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
//        let finalMessage = fullList.isEmpty ? "No devices or buttons found." : "Ok Turning off all the fan"
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
//        let urlString = "https://skromanautomation.in/skroman/lambda/device/postMqtt"
//        guard let url = URL(string: urlString) else {
//            print("Invalid URL.")
//            return
//        }
//
//        let payload: [String: Any] = [
//            "control": control,
//            "no": no,
//            "state": state,
//            "speed": speed,
//            "from": "X",
//            "deviceUniqueId": topic
//        ]
//
//        print("Sending to API with payload: \(payload)")
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
//            request.httpBody = jsonData
//        } catch {
//            print("Error serializing JSON: \(error)")
//            return
//        }
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("HTTP Request failed: \(error)")
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("Invalid response")
//                return
//            }
//
//            if (200...299).contains(httpResponse.statusCode) {
//                print("Successfully posted to API.")
//                if let data = data, let responseBody = String(data: data, encoding: .utf8) {
//                    print("Response body: \(responseBody)")
//                }
//            } else {
//                print("API call failed with status code: \(httpResponse.statusCode)")
//            }
//        }
//
//        task.resume()
//    }
//}
//
//
//
//
//
//
//
//struct LightOnButtonShortcutIntent: AppIntent {
//
//    static let title: LocalizedStringResource = "Turn on lights"
//    static var description = IntentDescription("Turns on a specific button in the selected room.")
//
//    @Parameter(title: "Room Name")
//    var roomName: String
//
//    @Parameter(title: "Button Number")
//    var buttonNumber: String
//
//    // Fuzzy string matching using Levenshtein Distance
//    func similarity(_ a: String, _ b: String) -> Int {
//        let a = Array(a.lowercased())
//        let b = Array(b.lowercased())
//        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
//
//        for i in 0...a.count { dist[i][0] = i }
//        for j in 0...b.count { dist[0][j] = j }
//
//        for i in 1...a.count {
//            for j in 1...b.count {
//                if a[i - 1] == b[j - 1] {
//                    dist[i][j] = dist[i - 1][j - 1]
//                } else {
//                    dist[i][j] = min(
//                        dist[i - 1][j] + 1,
//                        dist[i][j - 1] + 1,
//                        dist[i - 1][j - 1] + 1
//                    )
//                }
//            }
//        }
//
//        return dist[a.count][b.count]
//    }
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
//            print("without sort device  siri \(rooms)")
//            for room in rooms {
//                
//               
//                let match = similarity(room.roomName ?? "", roomName)
//                if match <= 2 { // Allow small typo or misheard, adjust threshold as needed
//                    let roomId = room.roomId ?? ""
//
//                    let devices = await withCheckedContinuation { continuation in
//                        SkromanIsraDatabaseHelper.shared.fetchDevicesforSiriByRoomId(roomId: roomId) { fetchedDevices in
//                            continuation.resume(returning: fetchedDevices)
//                        }
//                    }
//                    
//                    print("without sort device  siri \(devices)")
//                    for device in devices {
//                       // print("inside for loop \(device)")
//                        let deviceUniqueid = device.uniqueId ?? ""
//                        let deviceUid =  device.deviceUid
//                      
//                     
//                        var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonSiriDetails(uniqueId: deviceUniqueid)
//                      
//                        var  deviceState =  SkromanIsraDatabaseHelper.shared.fetchDeviceStateByDeviceUid(deviceUid: deviceUid)
//                        print("button state  at siri \(deviceState?.deviceUid) f state is \(deviceState?.fState)")
//                        buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                        
//                        // Filtering out invalid button names based on first characters
//                        let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                        buttonDetails = buttonDetails.filter { item in
//                            guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                            return !invalidFirstChars.contains(firstChar)
//                        }
//
//                        print("buttonDetails at siri \(buttonDetails)")
//
//                        // Now, handle the button press logic
//                        if buttonNumber.lowercased() == "all lights" {
//                            // If the user requested all buttons to be turned on
//                            for button in buttonDetails {
//                                publish_button(
//                                    control: button.buttonControlName,
//                                    no: button.buttonNo,
//                                    state: 1,
//                                    speed: 0,
//                                    topic: button.uniqueId
//                                )
//                                try? await Task.sleep(nanoseconds: 200_000_000)
//                            }
//                        } else if let number = Int(buttonNumber),
//                                  let targetButton = buttonDetails.first(where: { $0.buttonNo == number }) {
//                            // If the user specified a button number
//                            publish_button(
//                                control: targetButton.buttonControlName,
//                                no: targetButton.buttonNo,
//                                state: 1,
//                                speed: 0,
//                                topic: targetButton.uniqueId
//                            )
//                        } else {
//                            // If the specified button is not found
//                            return .result(dialog: IntentDialog("Button \(buttonNumber) not found in \(roomName)."))
//                        }
//                    }
//
//                    // After processing all devices, return a result
//                    return .result(dialog: IntentDialog("Processed all buttons in \(roomName)."))
//
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
//struct LightOffButtonShortcutIntent: AppIntent {
//
//    static let title: LocalizedStringResource = "Turn off lights"
//    static var description = IntentDescription("Turns on a specific button in the selected room.")
//
//    @Parameter(title: "Room Name")
//    var roomName: String
//
//    @Parameter(title: "Button Number")
//    var buttonNumber: String
//
//    // Fuzzy string matching using Levenshtein Distance
//    func similarity(_ a: String, _ b: String) -> Int {
//        let a = Array(a.lowercased())
//        let b = Array(b.lowercased())
//        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
//
//        for i in 0...a.count { dist[i][0] = i }
//        for j in 0...b.count { dist[0][j] = j }
//
//        for i in 1...a.count {
//            for j in 1...b.count {
//                if a[i - 1] == b[j - 1] {
//                    dist[i][j] = dist[i - 1][j - 1]
//                } else {
//                    dist[i][j] = min(
//                        dist[i - 1][j] + 1,
//                        dist[i][j - 1] + 1,
//                        dist[i - 1][j - 1] + 1
//                    )
//                }
//            }
//        }
//
//        return dist[a.count][b.count]
//    }
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
//                
//               
//                let match = similarity(room.roomName ?? "", roomName)
//                if match <= 2 { // Allow small typo or misheard, adjust threshold as needed
//                    let roomId = room.roomId ?? ""
//
//                    let devices = await withCheckedContinuation { continuation in
//                        SkromanIsraDatabaseHelper.shared.fetchDevicesforSiriByRoomId(roomId: roomId) { fetchedDevices in
//                            continuation.resume(returning: fetchedDevices)
//                        }
//                    }
//                    
////                    print("without sort device  siri \(devices)")
//                    for device in devices {
//                        
//                        let deviceUid = device.uniqueId ?? ""
//                        
//                        // Fetching button details for each device
//                        var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonSiriDetails(uniqueId: deviceUid)
//                       
//                        
//                        // Sorting button details by buttonNo
//                        buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                        
//                        // Filtering out invalid button names based on first characters
//                        let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                        buttonDetails = buttonDetails.filter { item in
//                            guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                            return !invalidFirstChars.contains(firstChar)
//                        }
//
////                        print("buttonDetails at siri \(buttonDetails)")
//
//                        // Now, handle the button press logic
//                        if buttonNumber.lowercased() == "all" {
//                            // If the user requested all buttons to be turned on
//                            for button in buttonDetails {
//                                publish_button(
//                                    control: button.buttonControlName,
//                                    no: button.buttonNo,
//                                    state: 0,
//                                    speed: 0,
//                                    topic: button.uniqueId
//                                )
//                                try? await Task.sleep(nanoseconds: 200_000_000)
//                            }
//                        } else if let number = Int(buttonNumber),
//                                  let targetButton = buttonDetails.first(where: { $0.buttonNo == number }) {
//                            // If the user specified a button number
//                            publish_button(
//                                control: targetButton.buttonControlName,
//                                no: targetButton.buttonNo,
//                                state: 0,
//                                speed: 0,
//                                topic: targetButton.uniqueId
//                            )
//                        } else {
//                            // If the specified button is not found
//                            return .result(dialog: IntentDialog("Button \(buttonNumber) not found in \(roomName)."))
//                        }
//                    }
//
//                    // After processing all devices, return a result
//                    return .result(dialog: IntentDialog("Processed all Light buttons in \(roomName)."))
//
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
////struct FetchSkromanAPIIntent: AppIntent {
////    static let title: LocalizedStringResource = "Skroman API Data"
////    static var description = IntentDescription("Fetches data from Skroman Automation API and reads it back.")
////    
////    func perform() async throws -> some IntentResult & ProvidesDialog {
////        guard let url = URL(string: "https://skromanautomation.in") else {
////            return .result(dialog: IntentDialog("Invalid API URL."))
////        }
////        
////        do {
////            let (data, _) = try await URLSession.shared.data(from: url)
////            let responseString = String(data: data, encoding: .utf8) ?? "Invalid response."
////            
////            // You can parse JSON here if needed
////            // For example:
////            // let decoded = try JSONDecoder().decode(YourModel.self, from: data)
////            
////            return .result(dialog: IntentDialog("API response: \(responseString)"))
////        } catch {
////            return .result(dialog: IntentDialog("Failed to fetch API response."))
////        }
////    }
////    
////}
//
//struct fanOnButtonShortcutIntent: AppIntent {
//
//    static let title: LocalizedStringResource = "Turn on fan"
//    static var description = IntentDescription("Turns on a specific button in the selected room.")
//
//    @Parameter(title: "Room Name")
//    var roomName: String
//
//    @Parameter(title: "Button Number")
//    var buttonNumber: String
//
//    // Fuzzy string matching using Levenshtein Distance
//    func similarity(_ a: String, _ b: String) -> Int {
//        let a = Array(a.lowercased())
//        let b = Array(b.lowercased())
//        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
//
//        for i in 0...a.count { dist[i][0] = i }
//        for j in 0...b.count { dist[0][j] = j }
//
//        for i in 1...a.count {
//            for j in 1...b.count {
//                if a[i - 1] == b[j - 1] {
//                    dist[i][j] = dist[i - 1][j - 1]
//                } else {
//                    dist[i][j] = min(
//                        dist[i - 1][j] + 1,
//                        dist[i][j - 1] + 1,
//                        dist[i - 1][j - 1] + 1
//                    )
//                }
//            }
//        }
//
//        return dist[a.count][b.count]
//    }
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
//                
//               
//                let match = similarity(room.roomName ?? "", roomName)
//                if match <= 2 { // Allow small typo or misheard, adjust threshold as needed
//                    let roomId = room.roomId ?? ""
//
//                    let devices = await withCheckedContinuation { continuation in
//                        SkromanIsraDatabaseHelper.shared.fetchDevicesforSiriByRoomId(roomId: roomId) { fetchedDevices in
//                            continuation.resume(returning: fetchedDevices)
//                        }
//                    }
//                    
////                    print("without sort device  siri \(devices)")
//                    for device in devices {
//                        
//                        
//                        let deviceUniqueid = device.uniqueId ?? ""
//                        let deviceUid  =  device.deviceUid ?? ""
//                        var  deviceState =  SkromanIsraDatabaseHelper.shared.fetchDeviceStateByDeviceUid(deviceUid: deviceUid)
//                        print("button state  at siri \(deviceState?.deviceUid) f state is \(deviceState?.fState)")
//                        var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonSiriDetails(uniqueId: deviceUniqueid)
//                       
//                        
//                        var buttonState  =  SkromanIsraDatabaseHelper.shared.fetchDeviceStatesByDeviceUid(deviceUid: deviceUid)
//                        print("buttonState at siri\(buttonState)")
//                        
//                        buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                        
//                        // Filtering out invalid button names based on first characters
//                        let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                        buttonDetails = buttonDetails.filter { item in
//                            guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                            return !invalidFirstChars.contains(firstChar)
//                        }
//
////
//
//                      print("button number at siri \(buttonNumber)")
//                        if buttonNumber.lowercased() == "all" {
//                            var fanNumber =  1
//                            
//                           
//                            for button in buttonDetails {
//                              
//                                if button.buttonControlName == "F"{
//                                    
//                                   
//                                    publish_button(
//                                        control: button.buttonControlName,
//                                        no: fanNumber,
//                                        state: 1,
//                                        speed: 1,
//                                        topic: button.uniqueId
//                                    )
//                                    
//                                    
//                                    try? await Task.sleep(nanoseconds: 200_000_000)
//                                    fanNumber = fanNumber+1
//                                }
//                            }
//                         } else if let number = Int(buttonNumber) {
//                            // Get only fan buttons
//                            let fanButtons = buttonDetails.filter { $0.buttonControlName == "F" }
//                            
//                            // Fans are 1-indexed for the user, so adjust for 0-based array index
//                            if number > 0 && number <= fanButtons.count {
//                                let targetButton = fanButtons[number - 1]
//                                
//                                publish_button(
//                                    control: "F",
//                                    no: number,
//                                    state: 1,
//                                    speed: 1,
//                                    topic: targetButton.uniqueId
//                                )
//                            }
//                        }
//
//                    }
//
//                    // After processing all devices, return a result
//                    return .result(dialog: IntentDialog("Turning on fan in \(roomName)."))
//
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
//struct fanOffButtonShortcutIntent: AppIntent {
//
//    static let title: LocalizedStringResource = "Turn off fan"
//    static var description = IntentDescription("Turns on a specific button in the selected room.")
//
//    @Parameter(title: "Room Name")
//    var roomName: String
//
//    @Parameter(title: "Button Number")
//    var buttonNumber: String
//
//    // Fuzzy string matching using Levenshtein Distance
//    func similarity(_ a: String, _ b: String) -> Int {
//        let a = Array(a.lowercased())
//        let b = Array(b.lowercased())
//        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
//
//        for i in 0...a.count { dist[i][0] = i }
//        for j in 0...b.count { dist[0][j] = j }
//
//        for i in 1...a.count {
//            for j in 1...b.count {
//                if a[i - 1] == b[j - 1] {
//                    dist[i][j] = dist[i - 1][j - 1]
//                } else {
//                    dist[i][j] = min(
//                        dist[i - 1][j] + 1,
//                        dist[i][j - 1] + 1,
//                        dist[i - 1][j - 1] + 1
//                    )
//                }
//            }
//        }
//
//        return dist[a.count][b.count]
//    }
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
//                
//               
//                let match = similarity(room.roomName ?? "", roomName)
//                if match <= 2 { // Allow small typo or misheard, adjust threshold as needed
//                    let roomId = room.roomId ?? ""
//
//                    let devices = await withCheckedContinuation { continuation in
//                        SkromanIsraDatabaseHelper.shared.fetchDevicesforSiriByRoomId(roomId: roomId) { fetchedDevices in
//                            continuation.resume(returning: fetchedDevices)
//                        }
//                    }
//                    
////                    print("without sort device  siri \(devices)")
//                    for device in devices {
//                        
//                        
//                        let deviceUniqueid = device.uniqueId ?? ""
//                        let deviceUid  =  device.deviceUid ?? ""
//                        var  deviceState =  SkromanIsraDatabaseHelper.shared.fetchDeviceStateByDeviceUid(deviceUid: deviceUid)
//                        print("button state  at siri \(deviceState?.deviceUid) f state is \(deviceState?.fState)")
//                        var buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonSiriDetails(uniqueId: deviceUniqueid)
//                       
//                        
//                        var buttonState  =  SkromanIsraDatabaseHelper.shared.fetchDeviceStatesByDeviceUid(deviceUid: deviceUid)
//                        print("buttonState at siri\(buttonState)")
//                        
//                        buttonDetails.sort { $0.buttonNo < $1.buttonNo }
//                        
//                        // Filtering out invalid button names based on first characters
//                        let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
//                        buttonDetails = buttonDetails.filter { item in
//                            guard let firstChar = item.buttonControlName.uppercased().first else { return false }
//                            return !invalidFirstChars.contains(firstChar)
//                        }
//
//
//                      print("button number at siri \(buttonNumber)")
//                        if buttonNumber.lowercased() == "all" {
//                            var fanNumber =  1
//                            
//                           
//                            for button in buttonDetails {
//                              
//                                if button.buttonControlName == "F"{
//                                    
//                                   
//                                    publish_button(
//                                        control: button.buttonControlName,
//                                        no: fanNumber,
//                                        state: 1,
//                                        speed: 1,
//                                        topic: button.uniqueId
//                                    )
//                                    
//                                    
//                                    try? await Task.sleep(nanoseconds: 200_000_000)
//                                    fanNumber = fanNumber+1
//                                }
//                            }
//                         } else if let number = Int(buttonNumber) {
//                            // Get only fan buttons
//                            let fanButtons = buttonDetails.filter { $0.buttonControlName == "F" }
//                            
//                            // Fans are 1-indexed for the user, so adjust for 0-based array index
//                            if number > 0 && number <= fanButtons.count {
//                                let targetButton = fanButtons[number - 1]
//                                
//                                publish_button(
//                                    control: "F",
//                                    no: number,
//                                    state: 0,
//                                    speed: 1,
//                                    topic: targetButton.uniqueId
//                                )
//                            }
//                        }
//
//                    }
//
//                    // After processing all devices, return a result
//                    return .result(dialog: IntentDialog("Turning off fan in \(roomName)."))
//
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
//                    "Turn On all home Light \(.applicationName)",
//                    "Turn on lights \(.applicationName)",
//                    "Lights on \(.applicationName)",
//                    "Switch on my light \(.applicationName)",
//                    "Control my room \(.applicationName)",
//                    "Control my lights",
//                ],
//                shortTitle: "Turn On all home Light",
//                systemImageName: "lightbulb"
//            ),
//            AppShortcut(
//                intent: AddLightOffShortcutIntent(),
//                phrases: [
//                    "Turn Off all home Light \(.applicationName)",
//                    "Turn off lights \(.applicationName)",
//                   
//                    "Lights off \(.applicationName)",
//                    "Switch off my light \(.applicationName)",
//                    "Shutdown light \(.applicationName)",
//                    "Turn off lights",
//                ],
//                shortTitle: "Turn Off all home Light",
//                systemImageName: "lightbulb"
//            ),
//            AppShortcut(
//                intent: AddFanOnShortcutIntent(),
//                phrases: [
//                    "Turn on all fan \(.applicationName)",
//                    "Turn on fans \(.applicationName)",
//                   
//                    "Fan on \(.applicationName)",
//                    "Switch on my fans \(.applicationName)",
//                    "Turn on fans",
//                ],
//                shortTitle: "Turn on all fans",
//                systemImageName: "fan.ceiling.fill"
//            ),
//            AppShortcut(
//                intent: AddFanOffShortcutIntent(),
//                phrases: [
//                    "Turn off all fan \(.applicationName)",
//                   
//                    "Fan off \(.applicationName)",
//                    "Switch off my fan \(.applicationName)",
//                    "Shutdown  all fans \(.applicationName)",
//                    "Turn off fan",
//                ],
//                shortTitle: "Turn Off all fans",
//                systemImageName: "fan.ceiling"
//            ),
//           
//            AppShortcut(
//                intent: LightOnButtonShortcutIntent(),
//                phrases: [
//                    "Turn on light \(.applicationName)",
//                   
//                    
//                ],
//                shortTitle: "Turn on light",
//                systemImageName: "lightbulb"
//            ),
//            AppShortcut(
//                intent: LightOffButtonShortcutIntent(),
//                phrases: [
//                    "Turn on light \(.applicationName)",
//                   
//                    
//                ],
//                shortTitle: "Turn on light",
//                systemImageName: "lightbulb"
//            ),
//            AppShortcut(
//                intent: fanOnButtonShortcutIntent(),
//                phrases: [
//                    "Turn on fan \(.applicationName)",
//                   
//                    
//                ],
//                shortTitle: "Turn on fan",
//                systemImageName: "fan.ceiling.fill"
//            ),
//            AppShortcut(
//                intent: fanOffButtonShortcutIntent(),
//                phrases: [
//                    "Turn off fan \(.applicationName)",
//                   
//                    
//                ],
//                shortTitle: "Turn Off fan",
//                systemImageName: "fan.ceiling"
//            )
//            
//            
//            
//        ]
//    }
//}
//
//
//
//
