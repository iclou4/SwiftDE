import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import SwiftDE 1.0

// SwiftDE Lockscreen — macOS-style, ported 1:1 from reference.
Window {
    id: loginWindow
    visible: false
    color: "black"
    title: "SwiftDE Lockscreen"

    FontLoader { id: rundeMedium; source: "../../../../Fonts/OpenRunde-Medium.otf" }
    FontLoader { id: rundeSemibold; source: "../../../../Fonts/OpenRunde-Semibold.otf" }
    FontLoader { id: sfPro; source: "../../../../Fonts/SF-Pro-Display-Regular.otf" }

    property string dateFont: rundeMedium.status === FontLoader.Ready ? rundeMedium.name : "Sans Serif"
    property string clockFont: rundeSemibold.status === FontLoader.Ready ? rundeSemibold.name : "Sans Serif"
    property string pwFont: sfPro.status === FontLoader.Ready ? sfPro.name : "Sans Serif"

    // Viewport-fraction metrics (frozen from reference).
    property real clockFS: height * 0.125
    property real dateFS: height * 0.03125
    property real clockBase: height * 0.2396
    property real dateBase: height * 0.1146
    property bool failed: false

    // Click anywhere to focus password field (macOS behavior)
    MouseArea {
        anchors.fill: parent
        onClicked: passwordField.forceActiveFocus()
    }

    // --- Wallpaper (cover) ---
    Image {
        id: wallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: "../../../../../../Library/DesktopPictures/Wallpaper.jpg"
    }
    Rectangle { // fallback if wallpaper missing
        anchors.fill: parent
        visible: wallpaper.status !== Image.Ready
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#55a047" }
            GradientStop { position: 1.0; color: "#1d5b26" }
        }
    }

    // --- Frosted-Glass Source (clock & date: highlight + contrast boost) ---
    FastBlur {
        id: glassBlur
        anchors.fill: parent
        source: wallpaper
        radius: Math.max(12, height * 0.031)
        visible: false
    }
    BrightnessContrast {
        id: glassTint
        anchors.fill: parent
        source: glassBlur
        brightness: 0.18
        contrast: 0.22
        visible: false
    }

    // --- Frosted-Glass Source (field: stronger blur + highlight boost) ---
    FastBlur {
        id: fieldGlassBlur
        anchors.fill: parent
        source: wallpaper
        radius: Math.max(24, height * 0.065)
        visible: false
    }
    BrightnessContrast {
        id: fieldGlassTint
        anchors.fill: parent
        source: fieldGlassBlur
        brightness: 0.20
        contrast: 0.25
        visible: false
    }

    // --- Date (frosted glyphs, Open Runde Medium) ---
    Item {
        anchors.fill: parent

        Item {
            id: dateMaskItem
            anchors.fill: parent
            Text {
                x: dateCrisp.x
                y: dateCrisp.y
                font.family: dateFont
                font.weight: Font.Medium
                font.pixelSize: dateFS
                text: dateCrisp.text
                color: "white"
            }
        }

        ShaderEffectSource {
            id: dateMaskSource
            anchors.fill: parent
            sourceItem: dateMaskItem
            hideSource: true
            live: true
        }

        OpacityMask {
            anchors.fill: parent
            source: glassTint
            maskSource: dateMaskSource
        }

        Text {
            id: dateCrisp
            x: (parent.width - width) / 2
            y: Math.round(dateBase - baselineOffset)
            font.family: dateFont
            font.weight: Font.Medium
            font.pixelSize: dateFS
            color: "#ffffff"
            opacity: 0.70
            text: "--"
        }
    }

    // --- Clock (frosted glyphs, Open Runde SemiBold, raised colon) ---
    Item {
        anchors.fill: parent

        Item {
            id: clockMaskItem
            anchors.fill: parent
            Row {
                x: clockCrisp.x
                y: clockCrisp.y
                spacing: -clockFS * 0.04
                Text { font.family: clockFont; font.weight: Font.DemiBold; font.pixelSize: clockFS; text: clockH.text; color: "white" }
                Text { text: ":"; font.family: clockFont; font.weight: Font.DemiBold; font.pixelSize: clockFS; y: -clockFS * 0.0625; color: "white" }
                Text { font.family: clockFont; font.weight: Font.DemiBold; font.pixelSize: clockFS; text: clockM.text; color: "white" }
            }
        }

        ShaderEffectSource {
            id: clockMaskSource
            anchors.fill: parent
            sourceItem: clockMaskItem
            hideSource: true
            live: true
        }

        OpacityMask {
            anchors.fill: parent
            source: glassTint
            maskSource: clockMaskSource
        }

        Row {
            id: clockCrisp
            x: (parent.width - width) / 2
            y: Math.round(clockBase - clockH.baselineOffset)
            spacing: -clockFS * 0.04
            Text { id: clockH; font.family: clockFont; font.weight: Font.DemiBold; font.pixelSize: clockFS; color: "#ffffff"; opacity: 0.60; text: "9" }
            Text { text: ":"; font.family: clockFont; font.weight: Font.DemiBold; font.pixelSize: clockFS; color: "#ffffff"; opacity: 0.60; y: -clockFS * 0.0625 }
            Text { id: clockM; font.family: clockFont; font.weight: Font.DemiBold; font.pixelSize: clockFS; color: "#ffffff"; opacity: 0.60; text: "19" }
        }
    }

    // --- Avatar (pre-rendered circle PNG) ---
    Image {
        id: avatarImg
        x: (parent.width - width) / 2
        y: loginWindow.height * 0.7995
        width: loginWindow.height * 0.0625
        height: width
        source: "../../../../../../Library/UserPictures/AvatarCircle.png"
    }

    // --- Password field (frosted glass capsule + input) ---
    Item {
        anchors.fill: parent

        Rectangle {
            id: fieldMaskRect
            x: (parent.width - width) / 2
            y: loginWindow.height * 0.8776
            width: loginWindow.width * 0.078
            height: loginWindow.height * 0.03
            radius: height / 2
            visible: false
        }

        Item {
            id: fieldMaskItem
            anchors.fill: parent
            Rectangle {
                x: fieldMaskRect.x; y: fieldMaskRect.y
                width: fieldMaskRect.width; height: fieldMaskRect.height
                radius: fieldMaskRect.radius
                color: "white"
            }
        }

        ShaderEffectSource {
            id: fieldMaskSource
            anchors.fill: parent
            sourceItem: fieldMaskItem
            hideSource: true
            live: true
        }

        OpacityMask {
            anchors.fill: parent
            source: fieldGlassTint
            maskSource: fieldMaskSource
        }

        TextField {
            id: passwordField
            x: fieldMaskRect.x; y: fieldMaskRect.y
            width: fieldMaskRect.width; height: fieldMaskRect.height
            leftPadding: height * 0.55
            rightPadding: height * 0.55
            verticalAlignment: TextInput.AlignVCenter
            placeholderText: qsTr("Enter Password")
            echoMode: TextInput.Password
            font.family: pwFont
            font.pixelSize: loginWindow.height * 0.013
            color: "#ffffff"
            placeholderTextColor: Qt.rgba(1.0, 1.0, 1.0, 0.8)
            selectByMouse: true
            selectionColor: Qt.rgba(1.0, 1.0, 1.0, 0.3)
            background: Rectangle {
                radius: height / 2
                color: loginWindow.failed ? Qt.rgba(122 / 255.0, 31 / 255.0, 31 / 255.0, 0.8) : Qt.rgba(1.0, 1.0, 1.0, 0.24)
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.16)
                border.width: 1
            }
            onAccepted: loginWindow.attemptUnlock()
            Keys.onEscapePressed: clear()
        }
    }

    function attemptUnlock() {
        if (passwordField.text.length === 0) {
            failed = true
            shakeAnim.restart()
            failedReset.restart()
            return
        }
        // Real check: PAM via setuid helper, only the caller's own account.
        if (sysProc.checkPassword(sysProc.userName(), passwordField.text) === 0) {
            passwordField.clear()
            Qt.quit()
        } else {
            failed = true
            shakeAnim.restart()
            failedReset.restart()
        }
    }
    SysProc { id: sysProc }

    Timer { id: failedReset; interval: 1200; onTriggered: loginWindow.failed = false }
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: passwordField; property: "x"; from: passwordField.x - 8; to: passwordField.x + 8; duration: 60 }
        NumberAnimation { target: passwordField; property: "x"; from: passwordField.x + 8; to: passwordField.x - 5; duration: 60 }
        NumberAnimation { target: passwordField; property: "x"; from: passwordField.x - 5; to: fieldMaskRect.x; duration: 60 }
    }

    function tick() {
        var d = new Date()
        var h = String(d.getHours()), m = ("0" + d.getMinutes()).slice(-2)
        clockH.text = h
        clockM.text = m
        var ds = d.toLocaleDateString(Qt.locale("en_US"), "dddd, MMMM d")
        dateCrisp.text = ds
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: loginWindow.tick() }

    Timer {
        id: focusBurstTimer
        interval: 80
        repeat: true
        running: true
        property int burstCount: 0
        onTriggered: {
            passwordField.forceActiveFocus()
            burstCount++
            if (burstCount > 6) {
                running = false
            }
        }
    }

    Component.onCompleted: {
        console.log("FONTS medium=" + rundeMedium.status + " semibold=" + rundeSemibold.status
            + " sfpro=" + sfPro.status + " clockFont=" + clockFont)
        loginWindow.tick()
        passwordField.forceActiveFocus()
    }
}
