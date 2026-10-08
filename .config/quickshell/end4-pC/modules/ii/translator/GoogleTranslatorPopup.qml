pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "TechGlossary.js" as TechGlossary

Scope {
    id: root

    IpcHandler {
        target: "translatorService"

        function translateText(text: string): void {
            GlobalStates.translatorOpen = true;
            let clean = text ? text.trim() : "";
            if (clean.length > 0) {
                sourceInput.text = clean;
                sourceInput.selectAll();
                if (card.codeMode) {
                    card.sourceLang = "ru";
                    card.targetLang = "en";
                } else if (card.isAutoLang) {
                    card.autoDetectLanguage(clean);
                }
                card.translate();
            }
        }

        function setCodeMode(enabled: bool): void {
            card.codeMode = enabled;
        }

        function setCodeCase(c: string): void {
            card.codeCase = c;
        }
    }

    readonly property real popupWidth: 620
    readonly property real popupHeight: 600
    readonly property real popupRounding: Appearance.rounding.windowRounding

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.translatorOpen
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:googleTranslator"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.translatorOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                pastePrimaryProc.running = true;
                Qt.callLater(() => {
                    sourceInput.forceActiveFocus();
                });
            }
        }

        // Clicking outside the card closes the translator
        MouseArea {
            anchors.fill: parent
            onClicked: {
                GlobalStates.translatorOpen = false;
            }
        }

        // Main Glassmorphic Container Card matching shell theme
        Rectangle {
            id: card
            anchors.centerIn: parent
            width: root.popupWidth
            height: root.popupHeight
            radius: root.popupRounding
            color: Appearance.colors.colLayer1Base
            border.color: Appearance.colors.colLayer0Border
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                color: "#60000000"
                radius: 24
                samples: 25
                horizontalOffset: 0
                verticalOffset: 8
            }

            // Consume clicks inside card
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.translatorOpen = false;
                    event.accepted = true;
                }
            }

            // Internal state
            property string sourceLang: GlobalStates.translatorSourceLang || "en"
            property string targetLang: GlobalStates.translatorTargetLang || "ru"
            property string translatedText: ""
            property string rawTranslatedText: ""
            property bool codeMode: GlobalStates.translatorCodeMode
            property string codeCase: GlobalStates.translatorCodeCase || "pascal"
            property var codeIdentifiers: TechGlossary.getCodeIdentifiers(
                rawTranslatedText && rawTranslatedText.trim().length > 0
                    ? rawTranslatedText
                    : (card.targetLang === "en" || card.codeMode ? card.translatedText : "")
            )
            property bool isTranslating: false
            property bool showCopied: false
            property bool itMode: true
            property bool isAutoLang: true
            property string detectedLang: ""

            onCodeModeChanged: {
                GlobalStates.translatorCodeMode = card.codeMode;
                card.updateOutput();
            }
            onCodeCaseChanged: {
                GlobalStates.translatorCodeCase = card.codeCase;
                card.updateOutput();
            }

            function updateOutput() {
                if (!card.rawTranslatedText || card.rawTranslatedText.trim().length === 0) {
                    card.translatedText = "";
                    return;
                }

                if (card.codeMode) {
                    let ids = TechGlossary.getCodeIdentifiers(card.rawTranslatedText);
                    let val = "";
                    if (card.codeCase === "pascal") val = ids.pascal;
                    else if (card.codeCase === "camel") val = ids.camel;
                    else if (card.codeCase === "snake") val = ids.snake;
                    else if (card.codeCase === "screaming") val = ids.screaming;
                    else if (card.codeCase === "kebab") val = ids.kebab;

                    card.translatedText = val || ids.pascal || card.rawTranslatedText;
                } else {
                    card.translatedText = card.rawTranslatedText;
                }
            }

            function autoDetectLanguage(text) {
                if (!text || text.trim().length === 0) return;
                let clean = text.trim();
                let cyrMatches = clean.match(/[а-яёА-ЯЁ]/g);
                let latMatches = clean.match(/[a-zA-Z]/g);
                let cyrCount = cyrMatches ? cyrMatches.length : 0;
                let latCount = latMatches ? latMatches.length : 0;
                if (cyrCount > latCount) {
                    card.sourceLang = "ru";
                    card.targetLang = "en";
                } else {
                    card.sourceLang = "en";
                    card.targetLang = "ru";
                }
            }

            function translate() {
                let rawText = sourceInput.text ? sourceInput.text.trim() : "";
                if (rawText.length === 0) {
                    card.rawTranslatedText = "";
                    card.translatedText = "";
                    card.isTranslating = false;
                    return;
                }

                // Smart sentence unwrapping to fix broken OCR line-breaks
                let text = TechGlossary.smartUnwrap(rawText);
                let cyrMatches = text.match(/[а-яёА-ЯЁ]/g);
                let latMatches = text.match(/[a-zA-Z]/g);
                let cyrCount = cyrMatches ? cyrMatches.length : 0;
                let latCount = latMatches ? latMatches.length : 0;

                if (card.codeMode) {
                    if (cyrCount === 0 && latCount > 0) {
                        card.isTranslating = false;
                        card.sourceLang = "en";
                        card.targetLang = "en";
                        card.rawTranslatedText = text;
                        card.updateOutput();
                        return;
                    } else {
                        card.sourceLang = "ru";
                        card.targetLang = "en";
                    }
                } else if (card.isAutoLang) {
                    card.autoDetectLanguage(text);
                }

                card.isTranslating = true;
                let slParam = (card.isAutoLang && !card.codeMode) ? "auto" : card.sourceLang;
                let url = "https://clients5.google.com/translate_a/t?client=dict-chrome-ex"
                    + "&sl=" + encodeURIComponent(slParam)
                    + "&tl=" + encodeURIComponent(card.targetLang)
                    + "&q=" + encodeURIComponent(text);

                let xhr = new XMLHttpRequest();
                xhr.open("GET", url);
                xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36");
                xhr.timeout = 10000;
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        card.isTranslating = false;
                        if (xhr.status === 200) {
                            try {
                                let res = JSON.parse(xhr.responseText);
                                let rawResult = "";
                                let detected = "";

                                if (Array.isArray(res)) {
                                    if (res.length > 0 && Array.isArray(res[0])) {
                                        rawResult = res[0][0] || "";
                                        detected = res[0][1] || "";
                                    } else {
                                        rawResult = res.join("\n");
                                    }
                                } else if (typeof res === "string") {
                                    rawResult = res;
                                } else {
                                    rawResult = xhr.responseText;
                                }

                                if (detected && detected.length > 0) {
                                    card.detectedLang = detected;
                                    if (card.isAutoLang && !card.codeMode) {
                                        if (detected === "ru") {
                                            card.sourceLang = "ru";
                                            card.targetLang = "en";
                                        } else {
                                            card.sourceLang = detected;
                                            card.targetLang = "ru";
                                        }
                                    }
                                }

                                if (card.itMode) {
                                    card.rawTranslatedText = TechGlossary.enhance(text, rawResult, card.sourceLang, card.targetLang);
                                } else {
                                    card.rawTranslatedText = rawResult;
                                }
                                card.updateOutput();
                            } catch(e) {
                                card.rawTranslatedText = xhr.responseText;
                                card.updateOutput();
                            }
                        } else {
                            card.translatedText = "Ошибка соединения (" + xhr.status + ")";
                        }
                    }
                };
                xhr.ontimeout = function() {
                    card.isTranslating = false;
                    card.translatedText = "Превышено время ожидания";
                };
                xhr.onerror = function() {
                    card.isTranslating = false;
                    card.translatedText = "Ошибка сети";
                };
                xhr.send();
            }

            function swap() {
                card.isAutoLang = false;
                let temp = card.sourceLang;
                card.sourceLang = card.targetLang;
                card.targetLang = temp;
                GlobalStates.translatorSourceLang = card.sourceLang;
                GlobalStates.translatorTargetLang = card.targetLang;

                if (card.rawTranslatedText && card.rawTranslatedText.length > 0) {
                    sourceInput.text = card.rawTranslatedText;
                    card.translate();
                } else if (card.translatedText.length > 0) {
                    sourceInput.text = card.translatedText;
                    card.translate();
                } else if (sourceInput.text.trim().length > 0) {
                    card.translate();
                }
            }

            Timer {
                id: debounceTimer
                interval: 350
                repeat: false
                onTriggered: card.translate()
            }

            Timer {
                id: copiedTimer
                interval: 2000
                onTriggered: card.showCopied = false
            }

            // Clipboard process
            Process {
                id: pasteProc
                command: ["wl-paste", "--type", "text"]
                property string buffer: ""
                stdout: SplitParser {
                    onRead: data => {
                        pasteProc.buffer += data + "\n";
                    }
                }
                onExited: (code, status) => {
                    let clean = pasteProc.buffer.trim();
                    pasteProc.buffer = "";
                    if (code === 0 && clean.length > 0 && clean !== "Nothing is copied") {
                        sourceInput.text = clean;
                        sourceInput.cursorPosition = clean.length;
                        if (card.isAutoLang) {
                            card.autoDetectLanguage(clean);
                        }
                        card.translate();
                    }
                }
            }

            // Primary selection process (mouse selection in any app)
            Process {
                id: pastePrimaryProc
                command: ["wl-paste", "--primary", "--type", "text"]
                property string buffer: ""
                stdout: SplitParser {
                    onRead: data => {
                        pastePrimaryProc.buffer += data + "\n";
                    }
                }
                onExited: (code, status) => {
                    let clean = pastePrimaryProc.buffer.trim();
                    pastePrimaryProc.buffer = "";
                    if (code === 0 && clean.length > 0 && clean !== "Nothing is copied") {
                        sourceInput.text = clean;
                        sourceInput.selectAll();
                        if (card.isAutoLang) {
                            card.autoDetectLanguage(clean);
                        }
                        card.translate();
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // ==========================================
                // 1. Header (Icon + Title + Close Button)
                // ==========================================
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "g_translate"
                            iconSize: 20
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    StyledText {
                        text: "Google Переводчик"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }

                    // IT Slang mode toggle chip
                    Rectangle {
                        implicitHeight: 24
                        implicitWidth: itRow.implicitWidth + 14
                        radius: Appearance.rounding.full
                        color: card.itMode ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        border.color: card.itMode ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        border.width: 1

                        RowLayout {
                            id: itRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: "terminal"
                                iconSize: 13
                                color: card.itMode ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: "IT-сленг"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: card.itMode ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }
                        }

                        MouseArea {
                            id: itMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.itMode = !card.itMode;
                                if (sourceInput.text.trim().length > 0) {
                                    card.translate();
                                }
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: itMouse.containsMouse
                            text: card.itMode ? "IT-режим включен (сленг программистов и термины)" : "Включить адаптацию IT-сленга"
                        }
                    }

                    // Auto-Language Mode toggle chip
                    Rectangle {
                        implicitHeight: 24
                        implicitWidth: autoRow.implicitWidth + 14
                        radius: Appearance.rounding.full
                        color: card.isAutoLang ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        border.color: card.isAutoLang ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        border.width: 1

                        RowLayout {
                            id: autoRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: "auto_mode"
                                iconSize: 13
                                color: card.isAutoLang ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: "Авто"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: card.isAutoLang ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }
                        }

                        MouseArea {
                            id: autoMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.isAutoLang = !card.isAutoLang;
                                if (card.isAutoLang && sourceInput.text.trim().length > 0) {
                                    card.autoDetectLanguage(sourceInput.text);
                                }
                                if (sourceInput.text.trim().length > 0) {
                                    card.translate();
                                }
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: autoMouse.containsMouse
                            text: card.isAutoLang ? "Автоматическое определение языка включено" : "Включить автоопределение языка"
                        }
                    }

                    // Variable / Code Naming Mode toggle chip
                    Rectangle {
                        implicitHeight: 24
                        implicitWidth: codeRow.implicitWidth + 14
                        radius: Appearance.rounding.full
                        color: card.codeMode ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        border.color: card.codeMode ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        border.width: 1

                        RowLayout {
                            id: codeRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: "data_object"
                                iconSize: 13
                                color: card.codeMode ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: "Код"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: card.codeMode ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            }
                        }

                        MouseArea {
                            id: codeChipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.codeMode = !card.codeMode;
                                if (card.codeMode) {
                                    let clean = sourceInput.text.trim();
                                    let cyr = clean.match(/[а-яёА-ЯЁ]/g);
                                    if (cyr && cyr.length > 0) {
                                        card.sourceLang = "ru";
                                        card.targetLang = "en";
                                    }
                                }
                                if (sourceInput.text.trim().length > 0) {
                                    card.translate();
                                }
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: codeChipMouse.containsMouse
                            text: card.codeMode 
                                ? "Режим имён переменных активен (PascalCase, camelCase и др.)" 
                                : "Включить режим имён переменных для кода (PascalCase, camelCase)"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Close button
                    Rectangle {
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: Appearance.rounding.full
                        color: closeMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 18
                            color: closeMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalStates.translatorOpen = false
                        }
                    }
                }

                // ==========================================
                // 2. Language Bar (Source ⇄ Target)
                // ==========================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer2Base

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 6

                        // Source Language Button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Appearance.rounding.normal - 2
                            color: card.sourceLang === "en" ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1

                            StyledText {
                                anchors.centerIn: parent
                                text: {
                                    let label = (card.sourceLang === "en" ? "Английский (EN)" : (card.sourceLang === "ru" ? "Русский (RU)" : card.sourceLang.toUpperCase()));
                                    return card.isAutoLang ? ("Авто: " + label) : label;
                                }
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: card.sourceLang === "en" ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            }
                        }

                        // Swap Button
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: Appearance.rounding.full
                            color: swapMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "swap_horiz"
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }

                            MouseArea {
                                id: swapMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: card.swap()
                            }
                        }

                        // Target Language Button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Appearance.rounding.normal - 2
                            color: card.targetLang === "ru" ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1

                            StyledText {
                                anchors.centerIn: parent
                                text: card.targetLang === "ru" ? "Русский (RU)" : "Английский (EN)"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: card.targetLang === "ru" ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }

                // ==========================================
                // 3. Input Section (Source text)
                // ==========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer2Base
                    border.color: sourceInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    border.width: sourceInput.activeFocus ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        // Top action row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: card.sourceLang === "en" ? "Исходный текст (EN)" : "Исходный текст (RU)"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colSubtext
                            }

                            Item { Layout.fillWidth: true }

                            // Paste from clipboard button
                            Rectangle {
                                implicitWidth: pasteRow.implicitWidth + 12
                                implicitHeight: 26
                                radius: Appearance.rounding.full
                                color: pasteMouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
                                border.color: Appearance.colors.colLayer0Border
                                border.width: 1

                                RowLayout {
                                    id: pasteRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: "content_paste"; iconSize: 14; color: Appearance.colors.colPrimary }
                                    StyledText { text: "Вставить"; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                                }

                                MouseArea {
                                    id: pasteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pasteProc.running = true
                                }
                            }

                            // Paste primary selection button
                            Rectangle {
                                implicitWidth: selRow.implicitWidth + 12
                                implicitHeight: 26
                                radius: Appearance.rounding.full
                                color: selMouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
                                border.color: Appearance.colors.colLayer0Border
                                border.width: 1

                                RowLayout {
                                    id: selRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: "format_quote"; iconSize: 14; color: Appearance.colors.colPrimary }
                                    StyledText { text: "Выделение"; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                                }

                                MouseArea {
                                    id: selMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pastePrimaryProc.running = true
                                }
                            }

                            // Clear button
                            Rectangle {
                                visible: sourceInput.text.length > 0
                                implicitWidth: 26
                                implicitHeight: 26
                                radius: Appearance.rounding.full
                                color: clearMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "backspace"
                                    iconSize: 14
                                    color: Appearance.colors.colSubtext
                                }

                                MouseArea {
                                    id: clearMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        sourceInput.text = "";
                                        card.translatedText = "";
                                    }
                                }
                            }
                        }

                        // Text Area
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: sourceInput
                                wrapMode: TextEdit.Wrap
                                placeholderText: card.sourceLang === "en"
                                    ? "Введите или вставьте текст на английском..."
                                    : "Введите или вставьте текст на русском..."
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer2
                                placeholderTextColor: Appearance.colors.colSubtext
                                background: null
                                selectByMouse: true
                                topPadding: 4
                                bottomPadding: 4
                                leftPadding: 2
                                rightPadding: 2

                                onTextChanged: {
                                    if (card.isAutoLang && sourceInput.text.trim().length > 0) {
                                        card.autoDetectLanguage(sourceInput.text);
                                    }
                                    debounceTimer.restart();
                                }

                                Keys.onReturnPressed: (event) => {
                                    if (event.modifiers === Qt.ControlModifier) {
                                        debounceTimer.stop();
                                        card.translate();
                                        event.accepted = true;
                                    } else {
                                        event.accepted = false;
                                    }
                                }
                            }
                        }

                        // Bottom info (character count)
                        RowLayout {
                            Layout.fillWidth: true
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: sourceInput.text.length + " символов"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }

                // ==========================================
                // 4. Output Section (Target translation)
                // ==========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer2Base
                    border.color: Appearance.colors.colLayer0Border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        // Top action row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: card.codeMode
                                    ? ("Имя в коде (" + (card.codeCase === "pascal" ? "PascalCase" : (card.codeCase === "camel" ? "camelCase" : (card.codeCase === "snake" ? "snake_case" : (card.codeCase === "screaming" ? "CONST_CASE" : "kebab-case")))) + ")")
                                    : (card.targetLang === "ru" ? "Перевод (Русский)" : "Перевод (Английский)")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colPrimary
                            }

                            RowLayout {
                                visible: card.isTranslating
                                spacing: 4
                                MaterialSymbol {
                                    text: "sync"
                                    iconSize: 14
                                    color: Appearance.colors.colPrimary
                                    RotationAnimation on rotation {
                                        from: 0
                                        to: 360
                                        duration: 1000
                                        loops: Animation.Infinite
                                    }
                                }
                                StyledText {
                                    text: "Переводим..."
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Copy button
                            Rectangle {
                                visible: card.translatedText.length > 0
                                implicitWidth: copyRow.implicitWidth + 14
                                implicitHeight: 26
                                radius: Appearance.rounding.full
                                color: card.showCopied
                                    ? Appearance.colors.colPrimary
                                    : (copyMouse.containsMouse ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colPrimaryContainer)

                                RowLayout {
                                    id: copyRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: card.showCopied ? "check" : "content_copy"
                                        iconSize: 14
                                        color: card.showCopied ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                                    }
                                    StyledText {
                                        text: card.showCopied ? "Скопировано!" : "Копировать"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.Medium
                                        color: card.showCopied ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                                    }
                                }

                                MouseArea {
                                    id: copyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["wl-copy", card.translatedText]);
                                        card.showCopied = true;
                                        copiedTimer.restart();
                                    }
                                }
                            }
                        }

                        // Translation Text Display
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                text: card.translatedText
                                placeholderText: card.codeMode ? "Имя переменной появится здесь..." : "Перевод появится здесь..."
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.family: card.codeMode ? Appearance.font.family.monospace : Appearance.font.family.main
                                font.weight: card.translatedText.length > 0 ? Font.Medium : Font.Normal
                                color: card.translatedText.length > 0 ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                                placeholderTextColor: Appearance.colors.colSubtext
                                background: null
                                selectByMouse: true
                                topPadding: 4
                                bottomPadding: 4
                                leftPadding: 2
                                rightPadding: 2
                            }
                        }

                        // Code naming formats bar (PascalCase, camelCase, snake_case, CONST_CASE, kebab-case)
                        // Code naming formats bar (PascalCase, camelCase, snake_case, CONST_CASE, kebab-case)
                        Rectangle {
                            visible: !!(card.codeIdentifiers && card.codeIdentifiers.pascal && card.codeIdentifiers.pascal.length > 0)
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer1Base
                            border.color: Appearance.colors.colLayer0Border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 4

                                Repeater {
                                    model: [
                                        { key: "pascal", label: "Pascal" },
                                        { key: "camel", label: "camel" },
                                        { key: "snake", label: "snake" },
                                        { key: "screaming", label: "CONST" },
                                        { key: "kebab", label: "kebab" }
                                    ]

                                    Rectangle {
                                        id: segRect
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Appearance.rounding.small - 2
                                        color: (card.codeMode && card.codeCase === segRect.modelData.key)
                                            ? Appearance.colors.colPrimaryContainer
                                            : (segMouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1)
                                        border.color: (card.codeMode && card.codeCase === segRect.modelData.key)
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colLayer0Border
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.topMargin: 3
                                            anchors.bottomMargin: 3
                                            anchors.leftMargin: 4
                                            anchors.rightMargin: 4
                                            spacing: 1

                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                text: segRect.modelData.label
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                color: (card.codeMode && card.codeCase === segRect.modelData.key)
                                                    ? Appearance.colors.colOnPrimaryContainer
                                                    : Appearance.colors.colPrimary
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                text: (card.codeIdentifiers && card.codeIdentifiers[segRect.modelData.key]) ? card.codeIdentifiers[segRect.modelData.key] : ""
                                                font.pixelSize: 10
                                                font.family: Appearance.font.family.monospace
                                                elide: Text.ElideRight
                                                color: (card.codeMode && card.codeCase === segRect.modelData.key)
                                                    ? Appearance.colors.colOnPrimaryContainer
                                                    : Appearance.colors.colOnLayer1
                                            }
                                        }

                                        MouseArea {
                                            id: segMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let val = (card.codeIdentifiers && card.codeIdentifiers[segRect.modelData.key]) ? card.codeIdentifiers[segRect.modelData.key] : "";
                                                if (val.length > 0) {
                                                    card.codeCase = segRect.modelData.key;
                                                    card.codeMode = true;
                                                    card.translatedText = val;
                                                    Quickshell.execDetached(["wl-copy", val]);
                                                    card.showCopied = true;
                                                    copiedTimer.restart();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                }
            }
        }
    }
}
}

