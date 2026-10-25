import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root

    readonly property var player: mpris.currentPlayer
    readonly property bool hasPlayer: player !== null
    // Browsers keep an empty player registered after the tab closes, so also require a track
    readonly property bool hasMedia: hasPlayer && !!player.track && player.playbackStatus !== Mpris.PlaybackStatus.Stopped
    readonly property bool isPlaying: hasPlayer && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property string track: hasPlayer && player.track ? player.track : i18n("No media playing")
    readonly property string artist: hasPlayer ? player.artist : ""
    readonly property string album: hasPlayer ? player.album : ""
    readonly property string artUrl: hasPlayer ? player.artUrl : ""
    // MPRIS times are in microseconds
    readonly property real length: hasPlayer ? player.length : 0
    readonly property real position: hasPlayer ? player.position : 0

    function formatTime(us) {
        const total = Math.max(0, Math.floor(us / 1000000));
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = String(total % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${s}` : `${m}:${s}`;
    }

    Mpris.Mpris2Model {
        id: mpris
    }

    // Hidden status removes the widget from the panel (panels still show it in edit mode).
    // Set imperatively: Plasma rewrites the status when the popup opens/closes, which
    // would leave a declarative binding stale.
    Plasmoid.status: PlasmaCore.Types.HiddenStatus
    onHasMediaChanged: if (hasMedia) Plasmoid.status = PlasmaCore.Types.ActiveStatus

    // Hide only after nothing has played for a while, so skipping tracks doesn't flicker
    Timer {
        interval: 10000
        running: !root.hasMedia && !root.expanded
        onTriggered: Plasmoid.status = PlasmaCore.Types.HiddenStatus
    }
    Plasmoid.icon: isPlaying ? "media-playback-playing" : (hasPlayer ? "media-playback-paused" : "media-playback-stopped")
    toolTipMainText: track
    toolTipSubText: artist

    compactRepresentation: MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton && root.hasPlayer) {
                root.player.PlayPause();
            } else {
                root.expanded = !root.expanded;
            }
        }
        onWheel: wheel => {
            if (root.hasPlayer) {
                root.player.changeVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05, true);
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: parent.containsMouse
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Layout.preferredHeight

        // Players only push position on seek, so poll while the popup is visible
        Timer {
            interval: 500
            repeat: true
            running: root.isPlaying && root.expanded && !seekSlider.pressed
            onTriggered: root.player.updatePosition()
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // Album art + track info
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 4

                    Kirigami.ShadowedImage {
                        id: cover
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        radius: Kirigami.Units.cornerRadius * 2
                        visible: status === Image.Ready
                        sourceSize: Qt.size(width * 2, height * 2)
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: !cover.visible
                        radius: Kirigami.Units.cornerRadius * 2
                        color: Qt.alpha(Kirigami.Theme.highlightColor, 0.2)

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: parent.width / 2
                            height: width
                            source: root.hasPlayer && root.player.iconName ? root.player.iconName : "media-album-cover"
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: root.track
                        font.weight: Font.Bold
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
                        elide: Text.ElideRight
                    }
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: root.artist
                        visible: text.length > 0
                        opacity: 0.75
                        elide: Text.ElideRight
                    }
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: root.album
                        visible: text.length > 0
                        opacity: 0.75
                        font: Kirigami.Theme.smallFont
                        elide: Text.ElideRight
                    }
                }
            }

            // Seek bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: root.length > 0

                PlasmaComponents3.Slider {
                    id: seekSlider
                    Layout.fillWidth: true
                    from: 0
                    to: root.length
                    enabled: root.hasPlayer && root.player.canSeek
                    // Break the binding only while dragging so it follows playback otherwise
                    value: pressed ? value : root.position
                    onMoved: root.player.position = value
                }

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents3.Label {
                        text: root.formatTime(seekSlider.value)
                        font: Kirigami.Theme.smallFont
                        opacity: 0.75
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents3.Label {
                        text: root.formatTime(root.length)
                        font: Kirigami.Theme.smallFont
                        opacity: 0.75
                    }
                }
            }

            // Transport controls
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                PlasmaComponents3.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "media-playlist-shuffle"
                    checkable: true
                    checked: root.hasPlayer && root.player.shuffle === Mpris.ShuffleStatus.On
                    enabled: root.hasPlayer && root.player.canControl && root.player.shuffle !== Mpris.ShuffleStatus.Unknown
                    onToggled: root.player.shuffle = checked ? Mpris.ShuffleStatus.On : Mpris.ShuffleStatus.Off
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Shuffle")
                    PlasmaComponents3.ToolTip.text: text
                    PlasmaComponents3.ToolTip.visible: hovered
                }

                PlasmaComponents3.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "media-skip-backward"
                    enabled: root.hasPlayer && root.player.canGoPrevious
                    onClicked: root.player.Previous()
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Previous")
                }

                QQC2.AbstractButton {
                    id: playButton
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    enabled: root.hasPlayer && (root.isPlaying ? root.player.canPause : root.player.canPlay)
                    onClicked: root.player.PlayPause()
                    text: root.isPlaying ? i18n("Pause") : i18n("Play")
                    hoverEnabled: true

                    background: Rectangle {
                        radius: width / 2
                        color: Kirigami.Theme.highlightColor
                        opacity: playButton.enabled ? (playButton.pressed ? 0.8 : 1) : 0.4
                        scale: playButton.hovered && !playButton.pressed ? 1.05 : 1
                        Behavior on scale { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                    }
                    contentItem: Item {
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.medium
                            height: width
                            source: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                            isMask: true
                            color: Kirigami.Theme.highlightedTextColor
                        }
                    }
                }

                PlasmaComponents3.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "media-skip-forward"
                    enabled: root.hasPlayer && root.player.canGoNext
                    onClicked: root.player.Next()
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Next")
                }

                PlasmaComponents3.ToolButton {
                    Layout.fillWidth: true
                    readonly property int loop: root.hasPlayer ? root.player.loopStatus : Mpris.LoopStatus.Unknown
                    icon.name: loop === Mpris.LoopStatus.Track ? "media-repeat-single"
                             : loop === Mpris.LoopStatus.Playlist ? "media-repeat-all"
                             : "media-repeat-none"
                    checkable: true
                    checked: loop === Mpris.LoopStatus.Track || loop === Mpris.LoopStatus.Playlist
                    enabled: root.hasPlayer && root.player.canControl && loop !== Mpris.LoopStatus.Unknown
                    // Cycle None -> Playlist -> Track -> None
                    onClicked: root.player.loopStatus = loop === Mpris.LoopStatus.None ? Mpris.LoopStatus.Playlist
                                                      : loop === Mpris.LoopStatus.Playlist ? Mpris.LoopStatus.Track
                                                      : Mpris.LoopStatus.None
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Repeat")
                    PlasmaComponents3.ToolTip.text: text
                    PlasmaComponents3.ToolTip.visible: hovered
                }
            }
        }
    }
}
