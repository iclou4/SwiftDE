import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import SwiftDE 1.0

Window {
    id: launchpadWindow
    visible: false
    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    color: "transparent"
    flags: Qt.FramelessWindowHint

    SysProc { id: sysProc }

    FontLoader { id: sfDisplayBold; source: "../../../../../../Library/Fonts/SF-Pro-Display-Bold.otf" }
    FontLoader { id: sfDisplayMedium; source: "../../../../../../Library/Fonts/SF-Pro-Display-Medium.otf" }
    FontLoader { id: sfTextMedium; source: "../../../../../../Library/Fonts/SF-Pro-Text-Medium.otf" }
    FontLoader { id: sfTextBold; source: "../../../../../../Library/Fonts/SF-Pro-Text-Bold.otf" }
    FontLoader { id: sfSymbols; source: "../../../../../../Library/Fonts/SF-Symbols-6.otf" }

    property bool isClosing: false

    function closeLaunchpad() {
        if (folderPopupOpen) {
            folderPopupOpen = false
            return
        }
        if (isClosing) return
        isClosing = true
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: 160
        onTriggered: Qt.quit()
    }

    // Capture Escape key to close search, folder, or launchpad
    Item {
        focus: true
        Keys.onEscapePressed: {
            if (folderPopupOpen) folderPopupOpen = false
            else if (searchInput.text.length > 0) searchInput.text = ""
            else launchpadWindow.closeLaunchpad()
        }
    }

    // --- Blurred Wallpaper Background (macOS Sequoia frosted glass) ---
    Image {
        id: bgWall
        width: 480
        height: 270
        source: sysProc.wallpaperUrl.length > 0 ? sysProc.wallpaperUrl : "../../../../../../Library/DesktopPictures/Wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 480
        sourceSize.height: 270
        visible: false
        cache: true
    }

    Item {
        anchors.fill: parent
        clip: true
        FastBlur {
            id: wallBlur
            width: 480
            height: 270
            source: bgWall
            radius: 20
            scale: parent.width / 480
            transformOrigin: Item.TopLeft
        }
    }

    // Frosted dark acrylic tint
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.32)
    }

    // Background Click Area (dismisses Launchpad when clicking outside)
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (folderPopupOpen) folderPopupOpen = false
            else launchpadWindow.closeLaunchpad()
        }
    }

    // Layout model & persistence
    property var appsModel: []
    property bool folderPopupOpen: false
    property var activeFolder: null
    property int activeFolderIndex: -1

    // Drag-and-drop state
    property int draggedIndex: -1
    property var draggedItem: null
    property real dragGlobalX: 0
    property real dragGlobalY: 0
    property int hoverFolderTarget: -1
    property int hoverReorderTarget: -1

    Component.onCompleted: {
        loadLayout()
    }

    function defaultLayout() {
        return [
            // Row 0
            { name: "App Store", icon: "App Store.png", command: "gnome-software || snap-store || true", isFolder: false },
            { name: "Safari", icon: "Safari.png", command: "google-chrome || chromium || firefox || true", isFolder: false },
            { name: "Mail", icon: "Mail.png", command: "thunderbird || true", isFolder: false },
            { name: "Contacts", icon: "Contacts.png", command: "gnome-contacts || true", isFolder: false },
            { name: "Calendar", icon: "Calendar_Blank.png", command: "gnome-calendar || true", isFolder: false, isCalendar: true },
            { name: "Reminders", icon: "Reminders.png", command: "gnome-todo || true", isFolder: false },
            { name: "Notes", icon: "Notes.png", command: "gnome-text-editor || gedit || true", isFolder: false },

            // Row 1
            { name: "FaceTime", icon: "FaceTime.png", command: "cheese || true", isFolder: false },
            { name: "Messages", icon: "Messages.png", command: "telegram-desktop || true", isFolder: false },
            { name: "Maps", icon: "Maps.png", command: "gnome-maps || true", isFolder: false },
            { name: "Find My", icon: "Find My.png", command: "google-chrome https://www.icloud.com/find || firefox https://www.icloud.com/find || true", isFolder: false },
            { name: "Photo Booth", icon: "Photo Booth.png", command: "cheese || true", isFolder: false },
            { name: "Photos", icon: "Photos.png", command: "eog || loupe || gthumb || true", isFolder: false },
            { name: "Music", icon: "Music.png", command: "rhythmbox || spotify || true", isFolder: false },

            // Row 2
            { name: "Podcasts", icon: "Podcasts.png", command: "rhythmbox || true", isFolder: false },
            { name: "TV", icon: "TV.png", command: "totem || vlc || true", isFolder: false },
            { name: "Voice Memos", icon: "Voice Memos.png", command: "gnome-sound-recorder || true", isFolder: false },
            { name: "Weather", icon: "Weather.png", command: "gnome-weather || true", isFolder: false },
            { name: "News", icon: "News.png", command: "liferea || true", isFolder: false },
            { name: "Stocks", icon: "Stocks.png", command: "gnome-finance || true", isFolder: false },
            { name: "Books", icon: "Books.png", command: "evince || true", isFolder: false },

            // Row 3
            { name: "Clock", icon: "Clock.png", command: "gnome-clocks || true", isFolder: false },
            { name: "Calculator", icon: "Calculator.png", command: "gnome-calculator || true", isFolder: false },
            { name: "Freeform", icon: "Freeform.png", command: "libreoffice --draw || true", isFolder: false },
            { name: "Home", icon: "Home.png", command: "nautilus ~ || true", isFolder: false },
            { name: "Siri", icon: "siri.png", command: "true", isFolder: false },
            { name: "System Settings", icon: "Settings.png", command: "gnome-control-center || true", isFolder: false },
            {
                name: "Other",
                isFolder: true,
                items: [
                    { name: "Terminal", icon: "Terminal.png", command: "gnome-terminal || xterm || true" },
                    { name: "Activity Monitor", icon: "Activity Monitor.png", command: "gnome-system-monitor || gnome-terminal -e top || true" },
                    { name: "Disk Utility", icon: "Disk Utility.png", command: "gnome-disks || true" },
                    { name: "TextEdit", icon: "TextEdit.png", command: "gnome-text-editor || gedit || true" },
                    { name: "Screenshot", icon: "Screenshot.png", command: "gnome-screenshot || grim /tmp/shot.png || true" },
                    { name: "Passwords", icon: "Keychain Access.png", command: "seahorse || true" },
                    { name: "Console", icon: "Console.png", command: "gnome-logs || true" },
                    { name: "System Information", icon: "System Information.png", command: "gnome-control-center info-overview || true" },
                    { name: "Font Book", icon: "Font Book.png", command: "gnome-font-viewer || gnome-characters || true" }
                ]
            }
        ]
    }

    function loadLayout() {
        var jsonStr = sysProc.loadLaunchpadLayout()
        if (jsonStr && jsonStr.length > 0) {
            try {
                var parsed = JSON.parse(jsonStr)
                if (Array.isArray(parsed) && parsed.length > 0) {
                    appsModel = parsed
                    return
                }
            } catch (e) {
                console.log("Error loading layout:", e)
            }
        }
        appsModel = defaultLayout()
    }

    function saveLayout() {
        sysProc.saveLaunchpadLayout(JSON.stringify(appsModel))
    }

    function renameFolder(folderIndex, newName) {
        if (folderIndex < 0 || folderIndex >= appsModel.length) return
        var next = []
        for (var i = 0; i < appsModel.length; ++i) {
            if (i === folderIndex) {
                var f = appsModel[i]
                f.name = newName
                next.push(f)
            } else {
                next.push(appsModel[i])
            }
        }
        appsModel = next
        launchpadWindow.saveLayout()
        if (activeFolder && activeFolderIndex === folderIndex) {
            activeFolder.name = newName
        }
    }

    // Main Animated Container for smooth Zoom/Fade
    Item {
        id: mainContainer
        anchors.fill: parent
        opacity: isClosing ? 0.0 : 1.0
        scale: isClosing ? 1.06 : 1.0

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        // --- Top Search Field (macOS Sequoia 1:1) ---
        Rectangle {
            id: searchBar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(launchpadWindow.height * 0.038)
            width: Math.round(Math.min(260, launchpadWindow.width * 0.16))
            height: 28
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.28)
            border.color: searchInput.activeFocus ? "#007aff" : Qt.rgba(1, 1, 1, 0.22)
            border.width: searchInput.activeFocus ? 1.5 : 0.8
            z: 20

            Row {
                anchors.centerIn: parent
                spacing: 6
                visible: !searchInput.text && !searchInput.activeFocus

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "􀊫"
                    font.family: sfSymbols.name
                    font.pixelSize: 12
                    color: Qt.rgba(1, 1, 1, 0.65)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search"
                    font.family: sfTextMedium.name
                    font.pixelSize: 12
                    color: Qt.rgba(1, 1, 1, 0.65)
                }
            }

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 26
                verticalAlignment: TextInput.AlignVCenter
                font.family: sfTextMedium.name
                font.pixelSize: 12
                color: "#ffffff"
                selectByMouse: true
                selectionColor: "#007aff"

                Keys.onEscapePressed: {
                    if (text.length > 0) text = ""
                    else launchpadWindow.closeLaunchpad()
                }
            }

            // Clear search button
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                text: "􀁡"
                font.family: sfSymbols.name
                font.pixelSize: 12
                color: Qt.rgba(1, 1, 1, 0.65)
                visible: searchInput.text.length > 0

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchInput.text = ""
                        searchInput.forceActiveFocus()
                    }
                }
            }
        }

        // --- 7x4 Apps Grid (1 to 1 geometry & icon sizes matching macOS Sequoia) ---
        // Exactly matches reference icon size ratio: ~90px on 914p, 106px on 1080p
        readonly property real iconSize: Math.max(72, Math.round(launchpadWindow.height * 0.098))
        readonly property real row0Center: Math.round(launchpadWindow.height * 0.14)
        readonly property real rowSpacing: Math.round(launchpadWindow.height * 0.155)

        Item {
            id: gridLayer
            anchors.fill: parent

            Repeater {
                model: appsModel

                delegate: Item {
                    id: appItem
                    property int itemRow: Math.floor(index / 7)
                    property int itemCol: index % 7

                    property real colCenterX: Math.round((itemCol + 1) * launchpadWindow.width / 8)
                    property real rowCenterY: mainContainer.row0Center + itemRow * mainContainer.rowSpacing

                    x: Math.round(colCenterX - width / 2)
                    y: Math.round(rowCenterY - mainContainer.iconSize / 2)
                    width: 130
                    height: mainContainer.iconSize + 28

                    visible: !searchInput.text || (modelData.name && modelData.name.toLowerCase().indexOf(searchInput.text.toLowerCase()) !== -1)
                    opacity: draggedIndex === index ? 0.25 : 1.0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            id: iconWrap
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: mainContainer.iconSize
                            height: mainContainer.iconSize
                            scale: itemMa.pressed ? 0.93 : 1.0
                            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                            // Hover target highlight when dragging another app over this item to combine into a folder
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 16
                                height: parent.height + 16
                                radius: (parent.width + 16) * 0.24
                                color: Qt.rgba(1, 1, 1, 0.28)
                                border.color: "#ffffff"
                                border.width: 2
                                visible: hoverFolderTarget === index && draggedIndex !== index
                                z: 10
                            }

                            // Regular Single App Icon
                            Image {
                                anchors.fill: parent
                                source: (!modelData.isFolder && modelData.icon) ? ("../../../../../../Library/Application/Icons/png/" + modelData.icon) : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                visible: !modelData.isFolder
                            }

                            // Dynamic Live Calendar Overlay
                            Item {
                                anchors.fill: parent
                                visible: !modelData.isFolder && modelData.isCalendar === true

                                // Red banner month text
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: Math.round(mainContainer.iconSize * 0.10)
                                    text: {
                                        var m = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
                                        return m[new Date().getMonth()]
                                    }
                                    font.family: sfTextBold.name
                                    font.bold: true
                                    font.pixelSize: Math.max(9, Math.round(mainContainer.iconSize * 0.15))
                                    color: "#ffffff"
                                }

                                // White body day text
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: Math.round(mainContainer.iconSize * 0.38)
                                    text: "" + new Date().getDate()
                                    font.family: sfDisplayMedium.name
                                    font.weight: Font.Normal
                                    font.pixelSize: Math.round(mainContainer.iconSize * 0.44)
                                    color: "#1d1d1f"
                                }
                            }

                            // Folder Squircle Tile with 3x3 Mini-Apps Grid (macOS 1:1)
                            Rectangle {
                                anchors.fill: parent
                                radius: mainContainer.iconSize * 0.22
                                color: Qt.rgba(1, 1, 1, 0.24)
                                border.color: Qt.rgba(1, 1, 1, 0.38)
                                border.width: 0.8
                                visible: modelData.isFolder === true

                                Grid {
                                    anchors.centerIn: parent
                                    columns: 3
                                    spacing: Math.max(2, Math.round(mainContainer.iconSize * 0.035))

                                    readonly property real miniSize: Math.floor((mainContainer.iconSize - 20) / 3)

                                    Repeater {
                                        model: modelData.items ? modelData.items.slice(0, 9) : []

                                        delegate: Item {
                                            width: parent.miniSize
                                            height: parent.miniSize

                                            Image {
                                                anchors.fill: parent
                                                source: "../../../../../../Library/Application/Icons/png/" + modelData.icon
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                mipmap: true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // App Label (SF Pro Text Medium, white with drop shadow)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name || ""
                            font.family: sfTextMedium.name
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: "#ffffff"
                            style: Text.Outline
                            styleColor: Qt.rgba(0, 0, 0, 0.45)
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        property real pressSceneX: 0
                        property real pressSceneY: 0
                        property bool isDragStarted: false

                        onPressed: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                var pt = appItem.mapToItem(launchpadWindow.contentItem, mouse.x, mouse.y)
                                pressSceneX = pt.x
                                pressSceneY = pt.y
                                isDragStarted = false
                            }
                        }

                        onPositionChanged: (mouse) => {
                            if (mouse.buttons & Qt.LeftButton) {
                                var pt = appItem.mapToItem(launchpadWindow.contentItem, mouse.x, mouse.y)
                                var dx = Math.abs(pt.x - pressSceneX)
                                var dy = Math.abs(pt.y - pressSceneY)
                                if ((dx > 12 || dy > 12) && !isDragStarted) {
                                    isDragStarted = true
                                    draggedIndex = index
                                    draggedItem = modelData
                                }
                                if (isDragStarted) {
                                    dragGlobalX = pt.x
                                    dragGlobalY = pt.y

                                    // Find target item under pointer
                                    var foundFolder = -1
                                    var foundReorder = -1
                                    for (var t = 0; t < appsModel.length; ++t) {
                                        if (t === index) continue
                                        var tCol = t % 7
                                        var tRow = Math.floor(t / 7)
                                        var tX = Math.round((tCol + 1) * launchpadWindow.width / 8)
                                        var tY = mainContainer.row0Center + tRow * mainContainer.rowSpacing
                                        var dist = Math.hypot(pt.x - tX, pt.y - tY)
                                        if (dist < mainContainer.iconSize * 0.46) {
                                            foundFolder = t
                                            break
                                        } else if (dist < mainContainer.iconSize * 0.85) {
                                            foundReorder = t
                                        }
                                    }
                                    hoverFolderTarget = foundFolder
                                    hoverReorderTarget = (foundFolder === -1) ? foundReorder : -1
                                }
                            }
                        }

                        onReleased: (mouse) => {
                            if (isDragStarted) {
                                if (hoverFolderTarget >= 0 && hoverFolderTarget !== draggedIndex) {
                                    var target = appsModel[hoverFolderTarget]
                                    var nextModel = []
                                    if (target.isFolder) {
                                        // Add to existing folder
                                        target.items.push(draggedItem)
                                        for (var i = 0; i < appsModel.length; ++i) {
                                            if (i !== draggedIndex) nextModel.push(appsModel[i])
                                        }
                                    } else {
                                        // Create new folder combining both apps
                                        var folder = {
                                            isFolder: true,
                                            name: "Folder",
                                            items: [target, draggedItem]
                                        }
                                        for (var k = 0; k < appsModel.length; ++k) {
                                            if (k === hoverFolderTarget) nextModel.push(folder)
                                            else if (k !== draggedIndex) nextModel.push(appsModel[k])
                                        }
                                    }
                                    appsModel = nextModel
                                    launchpadWindow.saveLayout()
                                } else if (hoverReorderTarget >= 0 && hoverReorderTarget !== draggedIndex) {
                                    // Reorder items
                                    var reordered = []
                                    for (var r = 0; r < appsModel.length; ++r) {
                                        if (r === draggedIndex) continue
                                        if (r === hoverReorderTarget) {
                                            if (draggedIndex > hoverReorderTarget) {
                                                reordered.push(draggedItem)
                                                reordered.push(appsModel[r])
                                            } else {
                                                reordered.push(appsModel[r])
                                                reordered.push(draggedItem)
                                            }
                                        } else {
                                            reordered.push(appsModel[r])
                                        }
                                    }
                                    appsModel = reordered
                                    launchpadWindow.saveLayout()
                                }

                                isDragStarted = false
                                draggedIndex = -1
                                draggedItem = null
                                hoverFolderTarget = -1
                                hoverReorderTarget = -1
                            } else if (mouse.button === Qt.LeftButton) {
                                if (modelData.isFolder) {
                                    // Open Folder Overlay
                                    activeFolder = modelData
                                    activeFolderIndex = index
                                    folderPopupOpen = true
                                } else {
                                    sysProc.launch(modelData.command)
                                    launchpadWindow.closeLaunchpad()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Floating Dragged Icon visual
        Item {
            visible: draggedIndex !== -1 && draggedItem !== null
            x: Math.round(dragGlobalX - width / 2)
            y: Math.round(dragGlobalY - height / 2)
            width: mainContainer.iconSize
            height: mainContainer.iconSize
            z: 999
            scale: 1.08

            Image {
                anchors.fill: parent
                source: (draggedItem && !draggedItem.isFolder && draggedItem.icon) ? ("../../../../../../Library/Application/Icons/png/" + draggedItem.icon) : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                visible: draggedItem && !draggedItem.isFolder
            }

            Rectangle {
                anchors.fill: parent
                radius: mainContainer.iconSize * 0.22
                color: Qt.rgba(1, 1, 1, 0.24)
                border.color: Qt.rgba(1, 1, 1, 0.38)
                border.width: 0.8
                visible: draggedItem && draggedItem.isFolder === true
            }
        }

        // --- macOS Sequoia Authentic Folder Overlay Popup ---
        Item {
            id: folderOverlay
            anchors.fill: parent
            visible: folderPopupOpen && activeFolder !== null
            z: 500

            // Dim backdrop
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.42)

                MouseArea {
                    anchors.fill: parent
                    onClicked: folderPopupOpen = false
                }
            }

            // Central Glass Card
            Rectangle {
                id: folderCard
                anchors.centerIn: parent
                width: Math.max(500, Math.min(680, parent.width * 0.44))
                height: Math.max(380, Math.min(540, parent.height * 0.52))
                radius: 24
                color: Qt.rgba(0.18, 0.18, 0.22, 0.78)
                border.color: Qt.rgba(1, 1, 1, 0.24)
                border.width: 1

                // Catch clicks inside card so it doesn't dismiss
                MouseArea {
                    anchors.fill: parent
                }

                // Top Editable Folder Title (renaming 1:1)
                Item {
                    id: titleArea
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 48
                    height: 38

                    TextInput {
                        id: folderTitleInput
                        anchors.centerIn: parent
                        text: activeFolder ? activeFolder.name : ""
                        font.family: sfDisplayBold.name
                        font.bold: true
                        font.pixelSize: 22
                        color: "#ffffff"
                        horizontalAlignment: TextInput.AlignHCenter
                        selectByMouse: true
                        selectionColor: "#007aff"
                        maximumLength: 30

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: -3
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1.5
                            color: folderTitleInput.activeFocus ? "#007aff" : "transparent"
                        }

                        onEditingFinished: {
                            if (activeFolder && text.trim().length > 0) {
                                renameFolder(activeFolderIndex, text.trim())
                            }
                        }
                    }
                }

                // Grid of apps inside the folder
                Grid {
                    id: folderAppsGrid
                    anchors.top: titleArea.bottom
                    anchors.topMargin: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 3
                    spacing: 24

                    Repeater {
                        model: (activeFolder && activeFolder.items) ? activeFolder.items : []

                        delegate: Item {
                            width: 100
                            height: 110

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Item {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 70
                                    height: 70
                                    scale: fAppMa.pressed ? 0.92 : (fAppMa.containsMouse ? 1.05 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                                    Image {
                                        anchors.fill: parent
                                        source: "../../../../../../Library/Application/Icons/png/" + modelData.icon
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.name || ""
                                    font.family: sfTextMedium.name
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: "#ffffff"
                                    style: Text.Outline
                                    styleColor: Qt.rgba(0, 0, 0, 0.45)
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            MouseArea {
                                id: fAppMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                property real fPressX: 0
                                property real fPressY: 0
                                property bool fIsDragging: false

                                onPressed: (mouse) => {
                                    var pt = mapToItem(folderCard, mouse.x, mouse.y)
                                    fPressX = pt.x
                                    fPressY = pt.y
                                    fIsDragging = false
                                }

                                onPositionChanged: (mouse) => {
                                    if (mouse.buttons & Qt.LeftButton) {
                                        var pt = mapToItem(folderCard, mouse.x, mouse.y)
                                        if (Math.hypot(pt.x - fPressX, pt.y - fPressY) > 14) {
                                            fIsDragging = true
                                        }
                                    }
                                }

                                onReleased: (mouse) => {
                                    if (fIsDragging) {
                                        var pt = mapToItem(folderCard, mouse.x, mouse.y)
                                        // If dragged outside folder card, move app out of folder to main grid
                                        var outside = (pt.x < 0 || pt.x > folderCard.width || pt.y < 0 || pt.y > folderCard.height)
                                        if (outside && activeFolder) {
                                            var appToMove = activeFolder.items[index]
                                            activeFolder.items.splice(index, 1)

                                            // If folder has 1 or 0 items left, dissolve folder
                                            var nextApps = []
                                            for (var a = 0; a < appsModel.length; ++a) {
                                                if (a === activeFolderIndex) {
                                                    if (activeFolder.items.length === 1) {
                                                        nextApps.push(activeFolder.items[0])
                                                    } else if (activeFolder.items.length > 1) {
                                                        nextApps.push(activeFolder)
                                                    }
                                                } else {
                                                    nextApps.push(appsModel[a])
                                                }
                                            }
                                            nextApps.push(appToMove)
                                            appsModel = nextApps
                                            launchpadWindow.saveLayout()
                                            folderPopupOpen = false
                                        }
                                        fIsDragging = false
                                    } else {
                                        sysProc.launch(modelData.command)
                                        folderPopupOpen = false
                                        launchpadWindow.closeLaunchpad()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
