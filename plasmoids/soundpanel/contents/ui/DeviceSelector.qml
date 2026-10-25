import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// Accent-bordered box showing the default device; clicking it opens a popover to pick another.
// The popover floats over the content below, so the layout never changes height.
MouseArea {
    id: selector

    required property var devicesModel
    required property var current
    property string fallbackIcon: "audio-card"

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 2.4
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: popover.opened ? popover.close() : popover.open()

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius * 3
        color: Qt.alpha(Kirigami.Theme.textColor, selector.containsMouse ? 0.07 : 0.04)
        border.width: 2
        border.color: popover.opened || selector.containsMouse ? Kirigami.Theme.highlightColor
                                                               : Qt.alpha(Kirigami.Theme.highlightColor, 0.7)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: implicitWidth
            source: (selector.current && selector.current.iconName) || selector.fallbackIcon
        }
        PC3.Label {
            Layout.fillWidth: true
            text: selector.current ? selector.current.description : i18n("No device")
            elide: Text.ElideRight
        }
        Kirigami.Icon {
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: implicitWidth
            source: "arrow-down"
            rotation: popover.opened ? 180 : 0
            Behavior on rotation {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }
        }
    }

    T.Popup {
        id: popover

        y: selector.height + Kirigami.Units.smallSpacing
        width: selector.width
        // Keep it inside the Plasma popup window
        margins: Kirigami.Units.smallSpacing
        padding: Kirigami.Units.smallSpacing
        implicitHeight: Math.min(deviceList.contentHeight, Kirigami.Units.gridUnit * 14) + topPadding + bottomPadding
        focus: true
        closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.shortDuration }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Kirigami.Units.shortDuration }
        }

        background: Kirigami.ShadowedRectangle {
            radius: Kirigami.Units.cornerRadius * 3
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
            shadow.size: Kirigami.Units.gridUnit
            shadow.yOffset: 2
            shadow.color: Qt.rgba(0, 0, 0, 0.35)
        }

        contentItem: ListView {
            id: deviceList
            model: popover.visible ? selector.devicesModel : null
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            spacing: 2

            delegate: MouseArea {
                id: entry
                required property var model
                readonly property bool isDefault: model.PulseObject.default

                width: ListView.view.width
                implicitHeight: Kirigami.Units.gridUnit * 2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    model.PulseObject.default = true;
                    popover.close();
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Kirigami.Units.cornerRadius * 2
                    color: entry.isDefault ? Qt.alpha(Kirigami.Theme.highlightColor, 0.25)
                                           : (entry.containsMouse ? Qt.alpha(Kirigami.Theme.textColor, 0.08)
                                                                  : "transparent")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                    anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: implicitWidth
                        source: entry.model.PulseObject.iconName || selector.fallbackIcon
                    }
                    PC3.Label {
                        Layout.fillWidth: true
                        text: entry.model.PulseObject.description
                        elide: Text.ElideRight
                        font.weight: entry.isDefault ? Font.DemiBold : Font.Normal
                    }
                    Kirigami.Icon {
                        visible: entry.isDefault
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: implicitWidth
                        source: "checkmark"
                        color: Kirigami.Theme.highlightColor
                        isMask: true
                    }
                }
            }
        }
    }
}
