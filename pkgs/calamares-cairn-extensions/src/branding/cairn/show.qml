import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Presentation {
    id: presentation

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome to Cairn"
                font.pointSize: 22
                font.bold: true
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 480
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "A modular NixOS distribution built on the Niri Wayland compositor and DankMaterialShell."
                font.pointSize: 12
            }
        }
    }

    Slide {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Reproducible by Design"
                font.pointSize: 22
                font.bold: true
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 480
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "Your entire system is defined in a Nix flake. Rebuild, rollback, or reproduce your setup on any machine."
                font.pointSize: 12
            }
        }
    }

    Slide {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "AI-Native Workflow"
                font.pointSize: 22
                font.bold: true
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 480
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "Claude Code, Gemini, MCP servers, and dynamic tool discovery are built in. Your AI assistants understand your system."
                font.pointSize: 12
            }
        }
    }

    Slide {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Modular Features"
                font.pointSize: 22
                font.bold: true
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 480
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "Gaming, PIM, photo backup, virtualization, secure boot — enable what you need, skip what you don't."
                font.pointSize: 12
            }
        }
    }

    Slide {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Getting Started"
                font.pointSize: 22
                font.bold: true
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 480
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "After installation, your config lives at /etc/nixos. Edit it directly or use 'nix run github:kcalvelli/cairn#init' to add hosts and users."
                font.pointSize: 12
            }
        }
    }
}
