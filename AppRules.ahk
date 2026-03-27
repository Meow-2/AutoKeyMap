isRAltOccupiedApp() {
    try {
        process_name := StrLower(WinGetProcessName("A"))
        for app in RAltOccupiedApps {
            if (process_name = StrLower(app))
                return True
        }
        return False
    }
    catch {
        return False
    }
}
