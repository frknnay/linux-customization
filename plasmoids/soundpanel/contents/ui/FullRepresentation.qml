import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.private.volume
import org.kde.taskmanager as TaskManager

Item {
    id: full

    required property var panel

    // 0 = Output, 1 = Input
    property int tab: 0
    readonly property bool isOutput: tab === 0
    readonly property var device: isOutput ? PreferredDevice.sink : PreferredDevice.source
    readonly property int devicePercent: device ? panel.toPercent(device.volume) : 0
    readonly property bool deviceMuted: device ? device.muted : true
    readonly property var streamsModel: isOutput ? playbackStreams : recordingStreams

    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18

    // App key -> { name, themeIcon, windowIcon, streams: [PulseObject] }.
    // groupModel only holds the keys, in display order, so rows are added and removed
    // individually instead of the whole list being rebuilt on every stream change.
    property var groupsByKey: ({})

    ListModel {
        id: groupModel
    }

    function appName(pulseObject, client) {
        const props = pulseObject.properties;
        return props["application.name"] || (client && client.name) || pulseObject.name;
    }

    // Streams with the same key are grouped into one row
    function streamKey(pulseObject) {
        if (!pulseObject) {
            return "";
        }
        return pulseObject.properties["application.process.binary"] || appName(pulseObject, pulseObject.client);
    }

    // Hide the peak-meter streams PulseAudioQt creates for VolumeMonitor
    function notPeakStream(pulseObject) {
        return pulseObject.properties["application.id"] !== "org.PulseAudio.pavucontrol";
    }

    // Icon of an open window whose app id matches one of the candidates (e.g. "helium").
    // Needed because apps often report an icon name their desktop entry doesn't use.
    function windowIcon(candidates) {
        for (let row = 0; row < tasksModel.rowCount(); row++) {
            const index = tasksModel.index(row, 0);
            const appId = String(tasksModel.data(index, TaskManager.AbstractTasksModel.AppId) || "")
                .toLowerCase().replace(/\.desktop$/, "");
            if (appId && candidates.includes(appId)) {
                return tasksModel.data(index, Qt.DecorationRole);
            }
        }
        return "";
    }

    function regroup() {
        const byKey = new Map();
        for (let i = 0; i < streamCollector.count; i++) {
            const entry = streamCollector.objectAt(i);
            if (!entry || !entry.pulseObject) {
                continue;
            }
            const props = entry.pulseObject.properties;
            const client = entry.client;
            const name = appName(entry.pulseObject, client);
            const key = streamKey(entry.pulseObject);

            if (!byKey.has(key)) {
                const binary = (props["application.process.binary"] || "").toLowerCase();
                const candidates = [
                    binary,
                    (props["application.icon_name"] || "").toLowerCase(),
                    (props["pipewire.access.portal.app_id"] || "").toLowerCase(),
                    name.toLowerCase(),
                ].filter(c => c);
                byKey.set(key, {
                    name: name,
                    themeIcon: props["application.icon_name"]
                        || (client && client.properties["application.icon_name"]) || binary,
                    windowIcon: windowIcon(candidates),
                    streams: [],
                });
            }
            byKey.get(key).streams.push(entry.pulseObject);
        }

        // Drop rows of apps that stopped, while their old data is still available
        const present = new Set();
        for (let row = groupModel.count - 1; row >= 0; row--) {
            const key = groupModel.get(row).appKey;
            if (byKey.has(key)) {
                present.add(key);
            } else {
                groupModel.remove(row);
            }
        }
        // Existing rows pick up their new stream lists through this binding
        const next = {};
        byKey.forEach((group, key) => next[key] = group);
        groupsByKey = next;
        for (const key of byKey.keys()) {
            if (!present.has(key)) {
                groupModel.append({ appKey: key });
            }
        }
    }

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    // Collects the stream objects of the current tab so they can be grouped by app
    Instantiator {
        id: streamCollector
        model: full.streamsModel
        delegate: QtObject {
            required property var model
            readonly property var pulseObject: model.PulseObject
            readonly property var client: model.Client
            readonly property string name: model.Name
        }
        onObjectAdded: Qt.callLater(full.regroup)
        onObjectRemoved: Qt.callLater(full.regroup)
    }

    PulseObjectFilterModel {
        id: sinks
        sourceModel: SinkModel {}
        filterOutInactiveDevices: true
    }
    PulseObjectFilterModel {
        id: sources
        sourceModel: SourceModel {}
        filterOutInactiveDevices: true
        filters: [{ role: "PulseObject", value: o => o.properties["device.class"] !== "monitor" }]
    }
    PulseObjectFilterModel {
        id: playbackStreams
        sourceModel: SinkInputModel {}
        filters: [{ role: "VirtualStream", value: false }]
    }
    PulseObjectFilterModel {
        id: recordingStreams
        sourceModel: SourceOutputModel {}
        filters: [
            { role: "VirtualStream", value: false },
            { role: "PulseObject", value: full.notPeakStream }
        ]
    }

    VolumeMonitor {
        id: deviceMonitor
        target: full.device
    }

    // The whole popup scrolls when its content is taller than the space Plasma gives it
    // (the system tray popup has a fixed size). The scrollbar floats over the right margin
    // instead of taking width, so the content never shifts when it appears.
    Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: scrollContent.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        T.ScrollBar.vertical: T.ScrollBar {
            id: scrollBar
            policy: T.ScrollBar.AsNeeded
            minimumSize: 0.1
            padding: 2
            implicitWidth: Kirigami.Units.smallSpacing * 2 + leftPadding + rightPadding
            visible: size < 1

            contentItem: Rectangle {
                implicitWidth: scrollBar.hovered || scrollBar.pressed ? Kirigami.Units.smallSpacing * 2
                                                                      : Kirigami.Units.smallSpacing
                x: scrollBar.availableWidth - width + scrollBar.leftPadding
                radius: width / 2
                color: Kirigami.Theme.textColor
                // Hidden at rest; shows while scrolling or when the pointer is on it
                opacity: scrollBar.pressed ? 0.5 : (scrollBar.active || scrollBar.hovered ? 0.3 : 0)

                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.longDuration }
                }
                Behavior on implicitWidth {
                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                }
            }
        }

        Item {
            id: scrollContent
            width: scroller.width
            implicitHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Kirigami.Units.largeSpacing
                }
                spacing: Kirigami.Units.largeSpacing

                // ── Header ─────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true

                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: implicitWidth
                        source: "audio-volume-high"
                        color: Kirigami.Theme.highlightColor
                        isMask: true
                    }
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 3
                        text: i18n("Sound")
                        font.weight: Font.Bold
                    }
                    PC3.ToolButton {
                        icon.name: "configure"
                        onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_pulseaudio")
                        PC3.ToolTip.text: i18n("Audio Settings")
                        PC3.ToolTip.visible: hovered
                        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }

                // ── Output / Input segmented control ───────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Kirigami.Units.gridUnit * 2
                    radius: height / 2
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.05)

                    Rectangle {
                        width: parent.width / 2 - 4
                        height: parent.height - 8
                        y: 4
                        x: full.isOutput ? 4 : parent.width / 2
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        Behavior on x {
                            NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [i18n("Output"), i18n("Input")]
                            delegate: MouseArea {
                                required property int index
                                required property string modelData
                                width: parent.width / 2
                                height: parent.height
                                cursorShape: Qt.PointingHandCursor
                                onClicked: full.tab = index

                                PC3.Label {
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    opacity: full.tab === parent.index ? 1 : 0.6
                                    font.weight: full.tab === parent.index ? Font.DemiBold : Font.Normal
                                }
                            }
                        }
                    }
                }

                // ── Device ─────────────────────────────────────────
                SectionLabel {
                    text: full.isOutput ? i18n("Output device") : i18n("Input device")
                }
                DeviceSelector {
                    devicesModel: full.isOutput ? sinks : sources
                    current: full.device
                    fallbackIcon: full.isOutput ? "audio-speakers" : "audio-input-microphone"
                }

                // ── Master volume ──────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    SectionLabel {
                        Layout.fillWidth: true
                        text: full.isOutput ? i18n("Master volume") : i18n("Microphone level")
                    }
                    PC3.Label {
                        text: full.deviceMuted ? i18n("Muted") : i18n("%1%", full.devicePercent)
                        font.weight: Font.DemiBold
                    }
                }
                RowLayout {
                    Layout.fillWidth: true

                    PC3.ToolButton {
                        icon.name: full.isOutput ? full.panel.volumeIcon(full.devicePercent, full.deviceMuted)
                                                 : (full.deviceMuted ? "microphone-sensitivity-muted" : "audio-input-microphone")
                        onClicked: if (full.device) full.device.muted = !full.device.muted
                        PC3.ToolTip.text: full.deviceMuted ? i18n("Unmute") : i18n("Mute")
                        PC3.ToolTip.visible: hovered
                        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                    VolumeSlider {
                        Layout.fillWidth: true
                        to: full.panel.maxPercent
                        value: full.devicePercent
                        muted: full.deviceMuted
                        peak: deviceMonitor.available ? deviceMonitor.volume : -1
                        onMoved: full.panel.setPercent(full.device, value)
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    opacity: 0.5
                }

                // ── Applications ───────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 4
                        text: full.isOutput ? i18n("Applications") : i18n("Recording apps")
                        font.weight: Font.Bold
                    }
                    PC3.Label {
                        text: i18np("%1 active", "%1 active", appList.count)
                        opacity: 0.7
                    }
                }

                Repeater {
                    id: appList
                    model: groupModel

                    delegate: StreamItem {
                        Layout.fillWidth: true
                        panel: full.panel
                        groupsByKey: full.groupsByKey
                        streamsModel: full.streamsModel
                        streamKey: full.streamKey
                        devicesModel: full.isOutput ? sinks : sources
                    }
                }

                PC3.Label {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    visible: appList.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: full.isOutput ? i18n("No apps are playing audio") : i18n("No apps are recording")
                    opacity: 0.6
                }

                PC3.Label {
                    Layout.fillWidth: true
                    visible: appList.count > 0
                    horizontalAlignment: Text.AlignHCenter
                    text: full.isOutput ? i18n("Right-click an app to change its output")
                                        : i18n("Right-click an app to change its input")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.45
                }
            }
        }
    }
}
