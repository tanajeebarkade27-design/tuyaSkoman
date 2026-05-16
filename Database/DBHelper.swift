//
//  DBHelper.swift
//  SkromanIsra
//
//  Created by Admin on 18/02/25.
//

import Foundation
import SQLite3

class SkromanIsraDatabaseHelper {
    static let shared = SkromanIsraDatabaseHelper()
    
    private var db: OpaquePointer?
    private let homeTable = "home"
    private let roomTable = "rooms"
    private let deviceTable = "devices"
    private let deviceState =  "deviceState"
    private let deviceSceneTable =  "deviceScene"
    private let deviceSchdeuleTable  =  "deviceSchdeule"
    private let buttonsDetailsTable = "buttonsDetails"
    private let userTable = "userData"
    private let roomSceneTable = "roomScene"
    private let tuyaDeviceTable = "tuyaDevices"

    private let databaseQueue = DispatchQueue(label: "com.SkromanIsra.databaseQueue")
    
    private init() {
 //  deleteDatabase()
        printHomeTableSchema()
    openDatabase()
        createTables()
        
        print("in init db")
        
    }
    
    func openDatabase() {
        let fileURL = try! FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("skroman.sqlite")
        
        
        print("SQLite file path: \(fileURL.path)")
        
        
        if sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) != SQLITE_OK {
            print("Error opening database")
        } else {
            print("Database opened successfully")
        }
    }
    func createTables() {
        
        let createUserTableQuery = """
        CREATE TABLE IF NOT EXISTS \(userTable) (
            userId TEXT PRIMARY KEY,
            userName TEXT,
            emailId TEXT TEXT,
            mobileNumber TEXT,
            address1 TEXT,
            address2 TEXT,
            city TEXT,
            state TEXT,
            pinCode TEXT,
            loginType TEXT,
            imageUser TEXT,
            verifyAlexa TEXT,
            verifyGoogle TEXT,
            password TEXT
        
        );
        """
        
        let createHomeTableQuery = """
        CREATE TABLE IF NOT EXISTS \(homeTable) (
            homeServerId TEXT PRIMARY KEY,
            homeName TEXT,
            homeUrl TEXT,
            tuyaHomeId INTEGER,
            isFamilyHome INTEGER DEFAULT 0
        );
        """

        
        let createRoomTableQuery = """
        CREATE TABLE IF NOT EXISTS \(roomTable) (
            roomId TEXT PRIMARY KEY,
            roomName TEXT,
            roomIconId TEXT,
            roomIconType TEXT,
            tuyaRoomId INTEGER,
            homeId TEXT
        );
        """
        
        
        let createRoomSceneTableQuery = """
          CREATE TABLE IF NOT EXISTS \(roomSceneTable) (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              roomId TEXT,
              sceneNo TEXT,
              sceneName TEXT,
              sceneIcon TEXT,
              FOREIGN KEY (roomId) REFERENCES \(roomTable)(roomId)
          );
          """

        
        let createDeviceTableQuery = """
        CREATE TABLE IF NOT EXISTS \(deviceTable) (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deviceUid TEXT,
            roomId TEXT,
            homeId TEXT,
            userId TEXT,
            deviceName TEXT,
            unique_id TEXT,
            POP TEXT,
            deviceModelNo TEXT,
            deviceType TEXT,
            connectedSsid TEXT,
            connectedPassword TEXT,
            deviceCategory TEXT,
            deviceDimmingType TEXT
        );
        """
        
        let createDeviceStateTableQuery = """
        CREATE TABLE IF NOT EXISTS \(deviceState) (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deviceUid TEXT,
            deviceStateUid TEXT,
            unique_id TEXT,
            working_mode TEXT,
            master TEXT,
            child_lock_f TEXT,
            child_lock_l TEXT,
            child_lock_m TEXT,
            config_buttons TEXT,
            config_dim TEXT,
            connectivity TEXT,
            dest_button TEXT,
            f_speed TEXT,
            f_state TEXT,
            fan_dest TEXT,
            l_speed TEXT,
            l_state TEXT,
            series TEXT,
          ota_status TEXT,
          F_regulator TEXT
        );
        """
        let createSceneTableQuery = """
        CREATE TABLE IF NOT EXISTS \(deviceSceneTable)(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sceneId TEXT,
            deviceUid TEXT,
            homeId TEXT,
            roomId TEXT,
            unique_id TEXT,
            modelNo TEXT,
            deviceType TEXT,
            sceneNo TEXT,
            sceneName TEXT,
            dest_button TEXT,
            config_buttons TEXT,
            config_dim TEXT,
            L_state TEXT,
            L_speed TEXT,
            F_state TEXT,
            F_speed TEXT,
            fan_dest TEXT,
            F_redundant TEXT,
            L_redundant TEXT
        
        );
        """

        let createTimeScheduleTableQuery = """
        CREATE TABLE IF NOT EXISTS \(deviceSchdeuleTable) (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scheduleId TEXT,
            scheduleNumber TEXT,
            deviceUid TEXT,
            unique_id TEXT,
            date TEXT,
            time TEXT,
            week_schedule TEXT,
            L_state TEXT,
            L_speed TEXT,
            F_state TEXT,
            F_speed TEXT,
            config_buttons TEXT,
            dest_button TEXT,
            fan_dest TEXT,
            master TEXT,
            modelNo TEXT,
            sceneId TEXT
        );
        """

        
        let createButtonDetailsTableQuery = """
        CREATE TABLE IF NOT EXISTS \(buttonsDetailsTable) (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            buttonId TEXT,
            buttonControlName TEXT,
            buttonIconId INTEGER,
            buttonName TEXT,
            buttonNo INTEGER,
            deviceServerId TEXT,
            deviceUid TEXT,
            power INTEGER,
            roomName TEXT,
            switchName TEXT,
            unique_id TEXT,
            isShortcut INTEGER,
            buttonIconName TEXT,
            buttonIconColor TEXT,
            isFavourite INTEGER,
             isHomeFav INTEGER
        );
        """

        let createTuyaDeviceTableQuery = """
        CREATE TABLE IF NOT EXISTS \(tuyaDeviceTable) (
            deviceId TEXT PRIMARY KEY,
            tuyaHomeId INTEGER,
            tuyaRoomId INTEGER,
            deviceName TEXT,
            deviceCategory TEXT
        );
        """
        
       


        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            func executeQuery(_ query: String, tableName: String) {
                var createTableStatement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, query, -1, &createTableStatement, nil) != SQLITE_OK {
                    print("Error preparing create \(tableName) table statement: \(String(cString: sqlite3_errmsg(self.db)))")
                } else {
                    if sqlite3_step(createTableStatement) != SQLITE_DONE {
                        print("Error creating \(tableName) table: \(String(cString: sqlite3_errmsg(self.db)))")
                    } else {
                        print("\(tableName) table created successfully!")
                        
                    }
                }
                sqlite3_finalize(createTableStatement)
            }
            executeQuery(createTuyaDeviceTableQuery, tableName: "tuyaDevices")
            executeQuery(createHomeTableQuery, tableName: "home")
            executeQuery(createRoomTableQuery, tableName: "rooms")
            executeQuery(createDeviceTableQuery, tableName: "devices")
            executeQuery(createDeviceStateTableQuery, tableName: "deviceState")
           executeQuery(createSceneTableQuery, tableName: "deviceScene")
            executeQuery(createTimeScheduleTableQuery, tableName: "deviceSchdeule")
            executeQuery(createButtonDetailsTableQuery, tableName: "buttonsDetails")
            executeQuery(createUserTableQuery, tableName: "userData")
            executeQuery(createRoomSceneTableQuery, tableName: "roomScene")

            
           
            
            
        }
    }

    func insertUser(userId: String, userName: String?, emailId: String?, mobileNumber: String?, address1: String?, address2: String?, city: String?, state: String?, pinCode: String?, loginType: String?, imageUser: String?, verifyAlexa: String?, verifyGoogle: String?, password: String?) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let insertQuery = """
            INSERT OR REPLACE INTO \(self.userTable) (userId, userName, emailId, mobileNumber, address1, address2, city, state, pinCode, loginType, imageUser, verifyAlexa, verifyGoogle, password)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            var insertStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
                print("❌ Error preparing user insert statement: \(String(cString: sqlite3_errmsg(self.db)))")
                return
            }
            
            defer {
                sqlite3_finalize(insertStatement)
            }

            sqlite3_bind_text(insertStatement, 1, (userId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (userName as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (emailId as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, (mobileNumber as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 5, (address1 as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, (address2 as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (city as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 8, (state as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 9, (pinCode as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 10, (loginType as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 11, (imageUser as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 12, (verifyAlexa as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 13, (verifyGoogle as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 13, (password as NSString?)?.utf8String, -1, nil)
            
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
//                print("✅ Successfully inserted user: \(userName ?? "Unknown")")
            } else {
                print("❌ Error inserting user: \(String(cString: sqlite3_errmsg(self.db)))")
            }
        }
    }
    
    func fetchUserById(userId: String) -> [User] {
        let fetchQuery = "SELECT * FROM \(userTable) WHERE userId = ?;"
        var queryStatement: OpaquePointer?
        var users: [User] = []

        if sqlite3_prepare_v2(db, fetchQuery, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (userId as NSString).utf8String, -1, nil)

            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let user = User(
                    userId: String(cString: sqlite3_column_text(queryStatement, 0)),
                    userName: sqlite3_column_text(queryStatement, 1).flatMap { String(cString: $0) },
                    emailId: sqlite3_column_text(queryStatement, 2).flatMap { String(cString: $0) },
                    mobileNumber: sqlite3_column_text(queryStatement, 3).flatMap { String(cString: $0) },
                    address1: sqlite3_column_text(queryStatement, 4).flatMap { String(cString: $0) },
                    address2: sqlite3_column_text(queryStatement, 5).flatMap { String(cString: $0) },
                    city: sqlite3_column_text(queryStatement, 6).flatMap { String(cString: $0) },
                    state: sqlite3_column_text(queryStatement, 7).flatMap { String(cString: $0) },
                    pinCode: sqlite3_column_text(queryStatement, 8).flatMap { String(cString: $0) },
                    loginType: sqlite3_column_text(queryStatement, 9).flatMap { String(cString: $0) },
                    imageUser: sqlite3_column_text(queryStatement, 10).flatMap { String(cString: $0) },
                    verifyAlexa: sqlite3_column_text(queryStatement, 11).flatMap { String(cString: $0) },
                    verifyGoogle: sqlite3_column_text(queryStatement, 12).flatMap { String(cString: $0) },
                    password: sqlite3_column_text(queryStatement, 12).flatMap { String(cString: $0) }
                )

                users.append(user)
            }

            if users.isEmpty {
                print("⚠️ No user found with userId: \(userId)")
            } else {
//                print("✅ Fetched \(users.count) user(s) successfully for userId: \(userId)")
            }
        } else {
            print("❌ Error preparing fetch statement: \(String(cString: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(queryStatement)
        return users
    }


    func insertTuyaDevice(
        tuyaHomeId: Int64,
        tuyaRoomId: Int64?,
        deviceId: String,
        deviceName: String,
        deviceCategory: String,
        completion: (() -> Void)? = nil
    ) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }

            guard let db = self.db else {
                print("❌ DB NIL during insert")
                return
            }

            guard !deviceId.isEmpty else {
                print("❌ Empty deviceId")
                return
            }

            print("✅ INSERT → \(deviceName) | home:", tuyaHomeId, "| room:", tuyaRoomId ?? -1)

            let query = """
            INSERT OR REPLACE INTO \(self.tuyaDeviceTable)
            (tuyaHomeId, tuyaRoomId, deviceId, deviceName, deviceCategory)
            VALUES (?, ?, ?, ?, ?);
            """

            var stmt: OpaquePointer?

            guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
                print("❌ Prepare failed:", String(cString: sqlite3_errmsg(db)))
                return
            }

            defer { sqlite3_finalize(stmt) }

            // Bind
            sqlite3_bind_int64(stmt, 1, tuyaHomeId)

            if let roomId = tuyaRoomId, roomId > 0 {
                sqlite3_bind_int64(stmt, 2, roomId)
            } else {
                sqlite3_bind_null(stmt, 2)
            }

            sqlite3_bind_text(stmt, 3, (deviceId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (deviceName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (deviceCategory as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) == SQLITE_DONE {
                print("✅ INSERT SUCCESS:", deviceId)
            } else {
                print("❌ INSERT FAIL:", String(cString: sqlite3_errmsg(db)))
            }

            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    func deleteTuyaDevice(deviceId: String, completion: (() -> Void)? = nil) {
        databaseQueue.async { [weak self] in
            guard let self = self, let db = self.db else { return }

            let query = "DELETE FROM \(self.tuyaDeviceTable) WHERE deviceId = ?;"
            var stmt: OpaquePointer?

            guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
                print("❌ Delete Tuya device prepare failed:", String(cString: sqlite3_errmsg(db)))
                return
            }

            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_text(stmt, 1, (deviceId as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) == SQLITE_DONE {
                print("✅ Tuya device deleted from DB:", deviceId)
            } else {
                print("❌ Delete Tuya device failed:", String(cString: sqlite3_errmsg(db)))
            }

            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func fetchTuyaDevices(
        tuyaHomeId: Int64,
        tuyaRoomId: Int64?,
        completion: @escaping ([TuyaDeviceModel]) -> Void
    ) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }

            guard let db = self.db else {
                print("❌ DB NIL during fetch")
                DispatchQueue.main.async { completion([]) }
                return
            }

            print("🔍 FETCH → home:", tuyaHomeId, "| room:", tuyaRoomId ?? -1)

            var devices: [TuyaDeviceModel] = []
            var stmt: OpaquePointer?

            // IMPORTANT:
            // If a room is selected, return by roomId (not strict homeId).
            // This supports cases where sync and newly added devices are saved with
            // different tuyaHomeId values for the same tuyaRoomId.
            let query: String
            let shouldFilterByRoom = (tuyaRoomId ?? 0) > 0
            if shouldFilterByRoom {
                query = """
                SELECT tuyaHomeId, tuyaRoomId, deviceId, deviceName, deviceCategory
                FROM \(self.tuyaDeviceTable)
                WHERE tuyaRoomId = ?;
                """
            } else {
                query = """
                SELECT tuyaHomeId, tuyaRoomId, deviceId, deviceName, deviceCategory
                FROM \(self.tuyaDeviceTable)
                WHERE tuyaHomeId = ?;
                """
            }

            guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
                print("❌ Fetch prepare failed:", String(cString: sqlite3_errmsg(db)))
                DispatchQueue.main.async { completion([]) }
                return
            }

            defer { sqlite3_finalize(stmt) }

            if shouldFilterByRoom {
                sqlite3_bind_int64(stmt, 1, tuyaRoomId ?? 0)
            } else {
                sqlite3_bind_int64(stmt, 1, tuyaHomeId)
            }

            while sqlite3_step(stmt) == SQLITE_ROW {

                let homeId = sqlite3_column_int64(stmt, 0)

                let roomId = sqlite3_column_type(stmt, 1) == SQLITE_NULL
                    ? 0
                    : sqlite3_column_int64(stmt, 1)

                let deviceId = sqlite3_column_text(stmt, 2).flatMap { String(cString: $0) } ?? ""
                let deviceName = sqlite3_column_text(stmt, 3).flatMap { String(cString: $0) } ?? ""
                let deviceCategory = sqlite3_column_text(stmt, 4).flatMap { String(cString: $0) } ?? ""

                guard !deviceId.isEmpty else { continue }

                devices.append(
                    TuyaDeviceModel(
                        tuyaHomeId: homeId,
                        tuyaRoomId: roomId,
                        deviceId: deviceId,
                        deviceName: deviceName,
                        deviceCategory: deviceCategory
                    )
                )
            }

            print("📦 TOTAL DB DEVICES:", devices.count)

            DispatchQueue.main.async {
                print("📦 FINAL RESULT:", devices.count)
                completion(devices)
            }
        }
    }
    
    func insertHome(homeServerId: String?,
                    homeName: String?,
                    homeUrl: String?,
                    tuyaHomeId: Int64?,   // ✅ use Int64
                    isFamilyHome: Int) {
        
        guard let homeServerId = homeServerId,
              let homeName = homeName else {
            print("❌ Missing homeServerId or homeName")
            return
        }
        
        databaseQueue.async { [weak self] in
            guard let self = self, let db = self.db else { return }
            
            let query = """
            INSERT OR REPLACE INTO \(self.homeTable)
            (homeServerId, homeName, homeUrl, isFamilyHome, tuyaHomeId)
            VALUES (?, ?, ?, ?, ?);
            """
            
            var stmt: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
                print("❌ Prepare Failed: \(String(cString: sqlite3_errmsg(db)))")
                return
            }
            
            defer { sqlite3_finalize(stmt) } // ✅ always finalize
            
            // 1️⃣ homeServerId
            sqlite3_bind_text(stmt, 1, (homeServerId as NSString).utf8String, -1, nil)
            
            // 2️⃣ homeName
            sqlite3_bind_text(stmt, 2, (homeName as NSString).utf8String, -1, nil)
            
            
            if let url = homeUrl {
                sqlite3_bind_text(stmt, 3, (url as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 3)
            }
            
            
            sqlite3_bind_int(stmt, 4, Int32(isFamilyHome))
            
            
            if let tuyaId = tuyaHomeId {
                sqlite3_bind_int64(stmt, 5, tuyaId)
            } else {
                sqlite3_bind_null(stmt, 5)
            }
            
            // Execute
            if sqlite3_step(stmt) == SQLITE_DONE {
                let tuyaIdString = tuyaHomeId.map { String($0) } ?? "nil"
                print("🏠 Home inserted → \(homeName) | TuyaID: \(tuyaIdString)")
            } else {
                print("❌ Insert Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
    }
    
   
    func updateHome(homeServerId: String,
                    newHomeName: String,
                    newHomeUrl: String?,
                    tuyaHomeId: Int64?) {   // ✅ use Int64
        
        let updateQuery = """
        UPDATE \(homeTable)
        SET homeName = ?, homeUrl = ?, tuyaHomeId = ?
        WHERE homeServerId = ?;
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK else {
            print("❌ Error preparing update: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        
        defer { sqlite3_finalize(statement) } // ✅ always finalize
        
        // 1️⃣ homeName
        sqlite3_bind_text(statement, 1, (newHomeName as NSString).utf8String, -1, nil)
        
        // 2️⃣ homeUrl
        if let url = newHomeUrl {
            sqlite3_bind_text(statement, 2, (url as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 2)
        }
        
       
        if let tuyaId = tuyaHomeId {
            sqlite3_bind_int64(statement, 3, tuyaId)
        } else {
            sqlite3_bind_null(statement, 3)
        }
        
      
        sqlite3_bind_text(statement, 4, (homeServerId as NSString).utf8String, -1, nil)
        
        // Execute
        if sqlite3_step(statement) == SQLITE_DONE {
            let tuyaIdString = tuyaHomeId.map { String($0) } ?? "nil"
            print("🏠 Home updated → \(newHomeName) | TuyaID: \(tuyaIdString)")
        } else {
            print("❌ Update failed: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    
    
    func fetchAllHomesData() -> [Home] {
        var homes: [Home] = []
        
        let selectQuery = """
        SELECT homeServerId, homeName, homeUrl, isFamilyHome, tuyaHomeId
        FROM \(self.homeTable);
        """
        
        var selectStatement: OpaquePointer?
        
        guard sqlite3_prepare_v2(self.db, selectQuery, -1, &selectStatement, nil) == SQLITE_OK else {
            print("❌ Error preparing select: \(String(cString: sqlite3_errmsg(self.db)))")
            return []
        }
        
        defer { sqlite3_finalize(selectStatement) }
        
        while sqlite3_step(selectStatement) == SQLITE_ROW {
            
           
            let homeServerId = String(cString: sqlite3_column_text(selectStatement, 0))
            
           
            let homeName = sqlite3_column_text(selectStatement, 1).flatMap { String(cString: $0) }
            
           
            let homeUrl = sqlite3_column_text(selectStatement, 2).flatMap { String(cString: $0) }
            
           
            let isFamilyHome = Int(sqlite3_column_int(selectStatement, 3))
            
          
            let tuyaHomeId: Int64? = {
                let value = sqlite3_column_int64(selectStatement, 4)
                return value == 0 ? nil : value
            }()
            
            let home = Home(
                homeServerId: homeServerId,
                homeName: homeName,
                homeUrl: homeUrl,
                isFamilyHome: isFamilyHome,
                tuyaHomeId: tuyaHomeId
            )
            
            let tuyaIdString = tuyaHomeId.map { String($0) } ?? "nil"
            print("🏠 Home → : \(homeName), TuyaID: \(tuyaIdString)")
            
            homes.append(home)
        }
        
        return homes
    }

    
    
    

    func fetchAllHomes(completion: @escaping ([Home]) -> Void) {

        databaseQueue.async { [weak self] in

            guard let self = self else { return }

            var homes: [Home] = []

            let query = """
            SELECT
            homeServerId,
            homeName,
            homeUrl,
            isFamilyHome,
            tuyaHomeId
            FROM \(self.homeTable);
            """

            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(
                self.db,
                query,
                -1,
                &stmt,
                nil
            ) == SQLITE_OK {

                while sqlite3_step(stmt) == SQLITE_ROW {

                    let homeServerId =
                    String(cString: sqlite3_column_text(stmt, 0))

                    let homeName =
                    sqlite3_column_text(stmt, 1).flatMap {
                        String(cString: $0)
                    }

                    let homeUrl =
                    sqlite3_column_text(stmt, 2).flatMap {
                        String(cString: $0)
                    }

                    let isFamilyHome =
                    Int(sqlite3_column_int(stmt, 3))

                    // IMPORTANT FIX
                    let tuyaHomeId: Int64? = {

                        let value = sqlite3_column_int64(stmt, 4)

                        return value == 0 ? nil : value
                    }()

                    let home = Home(
                        homeServerId: homeServerId,
                        homeName: homeName,
                        homeUrl: homeUrl,
                        isFamilyHome: isFamilyHome,
                        tuyaHomeId: tuyaHomeId
                    )

                    print(
                        "🏠 FETCH HOME:",
                        homeName ?? "",
                        "| Tuya:",
                        tuyaHomeId ?? -1
                    )

                    homes.append(home)
                }

            } else {

                print(
                    "❌ Fetch error:",
                    String(cString: sqlite3_errmsg(self.db))
                )
            }

            sqlite3_finalize(stmt)

            DispatchQueue.main.async {

                completion(homes)
            }
        }
    }



    
    func fetchHomeById(homeServerId: String) -> Home? {
        
        let query = """
        SELECT homeServerId, homeName, homeUrl, isFamilyHome, tuyaHomeId
        FROM home
        WHERE homeServerId = ?;
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("❌ Prepare failed: \(String(cString: sqlite3_errmsg(db)))")
            return nil
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind ID
        sqlite3_bind_text(statement, 1, (homeServerId as NSString).utf8String, -1, nil)
        
        // Execute
        if sqlite3_step(statement) == SQLITE_ROW {
            
            let homeServerId = String(cString: sqlite3_column_text(statement, 0))
            let homeName = sqlite3_column_text(statement, 1).flatMap { String(cString: $0) }
            let homeUrl = sqlite3_column_text(statement, 2).flatMap { String(cString: $0) }
            let isFamilyHome = Int(sqlite3_column_int(statement, 3))
            
           
            let tuyaHomeId: Int64? = {
                let value = sqlite3_column_int64(statement, 4)
                return value == 0 ? nil : value
            }()
            
            let home = Home(
                homeServerId: homeServerId,
                homeName: homeName,
                homeUrl: homeUrl,
                isFamilyHome: isFamilyHome,
                tuyaHomeId: tuyaHomeId
            )
            
            print("🏠 Found Home → \(homeName ?? "") | TuyaID: \(tuyaHomeId ?? -1)")
            
            return home
        }
        
        print("❌ No home found for ID: \(homeServerId)")
        return nil
    }
    
    func insertRoom(
        roomId: String,
        roomName: String,
        roomIconId: String,
        roomIconType: String,
        tuyaRoomId: Int64?,
        homeId: String
    ) {

        // 🔥 Step 1: Get existing tuyaRoomId from DB
        let existingRoomId = getExistingTuyaRoomId(roomId: roomId)

        let finalTuyaRoomId: Int64?

        if let newId = tuyaRoomId, newId > 0 {
            // ✅ Always accept valid ID
            finalTuyaRoomId = newId
        } else {
            // ❌ Ignore invalid (-1 / nil), keep old value
            finalTuyaRoomId = existingRoomId
            print("⚠️ Keeping old tuyaRoomId:", existingRoomId ?? -1)
        }

        let query = """
        INSERT OR REPLACE INTO \(roomTable)
        (roomId, roomName, roomIconId, roomIconType, tuyaRoomId, homeId)
        VALUES (?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("❌ Prepare failed:", String(cString: sqlite3_errmsg(db)))
            return
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (roomId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (roomName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (roomIconId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 4, (roomIconType as NSString).utf8String, -1, nil)

        if let id = finalTuyaRoomId {
            sqlite3_bind_int64(statement, 5, id)
        } else {
            sqlite3_bind_null(statement, 5)
        }

        sqlite3_bind_text(statement, 6, (homeId as NSString).utf8String, -1, nil)

        if sqlite3_step(statement) == SQLITE_DONE {
            print("✅ Room saved:",
                  "roomId:", roomId,
                  "| name:", roomName,
                  "| tuyaRoomId:", finalTuyaRoomId ?? -1)
        } else {
            print("❌ Insert failed:", String(cString: sqlite3_errmsg(db)))
        }
    }
    
    
    func getExistingTuyaRoomId(roomId: String) -> Int64? {

        let query = "SELECT tuyaRoomId FROM \(roomTable) WHERE roomId = ? LIMIT 1"

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            
            sqlite3_bind_text(statement, 1, (roomId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                sqlite3_finalize(statement)
                return id > 0 ? id : nil
            }
        }

        sqlite3_finalize(statement)
        return nil
    }
    
    func getTuyaRoomIdFromDB(roomId: String) -> Int64? {

        let query = "SELECT tuyaRoomId FROM \(roomTable) WHERE roomId = ? LIMIT 1"

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("❌ Prepare failed:", String(cString: sqlite3_errmsg(db)))
            return nil
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (roomId as NSString).utf8String, -1, nil)

        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)

            if id > 0 {
                print("✅ DB RoomId:", id)
                return id
            } else {
                print("❌ Invalid DB RoomId:", id)
            }
        }

        return nil
    }
    
    func fetchRoomsByHomeId(
        homeServerId: String,
        completion: @escaping ([(roomId: String,
                                 roomName: String,
                                 roomIconId: String,
                                 roomIconType: String,
                                 tuyaRoomId: Int64?,
                                 homeId: String)]) -> Void
    ) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            var rooms = [(roomId: String,
                          roomName: String,
                          roomIconId: String,
                          roomIconType: String,
                          tuyaRoomId: Int64?,
                          homeId: String)]()
            
            let query = """
            SELECT roomId, roomName, roomIconId, roomIconType, tuyaRoomId, homeId
            FROM \(self.roomTable)
            WHERE homeId = ?;
            """
            
            var queryStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, query, -1, &queryStatement, nil) == SQLITE_OK {
                
                sqlite3_bind_text(queryStatement, 1, (homeServerId as NSString).utf8String, -1, nil)
                
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    
                    let roomId = String(cString: sqlite3_column_text(queryStatement, 0))
                    let roomName = String(cString: sqlite3_column_text(queryStatement, 1))
                    let roomIconId = String(cString: sqlite3_column_text(queryStatement, 2))
                    let roomIconType = String(cString: sqlite3_column_text(queryStatement, 3))
                    
                    // 🔥 HANDLE OPTIONAL
                    let tuyaRoomId: Int64? = sqlite3_column_type(queryStatement, 4) == SQLITE_NULL
                        ? nil
                        : sqlite3_column_int64(queryStatement, 4)
                    
                    let homeId = String(cString: sqlite3_column_text(queryStatement, 5))
                    
                    let room = (roomId, roomName, roomIconId, roomIconType, tuyaRoomId, homeId)
                    rooms.append(room)
                    
                    print("📦 Room:",
                          roomId,
                          "| tuyaRoomId:", tuyaRoomId ?? -1)
                }
            }
            
            sqlite3_finalize(queryStatement)
            
            DispatchQueue.main.async {
                completion(rooms)
            }
        }
    }
    
    
    func fetchRoomByRoomId(
        roomId: String,
        completion: @escaping ((roomId: String,
                                roomName: String,
                                roomIconId: String,
                                roomIconType: String,
                                tuyaRoomId: Int64?,
                                homeId: String)?) -> Void
    ) {

        databaseQueue.async { [weak self] in
            guard let self = self else { return }

            let query = """
            SELECT roomId, roomName, roomIconId, roomIconType, tuyaRoomId, homeId
            FROM \(self.roomTable)
            WHERE roomId = ?
            LIMIT 1;
            """

            var queryStatement: OpaquePointer?
            var result: (roomId: String,
                         roomName: String,
                         roomIconId: String,
                         roomIconType: String,
                         tuyaRoomId: Int64?,
                         homeId: String)?

            if sqlite3_prepare_v2(self.db, query, -1, &queryStatement, nil) == SQLITE_OK {

                sqlite3_bind_text(queryStatement, 1, (roomId as NSString).utf8String, -1, nil)

                if sqlite3_step(queryStatement) == SQLITE_ROW {

                    let roomId = String(cString: sqlite3_column_text(queryStatement, 0))
                    let roomName = String(cString: sqlite3_column_text(queryStatement, 1))
                    let roomIconId = String(cString: sqlite3_column_text(queryStatement, 2))
                    let roomIconType = String(cString: sqlite3_column_text(queryStatement, 3))

                    let tuyaRoomId: Int64? = sqlite3_column_type(queryStatement, 4) == SQLITE_NULL
                        ? nil
                        : sqlite3_column_int64(queryStatement, 4)

                    let homeId = String(cString: sqlite3_column_text(queryStatement, 5))

                    result = (roomId, roomName, roomIconId, roomIconType, tuyaRoomId, homeId)

                    print("✅ Room fetched:",
                          roomId,
                          "| tuyaRoomId:", tuyaRoomId ?? -1)
                }
            }

            sqlite3_finalize(queryStatement)

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    /// Returns the number of rooms for a given homeId.
    func fetchRoomCountByHomeId(homeServerId: String, completion: @escaping (Int) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self, let db = self.db else { return }
            
            let query = "SELECT COUNT(*) FROM \(self.roomTable) WHERE homeId = ?;"
            var stmt: OpaquePointer?
            var count = 0
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (homeServerId as NSString).utf8String, -1, nil)
                if sqlite3_step(stmt) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(stmt, 0))
                }
            } else {
                print("❌ Room count prepare error: \(String(cString: sqlite3_errmsg(db)))")
            }
            
            sqlite3_finalize(stmt)
            DispatchQueue.main.async {
                completion(count)
            }
        }
    }
    
    func deleteHomeFromLocal(homeServerId: String) {
        let deleteQuery = "DELETE FROM \(homeTable) WHERE homeServerId = ?;"
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) != SQLITE_OK {
            print("❌ Error preparing delete statement: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (homeServerId as NSString).utf8String, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_DONE {
            print("🗑️ Home deleted successfully from local DB.")
        } else {
            print("❌ Failed to delete home: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    /// Deletes a home and all related local data (rooms, room scenes, devices, schedules, buttons, states).
    func deleteHomeCascadeFromLocal(homeServerId: String) {
        databaseQueue.async { [weak self] in
            guard let self, let db = self.db else { return }
            
            // 1) Delete device-related rows for devices under this home.
            let deviceCascadeQueries = [
                // deviceState/buttonsDetails/deviceScene/deviceSchedule use unique_id
                "DELETE FROM \(self.deviceState) WHERE unique_id IN (SELECT unique_id FROM \(self.deviceTable) WHERE homeId = ?);",
                "DELETE FROM \(self.buttonsDetailsTable) WHERE unique_id IN (SELECT unique_id FROM \(self.deviceTable) WHERE homeId = ?);",
                "DELETE FROM \(self.deviceSceneTable) WHERE unique_id IN (SELECT unique_id FROM \(self.deviceTable) WHERE homeId = ?);",
                "DELETE FROM \(self.deviceSchdeuleTable) WHERE unique_id IN (SELECT unique_id FROM \(self.deviceTable) WHERE homeId = ?);",
                // now delete devices
                "DELETE FROM \(self.deviceTable) WHERE homeId = ?;"
            ]
            
            for query in deviceCascadeQueries {
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(stmt, 1, (homeServerId as NSString).utf8String, -1, nil)
                    if sqlite3_step(stmt) != SQLITE_DONE {
                        print("❌ Cascade delete failed: \(String(cString: sqlite3_errmsg(db)))")
                    }
                } else {
                    print("❌ Prepare cascade delete failed: \(String(cString: sqlite3_errmsg(db)))")
                }
                sqlite3_finalize(stmt)
            }
            
            // 2) Delete room scenes for rooms under this home, then rooms.
            let roomSceneDelete = "DELETE FROM \(self.roomSceneTable) WHERE roomId IN (SELECT roomId FROM \(self.roomTable) WHERE homeId = ?);"
            let roomsDelete = "DELETE FROM \(self.roomTable) WHERE homeId = ?;"
            
            for query in [roomSceneDelete, roomsDelete] {
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(stmt, 1, (homeServerId as NSString).utf8String, -1, nil)
                    if sqlite3_step(stmt) != SQLITE_DONE {
                        print("❌ Cascade delete failed: \(String(cString: sqlite3_errmsg(db)))")
                    }
                } else {
                    print("❌ Prepare cascade delete failed: \(String(cString: sqlite3_errmsg(db)))")
                }
                sqlite3_finalize(stmt)
            }
            
            // 3) Finally delete home.
            let homeDelete = "DELETE FROM \(self.homeTable) WHERE homeServerId = ?;"
            var homeStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, homeDelete, -1, &homeStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(homeStmt, 1, (homeServerId as NSString).utf8String, -1, nil)
                if sqlite3_step(homeStmt) == SQLITE_DONE {
                    print("🗑️ Home cascade deleted successfully from local DB.")
                } else {
                    print("❌ Failed to delete home: \(String(cString: sqlite3_errmsg(db)))")
                }
            } else {
                print("❌ Error preparing home delete: \(String(cString: sqlite3_errmsg(db)))")
            }
            sqlite3_finalize(homeStmt)
        }
    }


    func updateRoom(
        roomId: String,
        newRoomName: String,
        newRoomIconId: String,
        newRoomIconType: String,
        tuyaRoomId: Int64?,   // ✅ ADD THIS
        homeId: String
    ) {
        
        let updateQuery = """
        UPDATE \(roomTable)
        SET roomName = ?, roomIconId = ?, roomIconType = ?, tuyaRoomId = ?
        WHERE roomId = ? AND homeId = ?;
        """
        
        var updateStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateQuery, -1, &updateStatement, nil) != SQLITE_OK {
            print("❌ Error preparing update:", String(cString: sqlite3_errmsg(db)))
            return
        }
        
        defer {
            sqlite3_finalize(updateStatement)
        }
        
        // MARK: - Bind values
        
        sqlite3_bind_text(updateStatement, 1, (newRoomName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateStatement, 2, (newRoomIconId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateStatement, 3, (newRoomIconType as NSString).utf8String, -1, nil)
        
        // 🔥 OPTIONAL tuyaRoomId handling
        if let tuyaRoomId = tuyaRoomId {
            sqlite3_bind_int64(updateStatement, 4, tuyaRoomId)
        } else {
            sqlite3_bind_null(updateStatement, 4)
        }
        
        sqlite3_bind_text(updateStatement, 5, (roomId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateStatement, 6, (homeId as NSString).utf8String, -1, nil)
        
        // MARK: - Execute
        
        if sqlite3_step(updateStatement) != SQLITE_DONE {
            print("❌ Error updating room:", String(cString: sqlite3_errmsg(db)))
        } else {
            print("✅ Room updated:",
                  "roomId:", roomId,
                  "| tuyaRoomId:", tuyaRoomId ?? -1)
        }
    }

    func deleteRoomFromLocal(roomId: String, homeId: String) {
        let deleteQuery = "DELETE FROM \(roomTable) WHERE roomId = ? AND homeId = ?;"
        
        var deleteStmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &deleteStmt, nil) != SQLITE_OK {
            print("❌ Error preparing delete: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        
        defer { sqlite3_finalize(deleteStmt) }
        
        sqlite3_bind_text(deleteStmt, 1, (roomId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(deleteStmt, 2, (homeId as NSString).utf8String, -1, nil)
        
        if sqlite3_step(deleteStmt) == SQLITE_DONE {
            print("🗑️ Room deleted from local DB successfully.")
        } else {
            print("❌ Error deleting from local DB: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    
    func insertRoomScene(roomId: String, sceneNo: String?, sceneName: String?, sceneIcon: String?) {
        let insertQuery = """
         INSERT OR REPLACE INTO \(roomSceneTable)(roomId, sceneNo, sceneName, sceneIcon) VALUES (?, ?, ?, ?);
        """

        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
            print("❌ Error preparing insert statement for roomScene: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        defer { sqlite3_finalize(insertStatement) }

        // Bind values (use "" if nil to avoid crash)
        sqlite3_bind_text(insertStatement, 1, (roomId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 2, ((sceneNo ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 3, ((sceneName ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 4, ((sceneIcon ?? "") as NSString).utf8String, -1, nil)

        if sqlite3_step(insertStatement) != SQLITE_DONE {
            print("❌ Error inserting roomScene: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✅ RoomScene inserted → roomId: \(roomId), sceneNo: \(sceneNo ?? "nil")")
        }
    }

    func deleteDevice(uniqueId: String) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }

            let queries = [
                "DELETE FROM \(self.deviceTable) WHERE unique_id = ?;",
                "DELETE FROM \(self.deviceState) WHERE unique_id = ?;",
                "DELETE FROM \(self.buttonsDetailsTable) WHERE unique_id = ?;",
                "DELETE FROM \(self.deviceSceneTable) WHERE unique_id = ?;",
                "DELETE FROM \(self.deviceSchdeuleTable) WHERE unique_id = ?;"
            ]

            for query in queries {
                var stmt: OpaquePointer?

                if sqlite3_prepare_v2(self.db, query, -1, &stmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(stmt, 1, (uniqueId as NSString).utf8String, -1, nil)

                    if sqlite3_step(stmt) == SQLITE_DONE {
                        print("✅ Deleted from table for unique_id: \(uniqueId)")
                    } else {
                        print("❌ Delete failed: \(String(cString: sqlite3_errmsg(self.db)))")
                    }
                }

                sqlite3_finalize(stmt)
            }
        }
    }
    
    func fetchRoomScenesByRoomId(roomId: String, completion: @escaping ([(sceneNo: String, sceneName: String, sceneIcon: String, roomId: String)]) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            var roomScenes = [(sceneNo: String, sceneName: String, sceneIcon: String, roomId: String)]()
            
            let query = "SELECT sceneNo, sceneName, sceneIcon, roomId FROM \(self.roomSceneTable) WHERE roomId = ?;"
            var queryStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, query, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(queryStatement, 1, (roomId as NSString).utf8String, -1, nil)
                
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let sceneNo = String(cString: sqlite3_column_text(queryStatement, 0))
                    let sceneName = String(cString: sqlite3_column_text(queryStatement, 1))
                    let sceneIcon = String(cString: sqlite3_column_text(queryStatement, 2))
                    let fetchedRoomId = String(cString: sqlite3_column_text(queryStatement, 3))
                    
                    let scene = (sceneNo, sceneName, sceneIcon, fetchedRoomId)
                    roomScenes.append(scene)
                    
                    // Debug print
                   // print("🎬 Fetched Scene - No: \(sceneNo), Name: \(sceneName), Icon: \(sceneIcon), RoomID: \(fetchedRoomId)")
                }
            } else {
                print("❌ Error preparing fetch statement for roomScene: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            
            sqlite3_finalize(queryStatement)
            
            DispatchQueue.main.async {
                completion(roomScenes)
            }
        }
    }

    
    
    func fetchDevicesByRoomIdSync(roomId: String) -> [Device] {

        var devices: [Device] = []

        let query = """
        SELECT deviceUid, roomId, homeId, userId, deviceName, unique_id, POP,
               deviceModelNo, deviceDimmingType, deviceType,
               connectedSsid, connectedPassword, deviceCategory
        FROM \(deviceTable)
        WHERE roomId = ?;
        """

        var queryStatement: OpaquePointer?

        // 🔥 IMPORTANT: run inside databaseQueue.sync
        databaseQueue.sync {

            if sqlite3_prepare_v2(self.db, query, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(queryStatement, 1, (roomId as NSString).utf8String, -1, nil)

                while sqlite3_step(queryStatement) == SQLITE_ROW {

                    let device = Device(
                        deviceUid: String(cString: sqlite3_column_text(queryStatement, 0)),
                        roomId: String(cString: sqlite3_column_text(queryStatement, 1)),
                        homeId: String(cString: sqlite3_column_text(queryStatement, 2)),
                        userId: String(cString: sqlite3_column_text(queryStatement, 3)),
                        deviceName: String(cString: sqlite3_column_text(queryStatement, 4)),
                        uniqueId: String(cString: sqlite3_column_text(queryStatement, 5)),
                        POP: String(cString: sqlite3_column_text(queryStatement, 6)),
                        deviceModelNo: String(cString: sqlite3_column_text(queryStatement, 7)),
                        deviceDimmingType: String(cString: sqlite3_column_text(queryStatement, 8)),
                        deviceType: String(cString: sqlite3_column_text(queryStatement, 9)),
                        connectedSsid: String(cString: sqlite3_column_text(queryStatement, 10)),
                        connectedPassword: String(cString: sqlite3_column_text(queryStatement, 11)),
                        deviceCategory: String(cString: sqlite3_column_text(queryStatement, 12))
                    )

                    devices.append(device)
                }
            } else {
                print("❌ Failed to prepare device fetch")
            }

            sqlite3_finalize(queryStatement)
        }

        return devices
    }
    func updateRoomScene(roomId: String, sceneNo: String, newName: String?, newIcon: String?) {
        let updateQuery = """
        UPDATE \(roomSceneTable)
        SET sceneName = ?, sceneIcon = ?
        WHERE roomId = ? AND sceneNo = ?;
        """

        var updateStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateQuery, -1, &updateStatement, nil) != SQLITE_OK {
            print("❌ Error preparing update statement for roomScene: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        defer { sqlite3_finalize(updateStatement) }

        // Bind values
        sqlite3_bind_text(updateStatement, 1, ((newName ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateStatement, 2, ((newIcon ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateStatement, 3, (roomId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateStatement, 4, (sceneNo as NSString).utf8String, -1, nil)

        if sqlite3_step(updateStatement) == SQLITE_DONE {
           // print("✅ RoomScene updated → roomId: \(roomId), sceneNo: \(sceneNo), newName: \(newName ?? "nil"), newIcon: \(newIcon ?? "nil")")
        } else {
            print("❌ Error updating roomScene: \(String(cString: sqlite3_errmsg(db)))")
        }
    }


    func insertDevice(deviceUid: String, roomId: String, homeId: String, userId: String, deviceName: String, uniqueId: String, POP: String, deviceModelNo: String, deviceDimmingType: String, deviceType: String, connectedSsid: String, connectedPassword: String, deviceCategory: String) {
            
        guard db != nil else {
            print("Database connection is nil.")
            return
        }
        
        let insertQuery = """
        INSERT INTO \(deviceTable) (deviceUid, roomId, homeId, userId, deviceName, unique_id, POP, deviceModelNo, deviceDimmingType, deviceType, connectedSsid, connectedPassword, deviceCategory) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
            print("Error preparing insert statement for device: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        defer {
            sqlite3_finalize(insertStatement)
        }

        // Bind parameters
        sqlite3_bind_text(insertStatement, 1, (deviceUid as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 2, (roomId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 3, (homeId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 4, (userId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 5, (deviceName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 6, (uniqueId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 7, (POP as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 8, (deviceModelNo as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 9, (deviceDimmingType as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 10, (deviceType as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 11, (connectedSsid as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 12, (connectedPassword as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 13, (deviceCategory as NSString).utf8String, -1, nil)

        if sqlite3_step(insertStatement) != SQLITE_DONE {
            print("Error inserting device data: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("Successfully inserted device with UID: \(uniqueId) \(roomId) homeId \(homeId)")
        }

    
       
    }

 
    
    func fetchDevicesByRoomId(roomId: String, completion: @escaping ([Device]) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            var devices: [Device] = []
            
            let query = """
            SELECT deviceUid, roomId, homeId, userId, deviceName, unique_id, POP,
                   deviceModelNo, deviceDimmingType, deviceType,
                   connectedSsid, connectedPassword, deviceCategory
            FROM \(self.deviceTable)
            WHERE roomId = ?;
            """
            
            var queryStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, query, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(queryStatement, 1, (roomId as NSString).utf8String, -1, nil)
                
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let device = Device(
                        deviceUid: String(cString: sqlite3_column_text(queryStatement, 0)),
                        roomId: String(cString: sqlite3_column_text(queryStatement, 1)),
                        homeId: String(cString: sqlite3_column_text(queryStatement, 2)),
                        userId: String(cString: sqlite3_column_text(queryStatement, 3)),
                        deviceName: String(cString: sqlite3_column_text(queryStatement, 4)),
                        uniqueId: String(cString: sqlite3_column_text(queryStatement, 5)),
                        POP: String(cString: sqlite3_column_text(queryStatement, 6)),
                        deviceModelNo: String(cString: sqlite3_column_text(queryStatement, 7)),
                        deviceDimmingType: String(cString: sqlite3_column_text(queryStatement, 8)),
                        deviceType: String(cString: sqlite3_column_text(queryStatement, 9)),
                        connectedSsid: String(cString: sqlite3_column_text(queryStatement, 10)),
                        connectedPassword: String(cString: sqlite3_column_text(queryStatement, 11)),
                        deviceCategory: String(cString: sqlite3_column_text(queryStatement, 12))
                    )
                    
                    devices.append(device)
                }
            } else {
                print("❌ Failed to prepare device fetch: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            
            sqlite3_finalize(queryStatement)
            
            DispatchQueue.main.async {
                completion(devices)
            }
        }
    }

    func fetchDevicesByHomeId(homeId: String, completion: @escaping ([Device]) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }

            var devices: [Device] = []

            let query = """
            SELECT deviceUid, roomId, homeId, userId, deviceName, unique_id, POP,
                   deviceModelNo, deviceDimmingType, deviceType,
                   connectedSsid, connectedPassword, deviceCategory
            FROM \(self.deviceTable)
            WHERE homeId = ?;
            """

            var queryStatement: OpaquePointer?

            if sqlite3_prepare_v2(self.db, query, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(queryStatement, 1, (homeId as NSString).utf8String, -1, nil)

                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let device = Device(
                        deviceUid: String(cString: sqlite3_column_text(queryStatement, 0)),
                        roomId: String(cString: sqlite3_column_text(queryStatement, 1)),
                        homeId: String(cString: sqlite3_column_text(queryStatement, 2)),
                        userId: String(cString: sqlite3_column_text(queryStatement, 3)),
                        deviceName: String(cString: sqlite3_column_text(queryStatement, 4)),
                        uniqueId: String(cString: sqlite3_column_text(queryStatement, 5)),
                        POP: String(cString: sqlite3_column_text(queryStatement, 6)),
                        deviceModelNo: String(cString: sqlite3_column_text(queryStatement, 7)),
                        deviceDimmingType: String(cString: sqlite3_column_text(queryStatement, 8)),
                        deviceType: String(cString: sqlite3_column_text(queryStatement, 9)),
                        connectedSsid: String(cString: sqlite3_column_text(queryStatement, 10)),
                        connectedPassword: String(cString: sqlite3_column_text(queryStatement, 11)),
                        deviceCategory: String(cString: sqlite3_column_text(queryStatement, 12))
                    )
                    
                    print("📦 Device fetched: \(device.deviceName), uniqueId: \(device.uniqueId)")
                    devices.append(device)
                }

            } else {
                print("❌ Failed to prepare device fetch: \(String(cString: sqlite3_errmsg(self.db)))")
            }

            sqlite3_finalize(queryStatement)

            DispatchQueue.main.async {
                completion(devices)
            }
        }
    }

    
    func fetchDevicesByUniqueId(uniqueId: String, completion: @escaping ([Device]) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }

            var devices: [Device] = []

            let query = """
            SELECT deviceUid, roomId, homeId, userId, deviceName, unique_id, POP,
                   deviceModelNo, deviceDimmingType, deviceType,
                   connectedSsid, connectedPassword, deviceCategory
            FROM \(self.deviceTable)
            WHERE uniqueId = ?;
            """

            var queryStatement: OpaquePointer?

            if sqlite3_prepare_v2(self.db, query, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(queryStatement, 1, (uniqueId as NSString).utf8String, -1, nil)

                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let device = Device(
                        deviceUid: String(cString: sqlite3_column_text(queryStatement, 0)),
                        roomId: String(cString: sqlite3_column_text(queryStatement, 1)),
                        homeId: String(cString: sqlite3_column_text(queryStatement, 2)),
                        userId: String(cString: sqlite3_column_text(queryStatement, 3)),
                        deviceName: String(cString: sqlite3_column_text(queryStatement, 4)),
                        uniqueId: String(cString: sqlite3_column_text(queryStatement, 5)),
                        POP: String(cString: sqlite3_column_text(queryStatement, 6)),
                        deviceModelNo: String(cString: sqlite3_column_text(queryStatement, 7)),
                        deviceDimmingType: String(cString: sqlite3_column_text(queryStatement, 8)),
                        deviceType: String(cString: sqlite3_column_text(queryStatement, 9)),
                        connectedSsid: String(cString: sqlite3_column_text(queryStatement, 10)),
                        connectedPassword: String(cString: sqlite3_column_text(queryStatement, 11)),
                        deviceCategory: String(cString: sqlite3_column_text(queryStatement, 12))
                    )
                    
                    print("📦 Device fetched: \(device.deviceName), uniqueId: \(device.uniqueId)")
                    devices.append(device)
                }

            } else {
                print("❌ Failed to prepare device fetch: \(String(cString: sqlite3_errmsg(self.db)))")
            }

            sqlite3_finalize(queryStatement)

            DispatchQueue.main.async {
                completion(devices)
            }
        }
    }

    

    func fetchDevicesforSiriByRoomId(roomId: String, completion: @escaping ([(deviceUid: String, deviceName: String, uniqueId: String, deviceModelNo: String, deviceType: String)]) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            var devices = [(deviceUid: String, deviceName: String, uniqueId: String, deviceModelNo: String, deviceType: String)]()
            
            let query = """
            SELECT deviceUid, deviceName, unique_id, deviceModelNo, deviceType
            FROM \(self.deviceTable)
            WHERE roomId = ?;
            """
            
            var queryStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, query, -1, &queryStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(queryStatement, 1, (roomId as NSString).utf8String, -1, nil)
                
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let deviceUid = String(cString: sqlite3_column_text(queryStatement, 0))
                    let deviceName = String(cString: sqlite3_column_text(queryStatement, 1))
                    let uniqueId = String(cString: sqlite3_column_text(queryStatement, 2))
                    let deviceModelNo = String(cString: sqlite3_column_text(queryStatement, 3))
                    let deviceType = String(cString: sqlite3_column_text(queryStatement, 4))
                    
                    let device = (deviceUid, deviceName, uniqueId, deviceModelNo, deviceType)
                    devices.append(device)
                    
//                    print("Fetched Device - UID: \(deviceUid), Name: \(deviceName), Unique ID: \(uniqueId), Model: \(deviceModelNo), Type: \(deviceType)")
                }
            } else {
                print("Error preparing fetch statement: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            
            sqlite3_finalize(queryStatement)
            
            DispatchQueue.main.async {
                completion(devices)
            }
        }
    }

    func insertDeviceState(
        deviceUid: String,
        deviceStateUid: String,
        uniqueId: String,
        working_mode: String,
        master: String,
        child_lock_f: String,
        child_lock_l: String,
        child_lock_m: String,
        config_buttons: String,
        config_dim: String,
        connectivity: String,
        dest_button: String,
        f_speed: String,
        f_state: String,
        fan_dest: String,
        l_speed: String,
        l_state: String,
        series: String?,
        ota_status: Int?,
        F_regulator: String?     // ✅ New string parameter
    ) {
        guard db != nil else {
            print("❌ Database connection is nil.")
            return
        }

        let insertQuery = """
        INSERT INTO \(deviceState) (
            deviceUid, deviceStateUid, unique_id, working_mode, master,
            child_lock_f, child_lock_l, child_lock_m,
            config_buttons, config_dim,
            connectivity, dest_button,
            f_speed, f_state, fan_dest,
            l_speed, l_state, series, ota_status, F_regulator
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
            print("❌ Error preparing insert: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        defer { sqlite3_finalize(insertStatement) }

        // ---- Bind Text Columns (1 to 17)
        sqlite3_bind_text(insertStatement, 1, (deviceUid as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 2, (deviceStateUid as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 3, (uniqueId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 4, (working_mode as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 5, (master as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 6, (child_lock_f as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 7, (child_lock_l as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 8, (child_lock_m as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 9, (config_buttons as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 10, (config_dim as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 11, (connectivity as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 12, (dest_button as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 13, (f_speed as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 14, (f_state as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 15, (fan_dest as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 16, (l_speed as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 17, (l_state as NSString).utf8String, -1, nil)

        // ---- Bind series (nullable TEXT) - index 18
        if let series = series {
            sqlite3_bind_text(insertStatement, 18, (series as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(insertStatement, 18)
        }

        // ---- Bind ota_status (nullable INTEGER) - index 19
        if let ota_status = ota_status {
            sqlite3_bind_int(insertStatement, 19, Int32(ota_status))
        } else {
            sqlite3_bind_null(insertStatement, 19)
        }

        // ---- Bind F_regulator (nullable TEXT) - index 20
        if let F_regulator = F_regulator {
            sqlite3_bind_text(insertStatement, 20, (F_regulator as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(insertStatement, 20)
        }

        // ---- Execute
        if sqlite3_step(insertStatement) == SQLITE_DONE {
            print("✅ Device state inserted successfully.")
        } else {
            print("❌ Insert failed: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    
    
    func fetchDeviceStatesByDeviceUid(deviceUid: String) -> [DeviceState] {

        let fetchQuery = "SELECT DISTINCT * FROM \(deviceState) WHERE deviceUid = ?;"
        var queryStatement: OpaquePointer?
        var deviceStates: [DeviceState] = []
        var seenDeviceStateUids: Set<String> = []

        if sqlite3_prepare_v2(db, fetchQuery, -1, &queryStatement, nil) == SQLITE_OK {

            sqlite3_bind_text(queryStatement, 1, (deviceUid as NSString).utf8String, -1, nil)

            while sqlite3_step(queryStatement) == SQLITE_ROW {

                let deviceStateUid = String(cString: sqlite3_column_text(queryStatement, 2))

                if !seenDeviceStateUids.contains(deviceStateUid) {

                    // --- Read all columns safely ---
                    let deviceUidVal = String(cString: sqlite3_column_text(queryStatement, 1))
                    let uniqueId = String(cString: sqlite3_column_text(queryStatement, 3))
                    let workingMode = String(cString: sqlite3_column_text(queryStatement, 4))
                    let master = String(cString: sqlite3_column_text(queryStatement, 5))
                    let childLockF = String(cString: sqlite3_column_text(queryStatement, 6))
                    let childLockL = String(cString: sqlite3_column_text(queryStatement, 7))
                    let childLockM = String(cString: sqlite3_column_text(queryStatement, 8))
                    let configButtons = String(cString: sqlite3_column_text(queryStatement, 9))
                    let configDim = String(cString: sqlite3_column_text(queryStatement, 10))
                    let connectivity = String(cString: sqlite3_column_text(queryStatement, 11))
                    let destButton = String(cString: sqlite3_column_text(queryStatement, 12))
                    let fSpeed = String(cString: sqlite3_column_text(queryStatement, 13))
                    let fState = String(cString: sqlite3_column_text(queryStatement, 14))
                    let fanDest = String(cString: sqlite3_column_text(queryStatement, 15))
                    let lSpeed = String(cString: sqlite3_column_text(queryStatement, 16))
                    let lState = String(cString: sqlite3_column_text(queryStatement, 17))

                    // series (column 18) — nullable TEXT
                    var series: String? = nil
                    if let cString = sqlite3_column_text(queryStatement, 18) {
                        series = String(cString: cString)
                    }

                    // ota_status (column 19) — nullable INT
                    var otaStatus: Int? = nil
                    if sqlite3_column_type(queryStatement, 19) != SQLITE_NULL {
                        otaStatus = Int(sqlite3_column_int(queryStatement, 19))
                    }

                    
                    var fRegulator: String? = nil
                    if let cString = sqlite3_column_text(queryStatement, 20) {
                        fRegulator = String(cString: cString)
                    }

                    // --- Create model object ---
                    let state = DeviceState(
                        deviceStateUid: deviceStateUid,
                        deviceUid: deviceUidVal,
                        uniqueId: uniqueId,
                        workingMode: workingMode,
                        master: master,
                        childLockF: childLockF,
                        childLockL: childLockL,
                        childLockM: childLockM,
                        configButtons: configButtons,
                        configDim: configDim,
                        connectivity: connectivity,
                        destButton: destButton,
                        fSpeed: fSpeed,
                        fState: fState,
                        fanDest: fanDest,
                        lSpeed: lSpeed,
                        lState: lState,
                        series: series,
                        otaStatus: otaStatus,
                        fRegulator: fRegulator
                    )

                    deviceStates.append(state)
                    seenDeviceStateUids.insert(deviceStateUid)
                }
            }
        } else {
            print("❌ Error preparing fetch: \(String(cString: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(queryStatement)
        return deviceStates
    }


    
    func fetchDeviceStateByUniqueId(uniqueId: String) -> DeviceState? {
        let normalizedId = uniqueId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        let fetchQuery = """
            SELECT * FROM \(deviceState)
            WHERE UPPER(TRIM(unique_id)) = ?;
        """
        
        var queryStatement: OpaquePointer?
        var fetchedState: DeviceState?

        if sqlite3_prepare_v2(db, fetchQuery, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (normalizedId as NSString).utf8String, -1, nil)
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {

                let deviceUid = String(cString: sqlite3_column_text(queryStatement, 1))
                let deviceStateUid = String(cString: sqlite3_column_text(queryStatement, 2))
                let unique_id = String(cString: sqlite3_column_text(queryStatement, 3))
                let working_mode = String(cString: sqlite3_column_text(queryStatement, 4))
                let master = String(cString: sqlite3_column_text(queryStatement, 5))
                let child_lock_f = String(cString: sqlite3_column_text(queryStatement, 6))
                let child_lock_l = String(cString: sqlite3_column_text(queryStatement, 7))
                let child_lock_m = String(cString: sqlite3_column_text(queryStatement, 8))
                let config_buttons = String(cString: sqlite3_column_text(queryStatement, 9))
                let config_dim = String(cString: sqlite3_column_text(queryStatement, 10))
                let connectivity = String(cString: sqlite3_column_text(queryStatement, 11))
                let dest_button = String(cString: sqlite3_column_text(queryStatement, 12))
                let f_speed = String(cString: sqlite3_column_text(queryStatement, 13))
                let f_state = String(cString: sqlite3_column_text(queryStatement, 14))
                let fan_dest = String(cString: sqlite3_column_text(queryStatement, 15))
                let l_speed = String(cString: sqlite3_column_text(queryStatement, 16))
                let l_state = String(cString: sqlite3_column_text(queryStatement, 17))
                
                var series: String? = nil
                if let cString = sqlite3_column_text(queryStatement, 18) {
                    series = String(cString: cString)
                }

                var ota_status: Int? = nil
                if sqlite3_column_type(queryStatement, 19) != SQLITE_NULL {
                    ota_status = Int(sqlite3_column_int(queryStatement, 19))
                }

                // ✅ Fetch F_regulator (column index 20)
                var fRegulator: String? = nil
                if let cString = sqlite3_column_text(queryStatement, 20) {
                    fRegulator = String(cString: cString)
                }

                fetchedState = DeviceState(
                    deviceStateUid: deviceStateUid,
                    deviceUid: deviceUid,
                    uniqueId: unique_id,
                    workingMode: working_mode,
                    master: master,
                    childLockF: child_lock_f,
                    childLockL: child_lock_l,
                    childLockM: child_lock_m,
                    configButtons: config_buttons,
                    configDim: config_dim,
                    connectivity: connectivity,
                    destButton: dest_button,
                    fSpeed: f_speed,
                    fState: f_state,
                    fanDest: fan_dest,
                    lSpeed: l_speed,
                    lState: l_state,
                    series: series,
                    otaStatus: ota_status,
                    fRegulator: fRegulator
                )
            } else {
                print("⚠️ No rows found for uniqueId: \(uniqueId)")
            }
        } else {
            print("❌ SQL Prepare Error: \(String(cString: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(queryStatement)
        return fetchedState
    }




    func insertScene(sceneId: String,
                     deviceUid: String,
                     homeId: String,
                     roomId: String,
                     uniqueId: String,
                     modelNo: String,
                     deviceType: String,
                     sceneNo: String,
                     sceneName: String,
                     destButton: String,
                     configButtons: String?,
                     configDim: String?,
                     LState: String,
                     LSpeed: String,
                     FState: String,
                     FSpeed: String,
                     fanDest: String,
                     LRedundant: String? = "NA",
                     FRedundant: String? = "NA") {

        guard db != nil else {
            print("Database connection is nil.")
            return
        }

        let insertQuery = """
        INSERT OR REPLACE INTO \(deviceSceneTable)
        (sceneId, deviceUid, homeId, roomId, unique_id, modelNo, deviceType, sceneNo, sceneName,
         dest_button, config_buttons, config_dim, L_state, L_speed, F_state, F_speed, fan_dest,
         L_redundant, F_redundant)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
            print("Error preparing insert statement for scene: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        defer { sqlite3_finalize(insertStatement) }

        sqlite3_bind_text(insertStatement, 1, (sceneId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 2, (deviceUid as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 3, (homeId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 4, (roomId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 5, (uniqueId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 6, (modelNo as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 7, (deviceType as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 8, (sceneNo as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 9, (sceneName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 10, (destButton as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 11, (configButtons as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 12, (configDim as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 13, (LState as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 14, (LSpeed as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 15, (FState as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 16, (FSpeed as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 17, (fanDest as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 18, (LRedundant as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 19, (FRedundant as NSString?)?.utf8String, -1, nil)

        if sqlite3_step(insertStatement) != SQLITE_DONE {
            print("Error inserting scene data: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✅ Successfully inserted scene: \(sceneName) — \(uniqueId) — \(sceneId) — SceneNo: \(sceneNo) -LRedundant\(LRedundant) - FRedundant \(FRedundant)")
        }
    }

    func fetchScenesByUniqueId(uniqueId: String) -> [DeviceScene] {
        let fetchQuery = """
        SELECT sceneId, deviceUid, homeId, roomId, unique_id, modelNo, deviceType,
               sceneNo, sceneName, dest_button, config_buttons, config_dim,
               L_state, L_speed, F_state, F_speed, fan_dest, L_redundant, F_redundant
        FROM \(deviceSceneTable)
        WHERE unique_id = ?;
        """

        var queryStatement: OpaquePointer?
        var scenes: [DeviceScene] = []

        guard let db = db else {
            print("❌ Database connection is nil.")
            return []
        }

        if sqlite3_prepare_v2(db, fetchQuery, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (uniqueId as NSString).utf8String, -1, nil)

            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let scene = DeviceScene(
                    sceneId: String(cString: sqlite3_column_text(queryStatement, 0)),
                    deviceUid: String(cString: sqlite3_column_text(queryStatement, 1)),
                    homeId: String(cString: sqlite3_column_text(queryStatement, 2)),
                    roomId: String(cString: sqlite3_column_text(queryStatement, 3)),
                    uniqueId: String(cString: sqlite3_column_text(queryStatement, 4)),
                    modelNo: String(cString: sqlite3_column_text(queryStatement, 5)),
                    deviceType: String(cString: sqlite3_column_text(queryStatement, 6)),
                    sceneNo: String(cString: sqlite3_column_text(queryStatement, 7)),
                    sceneName: String(cString: sqlite3_column_text(queryStatement, 8)),
                    destButton: String(cString: sqlite3_column_text(queryStatement, 9)),
                    configButtons: sqlite3_column_text(queryStatement, 10) != nil ? String(cString: sqlite3_column_text(queryStatement, 10)) : nil,
                    configDim: sqlite3_column_text(queryStatement, 11) != nil ? String(cString: sqlite3_column_text(queryStatement, 11)) : nil,
                    LState: String(cString: sqlite3_column_text(queryStatement, 12)),
                    LSpeed: String(cString: sqlite3_column_text(queryStatement, 13)),
                    FState: String(cString: sqlite3_column_text(queryStatement, 14)),
                    FSpeed: String(cString: sqlite3_column_text(queryStatement, 15)),
                    fanDest: String(cString: sqlite3_column_text(queryStatement, 16)),
                    LRedundant: sqlite3_column_text(queryStatement, 17) != nil ? String(cString: sqlite3_column_text(queryStatement, 17)) : "NA",
                    FRedundant: sqlite3_column_text(queryStatement, 18) != nil ? String(cString: sqlite3_column_text(queryStatement, 18)) : "NA"
                )
                scenes.append(scene)
            }
        } else {
            print("❌ Error preparing fetch statement: \(String(cString: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(queryStatement)
        return scenes
    }

    // Update by sceneId (updates ALL columns)
    func updateScene(sceneId: String,
                     deviceUid: String,
                     homeId: String,
                     roomId: String,
                     uniqueId: String,
                     modelNo: String,
                     deviceType: String,
                     sceneNo: String,
                     sceneName: String,
                     destButton: String,
                     configButtons: String?,
                     configDim: String?,
                     LState: String,
                     LSpeed: String,
                     FState: String,
                     FSpeed: String,
                     fanDest: String,
                     LRedundant: String? = "NA",
                     FRedundant: String? = "NA") {
        guard let db = db else { print("❌ Database connection is nil."); return }

        let sql = """
        UPDATE \(deviceSceneTable)
           SET deviceUid      = ?,
               homeId         = ?,
               roomId         = ?,
               unique_id      = ?,
               modelNo        = ?,
               deviceType     = ?,
               sceneNo        = ?,
               sceneName      = ?,
               dest_button    = ?,
               config_buttons = ?,
               config_dim     = ?,
               L_state        = ?,
               L_speed        = ?,
               F_state        = ?,
               F_speed        = ?,
               fan_dest       = ?,
               L_redundant    = ?,
               F_redundant    = ?
         WHERE sceneId        = ?;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            print("❌ Prepare failed: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt,  1, (deviceUid as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt,  2, (homeId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt,  3, (roomId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt,  4, (uniqueId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt,  5, (modelNo as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt,  6, (deviceType as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt,  7, (sceneNo as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt,  8, (sceneName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt,  9, (destButton as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 10, (configButtons as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(stmt, 11, (configDim as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(stmt, 12, (LState as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 13, (LSpeed as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 14, (FState as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 15, (FSpeed as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 16, (fanDest as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 17, (LRedundant as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(stmt, 18, (FRedundant as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(stmt, 19, (sceneId as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) == SQLITE_DONE {
            print("✅ Scene updated (sceneId=\(sceneId)) — LRedundant=\(LRedundant ?? "NA"), FRedundant=\(FRedundant ?? "NA")")
        } else {
            print("❌ Update failed: \(String(cString: sqlite3_errmsg(db)))")
        }
    }


    func insertSchedule(scheduleId: String, scheduleNumber: String, deviceUid: String, uniqueId: String, date: String, time: String, weekSchedule: String, LState: String, LSpeed: String, FState: String, FSpeed: String, configButtons: String?, destButton: String, fanDest: String, master: String?, modelNo: String?, sceneId: String?) {
        
        guard db != nil else {
            print("Database connection is nil. Cannot insert schedule.")
            return
        }

        let checkQuery = "SELECT COUNT(*) FROM \(deviceSchdeuleTable) WHERE scheduleId = ?"
        var checkStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, checkQuery, -1, &checkStatement, nil) != SQLITE_OK {
            print("Error preparing check statement: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        sqlite3_bind_text(checkStatement, 1, (scheduleId as NSString).utf8String, -1, nil)

        if sqlite3_step(checkStatement) == SQLITE_ROW {
            let count = sqlite3_column_int(checkStatement, 0)
            if count > 0 {
                print("Schedule with scheduleId \(scheduleId) already exists.")
                sqlite3_finalize(checkStatement)
                return
            }
        }

        sqlite3_finalize(checkStatement)

        let insertQuery = """
        INSERT OR REPLACE INTO \(deviceSchdeuleTable) (scheduleId, scheduleNumber, deviceUid, unique_id, date, time, week_schedule, L_state, L_speed, F_state, F_speed, config_buttons, dest_button, fan_dest, master, modelNo, sceneId)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        print("Preparing to insert schedule: \(scheduleId)")

        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
            print("Error preparing insert statement: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        defer {
            sqlite3_finalize(insertStatement)
        }

        sqlite3_bind_text(insertStatement, 1, (scheduleId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 2, (scheduleNumber as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 3, (deviceUid as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 4, (uniqueId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 5, (date as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 6, (time as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 7, (weekSchedule as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 8, (LState as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 9, (LSpeed as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 10, (FState as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 11, (FSpeed as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 12, (configButtons as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 13, (destButton as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 14, (fanDest as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 15, (master as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 16, (modelNo as NSString?)?.utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 17, (sceneId as NSString?)?.utf8String, -1, nil)

        print("Executing insert statement...")

        if sqlite3_step(insertStatement) != SQLITE_DONE {
            print("Error inserting schedule data: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("Successfully inserted schedule: \(scheduleId) for device: \(scheduleNumber) unqiueId:\(uniqueId) schdeule number\(scheduleNumber)")
        }
    }


    func fetchSchedulesByDeviceUid(deviceUid: String) -> [Schedule] {
        var schedules: [Schedule] = []
        let fetchQuery = """
            SELECT scheduleId, scheduleNumber, deviceUid, unique_id, date, time,
                   week_schedule, L_state, L_speed, F_state, F_speed,
                   config_buttons, dest_button, fan_dest, master, modelNo, sceneId
            FROM \(deviceSchdeuleTable)
            WHERE deviceUid = ?;
        """

        var queryStatement: OpaquePointer?
       

        guard let db = db else {
            print("Database connection is nil.")
            return []
        }

        if sqlite3_prepare_v2(db, fetchQuery, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (deviceUid as NSString).utf8String, -1, nil)
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let schedule = Schedule(
                    scheduleId: sqlite3_column_text(queryStatement, 0).flatMap { String(cString: $0) } ?? "",
                    scheduleNumber: sqlite3_column_text(queryStatement, 1).flatMap { String(cString: $0) } ?? "",
                    deviceUid: sqlite3_column_text(queryStatement, 2).flatMap { String(cString: $0) } ?? "",
                    uniqueId: sqlite3_column_text(queryStatement, 3).flatMap { String(cString: $0) } ?? "",
                    date: sqlite3_column_text(queryStatement, 4).flatMap { String(cString: $0) } ?? "",
                    time: sqlite3_column_text(queryStatement, 5).flatMap { String(cString: $0) } ?? "",   // ✅ Fixed missing time
                    weekSchedule: sqlite3_column_text(queryStatement, 6).flatMap { String(cString: $0) } ?? "", // ✅ Fixed missing weekSchedule
                    LState: sqlite3_column_text(queryStatement, 7).flatMap { String(cString: $0) } ?? "",
                    LSpeed: sqlite3_column_text(queryStatement, 8).flatMap { String(cString: $0) } ?? "",
                    FState: sqlite3_column_text(queryStatement, 9).flatMap { String(cString: $0) } ?? "",
                    FSpeed: sqlite3_column_text(queryStatement, 10).flatMap { String(cString: $0) } ?? "",
                    configButtons: sqlite3_column_text(queryStatement, 11).flatMap { String(cString: $0) } ?? "",
                    destButton: sqlite3_column_text(queryStatement, 12).flatMap { String(cString: $0) } ?? "",
                    fanDest: sqlite3_column_text(queryStatement, 13).flatMap { String(cString: $0) } ?? "",
                    master: sqlite3_column_text(queryStatement, 14).flatMap { String(cString: $0) } ?? "",
                    modelNo: sqlite3_column_text(queryStatement, 15).flatMap { String(cString: $0) } ?? "",
                    sceneId: sqlite3_column_text(queryStatement, 16).flatMap { String(cString: $0) } ?? ""
                )
                schedules.append(schedule)
                print("📅 Schedule Number: \(schedule.scheduleNumber)  \(schedule.uniqueId)  ")
                 
            }

            sqlite3_finalize(queryStatement)
        } else {
            print("❌ Error preparing fetch statement: \(String(cString: sqlite3_errmsg(db)))")
        }

        return schedules
    }

    
   
    
    

    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
            print("Database closed.")
        }
    }
    
    func insertButtonDetails(
        buttonId: String?,
        buttonControlName: String?,
        buttonIconId: Int?,
        buttonName: String?,
        buttonNo: Int?,
        deviceServerId: String?,
        deviceUid: String?,
        power: Int?,
        roomName: String?,
        switchName: String?,
        uniqueId: String?,
        isShortcut: Int?,
        buttonIconName: String?,
        buttonIconColor: String?,
        isFavourite: Int?,
        isHomeFav: Int?
    ) {
        guard let db = db else {
            print("❌ Database connection is nil.")
            return
        }

        let insertQuery = """
        INSERT OR REPLACE INTO \(buttonsDetailsTable)
        (buttonId, buttonControlName, buttonIconId, buttonName, buttonNo, deviceServerId, deviceUid, power, roomName, switchName, unique_id, isShortcut, buttonIconName, buttonIconColor, isFavourite, isHomeFav)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
            print("❌ Error preparing insert statement for button details: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        defer {
            sqlite3_finalize(insertStatement)
        }

        // Safe default values
        let safeButtonId = buttonId ?? "N/A"
        let safeButtonControlName = buttonControlName ?? "Unknown"
        let safeButtonIconId = buttonIconId ?? 0
        let safeButtonName = buttonName ?? "Unnamed"
        let safeButtonNo = buttonNo ?? 0
        let safeDeviceServerId = deviceServerId ?? "Unknown"
        let safeDeviceUid = deviceUid ?? "Unknown"
        let safePower = power ?? 0
        let safeRoomName = roomName ?? "Unknown"
        let safeSwitchName = switchName ?? "Unknown"
        let safeUniqueId = uniqueId ?? "Unknown"
        let safeIsShortcut = isShortcut ?? 0
        let safeButtonIconName = buttonIconName ?? "Unknown"
        let safeButtonIconColor = buttonIconColor ?? "Unknown"
        let safeIsFavourite = isFavourite ?? 0
        let safeIsHomeFav = isHomeFav ?? 0  // ✅ default to 0

        // Bind values
        sqlite3_bind_text(insertStatement, 1, (safeButtonId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 2, (safeButtonControlName as NSString).utf8String, -1, nil)
        sqlite3_bind_int(insertStatement, 3, Int32(safeButtonIconId))
        sqlite3_bind_text(insertStatement, 4, (safeButtonName as NSString).utf8String, -1, nil)
        sqlite3_bind_int(insertStatement, 5, Int32(safeButtonNo))
        sqlite3_bind_text(insertStatement, 6, (safeDeviceServerId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 7, (safeDeviceUid as NSString).utf8String, -1, nil)
        sqlite3_bind_int(insertStatement, 8, Int32(safePower))
        sqlite3_bind_text(insertStatement, 9, (safeRoomName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 10, (safeSwitchName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 11, (safeUniqueId as NSString).utf8String, -1, nil)
        sqlite3_bind_int(insertStatement, 12, Int32(safeIsShortcut))
        sqlite3_bind_text(insertStatement, 13, (safeButtonIconName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 14, (safeButtonIconColor as NSString).utf8String, -1, nil)
        sqlite3_bind_int(insertStatement, 15, Int32(safeIsFavourite))
        sqlite3_bind_int(insertStatement, 16, Int32(safeIsHomeFav)) // ✅ bind isHomeFav

        if sqlite3_step(insertStatement) != SQLITE_DONE {
            print("❌ Error inserting button details: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✅ Successfully inserted button details with ID: \(safeUniqueId) for buttonId: \(safeButtonId)")
        }
    }

    func fetchButtonDetails(uniqueId: String) -> [ButtonDetails] {
        var buttonDetailsList: [ButtonDetails] = []

        guard let db = db else {
            print("❌ Database connection is nil.")
            return []
        }

        let fetchQuery = """
            SELECT buttonId, buttonControlName, buttonIconId, buttonName, buttonNo,
                   deviceServerId, deviceUid, power, roomName, switchName,
                   unique_id, isShortcut, buttonIconName, buttonIconColor, isFavourite, isHomeFav
            FROM \(buttonsDetailsTable)
            WHERE unique_id = ?;
        """

        var fetchStatement: OpaquePointer?

        guard sqlite3_prepare_v2(db, fetchQuery, -1, &fetchStatement, nil) == SQLITE_OK else {
            print("❌ Error preparing fetch statement: \(String(cString: sqlite3_errmsg(db)))")
            return []
        }

        defer { sqlite3_finalize(fetchStatement) }

        sqlite3_bind_text(fetchStatement, 1, (uniqueId as NSString).utf8String, -1, nil)

        while sqlite3_step(fetchStatement) == SQLITE_ROW {
            let buttonDetails = ButtonDetails(
                buttonId: String(cString: sqlite3_column_text(fetchStatement, 0)),
                buttonControlName: String(cString: sqlite3_column_text(fetchStatement, 1)),
                buttonIconId: Int(sqlite3_column_int(fetchStatement, 2)),
                buttonName: String(cString: sqlite3_column_text(fetchStatement, 3)),
                buttonNo: Int(sqlite3_column_int(fetchStatement, 4)),
                deviceServerId: String(cString: sqlite3_column_text(fetchStatement, 5)),
                deviceUid: String(cString: sqlite3_column_text(fetchStatement, 6)),
                power: Int(sqlite3_column_int(fetchStatement, 7)),
                roomName: String(cString: sqlite3_column_text(fetchStatement, 8)),
                switchName: String(cString: sqlite3_column_text(fetchStatement, 9)),
                uniqueId: String(cString: sqlite3_column_text(fetchStatement, 10)),
                isShortcut: Int(sqlite3_column_int(fetchStatement, 11)),
                buttonIconName: String(cString: sqlite3_column_text(fetchStatement, 12)),
                buttonIconColor: String(cString: sqlite3_column_text(fetchStatement, 13)),
                isFavourite: Int(sqlite3_column_int(fetchStatement, 14)),
                isHomeFav: Int(sqlite3_column_int(fetchStatement, 15))
            )

            print("✅ Fetched button details: \(buttonDetails)")
            buttonDetailsList.append(buttonDetails)
        }

        if buttonDetailsList.isEmpty {
            print("⚠️ No button details found for uniqueId: \(uniqueId)")
        }

        return buttonDetailsList
    }

    
    func updateButtonDetails(
        buttonId: String,
        buttonName: String,
        power: Int,
        buttonIconName: String,
        isFavourite: Int
    ) {
        guard let db = db else {
            print("❌ Database connection is nil.")
            return
        }

        let updateQuery = """
            UPDATE \(buttonsDetailsTable)
            SET buttonName = ?,
                power = ?,
                buttonIconName = ?,
                isFavourite = ?
            WHERE buttonId = ?;
        """

        var updateStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, updateQuery, -1, &updateStatement, nil) == SQLITE_OK {

            sqlite3_bind_text(updateStatement, 1, (buttonName as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 2, Int32(power))
            sqlite3_bind_text(updateStatement, 3, (buttonIconName as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 4, Int32(isFavourite))
            sqlite3_bind_text(updateStatement, 5, (buttonId as NSString).utf8String, -1, nil)

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("✅ Button details updated locally for buttonId: \(buttonId)")
            } else {
                print("❌ Failed to update button: \(String(cString: sqlite3_errmsg(db)))")
            }
        }

        sqlite3_finalize(updateStatement)
    }
    func updateIsFavourite(buttonId: String, isFavourite: Int) {
        guard let db = db else {
            print("❌ Database connection is nil.")
            return
        }

        let updateQuery = """
            UPDATE \(buttonsDetailsTable)
            SET isFavourite = ?
            WHERE buttonId = ?;
        """

        var updateStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, updateQuery, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(updateStatement, 1, Int32(isFavourite))
            sqlite3_bind_text(updateStatement, 2, (buttonId as NSString).utf8String, -1, nil)

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("✅ Successfully updated isFavourite to \(isFavourite) for buttonId: \(buttonId)")
            } else {
                print("❌ Failed to update isFavourite: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("❌ Error preparing update statement: \(String(cString: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(updateStatement)
    }

    /// Updates home-shortcut flag for a button (matches `deviceServerId` from API `manageHomeFav`).
    func updateIsHomeFav(deviceServerId: String, isHomeFav: Int) {
        guard let db = db else {
            print("❌ Database connection is nil.")
            return
        }

        let updateQuery = """
            UPDATE \(buttonsDetailsTable)
            SET isHomeFav = ?
            WHERE deviceServerId = ?;
        """

        var updateStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, updateQuery, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(updateStatement, 1, Int32(isHomeFav))
            sqlite3_bind_text(updateStatement, 2, (deviceServerId as NSString).utf8String, -1, nil)

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("✅ isHomeFav=\(isHomeFav) for deviceServerId=\(deviceServerId)")
            } else {
                print("❌ Failed to update isHomeFav: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("❌ Error preparing isHomeFav update: \(String(cString: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(updateStatement)
    }


    
    func updateShortcutFlag(buttonId: String, isShortcut: Int) {
        guard let db = db else {
            print("❌ Database connection is nil.")
            return
        }

        let updateQuery = """
        UPDATE \(buttonsDetailsTable)
        SET isShortcut = ?
        WHERE buttonId = ?;
        """

        var updateStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, updateQuery, -1, &updateStatement, nil) != SQLITE_OK {
            print("❌ Error preparing update statement: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        defer {
            sqlite3_finalize(updateStatement)
        }

        sqlite3_bind_int(updateStatement, 1, Int32(isShortcut))
        sqlite3_bind_text(updateStatement, 2, (buttonId as NSString).utf8String, -1, nil)

        if sqlite3_step(updateStatement) != SQLITE_DONE {
            print("❌ Failed to update isShortcut for buttonId \(buttonId): \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✅ isShortcut updated for buttonId: \(buttonId) to \(isShortcut)")
        }
    }

    
    
    
    
    func fetchButtonSiriDetails(uniqueId: String) -> [(buttonId: String, buttonControlName: String, buttonIconId: Int, buttonName: String, buttonNo: Int, deviceServerId: String, deviceUid: String, power: Int, roomName: String, switchName: String, uniqueId: String)] {
        var buttonDetailsList: [(buttonId: String, buttonControlName: String, buttonIconId: Int, buttonName: String, buttonNo: Int, deviceServerId: String, deviceUid: String, power: Int, roomName: String, switchName: String, uniqueId: String)] = []

        guard let db = db else {
            print("❌ Database connection is nil.")
            return []
        }

        let fetchQuery = """
            SELECT buttonId, buttonControlName, buttonIconId, buttonName, buttonNo,
                   deviceServerId, deviceUid, power, roomName, switchName, unique_id
            FROM \(buttonsDetailsTable)
            WHERE unique_id = ?;
        """

        var fetchStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, fetchQuery, -1, &fetchStatement, nil) != SQLITE_OK {
            print("❌ Error preparing fetch statement: \(String(cString: sqlite3_errmsg(db)))")
            return []
        }

        defer {
            sqlite3_finalize(fetchStatement)
        }

        // Bind `uniqueId` to the query
        sqlite3_bind_text(fetchStatement, 1, (uniqueId as NSString).utf8String, -1, nil)

        print("🔍 Fetching button details for uniqueId: \(uniqueId)")

        while sqlite3_step(fetchStatement) == SQLITE_ROW {
            let buttonId = String(cString: sqlite3_column_text(fetchStatement, 0))
            let buttonControlName = String(cString: sqlite3_column_text(fetchStatement, 1))
            let buttonIconId = Int(sqlite3_column_int(fetchStatement, 2))
            let buttonName = String(cString: sqlite3_column_text(fetchStatement, 3))
            let buttonNo = Int(sqlite3_column_int(fetchStatement, 4))
            let deviceServerId = String(cString: sqlite3_column_text(fetchStatement, 5))
            let deviceUid = String(cString: sqlite3_column_text(fetchStatement, 6))
            let power = Int(sqlite3_column_int(fetchStatement, 7))
            let roomName = String(cString: sqlite3_column_text(fetchStatement, 8))
            let switchName = String(cString: sqlite3_column_text(fetchStatement, 9))
            let uniqueId = String(cString: sqlite3_column_text(fetchStatement, 10))

            // Append the details as a tuple
            buttonDetailsList.append((buttonId, buttonControlName, buttonIconId, buttonName, buttonNo, deviceServerId, deviceUid, power, roomName, switchName, uniqueId))
        }

        if buttonDetailsList.isEmpty {
            print("⚠️ No button details found for uniqueId: \(uniqueId)")
        }

        return buttonDetailsList
    }

    func printHomeTableSchema() {
        let query = "PRAGMA table_info(home);"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            print("📌 HOME TABLE SCHEMA:")
            while sqlite3_step(stmt) == SQLITE_ROW {
                let cid = sqlite3_column_int(stmt, 0)
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let type = String(cString: sqlite3_column_text(stmt, 2))
                print("Column \(cid): \(name) (\(type))")
            }
        }
        sqlite3_finalize(stmt)
    }

    
    func deleteDatabase() {
        // 1️⃣ Close DB if open
        closeDatabase()
        
        // 2️⃣ Path to your database file
        let fileURL = try! FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("skroman.sqlite") // your DB name

        // 3️⃣ Check if the file exists and remove it
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("✅ Database deleted successfully.")
            } catch {
                print("❌ Error deleting database: \(error)")
            }
        } else {
            print("⚠️ Database file does not exist.")
        }
    }


    
    func deleteAllTablesData(completion: @escaping (Bool) -> Void) {
        let tables = [userTable, homeTable, roomTable, deviceTable, deviceState, deviceSceneTable, deviceSchdeuleTable, buttonsDetailsTable]
        let group = DispatchGroup()
        var success = true

        databaseQueue.async { [weak self] in
            guard let self = self, self.db != nil else {
                completion(false)
                return
            }

            for tableName in tables {
                group.enter()
                let deleteQuery = "DELETE FROM \(tableName);"
                var deleteStatement: OpaquePointer?

                if sqlite3_prepare_v2(self.db, deleteQuery, -1, &deleteStatement, nil) == SQLITE_OK {
                    if sqlite3_step(deleteStatement) != SQLITE_DONE {
                        print("Error deleting data from \(tableName): \(String(cString: sqlite3_errmsg(self.db)))")
                        success = false
                    }
                } else {
                    print("Error preparing delete statement for \(tableName): \(String(cString: sqlite3_errmsg(self.db)))")
                    success = false
                }

                sqlite3_finalize(deleteStatement)
                group.leave()
            }

            group.notify(queue: DispatchQueue.main) {
                completion(success)
            }
        }
    }




}



struct TuyaDeviceModel {
    let tuyaHomeId: Int64
    let tuyaRoomId: Int64
    let deviceId: String
    let deviceName: String
    let deviceCategory: String
}
