import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import SwiftDE 1.0

Window {
    id: settingsWindow
    title: "System Settings"
    width: 880
    height: 640
    minimumWidth: 800
    minimumHeight: 560
    visible: true
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    SysProc {
        id: sysProc
    }

    FontLoader { id: sfDisplayBold; source: "../../../../../../Library/Fonts/SF-Pro-Display-Bold.otf" }
    FontLoader { id: sfTextMedium; source: "../../../../../../Library/Fonts/SF-Pro-Text-Medium.otf" }
    FontLoader { id: sfTextBold; source: "../../../../../../Library/Fonts/SF-Pro-Text-Bold.otf" }
    FontLoader { id: sfSymbols; source: "../../../../../../Library/Fonts/SF-Symbols-6.otf" }

    property string currentTab: "wallpaper"
    property var navHistory: ["wallpaper"]
    property int navIndex: 0

    function selectTab(tabId) {
        if (currentTab === tabId) return
        currentTab = tabId
        if (navIndex < navHistory.length - 1) {
            navHistory = navHistory.slice(0, navIndex + 1)
        }
        navHistory.push(tabId)
        navIndex = navHistory.length - 1
    }

    function navBack() {
        if (navIndex > 0) {
            navIndex--
            currentTab = navHistory[navIndex]
        }
    }

    function navForward() {
        if (navIndex < navHistory.length - 1) {
            navIndex++
            currentTab = navHistory[navIndex]
        }
    }

    Component.onCompleted: {
        var args = Qt.application.arguments
        for (var i = 0; i < args.length; i++) {
            var arg = args[i].toLowerCase()
            if (arg === "dock") arg = "desktop_dock"
            for (var j = 0; j < sidebarCol.rawItems.length; j++) {
                if (sidebarCol.rawItems[j].id === arg) {
                    currentTab = arg
                    navHistory = [arg]
                    navIndex = 0
                    return
                }
            }
        }
    }

    // Outer acrylic window frame matching macOS Sequoia
    Rectangle {
        id: windowFrame
        anchors.fill: parent
        radius: 14
        clip: true
        color: "#f6f6f7"
        border.color: Qt.rgba(0, 0, 0, 0.16)
        border.width: 1

        // --- Window Drag Area (Header) ---
        MouseArea {
            id: windowDragArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 48
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    settingsWindow.startSystemMove()
                }
            }
            onDoubleClicked: {
                if (settingsWindow.visibility === Window.Maximized) {
                    settingsWindow.showNormal()
                } else {
                    settingsWindow.showMaximized()
                }
            }
        }

        // ==========================================
        // LEFT SIDEBAR (Width: 246px)
        // ==========================================
        Rectangle {
            id: sidebar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 246
            color: "#ebecee"

            // Vertical divider between sidebar and content
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Qt.rgba(0, 0, 0, 0.1)
            }

            // --- Traffic Light Buttons ---
            Row {
                id: trafficLights
                x: 18
                y: 18
                spacing: 8
                z: 20

                // Close (Red)
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: closeHover.containsMouse ? "#ff5f56" : "#ff5f56"
                    border.color: "#e0443e"; border.width: 0.6
                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: settingsWindow.close()
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#4d0000"
                        visible: closeHover.containsMouse
                    }
                }

                // Minimize (Yellow)
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: minHover.containsMouse ? "#ffbd2e" : "#ffbd2e"
                    border.color: "#dea123"; border.width: 0.6
                    MouseArea {
                        id: minHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: settingsWindow.showMinimized()
                    }
                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: "-"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#603c00"
                        visible: minHover.containsMouse
                    }
                }

                // Zoom (Green)
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: zoomHover.containsMouse ? "#27c93f" : "#27c93f"
                    border.color: "#1aab29"; border.width: 0.6
                    MouseArea {
                        id: zoomHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (settingsWindow.visibility === Window.Maximized) {
                                settingsWindow.showNormal()
                            } else {
                                settingsWindow.showMaximized()
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 9
                        font.bold: true
                        color: "#003b00"
                        visible: zoomHover.containsMouse
                    }
                }
            }

            // --- Search Field ---
            Rectangle {
                id: searchBox
                x: 16
                y: 44
                width: parent.width - 32
                height: 28
                radius: 7
                color: "#ffffff"
                border.color: Qt.rgba(0, 0, 0, 0.12)
                border.width: 0.8

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "􀊫" // SF Symbol magnifyingglass
                        font.family: sfSymbols.name
                        font.pixelSize: 12
                        color: "#8e8e93"
                    }

                    TextInput {
                        id: searchInput
                        width: searchBox.width - 50
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: sfTextMedium.name
                        font.pixelSize: 12
                        color: "#1d1d1f"
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            text: "Search"
                            font.family: sfTextMedium.name
                            font.pixelSize: 12
                            color: "#8e8e93"
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }
                }

                // Clear button
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "􀁡"
                    font.family: sfSymbols.name
                    font.pixelSize: 12
                    color: "#8e8e93"
                    visible: searchInput.text.length > 0
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }

            // --- Sidebar Navigation List ---
            Flickable {
                id: sidebarFlickable
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: searchBox.bottom
                anchors.topMargin: 8
                anchors.bottom: parent.bottom
                contentHeight: sidebarCol.height + 20
                clip: true

                Column {
                    id: sidebarCol
                    width: parent.width
                    spacing: 2

                    // Helper list of all sidebar items
                    readonly property var rawItems: [
                        // Group 1: Desktop, Displays, Wallpaper
                        { id: "appearance", title: "Appearance", symbol: "􀤔", color: "#007aff", group: 1 },
                        { id: "desktop_dock", title: "Desktop & Dock", symbol: "􀤊", color: "#1d1d1f", group: 1 },
                        { id: "displays", title: "Displays", symbol: "􀆮", color: "#007aff", group: 1 },
                        { id: "screensaver", title: "Screen Saver", symbol: "􀎾", color: "#007aff", group: 1 },
                        { id: "siri", title: "Siri", symbol: "􀊰", color: "#5856d6", group: 1 },
                        { id: "wallpaper", title: "Wallpaper", symbol: "􀏅", color: "#007aff", group: 1 },

                        // Group 2: Notifications, Sound, Focus
                        { id: "notifications", title: "Notifications", symbol: "􀋚", color: "#ff3b30", group: 2 },
                        { id: "sound", title: "Sound", symbol: "􀊩", color: "#ff375f", group: 2 },
                        { id: "focus", title: "Focus", symbol: "􀆹", color: "#5856d6", group: 2 },
                        { id: "screentime", title: "Screen Time", symbol: "􀐫", color: "#5856d6", group: 2 },

                        // Group 3: Security & Accounts
                        { id: "lockscreen", title: "Lock Screen", symbol: "􀎡", color: "#1d1d1f", group: 3 },
                        { id: "privacy", title: "Privacy & Security", symbol: "􀎽", color: "#007aff", group: 3 },
                        { id: "touchid", title: "Touch ID & Password", symbol: "􀎹", color: "#ff2d55", group: 3 },
                        { id: "users", title: "Users & Groups", symbol: "􀉭", color: "#007aff", group: 3 },

                        // Group 4: Online & Utilities
                        { id: "accounts", title: "Internet Accounts", symbol: "􀍢", color: "#007aff", group: 4 },
                        { id: "gamecenter", title: "Game Center", symbol: "􀛨", color: "#ff9500", group: 4 },
                        { id: "icloud", title: "iCloud", symbol: "􀌍", color: "#007aff", group: 4 },
                        { id: "spotlight", title: "Spotlight", symbol: "􀊫", color: "#8e8e93", group: 4 },
                        { id: "wallet", title: "Wallet & Apple Pay", symbol: "􀍲", color: "#1d1d1f", group: 4 }
                    ]

                    Repeater {
                        model: sidebarCol.rawItems

                        delegate: Column {
                            width: sidebar.width
                            visible: !searchInput.text || modelData.title.toLowerCase().indexOf(searchInput.text.toLowerCase()) !== -1

                            // Spacing / separator between groups
                            Item {
                                width: parent.width
                                height: 10
                                visible: index > 0 && modelData.group !== sidebarCol.rawItems[index - 1].group
                            }

                            Rectangle {
                                id: itemRect
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: sidebar.width - 20
                                height: 32
                                radius: 7
                                color: settingsWindow.currentTab === modelData.id ? "#007aff" : (itemMa.containsMouse ? Qt.rgba(0, 0, 0, 0.05) : "transparent")

                                MouseArea {
                                    id: itemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsWindow.selectTab(modelData.id)
                                }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    spacing: 9

                                    // Colored squircle icon
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 5
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: settingsWindow.currentTab === modelData.id ? "#ffffff" : modelData.color

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.symbol
                                            font.family: sfSymbols.name
                                            font.pixelSize: 12
                                            color: settingsWindow.currentTab === modelData.id ? "#007aff" : "#ffffff"
                                        }
                                    }

                                    // Title label
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.title
                                        font.family: sfTextMedium.name
                                        font.weight: settingsWindow.currentTab === modelData.id ? Font.Medium : Font.Normal
                                        font.pixelSize: 13
                                        color: settingsWindow.currentTab === modelData.id ? "#ffffff" : "#1d1d1f"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // RIGHT CONTENT AREA
        // ==========================================
        Item {
            id: contentArea
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // --- Header: Navigation Chevrons & Title ---
            Item {
                id: contentHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 52

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 14

                    // Navigation Back / Forward Chevrons
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Rectangle {
                            width: 24; height: 24; radius: 5
                            color: backMa.containsMouse ? Qt.rgba(0,0,0,0.06) : "transparent"
                            opacity: settingsWindow.navIndex > 0 ? 1.0 : 0.35
                            Text {
                                anchors.centerIn: parent
                                text: "􀆉"
                                font.family: sfSymbols.name
                                font.pixelSize: 13
                                font.bold: true
                                color: "#1d1d1f"
                            }
                            MouseArea {
                                id: backMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsWindow.navBack()
                            }
                        }

                        Rectangle {
                            width: 24; height: 24; radius: 5
                            color: fwdMa.containsMouse ? Qt.rgba(0,0,0,0.06) : "transparent"
                            opacity: settingsWindow.navIndex < settingsWindow.navHistory.length - 1 ? 1.0 : 0.35
                            Text {
                                anchors.centerIn: parent
                                text: "􀆊"
                                font.family: sfSymbols.name
                                font.pixelSize: 13
                                font.bold: true
                                color: "#1d1d1f"
                            }
                            MouseArea {
                                id: fwdMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsWindow.navForward()
                            }
                        }
                    }

                    // Section Title
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            for (var i = 0; i < sidebarCol.rawItems.length; i++) {
                                if (sidebarCol.rawItems[i].id === settingsWindow.currentTab)
                                    return sidebarCol.rawItems[i].title
                            }
                            return "Settings"
                        }
                        font.family: sfDisplayBold.name
                        font.bold: true
                        font.pixelSize: 19
                        color: "#1d1d1f"
                    }
                }
            }

            // ==========================================
            // TAB 1: WALLPAPER (1 to 1 with reference)
            // ==========================================
            Flickable {
                id: wallpaperFlickable
                visible: settingsWindow.currentTab === "wallpaper"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: contentHeader.bottom
                anchors.bottom: parent.bottom
                contentHeight: wallpaperContent.height + 40
                clip: true

                Column {
                    id: wallpaperContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 22
                    spacing: 20

                    // --- Hero Card: Current Active Wallpaper ---
                    Item {
                        width: parent.width
                        height: 154

                        // Left: Wallpaper Preview
                        Rectangle {
                            id: heroThumbRect
                            width: 172
                            height: 104
                            radius: 8
                            clip: true
                            color: "#000000"
                            border.color: Qt.rgba(0, 0, 0, 0.16)
                            border.width: 1

                            Image {
                                id: heroImg
                                anchors.fill: parent
                                source: sysProc.wallpaperUrl.length > 0 ? sysProc.wallpaperUrl : "Assets/hero_sequoia.png"
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                cache: false
                            }
                        }

                        // Right: Controls column
                        Column {
                            anchors.left: heroThumbRect.right
                            anchors.leftMargin: 16
                            anchors.right: parent.right
                            spacing: 8

                            // Wallpaper Name Box
                            Rectangle {
                                width: parent.width
                                height: 32
                                radius: 6
                                color: "#f0f0f2"
                                border.color: Qt.rgba(0, 0, 0, 0.1)
                                border.width: 0.8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    text: sysProc.wallpaperName.length > 0 ? sysProc.wallpaperName : "Sequoia Sunrise"
                                    font.family: sfTextMedium.name
                                    font.pixelSize: 13
                                    color: "#1d1d1f"
                                }
                            }

                            // Switch row 1: Show as screen saver
                            Row {
                                width: parent.width
                                height: 26

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Show as screen saver"
                                    font.family: sfTextMedium.name
                                    font.pixelSize: 13
                                    color: "#1d1d1f"
                                }

                                Item { Layout.fillWidth: true; width: parent.width - 200 }

                                // macOS Toggle Switch
                                Rectangle {
                                    id: saverSwitch
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38
                                    height: 22
                                    radius: 11
                                    color: saverMa.checked ? "#34c759" : "#e5e5ea"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        width: 18; height: 18; radius: 9
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: saverMa.checked ? 18 : 2
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        id: saverMa
                                        property bool checked: true
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: checked = !checked
                                    }
                                }
                            }

                            // Switch row 2: Show on all Spaces
                            Row {
                                width: parent.width
                                height: 26

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Show on all Spaces"
                                    font.family: sfTextMedium.name
                                    font.pixelSize: 13
                                    color: "#1d1d1f"
                                }

                                Item { Layout.fillWidth: true; width: parent.width - 200 }

                                Rectangle {
                                    id: spacesSwitch
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38
                                    height: 22
                                    radius: 11
                                    color: spacesMa.checked ? "#007aff" : "#e5e5ea"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        width: 18; height: 18; radius: 9
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: spacesMa.checked ? 18 : 2
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        id: spacesMa
                                        property bool checked: true
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: checked = !checked
                                    }
                                }
                            }
                        }

                        // Bottom Action Buttons
                        Row {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            spacing: 8

                            Rectangle {
                                height: 26
                                width: photoText.implicitWidth + 24
                                radius: 6
                                color: photoMa.containsMouse ? "#f5f5f7" : "#ffffff"
                                border.color: Qt.rgba(0, 0, 0, 0.16)
                                border.width: 0.8

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        id: photoText
                                        text: "Add Photo"
                                        font.family: sfTextMedium.name
                                        font.pixelSize: 12
                                        color: "#1d1d1f"
                                    }
                                    Text {
                                        text: "􀆈"
                                        font.family: sfSymbols.name
                                        font.pixelSize: 9
                                        color: "#8e8e93"
                                    }
                                }
                                MouseArea {
                                    id: photoMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sysProc.launch("zenity --file-selection --title='Choose Wallpaper' | while read f; do gsettings set org.gnome.desktop.background picture-uri \"file://$f\"; gsettings set org.gnome.desktop.background picture-uri-dark \"file://$f\"; done || true")
                                }
                            }

                            Rectangle {
                                height: 26
                                width: folderText.implicitWidth + 24
                                radius: 6
                                color: folderMa.containsMouse ? "#f5f5f7" : "#ffffff"
                                border.color: Qt.rgba(0, 0, 0, 0.16)
                                border.width: 0.8

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        id: folderText
                                        text: "Add Folder or Album"
                                        font.family: sfTextMedium.name
                                        font.pixelSize: 12
                                        color: "#1d1d1f"
                                    }
                                    Text {
                                        text: "􀆈"
                                        font.family: sfSymbols.name
                                        font.pixelSize: 9
                                        color: "#8e8e93"
                                    }
                                }
                                MouseArea {
                                    id: folderMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sysProc.launch("zenity --file-selection --directory --title='Choose Wallpaper Folder' || true")
                                }
                            }
                        }
                    }

                    // --- Category 1: Dynamic Wallpapers ---
                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            width: parent.width
                            Text {
                                text: "Dynamic Wallpapers"
                                font.family: sfDisplayBold.name
                                font.bold: true
                                font.pixelSize: 14
                                color: "#1d1d1f"
                            }
                            Item { Layout.fillWidth: true; width: parent.width - 240 }
                            Text {
                                anchors.right: parent.right
                                text: "Show All (33)"
                                font.family: sfTextMedium.name
                                font.pixelSize: 12
                                color: "#8e8e93"
                            }
                        }

                        Row {
                            spacing: 12

                            readonly property var dynItems: [
                                { name: "Sequoia", thumb: "Assets/thumb_sequoia.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_sequoia.jpg" },
                                { name: "Macintosh", thumb: "Assets/thumb_macintosh.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_macintosh.jpg" },
                                { name: "Sonoma", thumb: "Assets/thumb_sonoma.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_sonoma.jpg" },
                                { name: "Ventura ↓", thumb: "Assets/thumb_ventura.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_ventura.jpg" }
                            ]

                            Repeater {
                                model: parent.dynItems

                                delegate: Column {
                                    spacing: 6

                                    Rectangle {
                                        width: 134
                                        height: 75
                                        radius: 8
                                        clip: true
                                        color: "#000000"
                                        border.color: sysProc.wallpaperName === modelData.name ? "#007aff" : (dynMa.containsMouse ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(0, 0, 0, 0.12))
                                        border.width: sysProc.wallpaperName === modelData.name ? 2.5 : 1

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: sysProc.wallpaperName === modelData.name ? 1.5 : 0
                                            source: modelData.thumb
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                        }

                                        // Dynamic icon badge
                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.margins: 4
                                            width: 16; height: 16; radius: 8
                                            color: Qt.rgba(0, 0, 0, 0.45)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "􀆮"
                                                font.family: sfSymbols.name
                                                font.pixelSize: 9
                                                color: "#ffffff"
                                            }
                                        }

                                        MouseArea {
                                            id: dynMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                sysProc.setWallpaper("file://" + modelData.wall, modelData.name)
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.name
                                        font.family: sfTextMedium.name
                                        font.pixelSize: 12
                                        color: "#1d1d1f"
                                    }
                                }
                            }
                        }
                    }

                    // --- Category 2: Landscape ---
                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            width: parent.width
                            Text {
                                text: "Landscape"
                                font.family: sfDisplayBold.name
                                font.bold: true
                                font.pixelSize: 14
                                color: "#1d1d1f"
                            }
                            Item { Layout.fillWidth: true; width: parent.width - 240 }
                            Text {
                                anchors.right: parent.right
                                text: "Show All (64)"
                                font.family: sfTextMedium.name
                                font.pixelSize: 12
                                color: "#8e8e93"
                            }
                        }

                        Row {
                            spacing: 12

                            readonly property var landItems: [
                                { name: "Sequoia Sunrise", thumb: "Assets/thumb_sequoia_sunrise.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/Wallpaper.jpg" },
                                { name: "Sonoma Horizon ↓", thumb: "Assets/thumb_sonoma_horizon.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_sonoma_horizon.jpg" },
                                { name: "California's Temblor Range ↓", thumb: "Assets/thumb_temblor.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_temblor.jpg" },
                                { name: "Redwoods from Above ↓", thumb: "Assets/thumb_redwoods.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_redwoods.jpg" }
                            ]

                            Repeater {
                                model: parent.landItems

                                delegate: Column {
                                    spacing: 6

                                    Rectangle {
                                        width: 134
                                        height: 75
                                        radius: 8
                                        clip: true
                                        color: "#000000"
                                        border.color: sysProc.wallpaperName === modelData.name ? "#007aff" : (landMa.containsMouse ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(0, 0, 0, 0.12))
                                        border.width: sysProc.wallpaperName === modelData.name ? 2.5 : 1

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: sysProc.wallpaperName === modelData.name ? 1.5 : 0
                                            source: modelData.thumb
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                        }

                                        // Video / landscape badge
                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.margins: 4
                                            width: 16; height: 16; radius: 8
                                            color: Qt.rgba(0, 0, 0, 0.45)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "􀊄" // play glyph
                                                font.family: sfSymbols.name
                                                font.pixelSize: 8
                                                color: "#ffffff"
                                            }
                                        }

                                        MouseArea {
                                            id: landMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                sysProc.setWallpaper("file://" + modelData.wall, modelData.name)
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.name
                                        font.family: sfTextMedium.name
                                        font.pixelSize: 12
                                        color: "#1d1d1f"
                                        elide: Text.ElideRight
                                        width: 134
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }
                    }

                    // --- Category 3: Cityscape ---
                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            width: parent.width
                            Text {
                                text: "Cityscape"
                                font.family: sfDisplayBold.name
                                font.bold: true
                                font.pixelSize: 14
                                color: "#1d1d1f"
                            }
                            Item { Layout.fillWidth: true; width: parent.width - 240 }
                            Text {
                                anchors.right: parent.right
                                text: "Show All (30)"
                                font.family: sfTextMedium.name
                                font.pixelSize: 12
                                color: "#8e8e93"
                            }
                        }

                        Row {
                            spacing: 12

                            readonly property var cityItems: [
                                { name: "Dubai", thumb: "Assets/thumb_dubai.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_dubai.jpg" },
                                { name: "Los Angeles", thumb: "Assets/thumb_highways.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_highways.jpg" },
                                { name: "Sunset City", thumb: "Assets/thumb_sunset_city.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_sunset_city.jpg" },
                                { name: "Tokyo", thumb: "Assets/thumb_tokyo.png", wall: "/home/gg/SwiftDE/Library/DesktopPictures/wall_tokyo.jpg" }
                            ]

                            Repeater {
                                model: parent.cityItems

                                delegate: Column {
                                    spacing: 6

                                    Rectangle {
                                        width: 134
                                        height: 75
                                        radius: 8
                                        clip: true
                                        color: "#000000"
                                        border.color: sysProc.wallpaperName === modelData.name ? "#007aff" : (cityMa.containsMouse ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(0, 0, 0, 0.12))
                                        border.width: sysProc.wallpaperName === modelData.name ? 2.5 : 1

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: sysProc.wallpaperName === modelData.name ? 1.5 : 0
                                            source: modelData.thumb
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                        }

                                        MouseArea {
                                            id: cityMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                sysProc.setWallpaper("file://" + modelData.wall, modelData.name)
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.name
                                        font.family: sfTextMedium.name
                                        font.pixelSize: 12
                                        color: "#1d1d1f"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // TAB 2: DESKTOP & DOCK
            // ==========================================
            Flickable {
                visible: settingsWindow.currentTab === "desktop_dock"
                anchors.fill: parent
                anchors.topMargin: 52
                contentHeight: dockContent.height + 40
                clip: true

                Column {
                    id: dockContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 24
                    spacing: 16

                    // Dock Group Card
                    Rectangle {
                        width: parent.width
                        height: dockInnerCol.height + 28
                        radius: 10
                        color: "#ffffff"
                        border.color: Qt.rgba(0,0,0,0.1)

                        Column {
                            id: dockInnerCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 14
                            spacing: 14

                            Text {
                                text: "Dock"
                                font.family: sfDisplayBold.name
                                font.bold: true
                                font.pixelSize: 14
                                color: "#1d1d1f"
                            }

                            // Size Slider
                            Row {
                                width: parent.width
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Size:"; width: 140; font.family: sfTextMedium.name; font.pixelSize: 13 }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Small"; font.family: sfTextMedium.name; font.pixelSize: 11; color: "#8e8e93" }
                                Slider {
                                    id: sizeSlider
                                    width: 180
                                    from: 40; to: 88
                                    value: (sysProc.dockSettings && sysProc.dockSettings.size) ? sysProc.dockSettings.size : 60
                                    onMoved: sysProc.setDockSetting("size", Math.round(value))
                                }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Large"; font.family: sfTextMedium.name; font.pixelSize: 11; color: "#8e8e93" }
                            }

                            // Magnification toggle & slider
                            Row {
                                width: parent.width
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Magnification:"; width: 140; font.family: sfTextMedium.name; font.pixelSize: 13 }
                                CheckBox {
                                    id: magCheck
                                    text: ""
                                    checked: (sysProc.dockSettings && sysProc.dockSettings.magnification !== undefined) ? sysProc.dockSettings.magnification : true
                                    onToggled: sysProc.setDockSetting("magnification", checked)
                                }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Small"; font.family: sfTextMedium.name; font.pixelSize: 11; color: "#8e8e93"; opacity: magCheck.checked ? 1.0 : 0.4 }
                                Slider {
                                    id: magSlider
                                    width: 140
                                    enabled: magCheck.checked
                                    opacity: magCheck.checked ? 1.0 : 0.4
                                    from: 68; to: 120
                                    value: (sysProc.dockSettings && sysProc.dockSettings.maxSize) ? sysProc.dockSettings.maxSize : 92
                                    onMoved: sysProc.setDockSetting("maxSize", Math.round(value))
                                }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Large"; font.family: sfTextMedium.name; font.pixelSize: 11; color: "#8e8e93"; opacity: magCheck.checked ? 1.0 : 0.4 }
                            }

                            // Position on screen
                            Row {
                                width: parent.width
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Position on screen:"; width: 140; font.family: sfTextMedium.name; font.pixelSize: 13 }
                                Row {
                                    spacing: 4
                                    Repeater {
                                        model: ["Left", "Bottom", "Right"]
                                        Rectangle {
                                            width: 72; height: 26; radius: 5
                                            color: ((sysProc.dockSettings && sysProc.dockSettings.position) ? sysProc.dockSettings.position : "bottom") === modelData.toLowerCase() ? "#007aff" : "#f0f0f2"
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.family: sfTextMedium.name
                                                font.pixelSize: 12
                                                color: ((sysProc.dockSettings && sysProc.dockSettings.position) ? sysProc.dockSettings.position : "bottom") === modelData.toLowerCase() ? "#ffffff" : "#1d1d1f"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: sysProc.setDockSetting("position", modelData.toLowerCase())
                                            }
                                        }
                                    }
                                }
                            }

                            // Minimize windows effect
                            Row {
                                width: parent.width
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Minimize windows using:"; width: 160; font.family: sfTextMedium.name; font.pixelSize: 13 }
                                Rectangle {
                                    width: 140; height: 26; radius: 5; color: "#f0f0f2"; border.color: Qt.rgba(0,0,0,0.1)
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                                        text: "Genie effect ▾"
                                        font.family: sfTextMedium.name; font.pixelSize: 12; color: "#1d1d1f"
                                    }
                                }
                            }

                            // Automatically hide and show Dock
                            Row {
                                width: parent.width
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Automatically hide and show the Dock"; font.family: sfTextMedium.name; font.pixelSize: 13 }
                                Item { Layout.fillWidth: true; width: parent.width - 320 }
                                Rectangle {
                                    anchors.right: parent.right
                                    width: 38; height: 22; radius: 11
                                    color: hideMa.checked ? "#007aff" : "#e5e5ea"
                                    Rectangle {
                                        width: 18; height: 18; radius: 9; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter
                                        x: hideMa.checked ? 18 : 2
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }
                                    MouseArea {
                                        id: hideMa
                                        property bool checked: (sysProc.dockSettings && sysProc.dockSettings.autohide) ? sysProc.dockSettings.autohide : false
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { checked = !checked; sysProc.setDockSetting("autohide", checked) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // TAB 3: DISPLAYS
            // ==========================================
            Flickable {
                visible: settingsWindow.currentTab === "displays"
                anchors.fill: parent
                anchors.topMargin: 52
                contentHeight: dispCol.height + 40
                clip: true

                Column {
                    id: dispCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 24
                    spacing: 16

                    Rectangle {
                        width: parent.width
                        height: 180
                        radius: 10
                        color: "#ffffff"
                        border.color: Qt.rgba(0,0,0,0.1)

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle {
                                width: 140; height: 88; radius: 6; color: "#000000"; anchors.horizontalCenter: parent.horizontalCenter
                                border.color: "#333333"
                                Image {
                                    anchors.fill: parent
                                    source: sysProc.wallpaperUrl.length > 0 ? sysProc.wallpaperUrl : "Assets/hero_sequoia.png"
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                            Text {
                                text: "Built-in Display (1920 × 1080 @ 60Hz)"
                                font.family: sfDisplayBold.name; font.bold: true; font.pixelSize: 13; color: "#1d1d1f"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 120
                        radius: 10
                        color: "#ffffff"
                        border.color: Qt.rgba(0,0,0,0.1)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Row {
                                width: parent.width
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Brightness:"; width: 120; font.family: sfTextMedium.name; font.pixelSize: 13 }
                                Slider {
                                    width: 240
                                    from: 0.1; to: 1.0
                                    value: sysProc.brightness
                                    onMoved: sysProc.setBrightness(value)
                                }
                            }

                            Row {
                                width: parent.width
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Night Shift:"; width: 120; font.family: sfTextMedium.name; font.pixelSize: 13 }
                                Rectangle {
                                    width: 100; height: 26; radius: 5; color: "#f0f0f2"
                                    Text { anchors.centerIn: parent; text: "Schedule..."; font.family: sfTextMedium.name; font.pixelSize: 12 }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // TAB 4: SOUND
            // ==========================================
            Flickable {
                visible: settingsWindow.currentTab === "sound"
                anchors.fill: parent
                anchors.topMargin: 52
                contentHeight: soundCol.height + 40
                clip: true

                Column {
                    id: soundCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 24
                    spacing: 16

                    Rectangle {
                        width: parent.width
                        height: 160
                        radius: 10
                        color: "#ffffff"
                        border.color: Qt.rgba(0,0,0,0.1)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            Text { text: "Output Volume"; font.family: sfDisplayBold.name; font.bold: true; font.pixelSize: 14 }

                            Row {
                                width: parent.width
                                spacing: 10
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "􀊠"; font.family: sfSymbols.name; font.pixelSize: 14; color: "#8e8e93" }
                                Slider {
                                    id: volSlider
                                    width: 320
                                    from: 0.0; to: 1.0
                                    value: sysProc.volume
                                    onMoved: sysProc.setVolume(value)
                                }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "􀊩"; font.family: sfSymbols.name; font.pixelSize: 14; color: "#8e8e93" }
                            }

                            Row {
                                width: parent.width
                                spacing: 10
                                CheckBox {
                                    text: "Mute"
                                    checked: sysProc.muted
                                    onToggled: sysProc.setMuted(checked)
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // TAB 5: APPEARANCE
            // ==========================================
            Flickable {
                visible: settingsWindow.currentTab === "appearance"
                anchors.fill: parent
                anchors.topMargin: 52
                contentHeight: appCol.height + 40
                clip: true

                Column {
                    id: appCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 24
                    spacing: 16

                    Rectangle {
                        width: parent.width
                        height: 240
                        radius: 10
                        color: "#ffffff"
                        border.color: Qt.rgba(0,0,0,0.1)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16

                            Text { text: "Appearance"; font.family: sfDisplayBold.name; font.bold: true; font.pixelSize: 14 }

                            Row {
                                spacing: 16
                                readonly property var modes: [
                                    { id: "default", name: "Light", color: "#f5f5f7", border: "#e0e0e0" },
                                    { id: "prefer-dark", name: "Dark", color: "#2c2c2e", border: "#444446" }
                                ]
                                Repeater {
                                    model: parent.modes
                                    Column {
                                        spacing: 6
                                        Rectangle {
                                            width: 100; height: 65; radius: 8
                                            color: modelData.color
                                            border.color: sysProc.colorScheme === modelData.id ? "#007aff" : modelData.border
                                            border.width: sysProc.colorScheme === modelData.id ? 2.5 : 1
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: sysProc.setColorScheme(modelData.id)
                                            }
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.name
                                            font.family: sfTextMedium.name; font.pixelSize: 12
                                        }
                                    }
                                }
                            }

                            // Accent Color Row
                            Text { text: "Accent color"; font.family: sfDisplayBold.name; font.bold: true; font.pixelSize: 13 }
                            Row {
                                spacing: 10
                                readonly property var colors: ["#007aff", "#af52de", "#ff2d55", "#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#8e8e93"]
                                Repeater {
                                    model: parent.colors
                                    Rectangle {
                                        width: 20; height: 20; radius: 10; color: modelData
                                        border.color: sysProc.accentColor === modelData ? "#000000" : "transparent"
                                        border.width: 2
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: sysProc.setAccentColor(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // TAB 6: USERS & GROUPS
            // ==========================================
            Flickable {
                visible: settingsWindow.currentTab === "users"
                anchors.fill: parent
                anchors.topMargin: 52
                contentHeight: usersCol.height + 40
                clip: true

                Column {
                    id: usersCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 24
                    spacing: 16

                    Rectangle {
                        width: parent.width
                        height: 100
                        radius: 10
                        color: "#ffffff"
                        border.color: Qt.rgba(0,0,0,0.1)

                        Row {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            Rectangle {
                                width: 56; height: 56; radius: 28; color: "#007aff"
                                Text { anchors.centerIn: parent; text: "􀉭"; font.family: sfSymbols.name; font.pixelSize: 28; color: "#ffffff" }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Text { text: sysProc.userName().length > 0 ? sysProc.userName() : "gg"; font.family: sfDisplayBold.name; font.bold: true; font.pixelSize: 15 }
                                Text { text: "Administrator"; font.family: sfTextMedium.name; font.pixelSize: 12; color: "#8e8e93" }
                            }
                        }
                    }
                }
            }

            // Generic fallback view for remaining tabs
            Flickable {
                visible: ["wallpaper", "desktop_dock", "displays", "sound", "appearance", "users"].indexOf(settingsWindow.currentTab) === -1
                anchors.fill: parent
                anchors.topMargin: 52
                contentHeight: 300
                clip: true

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        width: 64; height: 64; radius: 14; color: "#007aff"; anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "􀍲"; font.family: sfSymbols.name; font.pixelSize: 32; color: "#ffffff" }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: settingsWindow.currentTab.charAt(0).toUpperCase() + settingsWindow.currentTab.slice(1)
                        font.family: sfDisplayBold.name; font.bold: true; font.pixelSize: 18; color: "#1d1d1f"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Configured and active in SwiftDE."
                        font.family: sfTextMedium.name; font.pixelSize: 13; color: "#8e8e93"
                    }
                }
            }
        }
    }
}
