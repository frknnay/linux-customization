import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

// Thin rounded track with an accent fill, a live level meter behind it and a round knob.
T.Slider {
    id: control

    property bool muted: false
    // 0..1 live level of the stream/device, or -1 to hide the meter
    property real peak: -1
    // Values above this are drawn in the "danger" color (over-amplified)
    property real normalValue: 100

    from: 0
    to: 100
    stepSize: 1
    snapMode: T.Slider.SnapAlways
    wheelEnabled: false

    implicitWidth: Kirigami.Units.gridUnit * 10
    implicitHeight: Kirigami.Units.gridUnit * 1.4

    readonly property color accent: muted ? Kirigami.Theme.disabledTextColor
                                          : (value > normalValue ? Kirigami.Theme.negativeTextColor
                                                                 : Kirigami.Theme.highlightColor)

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: Kirigami.Units.gridUnit * 0.9
        radius: height / 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

        // Live audio level
        Rectangle {
            visible: control.peak >= 0 && !control.muted
            width: parent.width * Math.min(1, control.peak) * (control.value / control.to)
            height: parent.height
            radius: parent.radius
            color: Qt.alpha(control.accent, 0.25)
            Behavior on width {
                NumberAnimation { duration: 60 }
            }
        }

        // Volume fill
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: Qt.alpha(control.accent, 0.55)
        }

        // Tick at 100% when the range allows over-amplification
        Rectangle {
            visible: control.to > control.normalValue
            x: parent.width * (control.normalValue / control.to) - width / 2
            width: 2
            height: parent.height
            color: Qt.alpha(Kirigami.Theme.textColor, 0.25)
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        width: Kirigami.Units.gridUnit * 1.1
        height: width
        radius: width / 2
        color: control.muted ? Kirigami.Theme.disabledTextColor : "white"
        border.width: control.visualFocus ? 2 : 0
        border.color: Kirigami.Theme.highlightColor
        scale: control.pressed ? 1.15 : (control.hovered ? 1.05 : 1)

        Behavior on scale {
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }
    }
}
