import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.private.volume

// Compact controls for a single stream, shown when an app row is expanded.
RowLayout {
    id: row

    required property var panel
    required property var pulseObject
    // 1-based position within the app's streams, used when the stream has no real name
    property int position: 1

    readonly property var props: pulseObject ? pulseObject.properties : ({})
    readonly property int percent: pulseObject ? panel.toPercent(pulseObject.volume) : 0
    readonly property bool muted: pulseObject ? pulseObject.muted : false
    readonly property bool paused: pulseObject ? pulseObject.corked : false

    // Browsers mostly label every stream "Playback", which says nothing; number them then
    readonly property string title: {
        const mediaName = props["media.name"] || "";
        const generic = ["", "playback", "audiostream", "audio stream", "audio-stream", "output", "record"];
        return generic.includes(mediaName.toLowerCase()) ? i18n("Stream %1", position) : mediaName;
    }

    spacing: Kirigami.Units.smallSpacing

    VolumeMonitor {
        id: monitor
        target: row.pulseObject
    }

    PC3.Label {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        text: row.title
        elide: Text.ElideRight
        font: Kirigami.Theme.smallFont
        opacity: row.paused ? 0.5 : 0.8

        PC3.ToolTip.text: row.title
        PC3.ToolTip.visible: hover.hovered && truncated
        HoverHandler { id: hover }
    }

    VolumeSlider {
        Layout.fillWidth: true
        implicitHeight: Kirigami.Units.gridUnit * 1.1
        to: row.panel.maxPercent
        value: row.percent
        muted: row.muted
        peak: monitor.available ? monitor.volume : -1
        onMoved: row.panel.setPercent(row.pulseObject, value)
    }

    PC3.Label {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
        horizontalAlignment: Text.AlignRight
        text: row.muted ? i18n("Muted") : (row.paused ? i18n("Paused") : i18n("%1%", row.percent))
        font: Kirigami.Theme.smallFont
        opacity: 0.6
    }

    PC3.ToolButton {
        icon.name: row.panel.volumeIcon(row.percent, row.muted)
        icon.width: Kirigami.Units.iconSizes.small
        icon.height: Kirigami.Units.iconSizes.small
        onClicked: row.pulseObject.muted = !row.pulseObject.muted
        PC3.ToolTip.text: row.muted ? i18n("Unmute") : i18n("Mute")
        PC3.ToolTip.visible: hovered
        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }
}
