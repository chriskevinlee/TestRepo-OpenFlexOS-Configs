import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import QtMultimedia
import "Components"

Item {
    id: root
    width: Screen.width
    height: Screen.height

    FontLoader { id: segoeui; source: Qt.resolvedUrl("fonts/Segoe-UI-Variable-Static-Display.ttf") }
    FontLoader { id: segoeuisb; source: Qt.resolvedUrl("fonts/Segoe-UI-Variable-Static-Display-Semibold.ttf") }
    FontLoader { id: iconfont; source: Qt.resolvedUrl("fonts/Segoe-Fluent-Icons.ttf") }

    Rectangle {
        id: background
        anchors.fill: parent
        width: parent.width
        height: parent.height

        Image { id: bgimg; anchors.fill: parent; source: config.background; visible: false }

        MediaPlayer { id: startupSound; autoPlay: true; source: Qt.resolvedUrl("Assets/Startup-Sound.wav"); audioOutput: AudioOutput {} }

        GaussianBlur { anchors.fill: bgimg; source: bgimg; radius: 60; samples: 50 }

        Rectangle { anchors.fill: parent; color: "#1A000000" }
    }

    Rectangle {
        id: startupBg
        width: Screen.width
        height: Screen.height
        color: "transparent"
        z: 4

        Image { anchors.fill: parent; source: config.background; smooth: true }
        Rectangle { anchors.fill: parent; color: "#1A000000" }

        // --- custom text before login ---
        Text {
            id: preLoginMessage
            text: "Welcome to OpenFlexOS"
            color: "white"
            font.family: segoeuisb.name
            font.pointSize: 24
            font.weight: Font.DemiBold
            opacity: 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 180
            z: 5
        }

        // --- initial click/drag to show login ---
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            drag.target: timeDate
            drag.axis: Drag.YAxis
            drag.minimumY: -Screen.height / 2
            drag.maximumY: 0
            focus: true

            onClicked: {
                listView.focus = true
                mouseArea.focus = false
                mouseArea.enabled = false
                seqStart.start()
                parStart.start()
            }

            Keys.onPressed: {
                listView.focus = true
                mouseArea.focus = false
                mouseArea.enabled = false
                seqStart.start()
                parStart.start()
            }

            property bool dragActive: drag.active

            onDragActiveChanged: {
                if (!drag.active) {
                    listView.focus = true
                    mouseArea.focus = false
                    mouseArea.enabled = false
                    seqStart.start()
                    parslideStart.start()
                }
            }
        }

        // --- animations for forward transition ---
        ParallelAnimation {
            id: parStart
            running: false
            NumberAnimation { target: timeDate; properties: "y"; from: 0; to: -100; duration: 150 }
            NumberAnimation { target: timeDate; properties: "visible"; from: 1; to: 0; duration: 175 }
            NumberAnimation { target: startupBg; properties: "opacity"; from: 1; to: 0; duration: 180 }
        }

        ParallelAnimation {
            id: parslideStart
            running: false
            NumberAnimation { target: startupBg; properties: "opacity"; from: 1; to: 0; duration: 100 }
        }

        SequentialAnimation {
            id: seqStart
            running: false
            ParallelAnimation {
                ScaleAnimator { target: background; from: 1; to: 1.01; duration: 250 }
                NumberAnimation { target: centerPanel; properties: "opacity"; from: 0; to: 1; duration: 225 }
                NumberAnimation { target: rightPanel; properties: "opacity"; from: 0; to: 1; duration: 100 }
                NumberAnimation { target: leftPanel; properties: "opacity"; from: 0; to: 1; duration: 100 }
            }
        }

        // === reverse animation (go back to clock) ===
        ParallelAnimation {
            id: parBack
            running: false

            NumberAnimation { target: timeDate; properties: "y"; to: 0; duration: 150 }
            NumberAnimation { target: timeDate; properties: "visible"; to: 1; duration: 175 }
            NumberAnimation { target: startupBg; properties: "opacity"; to: 1; duration: 180 }

            onStopped: {
                mouseArea.enabled = true
                mouseArea.focus = true
                listView.focus = false
            }
        }

        ParallelAnimation {
            id: panelsOut
            running: false
            NumberAnimation { target: centerPanel; properties: "opacity"; to: 0; duration: 225 }
            NumberAnimation { target: rightPanel;  properties: "opacity"; to: 0; duration: 150 }
            NumberAnimation { target: leftPanel;   properties: "opacity"; to: 0; duration: 150 }
        }

        Rectangle {
            id: timeDate
            width: parent.width
            height: parent.height
            color: "transparent"

            Column {
                id: timeContainer
                anchors.top: parent.top
                anchors.topMargin: 145
                anchors.horizontalCenter: parent.horizontalCenter
                property date dateTime: new Date()
                Timer { interval: 100; running: true; repeat: true; onTriggered: timeContainer.dateTime = new Date() }

                Text {
                    id: time
                    color: "white"
                    font.pointSize: 94
                    font.family: Qt.resolvedUrl("../fonts") ? "Segoe UI Variable Static Display" : segoeuisb.name
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                    text: Qt.formatTime(timeContainer.dateTime, "hh:mm")
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle { width: 5; height: 5; color: "transparent"; anchors.horizontalCenter: parent.horizontalCenter }

                Text {
                    id: date
                    color: "white"
                    font.pointSize: 19
                    font.family: Qt.resolvedUrl("../fonts") ? "Segoe UI Variable Static Display" : segoeuisb.name
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignLeft
                    text: Qt.formatDate(timeContainer.dateTime, "dddd, d MMMM")
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // === main login panel ===
    Item {
        id: centerPanel
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.width / 1.75
        z: 2
        opacity: 0
        focus: true

        // allow ESC to go back
        Keys.onPressed: {
            if (event.key === Qt.Key_Escape && centerPanel.opacity > 0.01) {
                panelsOut.start()
                parBack.start()
                event.accepted = true
            }
        }

        Item {
            Component {
                id: userDelegate
                FocusScope {
                    anchors.centerIn: parent
                    name: (model.realName === "") ? model.name : model.realName
                    icon: "/var/lib/AccountsService/icons/" + model.name
                    property alias icon: icon.source
                    property alias name: name.text
                    property alias password: passwordField.text
                    property alias passwordpin: passwordFieldPin.text
                    property int session: sessionPanel.session
                    width: 296; height: 500

                    Connections {
                        target: sddm
                        function onLoginFailed() {
                            truePass.visible = false
                            passwordField.visible = false; passwordField.enabled = false; passwordField.focus = false
                            passwordFieldPin.visible = false; passwordFieldPin.enabled = false; passwordFieldPin.focus = false
                            rightPanel.visible = false; leftPanel.visible = false
                            falsePass.visible = true; falsePass.focus = true
                            bootani.stop()
                        }
                        function onLoginSucceeded() {}
                    }

                    Rectangle {
                        width: Screen.width; height: Screen.height; color: "transparent"
                        Image { id: fakebg; anchors.fill: parent; source: config.background; visible: false }
                        GaussianBlur { anchors.fill: fakebg; source: fakebg; radius: 60; samples: 50 }
                        Rectangle { anchors.fill: parent; color: "#1A000000" }
                        x: { if(1680===Screen.width) -Screen.width/2+28; else if(1600===Screen.width) -Screen.width/2+34; else -Screen.width/2+11 }
                        y: -Screen.height/2
                    }

                    Image {
                        id: icon; width:192; height:192; smooth:true; visible:false
                        onStatusChanged: {
                            if (icon.status == Image.Error) icon.source = "Assets/user-192.png"
                            else "/var/lib/AccountsService/icons/" + name
                        }
                        x: -(icon.width / 2)
                        y: -(icon.width * 2) + (icon.width * 0.8)
                    }

                    OpacityMask { anchors.fill: icon; source: icon; maskSource: mask }

                    Item {
                        id: mask; width: icon.width; height: icon.height; layer.enabled: true; visible: false
                        Rectangle { width: icon.width; height: icon.height; radius: width / 2; color: "black" }
                    }

                    Text {
                        id: name
                        color: "white"
                        font.pointSize: 27
                        font.family: Qt.resolvedUrl("../fonts") ? "Segoe UI Variable Static Display" : segoeuisb.name
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                        anchors.topMargin: 15
                        anchors.horizontalCenter: icon.horizontalCenter
                        anchors.top: icon.bottom
                    }

                    PasswordField {
                        id: passwordField
                        visible: config.PinMode === "off"
                        enabled: config.PinMode === "off"
                        focus: config.PinMode === "off"
                        x: -135
                        anchors.topMargin: 25
                        anchors.top: name.bottom

                        Keys.onReturnPressed: {
                            truePass.visible = true
                            passwordField.visible = false; passwordField.enabled = false
                            passwordFieldPin.visible = false; passwordFieldPin.enabled = false
                            rightPanel.visible = false; leftPanel.visible = false
                            sddm.login(model.name, password, session)
                            bootani.start(); capsOn.z = -1
                        }
                        Keys.onEnterPressed: Keys.onReturnPressed()
                    }

                    PasswordFieldPin {
                        id: passwordFieldPin
                        visible: config.PinMode !== "off"
                        enabled: config.PinMode !== "off"
                        focus: config.PinMode !== "off"
                        x: -135
                        property int pinSize: config.PinSize
                        function calculateTopValue(size){ return parseInt('9'.repeat(size)) }
                        validator: IntValidator { bottom: 1; top: calculateTopValue(pinSize) }

                        onTextChanged: {
                            passwordFieldPin.width = passwordFieldPin.text !== "" ? 225 : 296
                            revealButton.visible = passwordFieldPin.text !== ""
                            if (config.PinSize == passwordFieldPin.length) {
                                falsePass.visible = true
                                passwordField.visible = false; passwordField.enabled = false
                                passwordFieldPin.visible = false; passwordFieldPin.enabled = false
                                rightPanel.visible = false; leftPanel.visible = false
                                sddm.login(model.name, password, session)
                                bootani.start(); capsOn.z = -1
                            }
                        }

                        RevealButton { id: revealButton; visible: false; y: 7; anchors.right: passFieldBackgroundPin.right; anchors.rightMargin: 7 }
                        background: Rectangle { id: passFieldBackgroundPin; color: "#BF1C1C1C"; border.color: "#15FFFFFF"; border.width: 2; x: -5; width: 296; height: parent.height; radius: 6 }
                        anchors.topMargin: 25
                        anchors.top: name.bottom
                    }

                    FalsePass { id: falsePass; visible: false; anchors.topMargin: 25; anchors.top: name.bottom }

                    Rectangle {
                        id: truePass; color: "transparent"; visible: false
                        anchors.topMargin: 35; anchors.top: name.bottom
                        Text {
                            id: welcome
                            color: "white"
                            font.family: Qt.resolvedUrl("../fonts") ? "Segoe UI Variable Static Display" : segoeuisb.name
                            text: "Welcome"
                            renderType: Text.NativeRendering
                            font.weight: Font.DemiBold
                            font.pointSize: 17
                            anchors.centerIn: parent
                            topPadding: 125
                        }
                        Rectangle {
                            id: trueButton; color: "transparent"
                            FontLoader { id: animFont; source: Qt.resolvedUrl("fonts/SegoeBoot-Semilight.woff") }
                            Text {
                                id: splash; color: "white"; text: ""
                                font.family: Qt.resolvedUrl("../fonts") ? "Segoe Boot Semilight" : animFont.name
                                renderType: Text.NativeRendering; font.weight: Font.Normal; font.pointSize: 27
                                leftPadding: -25; topPadding: 25; visible: true
                                anchors.verticalCenter: parent.verticalCenter
                                BootAni { id: bootani }
                            }
                        }
                    }

                    CapsOn {
                        id: capsOn
                        visible: false
                        z: 2
                        state: keyboard.capsLock ? "on" : "off"
                        states: [
                            State { name: "on"; PropertyChanges { target: capsOn; visible: true } },
                            State { name: "off"; PropertyChanges { target: capsOn; visible: false; z: -1 } }
                        ]
                        anchors.top: passwordField.bottom
                        anchors.topMargin: 25
                    }
                }
            }

            Button { id: prevUser; anchors.left: parent.left; enabled: false; visible: false }
            ListView {
                id: listView; focus: true; model: userModel; delegate: userDelegate
                currentIndex: userModel.lastIndex; interactive: false
                anchors.left: prevUser.right; anchors.right: nextUser.left
            }
            Button { id: nextUser; anchors.right: parent.right; enabled: false; visible: false }
        }
    }

    // click empty background on login screen to return to lock
    MouseArea {
        id: backArea
        anchors.fill: parent
        z: 1
        enabled: centerPanel.opacity > 0.01
        visible: enabled
        onClicked: {
            panelsOut.start()
            parBack.start()
        }
    }

    Item {
        id: rightPanel
        z: 2
        opacity: 0
        anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 65
        PowerPanel { id: powerPanel }
        SessionPanel { id: sessionPanel; anchors.right: powerPanel.left; anchors.rightMargin: 10 }
        LayoutPanel { id: layoutPanel; anchors.right: sessionPanel.left; anchors.rightMargin: 10 }
    }

    Rectangle {
        id: leftPanel
        color: "transparent"
        anchors.fill: parent
        z: 2
        opacity: 0
        visible: listView2.count > 1
        enabled: listView2.count > 1

        Component {
            id: userDelegate2
            UserList {
                id: userList
                name: (model.realName === "") ? model.name : model.realName
                icon: "/var/lib/AccountsService/icons/" + model.name
                anchors.horizontalCenter: parent.horizontalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        listView2.currentIndex = index
                        listView2.focus = true
                        listView.currentIndex = index
                        listView.focus = true
                    }
                }
            }
        }

        Rectangle {
            width: 150
            height: listView2.count > 17 ? Screen.height - 68 : 58 * listView2.count
            color: "transparent"
            clip: true
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 35
            anchors.left: parent.left
            anchors.leftMargin: 35

            Item {
                id: usersContainer2
                width: 255
                height: parent.height
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                Button { id: prevUser2; visible: true; enabled: false; width: 0; anchors.bottom: parent.bottom; anchors.left: parent.left }
                ListView {
                    id: listView2; height: parent.height; focus: true
                    model: userModel; currentIndex: userModel.lastIndex
                    delegate: userDelegate2
                    verticalLayoutDirection: ListView.TopToBottom
                    orientation: ListView.Vertical
                    interactive: listView2.count > 17
                    anchors.left: prevUser2.right; anchors.right: nextUser2.left
                }
                Button { id: nextUser2; visible: true; width: 0; enabled: false; anchors.bottom: parent.bottom; anchors.right: parent.right }
            }
        }
    }
}
