import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

// Debug variant: no masks/effects. Isolates avatar load + field color.
Window {
    visible: true
    visibility: Window.FullScreen
    color: "black"
    title: "SwiftDE Debug"

    FontLoader { id: sfPro; source: "../../../../Fonts/SF-Pro-Display-Regular.otf" }

    Image {
        id: wp
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: "../../../../../../Library/DesktopPictures/Wallpaper.jpg"
        onStatusChanged: console.log("WP status:", status)
    }
    Image {
        x: (parent.width - 100) / 2
        y: parent.height * 0.75
        width: 100
        height: 100
        fillMode: Image.PreserveAspectCrop
        source: "../../../../../../Library/UserPictures/Avatar.jpg"
        onStatusChanged: console.log("AV status:", status)
    }
    TextField {
        x: (parent.width - 200) / 2
        y: parent.height * 0.87
        width: 200
        height: 40
        placeholderText: "Enter Password"
        echoMode: TextInput.Password
        font.family: sfPro.status === FontLoader.Ready ? sfPro.name : "Sans Serif"
        font.pixelSize: 16
        color: "white"
        placeholderTextColor: "#ffffffcc"
        background: Rectangle { radius: 20; color: "#ffffff2e" }
    }
    Component.onCompleted: console.log("DEBUG READY")
}
