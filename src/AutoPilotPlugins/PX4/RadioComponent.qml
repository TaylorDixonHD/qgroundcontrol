/*=====================================================================

 QGroundControl Open Source Ground Control Station

 (c) 2009 - 2015 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>

 This file is part of the QGROUNDCONTROL project

 QGROUNDCONTROL is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 QGROUNDCONTROL is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with QGROUNDCONTROL. If not, see <http://www.gnu.org/licenses/>.

 ======================================================================*/

/// @file
///     @brief Radio Calibration
///     @author Don Gagne <don@thegagnes.com>

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2

import QGroundControl.FactSystem 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Palette 1.0
import QGroundControl.Controls 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controllers 1.0

QGCView {
    id:         rootQGCView
    viewPanel:  panel

    QGCPalette { id: qgcPal; colorGroupEnabled: panel.enabled }

    readonly property real labelToMonitorMargin: defaultTextWidth * 3
    property bool controllerCompleted: false
    property bool controllerAndViewReady: false

    function updateChannelCount()
    {
        if (controllerAndViewReady) {
            if (controller.channelCount < controller.minChannelCount) {
                showDialog(channelCountDialogComponent, "Radio Config", 50, 0)
            } else {
                hideDialog()
            }
        }
    }

    RadioComponentController {
        id:             controller
        factPanel:      panel
        statusText:     statusText
        cancelButton:   cancelButton
        nextButton:     nextButton
        skipButton:     skipButton

        onChannelCountChanged: updateChannelCount()

        Component.onCompleted: {
            controllerCompleted = true
            if (rootQGCView.completedSignalled) {
                controllerAndViewReady = true
                controller.start()
                updateChannelCount()
            }
        }
    }

    onCompleted: {
        if (controllerCompleted) {
            controllerAndViewReady = true
            controller.start()
            updateChannelCount()
        }
    }

    QGCViewPanel {
        id:             panel
        anchors.fill:   parent

        Component {
            id: channelCountDialogComponent

            QGCViewMessage {
                message: controller.channelCount == 0 ? "Please turn on transmitter." : controller.minChannelCount + " channels or more are needed to fly."
            }
        }

        Component {
            id: spektrumBindDialogComponent

            QGCViewDialog {

                function accept() {
                    controller.spektrumBindMode(radioGroup.current.bindMode)
                    hideDialog()
                }

                function reject() {
                    hideDialog()
                }

                Column {
                    anchors.fill:   parent
                    spacing:        5

                    QGCLabel {
                        width:      parent.width
                        wrapMode:   Text.WordWrap
                        text:       "Click Ok to place your Spektrum receiver in the bind mode. Select the specific receiver type below:"
                    }

                    ExclusiveGroup { id: radioGroup }

                    QGCRadioButton {
                        exclusiveGroup: radioGroup
                        text:           "DSM2 Mode"

                        property int bindMode: RadioComponentController.DSM2
                    }

                    QGCRadioButton {
                        exclusiveGroup: radioGroup
                        text:           "DSMX (7 channels or less)"

                        property int bindMode: RadioComponentController.DSMX7
                    }

                    QGCRadioButton {
                        exclusiveGroup: radioGroup
                        checked:        true
                        text:           "DSMX (8 channels or more)"

                        property int bindMode: RadioComponentController.DSMX8
                    }
                }
            }
        } // Component - spektrumBindDialogComponent

        // Live channel monitor control component
        Component {
            id: channelMonitorDisplayComponent

            Item {
                property int    rcValue:    1500


                property int            __lastRcValue:      1500
                readonly property int   __rcValueMaxJitter: 2
                property color          __barColor:         qgcPal.windowShade

                // Bar
                Rectangle {
                    id:                     bar
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  parent.width
                    height:                 parent.height / 2
                    color:                  __barColor
                }

                // Center point
                Rectangle {
                    anchors.horizontalCenter:   parent.horizontalCenter
                    width:                      defaultTextWidth / 2
                    height:                     parent.height
                    color:                      qgcPal.window
                }

                // Indicator
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  parent.height * 0.75
                    height:                 width
                    x:                      ((Math.abs((rcValue - 1000) - (reversed ? 1000 : 0)) / 1000) * parent.width) - (width / 2)
                    radius:                 width / 2
                    color:                  qgcPal.text
                    visible:                mapped
                }

                QGCLabel {
                    anchors.fill:           parent
                    horizontalAlignment:    Text.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                    text:                   "Not Mapped"
                    visible:                !mapped
                }

                ColorAnimation {
                    id:         barAnimation
                    target:     bar
                    property:   "color"
                    from:       "yellow"
                    to:         __barColor
                    duration:   1500
                }

                onRcValueChanged: {
                    if (Math.abs(rcValue - __lastRcValue) > __rcValueMaxJitter) {
                        __lastRcValue = rcValue
                        barAnimation.restart()
                    }
                }

                /*
                // rcValue debugger
                QGCLabel {
                    anchors.fill: parent
                    text: rcValue
                }
                */
            }
        } // Component - channelMonitorDisplayComponent

        // Main view Qml starts here

        QGCLabel {
            id:             header
            font.pointSize: ScreenTools.largeFontPointSize
            text:           "RADIO CONFIG"
        }

        Item {
            id:             spacer
            anchors.top:    header.bottom
            width:          parent.width
            height:         10
        }

        // Left side column
        Column {
            id:             leftColumn
            anchors.top:    spacer.bottom
            anchors.left:   parent.left
            anchors.right:  columnSpacer.left
            spacing:        10

            Row {
                spacing: 10

                QGCLabel {
                    anchors.baseline:   bindButton.baseline
                    text:               "Place Spektrum satellite receiver in bind mode:"
                }

                QGCButton {
                    id:     bindButton
                    text:   "Spektrum Bind"

                    onClicked: showDialog(spektrumBindDialogComponent, "Radio Config", 50, StandardButton.Ok | StandardButton.Cancel)
                }
            }

            // Attitude Controls
            Column {
                width:      parent.width
                spacing:    5

                QGCLabel { text: "Attitude Controls" }

                Item {
                    width:  parent.width
                    height: defaultTextHeight * 2

                    QGCLabel {
                        id:     rollLabel
                        width:  defaultTextWidth * 10
                        text:   "Roll"
                    }

                    Loader {
                        id:                 rollLoader
                        anchors.left:       rollLabel.right
                        anchors.right:      parent.right
                        height:             rootQGCView.defaultTextHeight
                        width:              100
                        sourceComponent:    channelMonitorDisplayComponent

                        property real defaultTextWidth: rootQGCView.defaultTextWidth
                        property bool mapped:           controller.rollChannelMapped
                        property bool reversed:         controller.rollChannelReversed
                    }

                    Connections {
                        target: controller

                        onRollChannelRCValueChanged: rollLoader.item.rcValue = rcValue
                    }
                }

                Item {
                    width:  parent.width
                    height: defaultTextHeight * 2

                    QGCLabel {
                        id:     pitchLabel
                        width:  defaultTextWidth * 10
                        text:   "Pitch"
                    }

                    Loader {
                        id:                 pitchLoader
                        anchors.left:       pitchLabel.right
                        anchors.right:      parent.right
                        height:             rootQGCView.defaultTextHeight
                        width:              100
                        sourceComponent:    channelMonitorDisplayComponent

                        property real defaultTextWidth: rootQGCView.defaultTextWidth
                        property bool mapped:           controller.pitchChannelMapped
                        property bool reversed:         controller.pitchChannelReversed
                    }

                    Connections {
                        target: controller

                        onPitchChannelRCValueChanged: pitchLoader.item.rcValue = rcValue
                    }
                }

                Item {
                    width:  parent.width
                    height: defaultTextHeight * 2

                    QGCLabel {
                        id:     yawLabel
                        width:  defaultTextWidth * 10
                        text:   "Yaw"
                    }

                    Loader {
                        id:                 yawLoader
                        anchors.left:       yawLabel.right
                        anchors.right:      parent.right
                        height:             rootQGCView.defaultTextHeight
                        width:              100
                        sourceComponent:    channelMonitorDisplayComponent

                        property real defaultTextWidth: rootQGCView.defaultTextWidth
                        property bool mapped:           controller.yawChannelMapped
                        property bool reversed:         controller.yawChannelReversed
                    }

                    Connections {
                        target: controller

                        onYawChannelRCValueChanged: yawLoader.item.rcValue = rcValue
                    }
                }

                Item {
                    width:  parent.width
                    height: defaultTextHeight * 2

                    QGCLabel {
                        id:     throttleLabel
                        width:  defaultTextWidth * 10
                        text:   "Throttle"
                    }

                    Loader {
                        id:                 throttleLoader
                        anchors.left:       throttleLabel.right
                        anchors.right:      parent.right
                        height:             rootQGCView.defaultTextHeight
                        width:              100
                        sourceComponent:    channelMonitorDisplayComponent

                        property real defaultTextWidth: rootQGCView.defaultTextWidth
                        property bool mapped:           controller.throttleChannelMapped
                        property bool reversed:         controller.throttleChannelReversed
                    }

                    Connections {
                        target: controller

                        onThrottleChannelRCValueChanged: throttleLoader.item.rcValue = rcValue
                    }
                }
            } // Column - Attitude Control labels

            // Command Buttons
            Row {
                spacing: 10

                QGCButton {
                    id:     skipButton
                    text:   "Skip"

                    onClicked: controller.skipButtonClicked()
                }

                QGCButton {
                    id:     cancelButton
                    text:   "Cancel"

                    onClicked: controller.cancelButtonClicked()
                }

                QGCButton {
                    id:         nextButton
                    primary:    true
                    text:       "Calibrate"

                    onClicked: controller.nextButtonClicked()
                }
            } // Row - Buttons

            // Status Text
            QGCLabel {
                id:         statusText
                width:      parent.width
                wrapMode:   Text.WordWrap
            }
        } // Column - Left Column

        Item {
            id:             columnSpacer
            anchors.right:  rightColumn.left
            width:          20
        }

        // Right side column
        Column {
            id:             rightColumn
            anchors.top:    spacer.bottom
            anchors.right:  parent.right
            width:          defaultTextWidth * 35
            spacing:        10

            Row {
                spacing: 10
                ExclusiveGroup { id: modeGroup }

                QGCRadioButton {
                    exclusiveGroup: modeGroup
                    text:           "Mode 1"
                    checked:        controller.transmitterMode == 1

                    onClicked: controller.transmitterMode = 1
                }

                QGCRadioButton {
                    exclusiveGroup: modeGroup
                    text:           "Mode 2"
                    checked:        controller.transmitterMode == 2

                    onClicked: controller.transmitterMode = 2
                }
            }

            Image {
                width:      parent.width
                height:     defaultTextHeight * 15
                fillMode:   Image.PreserveAspectFit
                smooth:     true
                source:     controller.imageHelp
            }

            // Channel monitor
            Column {
                width:      parent.width
                spacing:    5

                QGCLabel { text: "Channel Monitor" }

                Connections {
                    target: controller

                    onChannelRCValueChanged: {
                        if (channelMonitorRepeater.itemAt(channel)) {
                            channelMonitorRepeater.itemAt(channel).loader.item.rcValue = rcValue
                        }
                    }
                }

                Repeater {
                    id:     channelMonitorRepeater
                    model:  controller.channelCount
                    width:  parent.width

                    Row {
                        spacing:    5

                        // Need this to get to loader from Connections above
                        property Item loader: theLoader

                        QGCLabel {
                            id:     channelLabel
                            text:   modelData + 1
                        }

                        Loader {
                            id:                     theLoader
                            anchors.verticalCenter: channelLabel.verticalCenter
                            height:                 rootQGCView.defaultTextHeight
                            width:                  200
                            sourceComponent:        channelMonitorDisplayComponent

                            property real defaultTextWidth:     rootQGCView.defaultTextWidth
                            property bool mapped:               true
                            readonly property bool reversed:    false
                        }
                    }
                }
            } // Column - Channel Monitor
        } // Column - Right Column
    } // QGCViewPanel
}
