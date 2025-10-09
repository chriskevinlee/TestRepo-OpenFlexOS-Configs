import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

import "./components"

Rectangle {
    id: root

    height: Screen.height
    width: Screen.width

    Image {
        anchors { fill: parent }

        source: config.BgSource
        fillMode: Image.PreserveAspectCrop
        clip: true
    }

    Item {
        anchors {
            fill: parent
            margins: config.Padding
        }

        DateTimePanel {
            anchors {
                top: parent.top
                right: parent.right
            }
        }

        Text {
            text: "Welcome! to\nOpenFlexOS"
            color: "#d2691e"
            font.pointSize: 48 // Adjust font size as needed
            anchors.horizontalCenter: parent.horizontalCenter // Positioning
            anchors.left: parent.left // Positioning
        }

        LoginPanel {
            anchors { fill: parent }
        }
    }
}
