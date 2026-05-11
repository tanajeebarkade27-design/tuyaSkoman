//
//  Colorconstant.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/25.
//





import UIKit

//UICOLOR FOR SKORMAN
let UICOLOR_WHITE = UIColor.white
let UICOLOR_CONTAINER_BG = UIColor(netHex: 0x2C2E3F)
let UICOLOR_MAIN_BG = UIColor(netHex: 0x1A1C2A)
let UICOLOR_SEPRATOR = UIColor(netHex: 0x3B3E4F)
let UICOLOR_RED = UIColor(netHex: 0xC34E4E)
let UICOLOR_BLUE = UIColor(netHex: 0x4060FA)
let UICOLOR_NAVIGATION_BAR = UIColor(netHex: 0x2C2E3F)
let UICOLOR_TEXTFIELD_CONTAINER_BORDER = UIColor(netHex: 0x383A4B)
let UICOLOR_TEXTFIELD_CONTAINER_BG = UIColor(netHex: 0x2D3042)
let UICOLOR_SELECTEDORON_BG = UIColor(netHex: 0xFFD166)
let UICOLOR_SWIPECELL_EDIT = UIColor(netHex: 0x06D6A0)
let UICOLOR_SWIPECELL_DELETE = UIColor(netHex: 0xF15151)
let UICOLOR_ODD_CELL_BG = UIColor(netHex: 0x383A4D)
let UICOLOR_CAPSMENU_SELECTED_LINE = UIColor(netHex: 0x4060FA)
let UICOLOR_ADD_MOOD_BG = UIColor(netHex: 0x616375)
let UICOLOR_ADDED_MOOD_CLR = UIColor(netHex: 0x2DCCED)
let UICOLOR_ROOM_CELL_BG = UIColor(netHex: 0x0B0C13)
let UICOLOR_ROOM_CELL_SEPRATOR = UIColor(netHex: 0x36394C)
let UICOLOR_TXTFIELD_BORDER_COLOR = UIColor(netHex: 0x898A93)
let UICOLOR_SWITCH_BORDER_COLOR_UNSELECTED = UIColor(netHex: 0x383B51)
let UICOLOR_SWITCH_BORDER_COLOR_BLUE = UIColor(netHex: 0x06B2D6)
let UICOLOR_SWITCH_BORDER_COLOR_YELLOW = UIColor(netHex: 0xFFD166)
let UICOLOR_MOODS_BUTTON_BG = UIColor(netHex: 0xA554FE)
let UICOLOR_POPUP_BORDER = UIColor(netHex: 0x8B9298)
let UICOLOR_CHANGE_PW_TEXT = UIColor(netHex: 0xE4BC5E)
let UICOLOR_DEVICE_MOOD_TABLE_BORDER = UIColor(netHex: 0xB5BBC3)
let UICOLOR_PINK = UIColor(netHex: 0xFF4081)
let UICOLOR_IPAD_HOME_BG = UIColor(netHex : 0x1A1C2A)

class ColorConstants: NSObject {

}



extension UIColor {
    
    convenience init(reds: Int, green: Int, blue: Int) {
        
        assert(reds >= 0 && reds <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(reds) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(reds:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

