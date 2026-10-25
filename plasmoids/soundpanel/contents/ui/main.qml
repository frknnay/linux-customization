import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.volume

PlasmoidItem {
    id: root

    // PA_VOLUME_NORM: the raw volume value that means 100%
    readonly property int normalVolume: 65536
    readonly property int maxPercent: 150
    readonly property int stepPercent: 5

    readonly property var sink: PreferredDevice.sink
    readonly property int sinkPercent: sink ? toPercent(sink.volume) : 0
    readonly property bool sinkMuted: sink ? sink.muted : true

    function toPercent(volume) {
        return Math.round(volume / normalVolume * 100);
    }

    function setPercent(pulseObject, percent) {
        if (!pulseObject) {
            return;
        }
        const clamped = Math.max(0, Math.min(maxPercent, percent));
        pulseObject.volume = Math.round(clamped / 100 * normalVolume);
        if (clamped > 0 && pulseObject.muted) {
            pulseObject.muted = false;
        }
    }

    function volumeIcon(percent, muted) {
        if (muted || percent <= 0) {
            return "audio-volume-muted";
        } else if (percent <= 33) {
            return "audio-volume-low";
        } else if (percent <= 66) {
            return "audio-volume-medium";
        } else if (percent <= 100) {
            return "audio-volume-high";
        }
        return "audio-volume-high-danger";
    }

    Plasmoid.icon: volumeIcon(sinkPercent, sinkMuted)
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    toolTipMainText: i18n("Sound")
    toolTipSubText: sink ? i18n("%1 — %2%", sink.description, sinkPercent) + (sinkMuted ? i18n(" (muted)") : "")
                         : i18n("No output device")

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 12

    compactRepresentation: MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true

        property real wheelDelta: 0

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.sink) {
                    root.sink.muted = !root.sink.muted;
                }
            } else {
                root.expanded = !root.expanded;
            }
        }

        onWheel: wheel => {
            wheelDelta += wheel.angleDelta.y || wheel.angleDelta.x;
            while (Math.abs(wheelDelta) >= 120) {
                const direction = wheelDelta > 0 ? 1 : -1;
                root.setPercent(root.sink, root.sinkPercent + direction * root.stepPercent);
                wheelDelta -= direction * 120;
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: parent.containsMouse
        }
    }

    fullRepresentation: FullRepresentation {
        panel: root
    }
}
