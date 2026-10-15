import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import SwiftDE 1.0

ApplicationWindow {
    id: dockWindow
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    SysProc { id: sysProc }

    Timer {
        interval: 2500; running: true; repeat: false
        onTriggered: console.log("DOCKDBG win=" + dockWindow.width + "x" + dockWindow.height
            + " pill=" + dockPill.width + "x" + dockPill.height + " @" + dockPill.x + "," + dockPill.y
            + " row=" + contentRow.width + "x" + contentRow.height
            + " items=" + dockWindow.dockItems.length
            + " isDark=" + dockWindow.isDark
            + " locked=" + sysProc.lockScreenActive
            + " op=" + dockWindow.opacity
            + " vis=" + dockWindow.visible)
    }

    // The Dock must never be visible on the lockscreen: hide it entirely while locked
    opacity: sysProc.lockScreenActive ? 0.0 : 1.0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // Screen dimensions
    width: Screen.width > 0 ? Screen.width : 1920
    // Ample headroom so magnified icons and tooltips NEVER get cut off at the top
    height: (contextMenuOpen || separatorMenuOpen || draggingItem !== null) ? 380 : 180

    // Configuration
    property bool magnificationEnabled: (sysProc.dockSettings && sysProc.dockSettings.magnification !== undefined) ? sysProc.dockSettings.magnification : true
    property bool autoHideEnabled: (sysProc.dockSettings && sysProc.dockSettings.autohide !== undefined) ? sysProc.dockSettings.autohide : false
    property string dockPosition: (sysProc.dockSettings && sysProc.dockSettings.position) ? sysProc.dockSettings.position : "bottom"
    property string minimizeEffect: "genie"

    readonly property bool isDark: sysProc.isDark

    // Theme colors for Light & Dark mode
    readonly property color menuBgColor: isDark ? Qt.rgba(0.16, 0.16, 0.18, 0.88) : Qt.rgba(0.94, 0.94, 0.93, 0.88)
    readonly property color menuBorderColor: isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.14)
    readonly property color menuInnerHighlight: isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.65)
    readonly property color menuTextColor: isDark ? "#f5f5f7" : "#1d1d1f"
    readonly property color menuSeparatorColor: isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color tooltipBgColor: isDark ? Qt.rgba(0.18, 0.18, 0.20, 0.92) : Qt.rgba(0.96, 0.96, 0.96, 0.92)
    readonly property color tooltipBorderColor: isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.16)
    readonly property color tooltipTextColor: isDark ? "#f5f5f7" : "#1d1d1f"

    // Magnification tracking: buttery smooth entry animation and cursor gliding
    property bool isMouseInDock: false
    readonly property bool isMagnifying: magnificationEnabled && isMouseInDock && !draggingItem && !contextMenuOpen && !separatorMenuOpen
    property real magProgress: isMagnifying ? 1.0 : 0.0

    Behavior on magProgress {
        NumberAnimation {
            duration: dockWindow.isMouseInDock ? 180 : 160
            easing.type: Easing.OutCubic
        }
    }

    property real mouseScreenX: -1

    // Drag-to-remove state
    property var draggingItem: null
    property int draggingIndex: -1
    property real dragGlobalX: 0
    property real dragGlobalY: 0
    property bool showRemovePrompt: false

    // Context menu states
    property bool contextMenuOpen: false
    property real contextMenuX: 0
    property var contextMenuTargetItem: null
    property int contextMenuTargetIndex: -1
    property bool showOptionsSubmenu: false

    property bool separatorMenuOpen: false
    property real separatorMenuX: 0
    property bool showPositionSubmenu: false
    property bool showMinimiseSubmenu: false

    // macOS Dock proportions: 1:1 with Apple Design Resources (macOS Sonoma / Sequoia)
    readonly property real baseIconSize: 54
    readonly property real maxIconSize: 96
    readonly property real iconStretch: 1.0
    readonly property real baseIconWidth: Math.round(baseIconSize * iconStretch)
    readonly property real effectRadius: 210
    readonly property real itemSpacing: 10
    readonly property real pillHeight: 76
    readonly property real pillRadius: 24
    readonly property real pillPaddingH: 14

    // Total resting width of content row
    readonly property real restingAppsWidth: dockItems.length * (baseIconWidth + itemSpacing)
    readonly property real restingSeparatorWidth: 25
    readonly property real restingRightWidth: rightItems.length * (baseIconWidth + itemSpacing)
    readonly property real totalRestingWidth: restingAppsWidth + restingSeparatorWidth + restingRightWidth
    readonly property real restingPillWidth: totalRestingWidth + pillPaddingH * 2
    readonly property real restingPillLeft: Math.round((dockWindow.width - restingPillWidth) / 2)

    // Pinned Applications (Finder is ALWAYS #1 and cannot be unpinned)
    property var dockItems: [
        { id: "finder", name: "Finder", icon: "Finder.png", isRunning: true, canUnpin: false, command: "nautilus ~ || xdg-open ~ || true" },
        { id: "launchpad", name: "Launchpad", icon: "Launchpad.png", isRunning: false, canUnpin: true, command: "launchpad" },
        { id: "safari", name: "Safari", icon: "Safari.png", isRunning: false, canUnpin: true, command: "google-chrome || chromium || firefox || true" },
        { id: "messages", name: "Messages", icon: "Messages.png", isRunning: false, canUnpin: true, command: "telegram-desktop || true" },
        { id: "mail", name: "Mail", icon: "Mail.png", isRunning: false, canUnpin: true, command: "thunderbird || true" },
        { id: "maps", name: "Maps", icon: "Maps.png", isRunning: false, canUnpin: true, command: "gnome-maps || true" },
        { id: "photos", name: "Photos", icon: "Photos.png", isRunning: false, canUnpin: true, command: "eog || loupe || gthumb || true" },
        { id: "facetime", name: "FaceTime", icon: "FaceTime.png", isRunning: false, canUnpin: true, command: "cheese || true" },
        { id: "calendar", name: "Calendar", icon: "Calendar_Blank.png", isRunning: false, canUnpin: true, command: "gnome-calendar || true", isCalendar: true },
        { id: "contacts", name: "Contacts", icon: "Contacts.png", isRunning: false, canUnpin: true, command: "gnome-contacts || true" },
        { id: "reminders", name: "Reminders", icon: "Reminders.png", isRunning: false, canUnpin: true, command: "gnome-todo || true" },
        { id: "notes", name: "Notes", icon: "Notes.png", isRunning: false, canUnpin: true, command: "gnome-text-editor || gedit || true" },
        { id: "freeform", name: "Freeform", icon: "Freeform.png", isRunning: false, canUnpin: true, command: "libreoffice --draw || true" },
        { id: "tv", name: "TV", icon: "TV.png", isRunning: false, canUnpin: true, command: "totem || vlc || true" },
        { id: "music", name: "Music", icon: "Music.png", isRunning: false, canUnpin: true, command: "rhythmbox || true" },
        { id: "news", name: "News", icon: "News.png", isRunning: false, canUnpin: true, command: "liferea || true" },
        { id: "appstore", name: "App Store", icon: "App Store.png", isRunning: false, canUnpin: true, command: "gnome-software || true" },
        { id: "settings", name: "System Settings", icon: "Settings.png", isRunning: false, canUnpin: true, command: "gnome-control-center || true" }
    ]

    // Right-side items: Folder for Downloads, Trash
    property var rightItems: [
        { id: "downloads", name: "Downloads", icon: "Downloads.png", isRunning: false, canUnpin: true, command: "nautilus ~/Downloads || true", isFolder: true },
        { id: "trash", name: "Trash", icon: "Trash Empty.png", isRunning: false, canUnpin: false, command: "nautilus trash:/// || true", isTrash: true }
    ]

    // Continuous mathematical size computation driven by magProgress and mouseScreenX
    function computeSizeForRestingX(x0) {
        if (magProgress <= 0.001 || mouseScreenX < 0) return baseIconSize
        var dist = Math.abs(mouseScreenX - x0)
        if (dist >= effectRadius) return baseIconSize
        var factor = (Math.cos(dist / effectRadius * Math.PI) + 1.0) / 2.0
        return Math.round(baseIconSize + (maxIconSize - baseIconSize) * factor * magProgress)
    }

    // Dismiss active menus
    function closeAllMenus() {
        contextMenuOpen = false
        separatorMenuOpen = false
        showOptionsSubmenu = false
        showPositionSubmenu = false
        showMinimiseSubmenu = false
    }

    // Unpin item logic (Finder at index 0 can NEVER be unpinned)
    function unpinItem(index) {
        if (index <= 0 || index >= dockItems.length) return
        var next = []
        for (var i = 0; i < dockItems.length; ++i) {
            if (i !== index) next.push(dockItems[i])
        }
        dockItems = next
        closeAllMenus()
    }

    // Launch app command
    function launchItem(item) {
        console.log("launchItem called for:", item ? item.id : "null")
        if (!item) return
        closeAllMenus()
        if (item.id === "launchpad") {
            sysProc.toggleLaunchpad()
            return
        }
        if (item.command) {
            sysProc.launch(item.command)
        }
    }

    // Desktop right-click / left-click integration for empty space around the dock
    MouseArea {
        anchors.fill: parent
        z: 2
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPositionChanged: (mouse) => {
            var pt = mapToItem(dockPill, mouse.x, mouse.y)
            var inPill = (pt.x >= 0 && pt.x <= dockPill.width && pt.y >= -15 && pt.y <= dockPill.height)
            if (!inPill && dockWindow.isMouseInDock) {
                dockWindow.handlePointerExit()
            }
        }

        onExited: {
            dockWindow.handlePointerExit()
        }

        onPressed: (mouse) => {
            var pt = mapToItem(dockPill, mouse.x, mouse.y)
            var inPill = (pt.x >= 0 && pt.x <= dockPill.width && pt.y >= 0 && pt.y <= dockPill.height)
            if (!inPill) {
                if (mouse.button === Qt.RightButton) {
                    var screenPt = mapToItem(dockWindow.contentItem, mouse.x, mouse.y)
                    var screenH = Screen.height > 0 ? Screen.height : 1080
                    var screenY = screenH - dockWindow.height + screenPt.y
                    sysProc.showDesktopContextMenu(screenPt.x, screenY)
                } else {
                    dockWindow.closeAllMenus()
                    sysProc.unfocusAll()
                }
            }
        }
    }

    // Backdrop click catcher to dismiss menus
    MouseArea {
        anchors.fill: parent
        z: 30
        visible: contextMenuOpen || separatorMenuOpen
        onClicked: closeAllMenus()
    }

    // Bottom edge proximity sensor for Auto-Hide
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 4
        z: 35
        visible: autoHideEnabled && dockPill.isFullyHidden

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                dockPill.isFullyHidden = false
                hideTimer.stop()
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 900
        repeat: false
        onTriggered: {
            if (autoHideEnabled && !dockWindow.isMouseInDock && !contextMenuOpen && !separatorMenuOpen && !draggingItem) {
                dockPill.isFullyHidden = true
            }
        }
    }

    Timer {
        id: mouseLeaveTimer
        interval: 35
        repeat: false
        onTriggered: {
            dockWindow.isMouseInDock = false
            dockWindow.mouseScreenX = -1
            if (dockWindow.autoHideEnabled) hideTimer.restart()
        }
    }

    function handleScreenPointerMove(screenX) {
        mouseLeaveTimer.stop()
        dockWindow.mouseScreenX = screenX
        dockWindow.isMouseInDock = true
        dockPill.isFullyHidden = false
        hideTimer.stop()
    }

    function handlePointerExit() {
        mouseLeaveTimer.restart()
    }

    // Background wallpaper reference for frosted acrylic sampling
    Image {
        id: wpFull
        source: (sysProc && sysProc.wallpaperUrl && sysProc.wallpaperUrl.length > 0) ? sysProc.wallpaperUrl : "../../../../../../Library/DesktopPictures/Wallpaper.jpg"
        width: Screen.width > 0 ? Screen.width : 1920
        height: Screen.height > 0 ? Screen.height : 1080
        fillMode: Image.PreserveAspectCrop
        smooth: true
        visible: false
    }

    // --- Main Glass Dock Pill Container (1:1 with Apple Design Resources) ---
    Item {
        id: dockPill
        property bool isFullyHidden: false

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: isFullyHidden ? -height - 20 : 10
        z: 40

        // Dock pill dynamically expands horizontally to accommodate magnified icons
        width: contentRow.width + dockWindow.pillPaddingH * 2
        height: dockWindow.pillHeight

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        // --- Frosted Glass Dock Background Pipeline ---
        Item {
            id: dockGlass
            anchors.fill: parent
            z: -1

            readonly property real originScreenX: dockPill.x
            readonly property real originScreenY: (Screen.height - dockWindow.height) + dockPill.y

            // Wallpaper crop: STRICTLY the exact bounding box behind dockPill
            ShaderEffectSource {
                id: wpCrop
                width: Math.max(1, dockPill.width)
                height: Math.max(1, dockPill.height)
                sourceItem: wpFull
                sourceRect: Qt.rect(
                    Math.max(0, dockGlass.originScreenX),
                    Math.max(0, dockGlass.originScreenY),
                    Math.max(1, dockPill.width),
                    Math.max(1, dockPill.height)
                )
                hideSource: false
                live: true
                visible: false
            }

            // Downsample 4x for deep acrylic blur diffusion & high performance
            Item {
                id: wpDownsampled
                width: Math.max(1, Math.round(dockPill.width / 4))
                height: Math.max(1, Math.round(dockPill.height / 4))
                visible: false

                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: wpCrop
                    hideSource: false
                    live: true
                    smooth: true
                }
            }

            FastBlur {
                id: blurPass1
                anchors.fill: wpDownsampled
                source: wpDownsampled
                radius: 48
                transparentBorder: false
                visible: false
            }

            Item {
                id: wpUpscaled
                width: Math.max(1, dockPill.width)
                height: Math.max(1, dockPill.height)
                visible: false

                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: blurPass1
                    hideSource: false
                    live: true
                    smooth: true
                }
            }

            FastBlur {
                id: blurPass2
                anchors.fill: wpUpscaled
                source: wpUpscaled
                radius: 24
                transparentBorder: false
                visible: false
            }

            // Continuous Squircle Mask for the Dock Pill
            Rectangle {
                id: pillMask
                anchors.fill: parent
                radius: dockWindow.pillRadius
                visible: false
            }

            // Masked Blurred Wallpaper Output
            OpacityMask {
                anchors.fill: parent
                source: blurPass2
                maskSource: pillMask
            }

            // Frosted Acrylic Tint Layer (macOS Sonoma / Sequoia tokens)
            Rectangle {
                id: pillTint
                anchors.fill: parent
                radius: dockWindow.pillRadius
                color: dockWindow.isDark ? Qt.rgba(0.12, 0.12, 0.14, 0.58)
                                         : Qt.rgba(1.0, 1.0, 1.0, 0.34)
                border.width: 1
                border.color: dockWindow.isDark ? Qt.rgba(1, 1, 1, 0.18)
                                                : Qt.rgba(1, 1, 1, 0.55)
            }

            // Top specular highlight rim (macOS signature glass edge catch-light)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                height: 1
                color: dockWindow.isDark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.75)
                opacity: 0.8
            }
        }

        // Multi-layer ambient drop shadow around the floating pill
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: dockWindow.pillRadius + 1
            color: "transparent"
            border.color: dockWindow.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.12)
            border.width: 1
            z: -2
        }

        DropShadow {
            anchors.fill: dockGlass
            source: dockGlass
            radius: dockWindow.isDark ? 22 : 16
            samples: 25
            spread: 0.0
            horizontalOffset: 0
            verticalOffset: dockWindow.isDark ? 8 : 6
            color: dockWindow.isDark ? Qt.rgba(0, 0, 0, 0.40) : Qt.rgba(0, 0, 0, 0.18)
            transparentBorder: true
            z: -3
        }

        // Master MouseArea strictly over the Dock Pill
        MouseArea {
            id: dockPillMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onEntered: {
                dockPill.isFullyHidden = false
                hideTimer.stop()
            }
            onPositionChanged: (mouse) => {
                var screenPt = mapToItem(dockWindow.contentItem, mouse.x, mouse.y)
                dockWindow.handleScreenPointerMove(screenPt.x)
            }
            onExited: dockWindow.handlePointerExit()
        }

        // --- Row of Dock Items (Expanding with Magnification) ---
        Row {
            id: contentRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 11
            spacing: dockWindow.itemSpacing

            // Left Section: Pinned Applications
            Repeater {
                id: appRepeater
                model: dockWindow.dockItems

                Item {
                    id: appItem
                    property real restingCenterX: dockWindow.restingPillLeft + dockWindow.pillPaddingH + (index + 0.5) * (dockWindow.baseIconWidth + dockWindow.itemSpacing)
                    property real itemSize: dockWindow.computeSizeForRestingX(restingCenterX)
                    property real itemScale: itemSize / dockWindow.baseIconSize
                    property real itemWidth: Math.round(itemSize * dockWindow.iconStretch)

                    width: itemWidth
                    height: dockWindow.baseIconSize
                    anchors.bottom: parent.bottom

                    property bool isDraggingThis: dockWindow.draggingIndex === index
                    opacity: isDraggingThis ? 0.35 : 1.0

                    // Directional scaling container:
                    // For horizontal Dock: pinned to Item.Bottom, scales ONLY UPWARDS (never downwards)!
                    // For vertical Left Dock: pinned to Item.Left, scales ONLY RIGHTWARDS!
                    // For vertical Right Dock: pinned to Item.Right, scales ONLY LEFTWARDS!
                    Item {
                        id: iconVisualContainer
                        width: dockWindow.baseIconWidth
                        height: dockWindow.baseIconSize
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom

                        transformOrigin: {
                            if (dockWindow.dockPosition === "left") return Item.Left
                            if (dockWindow.dockPosition === "right") return Item.Right
                            return Item.Bottom
                        }
                        scale: appItem.itemScale

                        Image {
                            id: iconImg
                            anchors.fill: parent
                            source: "../../../../../../Library/Application/Icons/png/" + modelData.icon
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            sourceSize.width: 128
                            sourceSize.height: 128

                            // Bounce animation on launch
                            SequentialAnimation on y {
                                id: bounceAnim
                                running: false
                                loops: 2
                                NumberAnimation { to: -16; duration: 160; easing.type: Easing.OutQuad }
                                NumberAnimation { to: 0; duration: 200; easing.type: Easing.InQuad }
                            }
                        }

                        // Dynamic live date for Calendar in Dock
                        Item {
                            anchors.fill: parent
                            visible: modelData.isCalendar === true

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: Math.round(parent.height * 0.10)
                                text: {
                                    var m = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
                                    return m[new Date().getMonth()]
                                }
                                font.family: sfBold.name
                                font.bold: true
                                font.pixelSize: Math.max(7, Math.round(parent.height * 0.15))
                                color: "#ffffff"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: Math.round(parent.height * 0.38)
                                text: "" + new Date().getDate()
                                font.family: sfMedium.name
                                font.pixelSize: Math.round(parent.height * 0.44)
                                color: "#1d1d1f"
                            }
                        }
                    }

                    // Running dot indicator (1:1 with Apple Design Resources)
                    Rectangle {
                        id: runningDot
                        width: 4
                        height: 4
                        radius: 2
                        color: dockWindow.isDark ? Qt.rgba(1, 1, 1, 0.82) : Qt.rgba(0, 0, 0, 0.72)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 3
                        visible: (sysProc.runningApps && sysProc.runningApps.indexOf(modelData.id) !== -1) || modelData.id === "finder"
                    }

                    MouseArea {
                        id: appMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        property real pressSceneX: 0
                        property real pressSceneY: 0
                        property bool isDragStarted: false

                        onEntered: {
                            var pt = appItem.mapToItem(dockWindow.contentItem, width / 2, height / 2)
                            dockWindow.handleScreenPointerMove(pt.x)
                        }

                        onPressed: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                var pt = appItem.mapToItem(null, mouse.x, mouse.y)
                                pressSceneX = pt.x
                                pressSceneY = pt.y
                                isDragStarted = false
                            }
                        }

                        onPositionChanged: (mouse) => {
                            var ptContent = appItem.mapToItem(dockWindow.contentItem, mouse.x, mouse.y)
                            dockWindow.handleScreenPointerMove(ptContent.x)

                            // Check drag threshold
                            if (mouse.buttons & Qt.LeftButton) {
                                var pt = appItem.mapToItem(null, mouse.x, mouse.y)
                                var dy = pressSceneY - pt.y
                                var dx = Math.abs(pressSceneX - pt.x)
                                if ((dy > 14 || dx > 18) && !isDragStarted) {
                                    // Finder can NEVER be dragged or unpinned
                                    if (modelData.canUnpin !== false) {
                                        isDragStarted = true
                                        dockWindow.draggingItem = modelData
                                        dockWindow.draggingIndex = index
                                    }
                                }
                                if (isDragStarted) {
                                    dockWindow.dragGlobalX = pt.x
                                    dockWindow.dragGlobalY = pt.y
                                    // If dragged above the dock pill, show "Remove" bubble
                                    dockWindow.showRemovePrompt = (pt.y < dockPill.y - 12)
                                }
                            }
                        }

                        onReleased: (mouse) => {
                            if (isDragStarted) {
                                if (dockWindow.showRemovePrompt) {
                                    dockWindow.unpinItem(dockWindow.draggingIndex)
                                }
                                dockWindow.draggingItem = null
                                dockWindow.draggingIndex = -1
                                dockWindow.showRemovePrompt = false
                                isDragStarted = false
                            }
                        }

                        onClicked: (mouse) => {
                            console.log("DOCK app clicked, button:", mouse.button, "id:", modelData ? modelData.id : "none")
                            if (mouse.button === Qt.RightButton) {
                                var globalPt = appItem.mapToItem(null, width / 2, 0)
                                dockWindow.contextMenuTargetItem = modelData
                                dockWindow.contextMenuTargetIndex = index
                                dockWindow.contextMenuX = globalPt.x
                                dockWindow.separatorMenuOpen = false
                                dockWindow.contextMenuOpen = true
                            } else if (mouse.button === Qt.LeftButton && !isDragStarted) {
                                bounceAnim.restart()
                                dockWindow.launchItem(modelData)
                            }
                        }
                    }

                    // Hover tooltip with app name (unified callout bubble matching macOS Sequoia)
                    Item {
                        id: nameTooltip
                        visible: appMa.containsMouse && !dockWindow.contextMenuOpen && !dockWindow.separatorMenuOpen && !dockWindow.draggingItem && !appMa.isDragStarted
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: Math.round(appItem.itemSize - dockWindow.baseIconSize) + 7
                        z: 100

                        readonly property real bubblePaddingH: 9
                        readonly property real bubbleW: Math.round(labelText.implicitWidth + bubblePaddingH * 2)
                        readonly property real bubbleH: 22
                        readonly property real cornerRadius: 5
                        readonly property real triW: 10
                        readonly property real triH: 5

                        width: bubbleW
                        height: bubbleH + triH

                        Shape {
                            anchors.fill: parent
                            layer.enabled: true
                            layer.samples: 4

                            ShapePath {
                                strokeColor: dockWindow.tooltipBorderColor
                                strokeWidth: 0.6
                                fillColor: dockWindow.tooltipBgColor
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin

                                startX: nameTooltip.cornerRadius; startY: 0
                                // Top edge
                                PathLine { x: nameTooltip.bubbleW - nameTooltip.cornerRadius; y: 0 }
                                // Top-right corner
                                PathArc {
                                    x: nameTooltip.bubbleW
                                    y: nameTooltip.cornerRadius
                                    radiusX: nameTooltip.cornerRadius
                                    radiusY: nameTooltip.cornerRadius
                                    direction: PathArc.Clockwise
                                }
                                // Right edge
                                PathLine { x: nameTooltip.bubbleW; y: nameTooltip.bubbleH - nameTooltip.cornerRadius }
                                // Bottom-right corner
                                PathArc {
                                    x: nameTooltip.bubbleW - nameTooltip.cornerRadius
                                    y: nameTooltip.bubbleH
                                    radiusX: nameTooltip.cornerRadius
                                    radiusY: nameTooltip.cornerRadius
                                    direction: PathArc.Clockwise
                                }
                                // Bottom edge right of triangle
                                PathLine { x: Math.round((nameTooltip.bubbleW + nameTooltip.triW) / 2); y: nameTooltip.bubbleH }
                                // Triangle right side down to tip
                                PathLine { x: Math.round(nameTooltip.bubbleW / 2); y: nameTooltip.bubbleH + nameTooltip.triH }
                                // Triangle left side up to bottom edge
                                PathLine { x: Math.round((nameTooltip.bubbleW - nameTooltip.triW) / 2); y: nameTooltip.bubbleH }
                                // Bottom edge left of triangle
                                PathLine { x: nameTooltip.cornerRadius; y: nameTooltip.bubbleH }
                                // Bottom-left corner
                                PathArc {
                                    x: 0
                                    y: nameTooltip.bubbleH - nameTooltip.cornerRadius
                                    radiusX: nameTooltip.cornerRadius
                                    radiusY: nameTooltip.cornerRadius
                                    direction: PathArc.Clockwise
                                }
                                // Left edge
                                PathLine { x: 0; y: nameTooltip.cornerRadius }
                                // Top-left corner
                                PathArc {
                                    x: nameTooltip.cornerRadius
                                    y: 0
                                    radiusX: nameTooltip.cornerRadius
                                    radiusY: nameTooltip.cornerRadius
                                    direction: PathArc.Clockwise
                                }
                            }
                        }

                        Text {
                            id: labelText
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: Math.round((nameTooltip.bubbleH - implicitHeight) / 2)
                            text: modelData.name
                            font.family: sfMedium.name
                            font.weight: Font.Medium
                            font.pixelSize: 12
                            color: dockWindow.tooltipTextColor
                        }
                    }
                }
            }

            // --- Vertical Dock Divider / Separator Line (1:1 with Apple Design Resources) ---
            Item {
                id: separatorItem
                width: dockWindow.restingSeparatorWidth
                height: dockWindow.baseIconSize
                anchors.bottom: parent.bottom

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 42
                    radius: 0.5
                    color: dockWindow.isDark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.18)
                }

                MouseArea {
                    id: separatorMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                    cursorShape: Qt.ArrowCursor

                    onEntered: {
                        var pt = separatorItem.mapToItem(dockWindow.contentItem, width / 2, height / 2)
                        dockWindow.handleScreenPointerMove(pt.x)
                    }

                    onPositionChanged: (mouse) => {
                        var pt = separatorItem.mapToItem(dockWindow.contentItem, mouse.x, mouse.y)
                        dockWindow.handleScreenPointerMove(pt.x)
                    }

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            var globalPt = separatorItem.mapToItem(null, width / 2, 0)
                            dockWindow.separatorMenuX = globalPt.x
                            dockWindow.contextMenuOpen = false
                            dockWindow.separatorMenuOpen = true
                        }
                    }
                }
            }

            // Right Section: Folders / Files & Trash
            Repeater {
                id: rightRepeater
                model: dockWindow.rightItems

                Item {
                    id: rightItem
                    property real restingCenterX: dockWindow.restingPillLeft + dockWindow.pillPaddingH + dockWindow.restingAppsWidth + dockWindow.restingSeparatorWidth + (index + 0.5) * (dockWindow.baseIconWidth + dockWindow.itemSpacing)
                    property real itemSize: dockWindow.computeSizeForRestingX(restingCenterX)
                    property real itemScale: itemSize / dockWindow.baseIconSize
                    property real itemWidth: Math.round(itemSize * dockWindow.iconStretch)

                    width: itemWidth
                    height: dockWindow.baseIconSize
                    anchors.bottom: parent.bottom

                    property bool isDraggingThis: dockWindow.draggingIndex === (dockWindow.dockItems.length + index)
                    opacity: isDraggingThis ? 0.35 : 1.0

                    Item {
                        id: rightVisualContainer
                        width: dockWindow.baseIconWidth
                        height: dockWindow.baseIconSize
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom

                        transformOrigin: {
                            if (dockWindow.dockPosition === "left") return Item.Left
                            if (dockWindow.dockPosition === "right") return Item.Right
                            return Item.Bottom
                        }
                        scale: rightItem.itemScale

                        Image {
                            anchors.fill: parent
                            source: "../../../../../../Library/Application/Icons/png/" + modelData.icon
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            sourceSize.width: 128
                            sourceSize.height: 128
                        }
                    }

                    MouseArea {
                        id: rightMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        property real pressSceneX: 0
                        property real pressSceneY: 0
                        property bool isDragStarted: false

                        onEntered: {
                            var pt = rightItem.mapToItem(dockWindow.contentItem, width / 2, height / 2)
                            dockWindow.handleScreenPointerMove(pt.x)
                        }

                        onPressed: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                var pt = rightItem.mapToItem(null, mouse.x, mouse.y)
                                pressSceneX = pt.x
                                pressSceneY = pt.y
                                isDragStarted = false
                            }
                        }

                        onPositionChanged: (mouse) => {
                            var ptContent = rightItem.mapToItem(dockWindow.contentItem, mouse.x, mouse.y)
                            dockWindow.handleScreenPointerMove(ptContent.x)

                            if (mouse.buttons & Qt.LeftButton) {
                                var pt = rightItem.mapToItem(null, mouse.x, mouse.y)
                                var dy = pressSceneY - pt.y
                                var dx = Math.abs(pressSceneX - pt.x)
                                if ((dy > 14 || dx > 18) && !isDragStarted) {
                                    if (modelData.canUnpin !== false) {
                                        isDragStarted = true
                                        dockWindow.draggingItem = modelData
                                        dockWindow.draggingIndex = dockWindow.dockItems.length + index
                                    }
                                }
                                if (isDragStarted) {
                                    dockWindow.dragGlobalX = pt.x
                                    dockWindow.dragGlobalY = pt.y
                                    dockWindow.showRemovePrompt = (pt.y < dockPill.y - 12)
                                }
                            }
                        }

                        onReleased: (mouse) => {
                            if (isDragStarted) {
                                if (dockWindow.showRemovePrompt) {
                                    var nextRight = []
                                    for (var r = 0; r < dockWindow.rightItems.length; ++r) {
                                        if (r !== index) nextRight.push(dockWindow.rightItems[r])
                                    }
                                    dockWindow.rightItems = nextRight
                                }
                                dockWindow.draggingItem = null
                                dockWindow.draggingIndex = -1
                                dockWindow.showRemovePrompt = false
                                isDragStarted = false
                            }
                        }

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                var globalPt = rightItem.mapToItem(null, width / 2, 0)
                                dockWindow.contextMenuTargetItem = modelData
                                dockWindow.contextMenuTargetIndex = dockWindow.dockItems.length + index
                                dockWindow.contextMenuX = globalPt.x
                                dockWindow.separatorMenuOpen = false
                                dockWindow.contextMenuOpen = true
                            } else if (mouse.button === Qt.LeftButton && !isDragStarted) {
                                dockWindow.launchItem(modelData)
                            }
                        }
                    }

                    // Hover tooltip (unified callout bubble matching macOS Sequoia)
                    Item {
                        id: rightTooltip
                        visible: rightMa.containsMouse && !dockWindow.contextMenuOpen && !dockWindow.separatorMenuOpen && !dockWindow.draggingItem && !rightMa.isDragStarted
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: Math.round(rightItem.itemSize - dockWindow.baseIconSize) + 7
                        z: 100

                        readonly property real bubblePaddingH: 9
                        readonly property real bubbleW: Math.round(rightLabel.implicitWidth + bubblePaddingH * 2)
                        readonly property real bubbleH: 22
                        readonly property real cornerRadius: 5
                        readonly property real triW: 10
                        readonly property real triH: 5

                        width: bubbleW
                        height: bubbleH + triH

                        Shape {
                            anchors.fill: parent
                            layer.enabled: true
                            layer.samples: 4

                            ShapePath {
                                strokeColor: dockWindow.tooltipBorderColor
                                strokeWidth: 0.6
                                fillColor: dockWindow.tooltipBgColor
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin

                                startX: rightTooltip.cornerRadius; startY: 0
                                // Top edge
                                PathLine { x: rightTooltip.bubbleW - rightTooltip.cornerRadius; y: 0 }
                                // Top-right corner
                                PathArc {
                                    x: rightTooltip.bubbleW
                                    y: rightTooltip.cornerRadius
                                    radiusX: rightTooltip.cornerRadius
                                    radiusY: rightTooltip.cornerRadius
                                    direction: PathArc.Clockwise
                                }
                                // Right edge
                                PathLine { x: rightTooltip.bubbleW; y: rightTooltip.bubbleH - rightTooltip.cornerRadius }
                                // Bottom-right corner
                                PathArc {
                                    x: rightTooltip.bubbleW - rightTooltip.cornerRadius
                                    y: rightTooltip.bubbleH
                                    radiusX: rightTooltip.cornerRadius
                                    radiusY: rightTooltip.cornerRadius
                                    direction: PathArc.Clockwise
                                }
                                // Bottom edge right of triangle
                                PathLine { x: Math.round((rightTooltip.bubbleW + rightTooltip.triW) / 2); y: rightTooltip.bubbleH }
                                // Triangle right side down to tip
                                PathLine { x: Math.round(rightTooltip.bubbleW / 2); y: rightTooltip.bubbleH + rightTooltip.triH }
                                // Triangle left side up to bottom edge
                                PathLine { x: Math.round((rightTooltip.bubbleW - rightTooltip.triW) / 2); y: rightTooltip.bubbleH }
                                // Bottom edge left of triangle
                                PathLine { x: rightTooltip.cornerRadius; y: rightTooltip.bubbleH }
                                // Bottom-left corner
                                PathArc {
                                    x: 0
                                    y: rightTooltip.bubbleH - rightTooltip.cornerRadius
                                    radiusX: rightTooltip.cornerRadius
                                    radiusY: rightTooltip.cornerRadius
                                    direction: PathArc.Clockwise
                                }
                                // Left edge
                                PathLine { x: 0; y: rightTooltip.cornerRadius }
                                // Top-left corner
                                PathArc {
                                    x: rightTooltip.cornerRadius
                                    y: 0
                                    radiusX: rightTooltip.cornerRadius
                                    radiusY: rightTooltip.cornerRadius
                                    direction: PathArc.Clockwise
                                }
                            }
                        }

                        Text {
                            id: rightLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: Math.round((rightTooltip.bubbleH - implicitHeight) / 2)
                            text: modelData.name
                            font.family: sfMedium.name
                            font.weight: Font.Medium
                            font.pixelSize: 12
                            color: dockWindow.tooltipTextColor
                        }
                    }
                }
            }
        }
    }

    // --- Drag-to-Remove Floating Icon & "Remove" Speech Bubble Tooltip ---
    Item {
        id: dragOverlay
        visible: dockWindow.draggingItem !== null
        z: 300
        x: dockWindow.dragGlobalX - 28
        y: dockWindow.dragGlobalY - 28
        width: 56
        height: 56

        Image {
            anchors.fill: parent
            source: dockWindow.draggingItem ? ("../../../../../../Library/Application/Icons/png/" + dockWindow.draggingItem.icon) : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.92
        }

        // "Remove" speech bubble callout matching reference image 4 (unified callout bubble)
        Item {
            id: removeBubble
            visible: dockWindow.showRemovePrompt
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 12

            readonly property real r: 7
            readonly property real bw: 76
            readonly property real bh: 25
            readonly property real tw: 12
            readonly property real th: 7

            width: bw
            height: bh + th

            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeColor: Qt.rgba(0, 0, 0, 0.18)
                    strokeWidth: 0.6
                    fillColor: Qt.rgba(0.92, 0.92, 0.92, 0.95)
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    startX: removeBubble.r; startY: 0
                    PathLine { x: removeBubble.bw - removeBubble.r; y: 0 }
                    PathArc { x: removeBubble.bw; y: removeBubble.r; radiusX: removeBubble.r; radiusY: removeBubble.r; direction: PathArc.Clockwise }
                    PathLine { x: removeBubble.bw; y: removeBubble.bh - removeBubble.r }
                    PathArc { x: removeBubble.bw - removeBubble.r; y: removeBubble.bh; radiusX: removeBubble.r; radiusY: removeBubble.r; direction: PathArc.Clockwise }
                    PathLine { x: Math.round((removeBubble.bw + removeBubble.tw) / 2); y: removeBubble.bh }
                    PathLine { x: Math.round(removeBubble.bw / 2); y: removeBubble.bh + removeBubble.th }
                    PathLine { x: Math.round((removeBubble.bw - removeBubble.tw) / 2); y: removeBubble.bh }
                    PathLine { x: removeBubble.r; y: removeBubble.bh }
                    PathArc { x: 0; y: removeBubble.bh - removeBubble.r; radiusX: removeBubble.r; radiusY: removeBubble.r; direction: PathArc.Clockwise }
                    PathLine { x: 0; y: removeBubble.r }
                    PathArc { x: removeBubble.r; y: 0; radiusX: removeBubble.r; radiusY: removeBubble.r; direction: PathArc.Clockwise }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 5
                text: "Remove"
                font.family: sfMedium.name
                font.weight: Font.Medium
                font.pixelSize: 13
                color: "#1d1d1f"
            }
        }
    }

    // --- Right-Click Context Menu for Dock Icons ---
    // Matches reference image 1
    Item {
        id: iconContextMenu
        visible: dockWindow.contextMenuOpen && dockWindow.contextMenuTargetItem !== null
        z: 200
        width: 190
        height: iconMenuColumn.height + 10
        x: Math.max(10, Math.min(dockWindow.contextMenuX - width / 2, dockWindow.width - width - 10))
        anchors.bottom: dockPill.top
        anchors.bottomMargin: 14

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: dockWindow.menuBgColor
            border.color: dockWindow.menuBorderColor
            border.width: 0.6

            Rectangle {
                anchors.fill: parent
                anchors.margins: 0.6
                radius: 7.4
                color: "transparent"
                border.color: dockWindow.menuInnerHighlight
                border.width: 0.6
            }
        }

        // Pointer tail pointing down to icon
        Shape {
            x: Math.max(12, Math.min(dockWindow.contextMenuX - iconContextMenu.x - 7, iconContextMenu.width - 24))
            anchors.top: parent.bottom
            anchors.topMargin: -0.6
            width: 14
            height: 7

            ShapePath {
                strokeColor: dockWindow.menuBorderColor
                strokeWidth: 0.6
                fillColor: dockWindow.menuBgColor
                startX: 0; startY: 0
                PathLine { x: 7; y: 7 }
                PathLine { x: 14; y: 0 }
                PathLine { x: 0; y: 0 }
            }
        }

        Column {
            id: iconMenuColumn
            x: 0
            y: 5
            width: parent.width
            spacing: 1

            // If Finder
            Item {
                width: parent.width
                height: 21
                visible: dockWindow.contextMenuTargetItem && dockWindow.contextMenuTargetItem.id === "finder"
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: finderMa1.containsMouse ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "New Finder Window"; font.family: sfMedium.name; font.pixelSize: 13
                        color: finderMa1.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: finderMa1; anchors.fill: parent; hoverEnabled: true
                        onClicked: { sysProc.launch("nautilus ~ || true"); dockWindow.closeAllMenus() }
                    }
                }
            }

            // Options item with submenu for unpinnable items
            Item {
                width: parent.width
                height: 21
                visible: dockWindow.contextMenuTargetItem && dockWindow.contextMenuTargetItem.id !== "finder"
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: (optMa.containsMouse || dockWindow.showOptionsSubmenu) ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "Options"; font.family: sfMedium.name; font.pixelSize: 13
                        color: (optMa.containsMouse || dockWindow.showOptionsSubmenu) ? "#ffffff" : dockWindow.menuTextColor
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "›"; font.family: sfMedium.name; font.pixelSize: 15; font.weight: Font.DemiBold
                        color: (optMa.containsMouse || dockWindow.showOptionsSubmenu) ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: optMa; anchors.fill: parent; hoverEnabled: true
                        onEntered: dockWindow.showOptionsSubmenu = true
                        onClicked: dockWindow.showOptionsSubmenu = !dockWindow.showOptionsSubmenu
                    }
                }
            }

            // Separator
            Item {
                width: parent.width
                height: 7
                Rectangle {
                    anchors.centerIn: parent; width: parent.width - 24; height: 0.8
                    color: dockWindow.menuSeparatorColor
                }
            }

            // Open item
            Item {
                width: parent.width
                height: 21
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: openMa.containsMouse ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "Open"; font.family: sfMedium.name; font.pixelSize: 13
                        color: openMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: openMa; anchors.fill: parent; hoverEnabled: true
                        onEntered: dockWindow.showOptionsSubmenu = false
                        onClicked: {
                            dockWindow.launchItem(dockWindow.contextMenuTargetItem)
                            dockWindow.closeAllMenus()
                        }
                    }
                }
            }

            // Quit item
            Item {
                width: parent.width
                height: 21
                visible: dockWindow.contextMenuTargetItem && dockWindow.contextMenuTargetItem.id !== "finder"
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: quitMa.containsMouse ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "Quit"; font.family: sfMedium.name; font.pixelSize: 13
                        color: quitMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: quitMa; anchors.fill: parent; hoverEnabled: true
                        onEntered: dockWindow.showOptionsSubmenu = false
                        onClicked: dockWindow.closeAllMenus()
                    }
                }
            }
        }

        // --- Options Submenu (Positioned directly to the left, as in reference image 1) ---
        Item {
            id: optionsSubmenu
            visible: dockWindow.showOptionsSubmenu
            width: 175
            height: optionsColumn.height + 10
            x: -width - 2
            y: 0

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: dockWindow.menuBgColor
                border.color: dockWindow.menuBorderColor
                border.width: 0.6

                Rectangle {
                    anchors.fill: parent; anchors.margins: 0.6; radius: 7.4
                    color: "transparent"; border.color: dockWindow.menuInnerHighlight; border.width: 0.6
                }
            }

            Column {
                id: optionsColumn
                x: 0; y: 5; width: parent.width; spacing: 1

                // Remove from Dock (Unpins icon!)
                Item {
                    width: parent.width
                    height: 21
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                        color: remMa.containsMouse ? "#007aff" : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: "Remove from Dock"; font.family: sfMedium.name; font.pixelSize: 13
                            color: remMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                        }
                        MouseArea {
                            id: remMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                dockWindow.unpinItem(dockWindow.contextMenuTargetIndex)
                            }
                        }
                    }
                }

                // Open at Login
                Item {
                    width: parent.width
                    height: 21
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                        color: loginMa.containsMouse ? "#007aff" : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: "Open at Login"; font.family: sfMedium.name; font.pixelSize: 13
                            color: loginMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                        }
                        MouseArea {
                            id: loginMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: dockWindow.closeAllMenus()
                        }
                    }
                }

                // Show in Finder
                Item {
                    width: parent.width
                    height: 21
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                        color: showFinderMa.containsMouse ? "#007aff" : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: "Show in Finder"; font.family: sfMedium.name; font.pixelSize: 13
                            color: showFinderMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                        }
                        MouseArea {
                            id: showFinderMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                sysProc.launch("nautilus ~ || true")
                                dockWindow.closeAllMenus()
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Right-Click Context Menu for the Separator Line ---
    // Matches reference images 2 and 5
    Item {
        id: separatorContextMenu
        visible: dockWindow.separatorMenuOpen
        z: 200
        width: 195
        height: sepColumn.height + 10
        x: Math.max(10, Math.min(dockWindow.separatorMenuX - width / 2, dockWindow.width - width - 10))
        anchors.bottom: dockPill.top
        anchors.bottomMargin: 14

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: dockWindow.menuBgColor
            border.color: dockWindow.menuBorderColor
            border.width: 0.6

            Rectangle {
                anchors.fill: parent; anchors.margins: 0.6; radius: 7.4
                color: "transparent"; border.color: dockWindow.menuInnerHighlight; border.width: 0.6
            }
        }

        // Pointer tail pointing down to separator
        Shape {
            x: Math.max(12, Math.min(dockWindow.separatorMenuX - separatorContextMenu.x - 7, separatorContextMenu.width - 24))
            anchors.top: parent.bottom
            anchors.topMargin: -0.6
            width: 14
            height: 7

            ShapePath {
                strokeColor: dockWindow.menuBorderColor
                strokeWidth: 0.6
                fillColor: dockWindow.menuBgColor
                startX: 0; startY: 0
                PathLine { x: 7; y: 7 }
                PathLine { x: 14; y: 0 }
                PathLine { x: 0; y: 0 }
            }
        }

        Column {
            id: sepColumn
            x: 0; y: 5; width: parent.width; spacing: 1

            // Turn Hiding On / Off
            Item {
                width: parent.width
                height: 21
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: hideMa.containsMouse ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: dockWindow.autoHideEnabled ? "Turn Hiding Off" : "Turn Hiding On"
                        font.family: sfMedium.name; font.pixelSize: 13
                        color: hideMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: hideMa; anchors.fill: parent; hoverEnabled: true
                        onEntered: { dockWindow.showPositionSubmenu = false; dockWindow.showMinimiseSubmenu = false }
                        onClicked: {
                            dockWindow.autoHideEnabled = !dockWindow.autoHideEnabled
                            if (!dockWindow.autoHideEnabled) dockPill.isFullyHidden = false
                            dockWindow.closeAllMenus()
                        }
                    }
                }
            }

            // Turn Magnification On / Off
            Item {
                width: parent.width
                height: 21
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: magMa.containsMouse ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: dockWindow.magnificationEnabled ? "Turn Magnification Off" : "Turn Magnification On"
                        font.family: sfMedium.name; font.pixelSize: 13
                        color: magMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: magMa; anchors.fill: parent; hoverEnabled: true
                        onEntered: { dockWindow.showPositionSubmenu = false; dockWindow.showMinimiseSubmenu = false }
                        onClicked: {
                            dockWindow.magnificationEnabled = !dockWindow.magnificationEnabled
                            dockWindow.closeAllMenus()
                        }
                    }
                }
            }

            // Position on Screen >
            Item {
                width: parent.width
                height: 21
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: (posMa.containsMouse || dockWindow.showPositionSubmenu) ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "Position on Screen"; font.family: sfMedium.name; font.pixelSize: 13
                        color: (posMa.containsMouse || dockWindow.showPositionSubmenu) ? "#ffffff" : dockWindow.menuTextColor
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "›"; font.family: sfMedium.name; font.pixelSize: 15; font.weight: Font.DemiBold
                        color: (posMa.containsMouse || dockWindow.showPositionSubmenu) ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: posMa; anchors.fill: parent; hoverEnabled: true
                        onEntered: { dockWindow.showPositionSubmenu = true; dockWindow.showMinimiseSubmenu = false }
                    }
                }
            }

            // Minimise Using >
            Item {
                width: parent.width
                height: 21
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: (minMa.containsMouse || dockWindow.showMinimiseSubmenu) ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "Minimise Using"; font.family: sfMedium.name; font.pixelSize: 13
                        color: (minMa.containsMouse || dockWindow.showMinimiseSubmenu) ? "#ffffff" : dockWindow.menuTextColor
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "›"; font.family: sfMedium.name; font.pixelSize: 15; font.weight: Font.DemiBold
                        color: (minMa.containsMouse || dockWindow.showMinimiseSubmenu) ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: minMa; anchors.fill: parent; hoverEnabled: true
                        onEntered: { dockWindow.showMinimiseSubmenu = true; dockWindow.showPositionSubmenu = false }
                    }
                }
            }

            // Separator line
            Item {
                width: parent.width
                height: 7
                Rectangle {
                    anchors.centerIn: parent; width: parent.width - 24; height: 0.8
                    color: dockWindow.menuSeparatorColor
                }
            }

            // Dock Settings...
            Item {
                width: parent.width
                height: 21
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                    color: setMa.containsMouse ? "#007aff" : "transparent"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: "Dock Settings..."; font.family: sfMedium.name; font.pixelSize: 13
                        color: setMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                    }
                    MouseArea {
                        id: setMa; anchors.fill: parent; hoverEnabled: true
                        onEntered: { dockWindow.showPositionSubmenu = false; dockWindow.showMinimiseSubmenu = false }
                        onClicked: {
                            sysProc.openSystemSettings("dock")
                            dockWindow.closeAllMenus()
                        }
                    }
                }
            }
        }

        // --- Position on Screen Submenu (matching reference image 5) ---
        Item {
            id: positionSubmenu
            visible: dockWindow.showPositionSubmenu
            width: 105
            height: posCol.height + 10
            x: parent.width + 2
            y: 42

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: dockWindow.menuBgColor
                border.color: dockWindow.menuBorderColor
                border.width: 0.6

                Rectangle {
                    anchors.fill: parent; anchors.margins: 0.6; radius: 7.4
                    color: "transparent"; border.color: dockWindow.menuInnerHighlight; border.width: 0.6
                }
            }

            Column {
                id: posCol
                x: 0; y: 5; width: parent.width; spacing: 1

                Item {
                    width: parent.width; height: 21
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                        color: posLeftMa.containsMouse ? "#007aff" : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            text: (dockWindow.dockPosition === "left" ? "✓ " : "  ") + "Left"
                            font.family: sfMedium.name; font.pixelSize: 13
                            color: posLeftMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                        }
                        MouseArea {
                            id: posLeftMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: { dockWindow.dockPosition = "left"; dockWindow.closeAllMenus() }
                        }
                    }
                }

                Item {
                    width: parent.width; height: 21
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                        color: posBotMa.containsMouse ? "#007aff" : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            text: (dockWindow.dockPosition === "bottom" ? "✓ " : "  ") + "Bottom"
                            font.family: sfMedium.name; font.pixelSize: 13
                            color: posBotMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                        }
                        MouseArea {
                            id: posBotMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: { dockWindow.dockPosition = "bottom"; dockWindow.closeAllMenus() }
                        }
                    }
                }

                Item {
                    width: parent.width; height: 21
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                        color: posRightMa.containsMouse ? "#007aff" : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            text: (dockWindow.dockPosition === "right" ? "✓ " : "  ") + "Right"
                            font.family: sfMedium.name; font.pixelSize: 13
                            color: posRightMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                        }
                        MouseArea {
                            id: posRightMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: { dockWindow.dockPosition = "right"; dockWindow.closeAllMenus() }
                        }
                    }
                }
            }
        }

        // --- Minimise Using Submenu ---
        Item {
            id: minimiseSubmenu
            visible: dockWindow.showMinimiseSubmenu
            width: 135
            height: minCol.height + 10
            x: parent.width + 2
            y: 64

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: dockWindow.menuBgColor
                border.color: dockWindow.menuBorderColor
                border.width: 0.6

                Rectangle {
                    anchors.fill: parent; anchors.margins: 0.6; radius: 7.4
                    color: "transparent"; border.color: dockWindow.menuInnerHighlight; border.width: 0.6
                }
            }

            Column {
                id: minCol
                x: 0; y: 5; width: parent.width; spacing: 1

                Item {
                    width: parent.width; height: 21
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                        color: genieMa.containsMouse ? "#007aff" : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            text: (dockWindow.minimizeEffect === "genie" ? "✓ " : "  ") + "Genie Effect"
                            font.family: sfMedium.name; font.pixelSize: 13
                            color: genieMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                        }
                        MouseArea {
                            id: genieMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: { dockWindow.minimizeEffect = "genie"; dockWindow.closeAllMenus() }
                        }
                    }
                }

                Item {
                    width: parent.width; height: 21
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; radius: 4.5
                        color: scaleEffMa.containsMouse ? "#007aff" : "transparent"
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            text: (dockWindow.minimizeEffect === "scale" ? "✓ " : "  ") + "Scale Effect"
                            font.family: sfMedium.name; font.pixelSize: 13
                            color: scaleEffMa.containsMouse ? "#ffffff" : dockWindow.menuTextColor
                        }
                        MouseArea {
                            id: scaleEffMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: { dockWindow.minimizeEffect = "scale"; dockWindow.closeAllMenus() }
                        }
                    }
                }
            }
        }
    }

    FontLoader { id: sfMedium; source: "../../../../../../Library/Fonts/SF-Pro-Text-Medium.otf" }
    FontLoader { id: sfBold; source: "../../../../../../Library/Fonts/SF-Pro-Text-Bold.otf" }
}
