import io.calamares.core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Page {
    width: parent.width
    height: parent.height

    Flickable {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            // ─── Profile Selection ──────────────────────────────
            Label {
                text: qsTr("How would you like to use axiOS?")
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
                        if (checked) Global.insert("axios_homeProfile", "standard")
                    }
                    Component.onCompleted: Global.insert("axios_homeProfile", "standard")
                }

                RadioButton {
                    id: normieRadio
                    text: qsTr("Simple — Streamlined experience for web browsing, media, and everyday tasks")
                    ButtonGroup.group: profileGroup
                    onCheckedChanged: {
                        if (checked) Global.insert("axios_homeProfile", "normie")
                    }
                }
            }

            // ─── Hardware Confirmation ──────────────────────────
            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            Label {
                text: qsTr("Detected Hardware")
                font.pointSize: 12
                font.bold: true
            }

            GridLayout {
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                // CPU vendor
                Label { text: qsTr("CPU:") }
                RowLayout {
                    ButtonGroup { id: cpuGroup }
                    RadioButton {
                        id: cpuAmd
                        text: "AMD"
                        ButtonGroup.group: cpuGroup
                        checked: Global.value("axios_cpuVendor") === "amd"
                        onCheckedChanged: { if (checked) Global.insert("axios_cpuVendor", "amd") }
                    }
                    RadioButton {
                        id: cpuIntel
                        text: "Intel"
                        ButtonGroup.group: cpuGroup
                        checked: Global.value("axios_cpuVendor") === "intel"
                        onCheckedChanged: { if (checked) Global.insert("axios_cpuVendor", "intel") }
                    }
                }

                // GPU vendor
                Label { text: qsTr("GPU:") }
                RowLayout {
                    ButtonGroup { id: gpuGroup }
                    RadioButton {
                        id: gpuAmd
                        text: "AMD"
                        ButtonGroup.group: gpuGroup
                        checked: Global.value("axios_gpuVendor") === "amd"
                        onCheckedChanged: { if (checked) Global.insert("axios_gpuVendor", "amd") }
                    }
                    RadioButton {
                        id: gpuNvidia
                        text: "NVIDIA"
                        ButtonGroup.group: gpuGroup
                        checked: Global.value("axios_gpuVendor") === "nvidia"
                        onCheckedChanged: { if (checked) Global.insert("axios_gpuVendor", "nvidia") }
                    }
                    RadioButton {
                        id: gpuIntel
                        text: "Intel"
                        ButtonGroup.group: gpuGroup
                        checked: Global.value("axios_gpuVendor") === "intel"
                        onCheckedChanged: { if (checked) Global.insert("axios_gpuVendor", "intel") }
                    }
                }

                // Form factor
                Label { text: qsTr("Form factor:") }
                RowLayout {
                    ButtonGroup { id: formGroup }
                    RadioButton {
                        id: formDesktop
                        text: qsTr("Desktop")
                        ButtonGroup.group: formGroup
                        checked: Global.value("axios_formFactor") !== "laptop"
                        onCheckedChanged: { if (checked) Global.insert("axios_formFactor", "desktop") }
                    }
                    RadioButton {
                        id: formLaptop
                        text: qsTr("Laptop")
                        ButtonGroup.group: formGroup
                        checked: Global.value("axios_formFactor") === "laptop"
                        onCheckedChanged: { if (checked) Global.insert("axios_formFactor", "laptop") }
                    }
                }

                // SSD
                Label { text: qsTr("SSD:") }
                CheckBox {
                    id: ssdCheck
                    text: qsTr("SSD detected")
                    checked: Global.value("axios_hasSSD") === true
                    onCheckedChanged: Global.insert("axios_hasSSD", checked)
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
                        onCheckedChanged: Global.insert("axios_enableGaming", checked)
                    }

                    CheckBox {
                        id: secureBoot
                        text: qsTr("Secure Boot")
                        onCheckedChanged: Global.insert("axios_enableSecureBoot", checked)
                    }

                    CheckBox {
                        id: pimCheck
                        text: qsTr("PIM (Email, Calendar, Contacts)")
                        onCheckedChanged: Global.insert("axios_enablePim", checked)
                    }

                    CheckBox {
                        id: secretsCheck
                        text: qsTr("Secrets Management (agenix)")
                        onCheckedChanged: Global.insert("axios_enableSecrets", checked)
                    }

                    CheckBox {
                        id: immichCheck
                        text: qsTr("Immich (Photo/Video Backup)")
                        onCheckedChanged: Global.insert("axios_enableImmich", checked)
                    }

                    CheckBox {
                        id: libvirtCheck
                        text: qsTr("Virtualization (libvirt)")
                        onCheckedChanged: Global.insert("axios_enableLibvirt", checked)
                    }

                    CheckBox {
                        id: localLlmCheck
                        text: qsTr("Local LLM Inference")
                        onCheckedChanged: Global.insert("axios_enableLocalLlm", checked)
                    }

                    CheckBox {
                        id: containersCheck
                        text: qsTr("Containers (Podman)")
                        onCheckedChanged: Global.insert("axios_enableContainers", checked)
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
                            onCheckedChanged: { if (checked) Global.insert("axios_pimRole", "server") }
                            Component.onCompleted: Global.insert("axios_pimRole", "server")
                        }
                        RadioButton {
                            text: qsTr("Client")
                            ButtonGroup.group: pimRoleGroup
                            onCheckedChanged: { if (checked) Global.insert("axios_pimRole", "client") }
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
                            onCheckedChanged: { if (checked) Global.insert("axios_immichRole", "server") }
                            Component.onCompleted: Global.insert("axios_immichRole", "server")
                        }
                        RadioButton {
                            text: qsTr("Client")
                            ButtonGroup.group: immichRoleGroup
                            onCheckedChanged: { if (checked) Global.insert("axios_immichRole", "client") }
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
                            onCheckedChanged: { if (checked) Global.insert("axios_localLlmRole", "server") }
                            Component.onCompleted: Global.insert("axios_localLlmRole", "server")
                        }
                        RadioButton {
                            text: qsTr("Client")
                            ButtonGroup.group: llmRoleGroup
                            onCheckedChanged: { if (checked) Global.insert("axios_localLlmRole", "client") }
                        }
                    }
                }

                // ─── Tailnet Domain (conditional) ───────────────
                ColumnLayout {
                    id: tailnetSection
                    visible: {
                        var pimClient = pimCheck.checked && pimRoleGroup.checkedButton && pimRoleGroup.checkedButton.text === qsTr("Client")
                        var immichEnabled = immichCheck.checked
                        var llmClient = localLlmCheck.checked && llmRoleGroup.checkedButton && llmRoleGroup.checkedButton.text === qsTr("Client")
                        return pimClient || immichEnabled || llmClient
                    }
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Label {
                        text: qsTr("Tailscale Network")
                        font.pointSize: 11
                        font.bold: true
                    }

                    Label {
                        text: qsTr("Enter your Tailnet domain for connecting to remote services:")
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    TextField {
                        id: tailnetField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        placeholderText: "example-tailnet.ts.net"
                        activeFocusOnPress: true
                        onTextChanged: Global.insert("axios_tailnetDomain", text)
                    }
                }
            }

            // Spacer
            Item {
                Layout.fillHeight: true
            }
        }
    }
}
