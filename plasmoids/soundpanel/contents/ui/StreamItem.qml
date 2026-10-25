import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.private.volume

// One application row: icon tile, name, percentage, slider and mute button.
// Controls every stream of the app at once (e.g. one per browser tab) and can
// expand to show each stream separately.
ColumnLayout {
    id: item

    required property var panel
    // Key into FullRepresentation.groupsByKey; the delegate stays alive while the app plays
    required property string appKey
    // Unfiltered stream model of the current tab, used for the per-stream rows
    required property var streamsModel
    required property var streamKey
    // Device list the streams can be moved to (sinks or sources)
    required property var devicesModel
    required property var groupsByKey

    // { name, themeIcon, windowIcon, streams }; may briefly be missing while the row is removed
    readonly property var group: groupsByKey[appKey] || ({ name: "", themeIcon: "", windowIcon: "", streams: [] })
    readonly property var streams: group.streams
    // Loudest stream drives the slider; the group only counts as muted when every stream is
    readonly property int percent: streams.reduce((max, s) => Math.max(max, panel.toPercent(s.volume)), 0)
    readonly property bool muted: streams.length > 0 && streams.every(s => s.muted)
    // Meter follows a stream that is actually playing
    readonly property var meteredStream: streams.find(s => !s.corked) || streams[0] || null

    property bool expanded: false
    readonly property bool showStreams: expanded && streams.length > 1

    function setPercent(percent) {
        streams.forEach(s => panel.setPercent(s, percent));
    }

    function toggleMute() {
        const mute = !muted;
        streams.forEach(s => s.muted = mute);
    }

    function moveTo(deviceIndex) {
        streams.forEach(s => s.deviceIndex = deviceIndex);
    }

    spacing: Kirigami.Units.smallSpacing

    VolumeMonitor {
        id: monitor
        target: item.meteredStream
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Kirigami.Units.gridUnit * 2.2
            implicitHeight: implicitWidth
            radius: Kirigami.Units.cornerRadius * 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                // The window's icon comes from the app's desktop entry, so it beats the stream's icon name
                source: item.group.windowIcon || item.group.themeIcon || "applications-multimedia"
                fallback: "applications-multimedia"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PC3.Label {
                    text: item.group.name
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.maximumWidth: implicitWidth
                    Layout.fillWidth: true
                }

                // "· 3 streams ⌄" doubles as the expand toggle
                MouseArea {
                    visible: item.streams.length > 1
                    implicitWidth: streamsLabel.implicitWidth
                    implicitHeight: streamsLabel.implicitHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: item.expanded = !item.expanded

                    RowLayout {
                        id: streamsLabel
                        spacing: 2
                        opacity: parent.containsMouse ? 0.9 : 0.55

                        PC3.Label {
                            text: "· " + i18np("%1 stream", "%1 streams", item.streams.length)
                            font: Kirigami.Theme.smallFont
                        }
                        Kirigami.Icon {
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: implicitWidth
                            source: "arrow-down"
                            rotation: item.showStreams ? 180 : 0
                            Behavior on rotation {
                                NumberAnimation { duration: Kirigami.Units.shortDuration }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                PC3.Label {
                    text: item.muted ? i18n("Muted") : i18n("%1%", item.percent)
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                }
            }

            VolumeSlider {
                Layout.fillWidth: true
                to: item.panel.maxPercent
                value: item.percent
                muted: item.muted
                peak: monitor.available ? monitor.volume : -1
                onMoved: item.setPercent(value)
            }
        }

        PC3.ToolButton {
            Layout.alignment: Qt.AlignBottom
            icon.name: item.panel.volumeIcon(item.percent, item.muted)
            onClicked: item.toggleMute()
            PC3.ToolTip.text: item.muted ? i18n("Unmute all") : i18n("Mute all")
            PC3.ToolTip.visible: hovered
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    // Per-stream rows. Built from the live stream model (not the group's array) so rows
    // stay put when other streams come and go.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.gridUnit * 2.2 + Kirigami.Units.largeSpacing
        visible: item.showStreams
        spacing: 0

        Repeater {
            model: item.showStreams ? item.streamsModel : null

            delegate: StreamRow {
                required property var model
                Layout.fillWidth: true
                panel: item.panel
                pulseObject: model.PulseObject
                position: item.streams.indexOf(model.PulseObject) + 1
                visible: item.streamKey(model.PulseObject) === item.appKey
            }
        }
    }

    // Right-click anywhere on the row to send this app to another device
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: routeMenu.popup()
    }

    PC3.Menu {
        id: routeMenu
        title: i18n("Play on")

        Instantiator {
            model: item.devicesModel
            delegate: PC3.MenuItem {
                required property var model
                text: model.Description
                checkable: true
                checked: item.streams.every(s => s.deviceIndex === model.PulseObject.index)
                onTriggered: item.moveTo(model.PulseObject.index)
            }
            onObjectAdded: (index, object) => routeMenu.insertItem(index, object)
            onObjectRemoved: (index, object) => routeMenu.removeItem(object)
        }
    }
}
