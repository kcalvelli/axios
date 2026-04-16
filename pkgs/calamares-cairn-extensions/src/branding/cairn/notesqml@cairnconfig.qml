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
        spacing: Kirigami.Units.largeSpacing

        // ─── Profile Selection ──────────────────────────────
        Label {
            text: qsTr("How would you like to use Cairn?")
            font.pointSize: 14
            font.bold: true
        }

        ButtonGroup {
            id: profileGroup
        }

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            RadioButton {
                id: standardRadio
                text: qsTr("Standard — Full-featured workstation with development tools, AI, and customizable features")
                ButtonGroup.group: profileGroup
                checked: true
                onCheckedChanged: {
                    if (checked) Global.insert("cairn_homeProfile", "standard")
                }
                Component.onCompleted: Global.insert("cairn_homeProfile", "standard")
            }

            RadioButton {
                id: normieRadio
                text: qsTr("Normie — Streamlined experience for web browsing, media, and everyday tasks")
                ButtonGroup.group: profileGroup
                onCheckedChanged: {
                    if (checked) Global.insert("cairn_homeProfile", "normie")
                }
            }
        }

        // ─── Feature Selection (standard only) ──────────────
        ColumnLayout {
            visible: standardRadio.checked
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            Label {
                text: qsTr("Features")
                font.pointSize: 12
                font.bold: true
            }

            GridLayout {
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing * 3
                rowSpacing: Kirigami.Units.smallSpacing

                CheckBox {
                    id: gamingCheck
                    text: qsTr("Gaming (Steam, GameMode)")
                    onCheckedChanged: Global.insert("cairn_enableGaming", checked)
                }

                CheckBox {
                    id: secureBoot
                    text: qsTr("Secure Boot")
                    onCheckedChanged: Global.insert("cairn_enableSecureBoot", checked)
                }

                CheckBox {
                    id: pimCheck
                    text: qsTr("PIM (Email, Calendar, Contacts)")
                    onCheckedChanged: Global.insert("cairn_enablePim", checked)
                }

                CheckBox {
                    id: secretsCheck
                    text: qsTr("Secrets Management (agenix)")
                    onCheckedChanged: Global.insert("cairn_enableSecrets", checked)
                }

                CheckBox {
                    id: immichCheck
                    text: qsTr("Immich (Photo/Video Backup)")
                    onCheckedChanged: Global.insert("cairn_enableImmich", checked)
                }

                CheckBox {
                    id: libvirtCheck
                    text: qsTr("Virtualization (libvirt)")
                    onCheckedChanged: Global.insert("cairn_enableLibvirt", checked)
                }

                CheckBox {
                    id: localLlmCheck
                    text: qsTr("Local LLM Inference")
                    onCheckedChanged: Global.insert("cairn_enableLocalLlm", checked)
                }

                CheckBox {
                    id: containersCheck
                    text: qsTr("Containers (Podman)")
                    onCheckedChanged: Global.insert("cairn_enableContainers", checked)
                }
            }

            // ─── Role Selectors (conditional) ───────────────
            GridLayout {
                visible: pimCheck.checked || immichCheck.checked || localLlmCheck.checked
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.largeSpacing

                Label {
                    visible: true
                    text: qsTr("Service Roles")
                    font.pointSize: 11
                    font.bold: true
                    Layout.columnSpan: 2
                }

                // PIM role
                Label {
                    visible: pimCheck.checked
                    text: qsTr("PIM role:")
                }
                RowLayout {
                    visible: pimCheck.checked
                    ButtonGroup { id: pimRoleGroup }
                    RadioButton {
                        text: qsTr("Server")
                        ButtonGroup.group: pimRoleGroup
                        checked: true
                        onCheckedChanged: { if (checked) Global.insert("cairn_pimRole", "server") }
                        Component.onCompleted: Global.insert("cairn_pimRole", "server")
                    }
                    RadioButton {
                        text: qsTr("Client")
                        ButtonGroup.group: pimRoleGroup
                        onCheckedChanged: { if (checked) Global.insert("cairn_pimRole", "client") }
                    }
                }

                // Immich role
                Label {
                    visible: immichCheck.checked
                    text: qsTr("Immich role:")
                }
                RowLayout {
                    visible: immichCheck.checked
                    ButtonGroup { id: immichRoleGroup }
                    RadioButton {
                        text: qsTr("Server")
                        ButtonGroup.group: immichRoleGroup
                        checked: true
                        onCheckedChanged: { if (checked) Global.insert("cairn_immichRole", "server") }
                        Component.onCompleted: Global.insert("cairn_immichRole", "server")
                    }
                    RadioButton {
                        text: qsTr("Client")
                        ButtonGroup.group: immichRoleGroup
                        onCheckedChanged: { if (checked) Global.insert("cairn_immichRole", "client") }
                    }
                }

                // Local LLM role
                Label {
                    visible: localLlmCheck.checked
                    text: qsTr("Local LLM role:")
                }
                RowLayout {
                    visible: localLlmCheck.checked
                    ButtonGroup { id: llmRoleGroup }
                    RadioButton {
                        text: qsTr("Server")
                        ButtonGroup.group: llmRoleGroup
                        checked: true
                        onCheckedChanged: { if (checked) Global.insert("cairn_localLlmRole", "server") }
                        Component.onCompleted: Global.insert("cairn_localLlmRole", "server")
                    }
                    RadioButton {
                        text: qsTr("Client")
                        ButtonGroup.group: llmRoleGroup
                        onCheckedChanged: { if (checked) Global.insert("cairn_localLlmRole", "client") }
                    }
                }
            }

        }

        // Spacer
        Item {
            Layout.fillHeight: true
        }
    }
}
