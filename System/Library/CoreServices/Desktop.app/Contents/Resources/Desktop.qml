import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SwiftDE 1.0

Window {
    id: desktopWindow
    visible: false
    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    color: "black"
    flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

    SysProc {
        id: sysProc
    }

    FontLoader {
        id: sfMedium
        source: "../../../../../../Library/Fonts/SF-Pro-Text-Medium.otf"
    }

    FontLoader {
        id: sfSymbols
        source: "Fonts/SF-Symbols-6.otf"
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: sysProc.wallpaperUrl.length > 0 ? sysProc.wallpaperUrl : "../../../../../../Library/DesktopPictures/Wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    property bool contextMenuOpen: false
    property real contextMenuX: 350
    property real contextMenuY: 140

    readonly property var contextMenuItems: [
        { title: "New Folder", action: "new_folder" },
        { separator: true },
        { title: "Get Info", action: "get_info" },
        { title: "Change Wallpaper...", action: "wallpaper" },
        { title: "Edit Widgets...", action: "edit_widgets" },
        { separator: true },
        { title: "Use Stacks", action: "use_stacks" },
        { title: "Sort By", hasSubmenu: true, action: "sort_by" },
        { title: "Clean Up", action: "clean_up" },
        { title: "Clean Up By", hasSubmenu: true, action: "clean_up_by" },
        { title: "Show View Options", action: "view_options" },
        { separator: true },
        { title: "Import from iPhone", hasSubmenu: true, action: "import_iphone" }
    ]

    function handleMenuAction(action) {
        contextMenuOpen = false
        if (action === "new_folder") {
            sysProc.launch("mkdir -p ~/Desktop/'New Folder' || true")
        } else if (action === "wallpaper") {
            sysProc.launch("gnome-control-center background || gnome-control-center || true")
        } else if (action === "get_info") {
            sysProc.launchAboutThisMac()
        }
    }

    MouseArea {
        id: desktopClickArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                sysProc.showDesktopContextMenu(mouse.x, mouse.y)
            } else {
                sysProc.unfocusAll()
            }
        }
    }
}
