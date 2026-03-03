import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Presentation {
    id: presentation

    Slide {
        anchors.fill: parent
        anchors.margins: 40

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome to axiOS"
                font.pointSize: 24
                font.bold: true
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 500
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "A modular NixOS distribution with the Niri Wayland compositor and DankMaterialShell."
                font.pointSize: 13
            }
        }
    }
}
