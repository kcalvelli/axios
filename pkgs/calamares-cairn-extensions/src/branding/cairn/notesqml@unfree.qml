import io.calamares.core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Page {
    width: parent.width
    height: parent.height

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Cairn can include proprietary (unfree) software such as NVIDIA drivers, certain WiFi firmware, and other hardware support packages.")
            font.pointSize: 11
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            wrapMode: Text.WordWrap
            text: qsTr("If your system has an NVIDIA GPU or requires proprietary WiFi drivers, you should enable this option.")
        }

        CheckBox {
            Layout.topMargin: Kirigami.Units.largeSpacing * 2
            text: qsTr("Allow unfree software")
            font.pointSize: 11
            onCheckedChanged: {
                Global.insert("nixos_allow_unfree", checked)
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
