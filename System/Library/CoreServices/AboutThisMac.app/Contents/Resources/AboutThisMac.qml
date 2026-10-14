import QtQuick
import QtQuick.Window
import SwiftDE 1.0

Window {
    id: aboutWindow
    title: "About This Mac"
    x: Screen.width > 0 ? Math.round((Screen.width - 260) / 2) : 510
    y: Screen.height > 0 ? Math.round((Screen.height - 418) / 2) : 191
    width: 260
    height: 418
    minimumWidth: 260
    maximumWidth: 260
    minimumHeight: 418
    visible: true
    color: "transparent"
    flags: Qt.Dialog | Qt.MSWindowsFixedSizeDialogHint | Qt.FramelessWindowHint

    SysProc {
        id: sysProc
    }

    FontLoader {
        id: sfDisplayBold
        source: "../../../../../../Library/Fonts/SF-Pro-Display-Bold.otf"
    }

    FontLoader {
        id: sfTextMedium
        source: "../../../../../../Library/Fonts/SF-Pro-Text-Medium.otf"
    }

    FontLoader {
        id: sfTextBold
        source: "../../../../../../Library/Fonts/SF-Pro-Text-Bold.otf"
    }

    // Outer card container with native 12px macOS corner radius and authentic light frosted acrylic glass
    Rectangle {
        id: card
        width: 260
        height: 418
        anchors.centerIn: parent
        radius: 12
        color: "#94ebe6dd" // Deeper warm translucent frosted acrylic matching macOS Sequoia light material
        border.color: "#35ffffff"
        border.width: 1
        clip: true

        // Native Wayland compositor window drag via startSystemMove
        MouseArea {
            id: dragArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    aboutWindow.startSystemMove()
                }
            }
        }

        // Top traffic light buttons
        Row {
            x: 12
            y: 12
            spacing: 6
            z: 20

            // Close (Red) button
            Rectangle {
                id: closeBtn
                width: 10
                height: 10
                radius: 5
                color: "#ff5f57"
                border.color: "#e0443e"
                border.width: 0.5

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: "#4d0000"
                    visible: closeMouse.containsMouse
                    y: -1
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        closeAnimation.start()
                    }
                }
            }

        ParallelAnimation {
            id: closeAnimation
            NumberAnimation {
                target: card
                property: "opacity"
                to: 0.0
                duration: 90
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: card
                property: "scale"
                to: 0.94
                duration: 90
                easing.type: Easing.OutQuad
            }
            onFinished: Qt.quit()
        }

            // Minimize (Disabled in Sequoia About This Mac)
            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: "#18000000"
                border.color: "#10000000"
                border.width: 0.5
            }

            // Zoom (Disabled in Sequoia About This Mac)
            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: "#18000000"
                border.color: "#10000000"
                border.width: 0.5
            }
        }

        // Mac Pro Device Icon
        Image {
            id: deviceImage
            source: "MacDevice.png"
            width: 104
            height: 104
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            y: 32
            smooth: true
            mipmap: true
            z: 2
        }

        // Device Model Title
        Text {
            id: titleText
            text: "Mac Pro"
            font.family: sfDisplayBold.name !== "" ? sfDisplayBold.name : "sans-serif"
            font.pixelSize: 17
            font.weight: Font.Bold
            color: "#111111"
            anchors.top: deviceImage.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            z: 2
        }

        // Subtitle / Year - darker grey for high contrast
        Text {
            id: subtitleText
            text: "2019"
            font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
            font.pixelSize: 11
            color: "#3a3a3e"
            anchors.top: titleText.bottom
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            z: 2
        }

        // Real System Specs Grid - Divider perfectly centered at card midpoint
        Column {
            id: specsColumn
            anchors.top: subtitleText.bottom
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            z: 2

            // Row 1: Processor
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignRight
                    text: "Processor"
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#2c2c2e"
                }
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignLeft
                    text: sysProc.cpuModel()
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#111111"
                    wrapMode: Text.WordWrap
                }
            }

            // Row 2: Memory
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignRight
                    text: "Memory"
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#2c2c2e"
                }
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignLeft
                    text: sysProc.memoryTotal()
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#111111"
                }
            }

            // Row 3: Startup disk
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignRight
                    text: "Startup disk"
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#2c2c2e"
                }
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignLeft
                    text: sysProc.startupDisk()
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#111111"
                    elide: Text.ElideRight
                }
            }

            // Row 4: Serial number
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignRight
                    text: "Serial number"
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#2c2c2e"
                }
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignLeft
                    text: sysProc.serialNumber()
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#111111"
                }
            }

            // Row 5: swiftOS
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignRight
                    text: "swiftOS"
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#2c2c2e"
                }
                Text {
                    width: 112
                    horizontalAlignment: Text.AlignLeft
                    text: "Sequoia 15.0"
                    font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                    font.pixelSize: 11
                    color: "#111111"
                }
            }
        }

        // "More Info..." Button (compact, tight padding matching macOS)
        Rectangle {
            id: moreInfoBtn
            anchors.top: specsColumn.bottom
            anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            width: moreInfoText.implicitWidth + 22
            height: 22
            radius: 5
            color: moreInfoMouse.pressed ? "#35000000" : (moreInfoMouse.containsMouse ? "#20000000" : "#12000000")
            border.color: "#18000000"
            border.width: 0.5
            z: 20

            Text {
                id: moreInfoText
                anchors.centerIn: parent
                text: "More Info..."
                font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
                font.pixelSize: 11
                color: "#111111"
            }

            MouseArea {
                id: moreInfoMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    sysProc.launch("gnome-control-center || true")
                }
            }
        }

        // "Regulatory Certification" Link - darker grey for contrast
        Text {
            id: regCert
            anchors.top: moreInfoBtn.bottom
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Regulatory Certification"
            font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
            font.pixelSize: 10
            font.underline: regMouse.containsMouse
            color: regMouse.containsMouse ? "#0055bb" : "#3a3a3e"
            z: 20

            MouseArea {
                id: regMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Optional regulatory info dialog
                }
            }
        }

        // Apple Copyright Notice - darker grey for readability
        Text {
            id: copyrightText
            anchors.top: regCert.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            text: "™ and © 1983-2024 Apple Inc.\nAll Rights Reserved."
            font.family: sfTextMedium.name !== "" ? sfTextMedium.name : "sans-serif"
            font.pixelSize: 9
            color: "#55555a"
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.15
            z: 2
        }
    }
}
