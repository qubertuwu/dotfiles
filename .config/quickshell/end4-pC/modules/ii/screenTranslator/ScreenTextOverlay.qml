pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property double scaleFactor: 1
    property color overlayColor: "#BB000000"
    property color textColor: "white"
    required property string screenshotPath

    property bool loading: true
    property var visionParagraphs: []
    property var translation: ({})

    function translate(s: string): string {
        return translation[s] ?? s;
    }

    property bool error: false
    property string errorMessage: ""
    function showError() {
        error = true;
    }

    Process {
        id: ocrProcess
        command: ["python3", Quickshell.shellPath("scripts/screen_ocr_translate.py"), root.screenshotPath]
        running: true
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                ocrProcess.buffer += data + "\n";
            }
        }
        onExited: (code, status) => {
            if (code === 0) {
                try {
                    let result = JSON.parse(ocrProcess.buffer.trim());
                    if (result.error) {
                        root.errorMessage = result.error;
                        root.showError();
                    } else {
                        root.visionParagraphs = result.paragraphs || [];
                        root.translation = result.translations || ({});
                        root.loading = false;
                    }
                } catch(e) {
                    root.errorMessage = "Ошибка обработки данных OCR: " + e;
                    root.showError();
                }
            } else {
                root.errorMessage = "Ошибка OCR (код " + code + ")";
                root.showError();
            }
        }
    }

    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        opacity: root.loading ? 1 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
        }
        color: root.overlayColor

        Column {
            visible: !root.error
            anchors.centerIn: parent
            spacing: 10 * root.scaleFactor
            MaterialLoadingIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitSize: 100 * root.scaleFactor
                scale: 1 + ((1 - loadingOverlay.opacity) * 0.5) * root.scaleFactor
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Распознавание и перевод текста..."
                font.pixelSize: Appearance.font.pixelSize.small * root.scaleFactor
                animateChange: true
                color: root.textColor
            }
        }

        Column {
            visible: root.error
            anchors.centerIn: parent
            spacing: 10 * root.scaleFactor

            MaterialShapeWrappedMaterialSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "exclamation"
                iconSize: 80 * root.scaleFactor
                padding: 6 * root.scaleFactor
                color: Appearance.colors.colError
                colSymbol: Appearance.colors.colOnError
                shape: MaterialShape.Shape.Sunny
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(root.windowWidth / 2, 800) * root.scaleFactor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: `**Ошибка перевода экрана**\n\n${root.errorMessage}`
                font.pixelSize: Appearance.font.pixelSize.small * root.scaleFactor
                color: root.textColor
            }
        }
    }

    property real windowWidth: QsWindow.window.screen.width
    property real windowHeight: QsWindow.window.screen.height

    StyledImage {
        id: screenshotImage
        z: 1
        asynchronous: false
        width: root.windowWidth
        height: root.windowHeight
        sourceSize: Qt.size(root.windowWidth, root.windowHeight)
        source: Qt.resolvedUrl(root.screenshotPath)
        visible: false
    }

    Item {
        id: blurMaskItem
        z: 2
        width: root.windowWidth
        height: root.windowHeight
        layer.enabled: true
        visible: false
        Repeater {
            model: root.loading ? [] : root.visionParagraphs
            delegate: VisionBoundingBoxRect {
                readonly property string text: modelData.text
                readonly property string translatedText: root.translate(text)
                visible: translatedText != text
                scaleFactor: 1
            }
        }
    }

    MaskMultiEffect {
        z: 4
        implicitWidth: parent.width
        implicitHeight: parent.height
        width: parent.width
        height: parent.height

        // Mask
        source: screenshotImage
        maskSource: blurMaskItem

        // Blur
        blurEnabled: true
        blur: 1
        blurMax: 50
        blurMultiplier: root.scaleFactor
        autoPaddingEnabled: false
    }

    Item {
        id: textItems
        z: 999
        Repeater {
            model: root.loading ? [] : root.visionParagraphs
            delegate: TextItem {}
        }
    }

    component VisionBoundingBoxRect: Rectangle {
        required property var modelData
        property real scaleFactor: root.scaleFactor
        property list<var> boundingVertices: modelData.boundingBox.vertices
        property real unscaledX: boundingVertices[0].x
        property real unscaledY: boundingVertices[0].y
        property real unscaledWidth: boundingVertices[1].x - boundingVertices[0].x
        property real unscaledHeight: boundingVertices[2].y - boundingVertices[0].y
        x: unscaledX * scaleFactor
        y: unscaledY * scaleFactor
        width: unscaledWidth * scaleFactor
        height: unscaledHeight * scaleFactor
        radius: 4
    }

    component TextItem: VisionBoundingBoxRect {
        id: ti
        readonly property string text: modelData.text
        readonly property string translatedText: root.translate(text)
        visible: translatedText != text && translatedText.length > 0

        color: ColorUtils.applyAlpha(Appearance.colors.colLayer1Base, 0.92)
        border.color: Appearance.colors.colLayer0Border
        border.width: 1

        SqueezedAnnotationStyledText {
            id: tiText
            anchors.centerIn: parent
            width: Math.max(10, parent.width - 4)
            height: Math.max(10, parent.height - 2)
            text: ti.translatedText
            color: Appearance.colors.colOnLayer1
            scaleFactor: root.scaleFactor
        }
    }
}
