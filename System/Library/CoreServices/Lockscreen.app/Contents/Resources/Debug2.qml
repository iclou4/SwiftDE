import QtQuick
import Qt5Compat.GraphicalEffects

// Debug2: visible Image + layer OpacityMask circle.
Window {
    visible: true
    visibility: Window.FullScreen
    color: "black"
    title: "SwiftDE Debug2"

    Rectangle {
        id: circleMask
        width: 200
        height: 200
        radius: 100
        visible: false
    }
    Image {
        id: av
        x: (parent.width - 200) / 2
        y: (parent.height - 200) / 2
        width: 200
        height: 200
        fillMode: Image.PreserveAspectCrop
        source: "../../../../../../Library/UserPictures/Avatar.jpg"
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: circleMask
        }
        onStatusChanged: console.log("AV2 status:", status)
    }
    Component.onCompleted: console.log("DEBUG2 READY")
}
