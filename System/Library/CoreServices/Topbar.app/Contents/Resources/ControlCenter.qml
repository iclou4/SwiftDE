import QtQuick
import QtQuick.Shapes
import SwiftDE 1.0

Item {
    id: ccRoot
    property bool isOpen: false
    property var sysProcRef: null
    property string currentView: "main" // "main" or "wifi"

    FontLoader {
        id: sfSymbols
        source: "Fonts/SF-Symbols-6.otf"
    }

    width: 315
    height: cardBox.height

    visible: opacity > 0.001
    opacity: isOpen ? 1.0 : 0.0
    scale: isOpen ? 1.0 : 0.94
    y: isOpen ? 32 : 22
    transformOrigin: Item.TopRight

    // Reset to main view whenever opened
    onIsOpenChanged: {
        if (isOpen) {
            currentView = "main"
            if (sysProcRef) sysProcRef.refreshWifiNetworks()
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: ccRoot.isOpen ? 240 : 160
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ccRoot.isOpen ? [0.16, 1.0, 0.3, 1.0] : [0.25, 1.0, 0.5, 1.0]
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: ccRoot.isOpen ? 240 : 160
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ccRoot.isOpen ? [0.16, 1.0, 0.3, 1.0] : [0.25, 1.0, 0.5, 1.0]
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: ccRoot.isOpen ? 240 : 160
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ccRoot.isOpen ? [0.16, 1.0, 0.3, 1.0] : [0.25, 1.0, 0.5, 1.0]
        }
    }

    // Outer Frosted Glass Card Container (Exact macOS Sequoia light frosted material)
    Rectangle {
        id: cardBox
        width: 315
        height: (ccRoot.currentView === "wifi" ? wifiCol.height : mainCol.height) + 20
        radius: 20
        color: Qt.rgba(0.92, 0.92, 0.94, 0.72)
        border.color: Qt.rgba(0, 0, 0, 0.12)
        border.width: 0.6
        clip: true

        // Outer subtle drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: 21
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.14)
            border.width: 1
            z: -1
        }

        Behavior on height {
            NumberAnimation {
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.16, 1.0, 0.3, 1.0]
            }
        }

        // Catch clicks on card so they don't fall through to backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // ==========================================
        // VIEW 1: MAIN CONTROL CENTER
        // ==========================================
        Item {
            id: mainContainer
            x: ccRoot.currentView === "main" ? 10 : -315
            y: 10
            width: parent.width - 20
            implicitHeight: mainCol.height
            opacity: ccRoot.currentView === "main" ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on x {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.16, 1.0, 0.3, 1.0]
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Column {
                id: mainCol
                width: parent.width
                spacing: 9

                // ROW 1: Connectivity Card (Left) + Focus/Stage/Mirroring (Right)
                Row {
                    width: parent.width
                    height: 110
                    spacing: 9

                    // Connectivity 3-row Card
                    Rectangle {
                        width: 143
                        height: 110
                        radius: 14
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                        border.color: Qt.rgba(1, 1, 1, 0.40)
                        border.width: 0.5

                        Column {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 1

                            // --- Row 1: Wi-Fi ---
                            Item {
                                width: parent.width
                                height: 32

                                Rectangle {
                                    id: wifiRowHover
                                    anchors.fill: parent
                                    radius: 10
                                    color: wifiRowMa.containsMouse ? Qt.rgba(0, 0, 0, 0.06) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }

                                // Wi-Fi Icon extracted from reference
                                Item {
                                    id: wifiIconBox
                                    x: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26
                                    height: 26

                                    Image {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        source: "Assets/cc_wifi.png"
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        opacity: (sysProcRef && sysProcRef.wifiEnabled) ? 1.0 : 0.40
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (sysProcRef) sysProcRef.toggleWifi()
                                        }
                                    }
                                }

                                // Wi-Fi Labels
                                Column {
                                    anchors.left: wifiIconBox.right
                                    anchors.leftMargin: 8
                                    anchors.right: wifiChevron.left
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Text {
                                        text: "Wi-Fi"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: "#1c1c1e"
                                    }
                                    Text {
                                        text: (sysProcRef && sysProcRef.wifiEnabled) ? (sysProcRef.wifiSsid !== "" ? sysProcRef.wifiSsid : "On") : "Off"
                                        font.pixelSize: 10
                                        color: "#636366"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }

                                Text {
                                    id: wifiChevron
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "›"
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    color: "#48484a"
                                }

                                // Click on row opens Wi-Fi details view
                                MouseArea {
                                    id: wifiRowMa
                                    anchors.fill: parent
                                    anchors.leftMargin: 30
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (sysProcRef) sysProcRef.refreshWifiNetworks()
                                        ccRoot.currentView = "wifi"
                                    }
                                }
                            }

                            // --- Row 2: Bluetooth ---
                            Item {
                                width: parent.width
                                height: 32

                                Rectangle {
                                    id: btRowHover
                                    anchors.fill: parent
                                    radius: 10
                                    color: btRowMa.containsMouse ? Qt.rgba(0, 0, 0, 0.06) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }

                                Item {
                                    id: btIconBox
                                    x: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26
                                    height: 26

                                    Image {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        source: "Assets/cc_bluetooth.png"
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        opacity: (sysProcRef && sysProcRef.bluetoothEnabled) ? 1.0 : 0.40
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (sysProcRef) sysProcRef.toggleBluetooth()
                                        }
                                    }
                                }

                                Column {
                                    anchors.left: btIconBox.right
                                    anchors.leftMargin: 8
                                    anchors.right: btChevron.left
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Text {
                                        text: "Bluetooth"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: "#1c1c1e"
                                    }
                                    Text {
                                        text: (sysProcRef && sysProcRef.bluetoothEnabled) ? "On" : "Off"
                                        font.pixelSize: 10
                                        color: "#636366"
                                    }
                                }

                                Text {
                                    id: btChevron
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "›"
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    color: "#48484a"
                                }

                                MouseArea {
                                    id: btRowMa
                                    anchors.fill: parent
                                    anchors.leftMargin: 30
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (sysProcRef) sysProcRef.toggleBluetooth()
                                    }
                                }
                            }

                            // --- Row 3: AirDrop ---
                            Item {
                                width: parent.width
                                height: 32

                                Rectangle {
                                    id: airdropRowHover
                                    anchors.fill: parent
                                    radius: 10
                                    color: airdropRowMa.containsMouse ? Qt.rgba(0, 0, 0, 0.06) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }

                                Item {
                                    id: airdropIconBox
                                    x: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26
                                    height: 26

                                    Image {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        source: "Assets/cc_airdrop.png"
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        opacity: (sysProcRef && sysProcRef.airdropState !== "Off") ? 1.0 : 0.40
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (sysProcRef) sysProcRef.cycleAirdrop()
                                        }
                                    }
                                }

                                Column {
                                    anchors.left: airdropIconBox.right
                                    anchors.leftMargin: 8
                                    anchors.right: airdropChevron.left
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Text {
                                        text: "AirDrop"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: "#1c1c1e"
                                    }
                                    Text {
                                        text: sysProcRef ? sysProcRef.airdropState : "Everyone"
                                        font.pixelSize: 10
                                        color: "#636366"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }

                                Text {
                                    id: airdropChevron
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "›"
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    color: "#48484a"
                                }

                                MouseArea {
                                    id: airdropRowMa
                                    anchors.fill: parent
                                    anchors.leftMargin: 30
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (sysProcRef) sysProcRef.cycleAirdrop()
                                    }
                                }
                            }
                        }
                    }

                    // Right Group: Focus (Top) + Stage Manager & Screen Mirroring (Bottom)
                    Column {
                        width: 143
                        height: 110
                        spacing: 8

                        // Focus Card
                        Rectangle {
                            id: focusBox
                            width: parent.width
                            height: 46
                            radius: 14
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                            border.color: Qt.rgba(1, 1, 1, 0.40)
                            border.width: 0.5

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                Item {
                                    width: 24
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uFE90"
                                        font.family: sfSymbols.name
                                        font.pixelSize: 17
                                        color: (sysProcRef && sysProcRef.focusEnabled) ? "#ffffff" : "#1c1c1e"
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Focus"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: "#1c1c1e"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (sysProcRef) sysProcRef.toggleFocus()
                                }
                            }
                        }

                        // Bottom Row: Stage Manager + Screen Mirroring
                        Row {
                            width: parent.width
                            height: 56
                            spacing: 8

                            // Stage Manager Tile
                            Rectangle {
                                width: 67.5
                                height: 56
                                radius: 14
                                color: (sysProcRef && sysProcRef.stageManagerEnabled) ? "#007aff" : Qt.rgba(1.0, 1.0, 1.0, 0.55)
                                border.color: Qt.rgba(1, 1, 1, 0.40)
                                border.width: 0.5
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Image {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 20
                                        height: 18
                                        source: "Assets/cc_stage_manager.png"
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Stage\nManager"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: (sysProcRef && sysProcRef.stageManagerEnabled) ? "#ffffff" : "#1c1c1e"
                                        horizontalAlignment: Text.AlignHCenter
                                        lineHeight: 0.95
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (sysProcRef) sysProcRef.toggleStageManager()
                                    }
                                }
                            }

                            // Screen Mirroring Tile
                            Rectangle {
                                width: 67.5
                                height: 56
                                radius: 14
                                color: (sysProcRef && sysProcRef.screenMirroringEnabled) ? "#007aff" : Qt.rgba(1.0, 1.0, 1.0, 0.55)
                                border.color: Qt.rgba(1, 1, 1, 0.40)
                                border.width: 0.5
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Image {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 20
                                        height: 18
                                        source: "Assets/cc_screen_mirroring.png"
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Screen\nMirroring"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: (sysProcRef && sysProcRef.screenMirroringEnabled) ? "#ffffff" : "#1c1c1e"
                                        horizontalAlignment: Text.AlignHCenter
                                        lineHeight: 0.95
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (sysProcRef) sysProcRef.toggleScreenMirroring()
                                    }
                                }
                            }
                        }
                    }
                }

                // ROW 2: Display Card with Slider & Circular Thumb Knob
                Rectangle {
                    width: parent.width
                    height: 56
                    radius: 14
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                    border.color: Qt.rgba(1, 1, 1, 0.40)
                    border.width: 0.5

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Text {
                            text: "Display"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: "#1c1c1e"
                        }

                        // Slider Capsule Track
                        Rectangle {
                            id: displayTrack
                            width: parent.width
                            height: 24
                            radius: 12
                            color: Qt.rgba(0.20, 0.20, 0.22, 0.18)
                            clip: true

                            property real val: sysProcRef ? sysProcRef.brightness : 0.8
                            property bool dragging: false

                            // White Progress Fill
                            Rectangle {
                                id: displayFill
                                height: parent.height
                                width: Math.max(24, Math.min(displayTrack.width, displayTrack.width * displayTrack.val))
                                radius: 12
                                color: "#ffffff"

                                // Circular Knob / Thumb at right edge of fill
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: "#ffffff"

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: "transparent"
                                        border.color: Qt.rgba(0, 0, 0, 0.12)
                                        border.width: 0.5
                                    }
                                }
                            }

                            // Sun Icon inside track on left
                            Text {
                                id: sunIcon
                                x: 7
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\uFE41"
                                font.family: sfSymbols.name
                                font.pixelSize: 13
                                color: "#3c3c43"
                                z: 2
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true

                                function handlePos(mouseX) {
                                    var r = Math.max(0.05, Math.min(1.0, mouseX / displayTrack.width))
                                    displayTrack.val = r
                                    if (sysProcRef) sysProcRef.setBrightness(r)
                                }

                                onPressed: (mouse) => {
                                    displayTrack.dragging = true
                                    handlePos(mouse.x)
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) handlePos(mouse.x)
                                }
                                onReleased: {
                                    displayTrack.dragging = false
                                }
                            }
                        }
                    }
                }

                // ROW 3: Sound Card with Slider, Circular Thumb, & AirPlay Button
                Rectangle {
                    width: parent.width
                    height: 56
                    radius: 14
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                    border.color: Qt.rgba(1, 1, 1, 0.40)
                    border.width: 0.5

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Text {
                            text: "Sound"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: "#1c1c1e"
                        }

                        Row {
                            width: parent.width
                            height: 24
                            spacing: 8

                            // Sound Slider Capsule Track
                            Rectangle {
                                id: soundTrack
                                width: parent.width - 32
                                height: 24
                                radius: 12
                                color: Qt.rgba(0.20, 0.20, 0.22, 0.18)
                                clip: true

                                property real volVal: (sysProcRef && !sysProcRef.muted) ? sysProcRef.volume : 0.0
                                property bool dragging: false

                                // White Progress Fill
                                Rectangle {
                                    id: soundFill
                                    height: parent.height
                                    width: Math.max(24, Math.min(soundTrack.width, soundTrack.width * soundTrack.volVal))
                                    radius: 12
                                    color: "#ffffff"

                                    // Circular Knob / Thumb at right edge of fill
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: "#ffffff"

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 12
                                            color: "transparent"
                                            border.color: Qt.rgba(0, 0, 0, 0.12)
                                            border.width: 0.5
                                        }
                                    }
                                }

                                // Speaker Icon inside track on left
                                Text {
                                    id: speakerIcon
                                    x: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "\uFD1D"
                                    font.family: sfSymbols.name
                                    font.pixelSize: 13
                                    color: "#3c3c43"
                                    z: 2
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true

                                    function handlePos(mouseX) {
                                        var r = Math.max(0.0, Math.min(1.0, mouseX / soundTrack.width))
                                        soundTrack.volVal = r
                                        if (sysProcRef) {
                                            if (sysProcRef.muted) sysProcRef.setMuted(false)
                                            sysProcRef.setVolume(r)
                                        }
                                    }

                                    onPressed: (mouse) => {
                                        soundTrack.dragging = true
                                        handlePos(mouse.x)
                                    }
                                    onPositionChanged: (mouse) => {
                                        if (pressed) handlePos(mouse.x)
                                    }
                                    onReleased: {
                                        soundTrack.dragging = false
                                    }
                                }
                            }

                            // AirPlay Audio Circle Button extracted from reference
                            Item {
                                width: 24
                                height: 24

                                Image {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    source: "Assets/cc_airplay.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (sysProcRef) sysProcRef.launch("gnome-control-center sound || true")
                                    }
                                }
                            }
                        }
                    }
                }

                // ROW 4: Now Playing / Music Module
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 14
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                    border.color: Qt.rgba(1, 1, 1, 0.40)
                    border.width: 0.5

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Apple Music red icon from reference
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28
                            source: "Assets/cc_music.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        // Track Title & Subtitle
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 28 - 10 - 56
                            spacing: 1

                            Text {
                                text: (sysProcRef && sysProcRef.mediaTitle !== "") ? sysProcRef.mediaTitle : "Music"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: "#1c1c1e"
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: (sysProcRef && sysProcRef.mediaArtist !== "") ? sysProcRef.mediaArtist : "Apple Music"
                                font.pixelSize: 10
                                color: "#636366"
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Play/Pause & Next Controls
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Play / Pause Button
                            Item {
                                width: 22
                                height: 22

                                Image {
                                    anchors.centerIn: parent
                                    width: 13
                                    height: 13
                                    source: "Assets/cc_play.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    visible: !(sysProcRef && sysProcRef.mediaPlaying)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "❚❚"
                                    font.pixelSize: 11
                                    color: "#1c1c1e"
                                    visible: (sysProcRef && sysProcRef.mediaPlaying)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (sysProcRef) sysProcRef.mediaPlayPause()
                                    }
                                }
                            }

                            // Next Button
                            Item {
                                width: 22
                                height: 22

                                Image {
                                    anchors.centerIn: parent
                                    width: 15
                                    height: 13
                                    source: "Assets/cc_next.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (sysProcRef) sysProcRef.mediaNext()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // VIEW 2: WI-FI SUBMENU (macOS Sequoia)
        // ==========================================
        Item {
            id: wifiContainer
            x: ccRoot.currentView === "wifi" ? 10 : 315
            y: 10
            width: parent.width - 20
            implicitHeight: wifiCol.height
            opacity: ccRoot.currentView === "wifi" ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on x {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.16, 1.0, 0.3, 1.0]
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Column {
                id: wifiCol
                width: parent.width
                spacing: 8

                // Header: Back Button (<), Title ("Wi-Fi"), Toggle Switch
                Row {
                    width: parent.width
                    height: 28
                    spacing: 8

                    // Back Button
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: 12
                        color: backMa.containsMouse ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(0, 0, 0, 0.05)
                        Behavior on color { ColorAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font.pixelSize: 18
                            color: "#1c1c1e"
                        }

                        MouseArea {
                            id: backMa
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                ccRoot.currentView = "main"
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wi-Fi"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#1c1c1e"
                    }

                    Item {
                        // Spacer
                        width: parent.width - 24 - 8 - 40 - 36
                        height: 1
                    }

                    // macOS Toggle Switch
                    Rectangle {
                        id: wifiToggleSwitch
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 20
                        radius: 10
                        color: (sysProcRef && sysProcRef.wifiEnabled) ? "#34c759" : Qt.rgba(0, 0, 0, 0.15)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            id: switchThumb
                            y: 2
                            x: (sysProcRef && sysProcRef.wifiEnabled) ? 18 : 2
                            width: 16
                            height: 16
                            radius: 8
                            color: "#ffffff"

                            Behavior on x {
                                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (sysProcRef) sysProcRef.toggleWifi()
                            }
                        }
                    }
                }

                // If Wi-Fi is Off
                Item {
                    width: parent.width
                    height: 40
                    visible: !(sysProcRef && sysProcRef.wifiEnabled)

                    Text {
                        anchors.centerIn: parent
                        text: "Wi-Fi is Turned Off"
                        font.pixelSize: 12
                        color: "#636366"
                    }
                }

                // If Wi-Fi is On: Available Networks List
                Column {
                    width: parent.width
                    spacing: 4
                    visible: (sysProcRef && sysProcRef.wifiEnabled)

                    Text {
                        text: "AVAILABLE NETWORKS"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: "#8e8e93"
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                    }

                    Repeater {
                        model: (sysProcRef && sysProcRef.wifiNetworks) ? sysProcRef.wifiNetworks : []

                        Rectangle {
                            id: netItem
                            width: wifiCol.width
                            height: 30
                            radius: 8
                            color: netMa.containsPress ? Qt.rgba(0.04, 0.38, 1.0, 0.85)
                                 : (netMa.containsMouse ? Qt.rgba(0, 0, 0, 0.06) : "transparent")
                            Behavior on color { ColorAnimation { duration: 60 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                // Wi-Fi Signal Icon (1, 2, or 3 bars)
                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 14

                                    Shape {
                                        anchors.fill: parent
                                        layer.enabled: true
                                        layer.samples: 4
                                        // Arc 3 (Top)
                                        ShapePath {
                                            strokeWidth: 1.2
                                            strokeColor: (modelData.bars >= 3) ? "#1c1c1e" : Qt.rgba(0, 0, 0, 0.20)
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap
                                            PathAngleArc {
                                                centerX: 7; centerY: 11
                                                radiusX: 9; radiusY: 9
                                                startAngle: -135; sweepAngle: 90
                                            }
                                        }
                                        // Arc 2 (Middle)
                                        ShapePath {
                                            strokeWidth: 1.2
                                            strokeColor: (modelData.bars >= 2) ? "#1c1c1e" : Qt.rgba(0, 0, 0, 0.20)
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap
                                            PathAngleArc {
                                                centerX: 7; centerY: 11
                                                radiusX: 5.5; radiusY: 5.5
                                                startAngle: -135; sweepAngle: 90
                                            }
                                        }
                                        // Dot (Bottom)
                                        ShapePath {
                                            strokeWidth: 0
                                            fillColor: "#1c1c1e"
                                            PathAngleArc {
                                                centerX: 7; centerY: 11
                                                radiusX: 1.3; radiusY: 1.3
                                                startAngle: 0; sweepAngle: 360
                                            }
                                        }
                                    }
                                }

                                // Network SSID
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.ssid || ""
                                    font.pixelSize: 12
                                    font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                    color: netMa.containsPress ? "#ffffff" : "#1c1c1e"
                                    elide: Text.ElideRight
                                    width: parent.width - 70
                                }

                                // Lock Icon if secured
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.secured ? "🔒" : ""
                                    font.pixelSize: 10
                                    color: "#636366"
                                    visible: !!modelData.secured
                                }

                                // Checkmark if active
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.active ? "✓" : ""
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    color: netMa.containsPress ? "#ffffff" : "#007aff"
                                    visible: !!modelData.active
                                }
                            }

                            MouseArea {
                                id: netMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    if (sysProcRef) sysProcRef.connectToNetwork(modelData.ssid)
                                }
                            }
                        }
                    }
                }

                // Separator Line
                Rectangle {
                    width: parent.width
                    height: 0.5
                    color: Qt.rgba(0, 0, 0, 0.10)
                }

                // Wi-Fi Settings Link Item
                Rectangle {
                    width: parent.width
                    height: 26
                    radius: 6
                    color: settingsMa.containsMouse ? Qt.rgba(0, 0, 0, 0.06) : "transparent"
                    Behavior on color { ColorAnimation { duration: 60 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wi-Fi Settings..."
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: "#1c1c1e"
                    }

                    MouseArea {
                        id: settingsMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (sysProcRef) sysProcRef.launch("gnome-control-center wifi || gnome-control-center network || true")
                        }
                    }
                }
            }
        }
    }
}
