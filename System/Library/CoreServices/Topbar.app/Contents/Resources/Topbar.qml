import QtQuick
import QtQuick.Window
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import SwiftDE 1.0

Window {
    id: topbarWindow
    visible: false
    width: Screen.width > 0 ? Screen.width : 1920
    height: (activeMenu !== "" || controlCenterOpen || desktopContextMenuOpen) ? (Screen.height > 0 ? Screen.height : 1080) : 25
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

    SysProc {
        id: sysProc
    }

    Connections {
        target: sysProc
        function onDesktopContextMenuRequested(x, y) {
            topbarWindow.desktopContextMenuX = Math.max(10, Math.min(x, topbarWindow.width - 228 - 10))
            topbarWindow.desktopContextMenuY = Math.max(28, Math.min(y, (Screen.height > 0 ? Screen.height : 1080) - 270))
            topbarWindow.activeMenu = ""
            topbarWindow.controlCenterOpen = false
            topbarWindow.desktopContextMenuOpen = true
        }
    }

    FontLoader {
        id: sfBold
        source: "../../../../../../Library/Fonts/SF-Pro-Text-Bold.otf"
    }

    FontLoader {
        id: sfMedium
        source: "../../../../../../Library/Fonts/SF-Pro-Text-Medium.otf"
    }

    FontLoader {
        id: sfSymbols
        source: "Fonts/SF-Symbols-6.otf"
    }

    // Desktop Context Menu properties (rendered on LayerTop to always stay on top of all windows)
    property bool desktopContextMenuOpen: false
    property real desktopContextMenuX: 100
    property real desktopContextMenuY: 100

    readonly property var desktopContextMenuItems: [
        { title: "New Folder", action: "new_folder" },
        { separator: true },
        { title: "Get Info", action: "get_info" },
        { title: "Change Wallpaper...", action: "wallpaper" },
        { title: "Edit Widgets...", action: "edit_widgets" },
        { separator: true },
        { title: "Use Stacks", action: "use_stacks" },
        { title: "Sort By", hasSubmenu: true, action: "sort_by" },
        { title: "Show View Options", action: "view_options" }
    ]

    function handleDesktopMenuAction(action) {
        topbarWindow.desktopContextMenuOpen = false
        if (!action) return
        if (action === "new_folder") {
            sysProc.sendKey("-M ctrl -M shift n -m shift -m ctrl")
        } else if (action === "wallpaper") {
            sysProc.launch("gnome-control-center background || gnome-control-center || true")
        } else if (action === "get_info") {
            sysProc.sendKey("-M ctrl i -m ctrl")
        }
    }

    // Active dropdown menu tracker: "" (none), "apple", "app", or menu name ("File", "Edit", etc.)
    property string activeMenu: ""
    onActiveMenuChanged: console.log("TOPBAR ACTIVE_MENU:", activeMenu, "activeMenuX:", activeMenuX)
    property real activeMenuX: 10
    property bool controlCenterOpen: false
    onControlCenterOpenChanged: console.log("CC_OPEN_CHANGED:", controlCenterOpen, "H:", ccComponent.height, "Y:", ccComponent.y, "OPACITY:", ccComponent.opacity, "VISIBLE:", ccComponent.visible)

    // Dynamic menu list depending on focused application
    readonly property var currentMenuItems: {
        var app = sysProc.activeAppName
        if (app === "Terminal") {
            return ["Shell", "Edit", "View", "Window", "Help"]
        } else if (app === "TextEdit") {
            return ["File", "Edit", "Format", "View", "Window", "Help"]
        } else if (app === "Safari") {
            return ["File", "Edit", "View", "History", "Bookmarks", "Window", "Help"]
        } else {
            // Finder and general macOS default
            return ["File", "Edit", "View", "Go", "Window", "Help"]
        }
    }

    function getDropdownItems(key) {
        var app = sysProc.activeAppName
        if (key === "apple") {
            return [
                { title: "About This Mac", action: "about" },
                { separator: true },
                { title: "System Settings...", shortcut: "", action: "settings" },
                { title: "App Store...", shortcut: "", action: "appstore" },
                { separator: true },
                { title: "Recent Items", hasSubmenu: true, action: "recent" },
                { separator: true },
                { title: "Force Quit...", shortcut: "⌥⌘⎋", action: "forcequit" },
                { separator: true },
                { title: "Sleep", shortcut: "", action: "sleep" },
                { title: "Restart...", shortcut: "", action: "restart" },
                { title: "Shut Down...", shortcut: "", action: "shutdown" },
                { separator: true },
                { title: "Lock Screen", shortcut: "⌃⌘Q", action: "lock" },
                { title: "Log Out " + (sysProc.userName() !== "" ? sysProc.userName() : "User") + "...", shortcut: "⇧⌘Q", action: "logout" }
            ]
        }
        if (key === "app") {
            if (app === "Terminal") {
                return [
                    { title: "About Terminal", action: "about_terminal" },
                    { separator: true },
                    { title: "Settings...", shortcut: "⌘,", action: "settings" },
                    { separator: true },
                    { title: "Hide Terminal", shortcut: "⌘H", action: "minimize" },
                    { title: "Hide Others", shortcut: "⌥⌘H", action: "hide_others" },
                    { title: "Show All", action: "show_all" },
                    { separator: true },
                    { title: "Quit Terminal", shortcut: "⌘Q", action: "quit_terminal" }
                ]
            } else if (app === "Finder") {
                return [
                    { title: "About Finder", action: "about_finder" },
                    { separator: true },
                    { title: "Settings...", shortcut: "⌘,", action: "settings" },
                    { separator: true },
                    { title: "Empty Trash...", shortcut: "⇧⌘⌫", action: "empty_trash" },
                    { separator: true },
                    { title: "Hide Finder", shortcut: "⌘H", action: "minimize" },
                    { title: "Hide Others", shortcut: "⌥⌘H", action: "hide_others" },
                    { title: "Show All", action: "show_all" }
                ]
            } else {
                return [
                    { title: "About " + app, action: "about_app" },
                    { separator: true },
                    { title: "Settings...", shortcut: "⌘,", action: "settings" },
                    { separator: true },
                    { title: "Hide " + app, shortcut: "⌘H", action: "minimize" },
                    { title: "Hide Others", shortcut: "⌥⌘H", action: "hide_others" },
                    { title: "Show All", action: "show_all" },
                    { separator: true },
                    { title: "Quit " + app, shortcut: "⌘Q", action: "quit_app" }
                ]
            }
        }
        if (key === "Shell") {
            return [
                { title: "New Window", shortcut: "⌘N", action: "new_terminal" },
                { title: "New Tab", shortcut: "⌘T", action: "new_terminal_tab" },
                { separator: true },
                { title: "Close Window", shortcut: "⌘W", action: "close_window" },
                { title: "Close Tab", shortcut: "⇧⌘W", action: "close_tab" }
            ]
        }
        if (key === "File") {
            if (app === "Finder") {
                return [
                    { title: "New Finder Window", shortcut: "⌘N", action: "new_finder" },
                    { title: "New Folder", shortcut: "⇧⌘N", action: "new_folder" },
                    { title: "New Smart Folder", shortcut: "⌥⌘N", action: "new_smart_folder" },
                    { separator: true },
                    { title: "Open", shortcut: "⌘O", action: "open" },
                    { title: "Close Window", shortcut: "⌘W", action: "close_window" },
                    { separator: true },
                    { title: "Get Info", shortcut: "⌘I", action: "get_info" },
                    { title: "Duplicate", shortcut: "⌘D", action: "duplicate" },
                    { separator: true },
                    { title: "Move to Trash", shortcut: "⌘⌫", action: "move_to_trash" }
                ]
            } else {
                return [
                    { title: "New", shortcut: "⌘N", action: "new_doc" },
                    { title: "Open...", shortcut: "⌘O", action: "open" },
                    { separator: true },
                    { title: "Save", shortcut: "⌘S", action: "save" },
                    { title: "Close Window", shortcut: "⌘W", action: "close_window" }
                ]
            }
        }
        if (key === "Edit") {
            return [
                { title: "Undo", shortcut: "⌘Z", action: "undo" },
                { title: "Redo", shortcut: "⇧⌘Z", action: "redo" },
                { separator: true },
                { title: "Cut", shortcut: "⌘X", action: "cut" },
                { title: "Copy", shortcut: "⌘C", action: "copy" },
                { title: "Paste", shortcut: "⌘V", action: "paste" },
                { title: "Select All", shortcut: "⌘A", action: "select_all" }
            ]
        }
        if (key === "View") {
            if (app === "Finder") {
                return [
                    { title: "as Icons", shortcut: "⌘1", action: "view_icons" },
                    { title: "as List", shortcut: "⌘2", action: "view_list" },
                    { title: "as Columns", shortcut: "⌘3", action: "view_columns" },
                    { title: "as Gallery", shortcut: "⌘4", action: "view_gallery" },
                    { separator: true },
                    { title: "Clean Up", action: "cleanup" },
                    { title: "Sort By", action: "sort_by" },
                    { separator: true },
                    { title: "Hide Sidebar", shortcut: "⌥⌘S", action: "toggle_sidebar" },
                    { title: "Show Preview", shortcut: "⇧⌘P", action: "toggle_preview" },
                    { separator: true },
                    { title: "Enter Full Screen", shortcut: "⌃⌘F", action: "fullscreen" }
                ]
            } else if (app === "Terminal") {
                return [
                    { title: "Bigger", shortcut: "⌘+", action: "zoom_in" },
                    { title: "Smaller", shortcut: "⌘-", action: "zoom_out" },
                    { title: "Actual Size", shortcut: "⌘0", action: "zoom_actual" },
                    { separator: true },
                    { title: "Enter Full Screen", shortcut: "⌃⌘F", action: "fullscreen" }
                ]
            } else {
                return [
                    { title: "Actual Size", shortcut: "⌘0", action: "zoom_actual" },
                    { title: "Zoom In", shortcut: "⌘+", action: "zoom_in" },
                    { title: "Zoom Out", shortcut: "⌘-", action: "zoom_out" },
                    { separator: true },
                    { title: "Enter Full Screen", shortcut: "⌃⌘F", action: "fullscreen" }
                ]
            }
        }
        if (key === "Go") {
            return [
                { title: "Back", shortcut: "⌘[", action: "go_back" },
                { title: "Forward", shortcut: "⌘]", action: "go_forward" },
                { title: "Enclosing Folder", shortcut: "⌘↑", action: "go_up" },
                { separator: true },
                { title: "Recents", shortcut: "⇧⌘F", action: "go_recents" },
                { title: "Documents", shortcut: "⇧⌘O", action: "go_docs" },
                { title: "Desktop", shortcut: "⇧⌘D", action: "go_desktop" },
                { title: "Downloads", shortcut: "⌥⌘L", action: "go_downloads" },
                { title: "Home", shortcut: "⇧⌘H", action: "go_home" },
                { title: "Computer", shortcut: "⇧⌘C", action: "go_root" },
                { title: "Network", shortcut: "⇧⌘K", action: "go_network" },
                { separator: true },
                { title: "Applications", shortcut: "⇧⌘A", action: "go_apps" },
                { title: "Utilities", shortcut: "⇧⌘U", action: "go_utils" }
            ]
        }
        if (key === "Format") {
            return [
                { title: "Font", action: "format_font" },
                { title: "Text", action: "format_text" },
                { separator: true },
                { title: "Wrap to Page", action: "wrap_page" }
            ]
        }
        if (key === "Window") {
            return [
                { title: "Minimize", shortcut: "⌘M", action: "minimize" },
                { title: "Zoom", action: "fullscreen" },
                { separator: true },
                { title: "Move to Left Side of Screen", action: "snap_left" },
                { title: "Move to Right Side of Screen", action: "snap_right" },
                { separator: true },
                { title: "Bring All to Front", action: "show_all" }
            ]
        }
        if (key === "Help") {
            return [
                { title: app + " Help", action: "app_help" },
                { title: "See What's New in SwiftDE", action: "whats_new" }
            ]
        }
        return []
    }

    function triggerAction(act) {
        if (!act || act === "") return
        if (act === "lock") {
            sysProc.lockScreen()
        } else if (act === "logout") {
            sysProc.logout()
        } else if (act === "restart") {
            sysProc.restart()
        } else if (act === "shutdown") {
            sysProc.shutdown()
        } else if (act === "about") {
            sysProc.launchAboutThisMac()
        } else if (act === "settings") {
            sysProc.launch("gnome-control-center || true")
        } else if (act === "about_finder") {
            sysProc.launch("nautilus --version; notify-send 'Finder' 'SwiftDE Finder 1.0 (Nautilus-powered)' || true")
        } else if (act === "about_terminal") {
            sysProc.launch("gnome-terminal --version; notify-send 'Terminal' 'SwiftDE Terminal (GNOME Terminal)' || true")
        } else if (act === "about_app") {
            sysProc.launch("notify-send '" + sysProc.activeAppName + "' 'SwiftDE Application' || true")
        } else if (act === "appstore") {
            sysProc.launch("snap-store || gnome-software || true")
        } else if (act === "forcequit") {
            sysProc.forceQuitActiveWindow()
        } else if (act === "show_all" || act === "hide_others") {
            sysProc.sendIpc("wm-actions/toggle_showdesktop")
        } else if (act === "sleep") {
            sysProc.launch("systemctl suspend || true")
        } else if (act === "new_finder" || act === "go_home") {
            sysProc.launch("nautilus ~")
        } else if (act === "go_docs") {
            sysProc.launch("nautilus ~/Documents")
        } else if (act === "go_desktop") {
            sysProc.launch("nautilus ~/Desktop")
        } else if (act === "go_downloads") {
            sysProc.launch("nautilus ~/Downloads")
        } else if (act === "go_root") {
            sysProc.launch("nautilus /")
        } else if (act === "go_apps") {
            sysProc.launch("nautilus /usr/share/applications")
        } else if (act === "go_utils") {
            sysProc.launch("nautilus /usr/bin")
        } else if (act === "go_recents") {
            sysProc.launch("nautilus recent://")
        } else if (act === "go_network") {
            sysProc.launch("nautilus network://")
        } else if (act === "empty_trash") {
            sysProc.launch("rm -rf ~/.local/share/Trash/files/* ~/.local/share/Trash/info/*; notify-send 'Trash' 'Trash is now empty' || true")
        } else if (act === "new_terminal") {
            sysProc.launch("gnome-terminal")
        } else if (act === "new_terminal_tab") {
            sysProc.sendKey("-M ctrl -M shift t -m shift -m ctrl")
        } else if (act === "close_tab") {
            sysProc.sendKey("-M ctrl -M shift w -m shift -m ctrl")
        } else if (act === "quit_terminal") {
            sysProc.launch("killall gnome-terminal-server")
        } else if (act === "quit_app" || act === "close_window") {
            sysProc.closeActiveWindow()
        } else if (act === "new_folder") {
            sysProc.sendKey("-M ctrl -M shift n -m shift -m ctrl")
        } else if (act === "new_smart_folder") {
            sysProc.sendKey("-M ctrl f -m ctrl")
        } else if (act === "new_doc") {
            sysProc.sendKey("-M ctrl n -m ctrl")
        } else if (act === "open") {
            sysProc.sendKey("-M ctrl o -m ctrl")
        } else if (act === "save") {
            sysProc.sendKey("-M ctrl s -m ctrl")
        } else if (act === "duplicate") {
            sysProc.sendKey("-M ctrl d -m ctrl")
        } else if (act === "get_info") {
            sysProc.sendKey("-M ctrl i -m ctrl")
        } else if (act === "move_to_trash") {
            sysProc.sendKey("-k Delete")
        } else if (act === "undo") {
            sysProc.sendKey("-M ctrl z -m ctrl")
        } else if (act === "redo") {
            sysProc.sendKey("-M ctrl -M shift z -m shift -m ctrl")
        } else if (act === "cut") {
            sysProc.sendKey("-M ctrl x -m ctrl")
        } else if (act === "copy") {
            sysProc.sendKey("-M ctrl c -m ctrl")
        } else if (act === "paste") {
            sysProc.sendKey("-M ctrl v -m ctrl")
        } else if (act === "select_all") {
            sysProc.sendKey("-M ctrl a -m ctrl")
        } else if (act === "fullscreen") {
            sysProc.toggleFullscreen()
        } else if (act === "minimize") {
            sysProc.minimizeActiveWindow()
        } else if (act === "snap_left") {
            sysProc.snapLeft()
        } else if (act === "snap_right") {
            sysProc.snapRight()
        } else if (act === "zoom_in") {
            sysProc.sendKey("-M ctrl plus -m ctrl")
        } else if (act === "zoom_out") {
            sysProc.sendKey("-M ctrl minus -m ctrl")
        } else if (act === "zoom_actual") {
            sysProc.sendKey("-M ctrl 0 -m ctrl")
        } else if (act === "view_icons") {
            sysProc.sendKey("-M ctrl 1 -m ctrl")
        } else if (act === "view_list") {
            sysProc.sendKey("-M ctrl 2 -m ctrl")
        } else if (act === "view_columns") {
            sysProc.sendKey("-M ctrl 3 -m ctrl")
        } else if (act === "view_gallery") {
            sysProc.sendKey("-M ctrl 4 -m ctrl")
        } else if (act === "cleanup") {
            sysProc.sendKey("-k F5")
        } else if (act === "sort_by") {
            sysProc.sendKey("-M ctrl s -m ctrl")
        } else if (act === "toggle_sidebar") {
            sysProc.sendKey("-k F9")
        } else if (act === "toggle_preview") {
            sysProc.sendKey("-M ctrl p -m ctrl")
        } else if (act === "go_back") {
            sysProc.sendKey("-M alt Left -m alt")
        } else if (act === "go_forward") {
            sysProc.sendKey("-M alt Right -m alt")
        } else if (act === "go_up") {
            sysProc.sendKey("-M alt Up -m alt")
        } else if (act === "format_font") {
            sysProc.sendKey("-M ctrl t -m ctrl")
        } else if (act === "format_text") {
            sysProc.sendKey("-M ctrl b -m ctrl")
        } else if (act === "wrap_page") {
            sysProc.sendKey("-M ctrl w -m ctrl")
        } else if (act === "app_help") {
            sysProc.launch("gnome-help || true")
        } else if (act === "whats_new") {
            sysProc.launch("xdg-open https://github.com/vinceliuice/WhiteSur-gtk-theme || true")
        }
    }

    function closeAndTrigger(act) {
        if (act && act !== "") {
            topbarWindow.triggerAction(act)
        }
        topbarWindow.activeMenu = ""
        topbarWindow.controlCenterOpen = false
    }

    // Current formatted date/time string: "Tue Sep 10  10:48AM"
    property string clockText: ""

    function updateClock() {
        var d = new Date()
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        var dayName = days[d.getDay()]
        var monthName = months[d.getMonth()]
        var dayNum = d.getDate()
        var hours = d.getHours()
        var minutes = d.getMinutes()
        var ampm = hours >= 12 ? "PM" : "AM"
        hours = hours % 12
        if (hours === 0) hours = 12
        var minStr = (minutes < 10 ? "0" : "") + minutes
        topbarWindow.clockText = dayName + " " + monthName + " " + dayNum + "  " + hours + ":" + minStr + ampm
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: topbarWindow.updateClock()
    }

    Component.onCompleted: updateClock()
    Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: console.log("LATER_POS_X:", controlCenterBtn.mapToItem(null, 0, 0).x, "rightRow x:", rightRow.x)
    }

    // Backdrop click catcher to dismiss open menu, Control Center, or Desktop Context Menu
    MouseArea {
        anchors.fill: parent
        z: 40
        visible: (topbarWindow.activeMenu !== "" || topbarWindow.controlCenterOpen || topbarWindow.desktopContextMenuOpen)
        onClicked: {
            topbarWindow.activeMenu = ""
            topbarWindow.controlCenterOpen = false
            topbarWindow.desktopContextMenuOpen = false
        }
    }

    // Wallpaper source
    Image {
        id: bgWall
        x: 0
        y: 0
        width: topbarWindow.width
        height: Screen.height > 0 ? Screen.height : 1080
        source: sysProc.wallpaperUrl.length > 0 ? sysProc.wallpaperUrl : "../../../../../../Library/DesktopPictures/Wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
        cache: false
    }

    // Isolate top strip
    Item {
        id: topSlice
        width: topbarWindow.width
        height: 60
        visible: false
        clip: true

        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: bgWall
            sourceRect: Qt.rect(0, 0, topbarWindow.width, 60)
            hideSource: false
        }
    }

    // Downscale by 4x for extreme blur diffusion
    Item {
        id: downsampled
        width: Math.round(topbarWindow.width / 4)
        height: 15
        visible: false

        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: topSlice
            hideSource: false
        }
    }

    FastBlur {
        id: blurPass1
        anchors.fill: downsampled
        source: downsampled
        radius: 64
        visible: false
    }

    FastBlur {
        id: blurPass2
        anchors.fill: downsampled
        source: blurPass1
        radius: 64
        visible: false
    }

    // Upscale back to screen width
    Item {
        id: upscaled
        width: topbarWindow.width
        height: 25
        visible: false

        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: blurPass2
            hideSource: false
            smooth: true
        }
    }

    FastBlur {
        id: finalSuperBlur
        anchors.fill: upscaled
        source: upscaled
        radius: 32
        visible: false
    }

    // --- Main 25px Bar Area ---
    Item {
        id: barArea
        x: 0
        y: 0
        width: parent.width
        height: 25
        z: 50
        clip: true

        ShaderEffectSource {
            id: barSurface
            anchors.fill: parent
            sourceItem: finalSuperBlur
            hideSource: false
            live: true
        }

        // Frosted acrylic tint (macOS Sequoia light glass)
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.13)
        }

        // Subtle light sheen for vibrancy
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.04)
        }

        // --- Left section: Apple logo + Global Menu Items ---
        Row {
            id: menuRow
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 2

            // Apple Logo Button
            Item {
                id: appleBtn
                width: 28
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: (topbarWindow.activeMenu === "apple") ? Qt.rgba(1, 1, 1, 0.25)
                         : (appleMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent")
                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                Text {
                    id: appleIcon
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1.2
                    text: "\uE900"
                    font.family: sfSymbols.name
                    font.pixelSize: 20
                    color: "#ffffff"
                    opacity: 0.95
                }

                MouseArea {
                    id: appleMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        if (topbarWindow.activeMenu !== "") {
                            topbarWindow.activeMenu = "apple"
                            topbarWindow.activeMenuX = appleBtn.x + menuRow.x
                        }
                    }
                    onClicked: {
                        topbarWindow.controlCenterOpen = false
                        if (topbarWindow.activeMenu === "apple") {
                            topbarWindow.activeMenu = ""
                        } else {
                            topbarWindow.activeMenuX = appleBtn.x + menuRow.x
                            topbarWindow.activeMenu = "apple"
                        }
                    }
                }
            }

            // App Name Button (Bold)
            Item {
                id: appNameBtn
                width: appNameText.implicitWidth + 16
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: (topbarWindow.activeMenu === "app") ? Qt.rgba(1, 1, 1, 0.25)
                         : (appNameMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent")
                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                Text {
                    id: appNameText
                    anchors.centerIn: parent
                    text: (sysProc.activeAppName !== "" && sysProc.activeAppName !== "Window" && sysProc.activeAppName !== "About") ? sysProc.activeAppName : "Finder"
                    font.family: sfBold.name
                    font.bold: true
                    font.pixelSize: 13
                    color: "#ffffff"
                    opacity: 0.95
                }

                MouseArea {
                    id: appNameMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        if (topbarWindow.activeMenu !== "") {
                            topbarWindow.activeMenu = "app"
                            topbarWindow.activeMenuX = appNameBtn.x + menuRow.x
                        }
                    }
                    onClicked: {
                        topbarWindow.controlCenterOpen = false
                        if (topbarWindow.activeMenu === "app") {
                            topbarWindow.activeMenu = ""
                        } else {
                            topbarWindow.activeMenuX = appNameBtn.x + menuRow.x
                            topbarWindow.activeMenu = "app"
                        }
                    }
                }
            }

            // Dynamic Menu Items Repeater
            Repeater {
                id: menuRepeater
                model: topbarWindow.currentMenuItems

                Item {
                    id: menuItemBtn
                    width: menuText.implicitWidth + 16
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    readonly property string menuKey: modelData

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: (topbarWindow.activeMenu === menuItemBtn.menuKey) ? Qt.rgba(1, 1, 1, 0.25)
                             : (menuMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent")
                        Behavior on color { ColorAnimation { duration: 90 } }
                    }

                    Text {
                        id: menuText
                        anchors.centerIn: parent
                        text: menuItemBtn.menuKey
                        font.family: sfMedium.name
                        font.weight: Font.Medium
                        font.pixelSize: 13
                        color: "#ffffff"
                        opacity: 0.95
                    }

                    MouseArea {
                        id: menuMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (topbarWindow.activeMenu !== "") {
                                topbarWindow.activeMenu = menuItemBtn.menuKey
                                topbarWindow.activeMenuX = menuItemBtn.x + menuRow.x
                            }
                        }
                        onClicked: {
                            topbarWindow.controlCenterOpen = false
                            if (topbarWindow.activeMenu === menuItemBtn.menuKey) {
                                topbarWindow.activeMenu = ""
                            } else {
                                topbarWindow.activeMenuX = menuItemBtn.x + menuRow.x
                                topbarWindow.activeMenu = menuItemBtn.menuKey
                            }
                        }
                    }
                }
            }
        }

        // --- Right section: WiFi + Spotlight + Control Center + Clock/Date ---
        Row {
            id: rightRow
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 4

            // WiFi Signal Indicator
            Item {
                id: wifiBtn
                width: 28
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                property int signalLevel: 3

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: wifiMa.containsPress ? Qt.rgba(1, 1, 1, 0.25)
                         : (wifiMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent")
                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                Item {
                    id: wifiIconBox
                    anchors.centerIn: parent
                    width: 17
                    height: 17

                    Shape {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.samples: 4

                        // Top Bar (Arc 3)
                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: wifiBtn.signalLevel >= 3 ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.28)
                            scale: Qt.size(wifiIconBox.width / 512.0, wifiIconBox.height / 512.0)
                            PathSvg {
                                path: "M256 96c-81.5 0-163 33.6-221.5 88.3-3.3 3-3.4 8.1-.3 11.4l26.7 27.9c3.1 3.3 8.3 3.4 11.6.3 23.3-21.6 49.9-38.8 79.3-51 33-13.8 68.1-20.7 104.3-20.7s71.3 7 104.3 20.7c29.4 12.3 56 29.4 79.3 51 3.3 3.1 8.5 3 11.6-.3l26.7-27.9c3.1-3.2 3-8.3-.3-11.4C419 129.6 337.5 96 256 96z"
                            }
                            Behavior on fillColor { ColorAnimation { duration: 200 } }
                        }

                        // Middle Bar (Arc 2)
                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: wifiBtn.signalLevel >= 2 ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.28)
                            scale: Qt.size(wifiIconBox.width / 512.0, wifiIconBox.height / 512.0)
                            PathSvg {
                                path: "M113.2 277.5l28.6 28.3c3.1 3 8 3.2 11.2.3 28.3-25.1 64.6-38.9 102.9-38.9s74.6 13.7 102.9 38.9c3.2 2.9 8.1 2.7 11.2-.3l28.6-28.3c3.3-3.3 3.2-8.6-.3-11.7-37.5-33.9-87.6-54.6-142.5-54.6s-105 20.7-142.5 54.6c-3.3 3.1-3.4 8.4-.1 11.7z"
                            }
                            Behavior on fillColor { ColorAnimation { duration: 200 } }
                        }

                        // Bottom Dot / Arc (Arc 1)
                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: wifiBtn.signalLevel >= 1 ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.28)
                            scale: Qt.size(wifiIconBox.width / 512.0, wifiIconBox.height / 512.0)
                            PathSvg {
                                path: "M256 324.2c-23.4 0-44.6 9.8-59.4 25.5-3 3.2-2.9 8.1.2 11.2l53.4 52.7c3.2 3.2 8.4 3.2 11.6 0l53.4-52.7c3.1-3.1 3.2-8 .2-11.2-14.8-15.6-36-25.5-59.4-25.5z"
                            }
                            Behavior on fillColor { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                MouseArea {
                    id: wifiMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: topbarWindow.activeMenu = ""
                    onClicked: {
                        topbarWindow.activeMenu = ""
                        sysProc.launch("gnome-control-center wifi || gnome-control-center network || true")
                    }
                }
            }

            // Spotlight Search Button
            Item {
                id: spotlightBtn
                width: 26
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: spotlightMa.containsPress ? Qt.rgba(1, 1, 1, 0.25)
                         : (spotlightMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent")
                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                Text {
                    id: spotlightIcon
                    anchors.centerIn: parent
                    text: "\uFCA6"
                    font.family: sfSymbols.name
                    font.pixelSize: 14
                    color: "#ffffff"
                    opacity: 0.95
                }

                MouseArea {
                    id: spotlightMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: topbarWindow.activeMenu = ""
                    onClicked: {
                        topbarWindow.activeMenu = ""
                        sysProc.launch("gnome-terminal || true")
                    }
                }
            }

            // Control Center Button
            Item {
                id: controlCenterBtn
                width: 26
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: topbarWindow.controlCenterOpen ? Qt.rgba(1, 1, 1, 0.25)
                         : (controlCenterMa.containsPress ? Qt.rgba(1, 1, 1, 0.25)
                         : (controlCenterMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"))
                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                Image {
                    id: controlCenterIcon
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "Assets/ControlCenter_native.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: false
                    opacity: 0.95
                }

                MouseArea {
                    id: controlCenterMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        if (topbarWindow.activeMenu !== "") {
                            topbarWindow.activeMenu = ""
                        }
                    }
                    onClicked: {
                        console.log("CLICKED_CC_BTN! Current was:", topbarWindow.controlCenterOpen)
                        topbarWindow.activeMenu = ""
                        topbarWindow.controlCenterOpen = !topbarWindow.controlCenterOpen
                    }
                }
            }

            // Clock / Date Button
            Item {
                id: clockBtn
                width: clockLabel.implicitWidth + 14
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: clockMa.containsPress ? Qt.rgba(1, 1, 1, 0.25)
                         : (clockMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent")
                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                Text {
                    id: clockLabel
                    anchors.centerIn: parent
                    text: topbarWindow.clockText
                    font.family: sfMedium.name
                    font.weight: Font.Medium
                    font.pixelSize: 13
                    color: "#ffffff"
                    opacity: 0.95
                }

                MouseArea {
                    id: clockMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: topbarWindow.activeMenu = ""
                    onClicked: {
                        topbarWindow.activeMenu = ""
                        sysProc.launch("gnome-control-center system || gnome-calendar || true")
                    }
                }
            }
        }
    }

    // --- Drop-down Popup Menu Component ---
    Item {
        id: dropdownContainer
        property real menuWidth: topbarWindow.activeMenu === "apple" ? 350 : 230
        x: topbarWindow.activeMenu === "apple" ? 6 : Math.min(topbarWindow.activeMenuX, topbarWindow.width - menuWidth - 10)
        y: 28
        z: 100
        visible: topbarWindow.activeMenu !== ""
        width: menuWidth
        height: menuColumn.height + 10

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Qt.rgba(0.94, 0.94, 0.93, 0.70)
            border.color: Qt.rgba(0, 0, 0, 0.14)
            border.width: 0.6

            // Subtle inner light reflection for vibrancy
            Rectangle {
                anchors.fill: parent
                anchors.margins: 0.6
                radius: 7.4
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.65)
                border.width: 0.6
            }

            // Subtle outer shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: 9
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.08)
                border.width: 1
                z: -1
            }
        }

        Column {
                id: menuColumn
                x: 0
                y: 5
                width: parent.width
                spacing: 1

                Repeater {
                    model: topbarWindow.getDropdownItems(topbarWindow.activeMenu)

                    Item {
                        width: menuColumn.width
                        height: modelData.separator ? 7 : 21

                        // Separator line
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            height: 0.8
                            color: Qt.rgba(0, 0, 0, 0.08)
                            visible: !!modelData.separator
                        }

                        // Regular menu item
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            radius: 4.5
                            visible: !modelData.separator
                            color: itemMa.containsMouse ? "#007aff" : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title || ""
                                font.family: sfMedium.name
                                font.weight: Font.Medium
                                font.pixelSize: 13
                                color: itemMa.containsMouse ? "#ffffff" : "#1d1d1f"
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.shortcut || ""
                                font.family: sfMedium.name
                                font.weight: Font.Medium
                                font.pixelSize: 13
                                color: itemMa.containsMouse ? "#ffffff" : "#48484a"
                                visible: !!modelData.shortcut
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "›"
                                font.family: sfMedium.name
                                font.weight: Font.DemiBold
                                font.pixelSize: 15
                                color: itemMa.containsMouse ? "#ffffff" : "#1d1d1f"
                                visible: !!modelData.hasSubmenu
                            }

                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var act = modelData ? modelData.action : ""
                                    topbarWindow.closeAndTrigger(act)
                                }
                            }
                        }
                    }
                }
            }
        }

    // --- Desktop Context Menu Component (LayerTop: Always above all windows) ---
    Item {
        id: desktopContextMenuContainer
        x: topbarWindow.desktopContextMenuX
        y: topbarWindow.desktopContextMenuY
        z: 100
        visible: topbarWindow.desktopContextMenuOpen
        width: 230
        height: desktopMenuColumn.height + 10

        // Frosted glass background with vibrancy tint (live-blurred by Wayfire compositor)
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Qt.rgba(0.94, 0.94, 0.93, 0.70)
            border.color: Qt.rgba(0, 0, 0, 0.14)
            border.width: 0.6

            // Subtle inner light reflection for vibrancy
            Rectangle {
                anchors.fill: parent
                anchors.margins: 0.6
                radius: 7.4
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.65)
                border.width: 0.6
            }

            // Subtle outer shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: 9
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.08)
                border.width: 1
                z: -1
            }
        }

        Column {
            id: desktopMenuColumn
            x: 0
            y: 5
            width: parent.width
            spacing: 1

            Repeater {
                model: topbarWindow.desktopContextMenuItems

                Item {
                    width: desktopMenuColumn.width
                    height: modelData.separator ? 7 : 21

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 24
                        height: 0.8
                        color: Qt.rgba(0, 0, 0, 0.08)
                        visible: !!modelData.separator
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        radius: 4.5
                        visible: !modelData.separator
                        color: dmenuMa.containsMouse ? "#007aff" : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title || ""
                            font.family: sfMedium.name
                            font.weight: Font.Medium
                            font.pixelSize: 13
                            color: dmenuMa.containsMouse ? "#ffffff" : "#1d1d1f"
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            font.family: sfMedium.name
                            font.weight: Font.DemiBold
                            font.pixelSize: 15
                            color: dmenuMa.containsMouse ? "#ffffff" : "#1d1d1f"
                            visible: !!modelData.hasSubmenu
                        }

                        MouseArea {
                            id: dmenuMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                topbarWindow.handleDesktopMenuAction(modelData.action)
                            }
                        }
                    }
                }
            }
        }
    }

    // --- macOS Sequoia Control Center Component ---
    ControlCenter {
        id: ccComponent
        x: topbarWindow.width - width - 12
        z: 100
        isOpen: topbarWindow.controlCenterOpen
        sysProcRef: sysProc
    }
}
