pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "Singletons"

/**
 * 対 CHATBOT surface: Full-featured Desktop AI Assistant.
 * Multi-provider support (Gemini, OpenRouter, Claude, Groq, DeepSeek, Mistral, OpenAI, Ollama),
 * Provider & Model dropdown pickers with dynamic model fetching,
 * Natural live typewriter streaming generation (like ChatGPT/Claude/Gemini apps),
 * Persistent session history across reboots, /commands,
 * and safe system tool execution with interactive permission cards.
 */
PillSurface {
    id: root

    mTop: 14
    mLeft: 14
    mRight: 14
    mBottom: 14

    property string engineScript: Quickshell.env("HOME") + "/.config/hypr/scripts/chatbot-engine.py"

    property string currentSessionId: ""
    property string activeProvider: "OpenRouter"
    property string activeModel: "deepseek/deepseek-chat"
    property var availableModels: []
    property var availableProviders: ["OpenRouter", "Gemini", "Claude", "Groq", "DeepSeek", "Mistral", "OpenAI", "NVIDIA", "Ollama", "Custom"]
    property var sessionsList: []
    property var configData: ({})

    property bool isThinking: false
    property bool isFetchingModels: false

    // Natural Typewriter Streaming Queue & State
    property string typeStreamTarget: ""
    property int typeStreamMsgIndex: -1
    property bool typeStreamActive: false
    property var pendingDoneEvent: null

    // Modal / Dropdown visibility states
    property bool providerMenuOpen: false
    property bool modelMenuOpen: false
    property bool sessionsModalOpen: false
    property bool connectModalOpen: false

    property string modelSearchQuery: ""
    property string connectSelectedProvider: "OpenRouter"
    property string connectKeyInput: ""
    property string connectUrlInput: ""

    function focusInput() {
        if (!sessionsModalOpen && !connectModalOpen && !providerMenuOpen && !modelMenuOpen) {
            inputField.forceActiveFocus();
        }
    }

    function closeAllMenus() {
        providerMenuOpen = false;
        modelMenuOpen = false;
        sessionsModalOpen = false;
        connectModalOpen = false;
    }

    function adjustWidth(delta) {
        var current = Flags.chatbotWidth > 0 ? Flags.chatbotWidth : 500;
        var next = Math.max(380, Math.min(1200, current + delta));
        Flags.chatbotWidth = next;
    }

    function adjustHeight(delta) {
        var current = Flags.chatbotHeight > 0 ? Flags.chatbotHeight : 540;
        var next = Math.max(360, Math.min(1000, current + delta));
        Flags.chatbotHeight = next;
    }

    function handleResizeKey(e) {
        var isCtrl = (e.modifiers & Qt.ControlModifier);
        var isShift = (e.modifiers & Qt.ShiftModifier);
        if (!isCtrl)
            return false;

        var isPlus = (e.key === Qt.Key_Plus || e.key === Qt.Key_Equal);
        var isMinus = (e.key === Qt.Key_Minus || e.key === Qt.Key_Underscore);

        if (isShift) {
            if (isPlus) {
                root.adjustHeight(40);
                e.accepted = true;
                return true;
            } else if (isMinus) {
                root.adjustHeight(-40);
                e.accepted = true;
                return true;
            }
        } else {
            if (isPlus) {
                root.adjustWidth(40);
                e.accepted = true;
                return true;
            } else if (isMinus) {
                root.adjustWidth(-40);
                e.accepted = true;
                return true;
            }
        }
        return false;
    }

    // ========================================================================
    // NATURAL TYPEWRITER STREAMING TIMER (~60 FPS)
    // ========================================================================
    Timer {
        id: typewriterTimer
        interval: 16 // Smooth natural typing cadence
        repeat: true
        running: root.typeStreamActive

        onTriggered: {
            if (root.typeStreamMsgIndex < 0 || root.typeStreamMsgIndex >= chatModel.count) {
                root.typeStreamActive = false;
                return;
            }

            var curText = chatModel.get(root.typeStreamMsgIndex).text;
            if (curText.length < root.typeStreamTarget.length) {
                var remaining = root.typeStreamTarget.length - curText.length;
                // Adaptive typing pace: small steps for natural human cadence, faster if buffer grows
                var step = remaining > 120 ? 8 : (remaining > 50 ? 4 : (remaining > 15 ? 2 : 1));
                var nextText = root.typeStreamTarget.substring(0, curText.length + step);
                chatModel.setProperty(root.typeStreamMsgIndex, "text", nextText);
                messageList.positionViewAtEnd();
            } else {
                if (!root.isThinking) {
                    root.typeStreamActive = false;
                    if (root.pendingDoneEvent) {
                        var ev = root.pendingDoneEvent;
                        var action = ev.toolAction;
                        chatModel.setProperty(root.typeStreamMsgIndex, "status", action ? "pending_permission" : "done");
                        if (action) {
                            chatModel.setProperty(root.typeStreamMsgIndex, "toolName", action.tool || "");
                            chatModel.setProperty(root.typeStreamMsgIndex, "toolPath", action.path || "");
                            chatModel.setProperty(root.typeStreamMsgIndex, "toolCommand", action.command || "");
                            chatModel.setProperty(root.typeStreamMsgIndex, "toolContent", action.content || "");
                            chatModel.setProperty(root.typeStreamMsgIndex, "toolExplanation", action.explanation || "");
                        }
                        root.pendingDoneEvent = null;
                        messageList.positionViewAtEnd();
                    }
                }
            }
        }
    }

    // ========================================================================
    // BACKEND PROCESSES & HANDLERS
    // ========================================================================

    // 1. Load Initial Config & Session
    Process {
        id: initProc
        command: [root.engineScript, "--get-config"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.configData = data;
                    if (data.provider) root.activeProvider = data.provider;
                    if (data.model) root.activeModel = data.model;
                    root.fetchModelsForProvider(root.activeProvider);
                    loadCurrentSessionProc.running = true;
                } catch (e) {}
            }
        }
    }

    Process {
        id: loadCurrentSessionProc
        command: [root.engineScript, "--get-session", root.currentSessionId || ""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    if (data && data.id) {
                        root.currentSessionId = data.id;
                        chatModel.clear();
                        var msgs = data.messages || [];
                        for (var i = 0; i < msgs.length; i++) {
                            chatModel.append({
                                "sender": msgs[i].sender || "assistant",
                                "text": msgs[i].text || "",
                                "time": msgs[i].time || "",
                                "status": msgs[i].status || "done",
                                "toolName": (msgs[i].toolAction && msgs[i].toolAction.tool) ? msgs[i].toolAction.tool : "",
                                "toolPath": (msgs[i].toolAction && msgs[i].toolAction.path) ? msgs[i].toolAction.path : "",
                                "toolCommand": (msgs[i].toolAction && msgs[i].toolAction.command) ? msgs[i].toolAction.command : "",
                                "toolContent": (msgs[i].toolAction && msgs[i].toolAction.content) ? msgs[i].toolAction.content : "",
                                "toolExplanation": (msgs[i].toolAction && msgs[i].toolAction.explanation) ? msgs[i].toolAction.explanation : ""
                            });
                        }
                        messageList.positionViewAtEnd();
                    }
                } catch (e) {}
            }
        }
    }

    // 2. Fetch Models Process
    function fetchModelsForProvider(p) {
        root.isFetchingModels = true;
        fetchModelsProc.command = [root.engineScript, "--list-models", "--provider", p];
        fetchModelsProc.running = true;
    }

    Process {
        id: fetchModelsProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.isFetchingModels = false;
                try {
                    var data = JSON.parse(this.text);
                    if (data && data.models) {
                        root.availableModels = data.models;
                        if (data.models.length > 0 && data.models.indexOf(root.activeModel) === -1) {
                            root.activeModel = data.models[0];
                            root.saveActiveModel(root.activeModel);
                        }
                    }
                } catch (e) {}
            }
        }
    }

    function saveActiveProvider(p) {
        root.activeProvider = p;
        saveConfigProc.command = [root.engineScript, "--set-config", JSON.stringify({ "provider": p })];
        saveConfigProc.running = true;
        root.fetchModelsForProvider(p);
    }

    function saveActiveModel(m) {
        root.activeModel = m;
        saveConfigProc.command = [root.engineScript, "--set-config", JSON.stringify({ "model": m })];
        saveConfigProc.running = true;
    }

    Process { id: saveConfigProc }

    // 3. Natural Streaming Chat Turn Process
    function sendMessage(text) {
        var msg = (text !== undefined ? text : inputField.text).trim();
        if (msg.length === 0)
            return;

        closeAllMenus();

        if (msg === "/clear") {
            triggerClearSession();
            inputField.text = "";
            return;
        } else if (msg === "/new") {
            triggerNewSession();
            inputField.text = "";
            return;
        } else if (msg === "/sessions") {
            openSessionsModal();
            inputField.text = "";
            return;
        } else if (msg === "/models") {
            root.fetchModelsForProvider(root.activeProvider);
            inputField.text = "";
            return;
        } else if (msg.indexOf("/connect") === 0) {
            var parts = msg.split(" ");
            if (parts.length >= 3) {
                var p = parts[1];
                var k = parts[2];
                var keysObj = root.configData.keys || {};
                keysObj[p] = k;
                saveConfigProc.command = [root.engineScript, "--set-config", JSON.stringify({ "keys": keysObj })];
                saveConfigProc.running = true;
                chatModel.append({
                    "sender": "assistant",
                    "text": "Saved API key for **" + p + "**.",
                    "time": Qt.formatTime(new Date(), "HH:mm"),
                    "status": "done",
                    "toolName": "", "toolPath": "", "toolCommand": "", "toolContent": "", "toolExplanation": ""
                });
            } else {
                root.openConnectModal();
            }
            inputField.text = "";
            return;
        }

        var now = new Date();
        var timeStr = Qt.formatTime(now, "HH:mm");

        chatModel.append({
            "sender": "user",
            "text": msg,
            "time": timeStr,
            "status": "done",
            "toolName": "", "toolPath": "", "toolCommand": "", "toolContent": "", "toolExplanation": ""
        });

        inputField.text = "";
        messageList.positionViewAtEnd();

        root.isThinking = true;
        chatTurnProc.command = [
            root.engineScript,
            "--stream-chat", msg,
            "--session-id", root.currentSessionId,
            "--provider", root.activeProvider,
            "--model", root.activeModel
        ];
        chatTurnProc.running = true;
    }

    Process {
        id: chatTurnProc

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (!line || line.trim().length === 0)
                    return;
                try {
                    var ev = JSON.parse(line.trim());
                    if (ev.event === "start") {
                        if (ev.session_id)
                            root.currentSessionId = ev.session_id;
                        var now = new Date();
                        var timeStr = Qt.formatTime(now, "HH:mm");
                        chatModel.append({
                            "sender": "assistant",
                            "text": "",
                            "time": timeStr,
                            "status": "streaming",
                            "toolName": "", "toolPath": "", "toolCommand": "", "toolContent": "", "toolExplanation": ""
                        });
                        root.typeStreamMsgIndex = chatModel.count - 1;
                        root.typeStreamTarget = "";
                        root.typeStreamActive = true;
                        root.pendingDoneEvent = null;
                        messageList.positionViewAtEnd();
                    } else if (ev.event === "chunk") {
                        root.typeStreamTarget += ev.text;
                        root.typeStreamActive = true;
                    } else if (ev.event === "done") {
                        root.isThinking = false;
                        root.pendingDoneEvent = ev;
                    }
                } catch (err) {}
            }
        }
    }

    // 4. Tool Execution on User Permission
    function allowToolAction(msgIndex, toolName, toolPath, toolCmd, toolContent) {
        var args = {};
        if (toolPath) args.path = toolPath;
        if (toolCmd) args.command = toolCmd;
        if (toolContent) args.content = toolContent;

        if (msgIndex >= 0 && msgIndex < chatModel.count) {
            chatModel.setProperty(msgIndex, "status", "executing_tool");
        }

        executeToolProc.targetIndex = msgIndex;
        executeToolProc.toolName = toolName;
        executeToolProc.command = [
            root.engineScript,
            "--execute-tool", toolName,
            "--tool-args", JSON.stringify(args)
        ];
        executeToolProc.running = true;
    }

    function denyToolAction(msgIndex) {
        if (msgIndex >= 0 && msgIndex < chatModel.count) {
            chatModel.setProperty(msgIndex, "status", "denied");
        }
        chatModel.append({
            "sender": "assistant",
            "text": "Action was cancelled by user.",
            "time": Qt.formatTime(new Date(), "HH:mm"),
            "status": "done",
            "toolName": "", "toolPath": "", "toolCommand": "", "toolContent": "", "toolExplanation": ""
        });
        messageList.positionViewAtEnd();
    }

    Process {
        id: executeToolProc
        property var targetIndex: -1
        property string toolName: ""
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    var resultStr = data.result || "Executed";
                    if (executeToolProc.targetIndex >= 0 && executeToolProc.targetIndex < chatModel.count) {
                        chatModel.setProperty(executeToolProc.targetIndex, "status", "executed");
                    }
                    chatModel.append({
                        "sender": "assistant",
                        "text": "**[System Tool Result - " + executeToolProc.toolName + "]**:\n```\n" + resultStr + "\n```",
                        "time": Qt.formatTime(new Date(), "HH:mm"),
                        "status": "done",
                        "toolName": "", "toolPath": "", "toolCommand": "", "toolContent": "", "toolExplanation": ""
                    });
                    messageList.positionViewAtEnd();
                } catch (e) {}
            }
        }
    }

    // 5. Sessions Management
    function openSessionsModal() {
        closeAllMenus();
        listSessionsProc.running = true;
        root.sessionsModalOpen = true;
    }

    Process {
        id: listSessionsProc
        command: [root.engineScript, "--list-sessions"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.sessionsList = JSON.parse(this.text) || [];
                } catch (e) {
                    root.sessionsList = [];
                }
            }
        }
    }

    function switchToSession(sid) {
        root.currentSessionId = sid;
        root.sessionsModalOpen = false;
        loadCurrentSessionProc.command = [root.engineScript, "--get-session", sid];
        loadCurrentSessionProc.running = true;
    }

    function triggerNewSession() {
        closeAllMenus();
        newSessionProc.running = true;
    }

    Process {
        id: newSessionProc
        command: [root.engineScript, "--new-session"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.currentSessionId = data.id;
                    loadCurrentSessionProc.running = true;
                } catch (e) {}
            }
        }
    }

    function triggerClearSession() {
        closeAllMenus();
        chatModel.clear();
        clearSessionProc.command = [root.engineScript, "--chat", "/clear", "--session-id", root.currentSessionId];
        clearSessionProc.running = true;
    }

    Process {
        id: clearSessionProc
        stdout: StdioCollector {
            onStreamFinished: {
                chatModel.append({
                    "sender": "assistant",
                    "text": "Chat cleared. What would you like to explore next?",
                    "time": Qt.formatTime(new Date(), "HH:mm"),
                    "status": "done",
                    "toolName": "", "toolPath": "", "toolCommand": "", "toolContent": "", "toolExplanation": ""
                });
            }
        }
    }

    function deleteSessionById(sid) {
        deleteSessionProc.command = [root.engineScript, "--delete-session", sid];
        deleteSessionProc.running = true;
    }

    Process {
        id: deleteSessionProc
        stdout: StdioCollector {
            onStreamFinished: {
                listSessionsProc.running = true;
            }
        }
    }

    // 6. Connect / API Key Modal
    function openConnectModal() {
        closeAllMenus();
        root.connectSelectedProvider = root.activeProvider;
        var keys = root.configData.keys || {};
        root.connectKeyInput = keys[root.connectSelectedProvider] || "";
        root.connectUrlInput = (root.connectSelectedProvider === "Ollama" ? root.configData.ollama_base_url : root.configData.custom_base_url) || "";
        root.connectModalOpen = true;
    }

    function saveConnectModal() {
        var keysObj = root.configData.keys || {};
        keysObj[root.connectSelectedProvider] = root.connectKeyInput.trim();
        var updatePayload = { "keys": keysObj };
        if (root.connectSelectedProvider === "Ollama") {
            updatePayload.ollama_base_url = root.connectUrlInput.trim();
        } else if (root.connectSelectedProvider === "Custom") {
            updatePayload.custom_base_url = root.connectUrlInput.trim();
        }
        saveConfigProc.command = [root.engineScript, "--set-config", JSON.stringify(updatePayload)];
        saveConfigProc.running = true;
        root.connectModalOpen = false;
        root.fetchModelsForProvider(root.activeProvider);
    }

    function pasteClipboard() {
        clipProc.running = true;
    }

    Process {
        id: clipProc
        command: ["wl-paste", "--no-newline"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.length > 0) {
                    inputField.insert(inputField.cursorPosition, this.text);
                    root.focusInput();
                }
            }
        }
    }

    function copyToClipboard(content) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "_", content]);
    }

    onActiveChanged: {
        if (active) {
            initProc.running = true;
            Qt.callLater(root.focusInput);
        }
    }

    ListModel {
        id: chatModel
    }

    // ========================================================================
    // MAIN UI LAYOUT
    // ========================================================================
    Column {
        anchors.fill: parent
        spacing: 10 * root.s

        // ====================================================================
        // HEADER BAR (With Provider & Model Dropdowns in marked area)
        // ====================================================================
        Item {
            id: header
            width: parent.width
            height: 32 * root.s

            // Left Section: Title & Status
            Row {
                id: leftHead
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Flags.showGlyphs
                    text: "対"
                    color: Theme.vermLit
                    font.family: Theme.fontJp
                    font.weight: Font.Medium
                    font.pixelSize: 17 * root.s
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AI"
                    color: Theme.cream
                    font.family: Theme.font
                    font.weight: Font.DemiBold
                    font.pixelSize: 13 * root.s
                    font.letterSpacing: 0.8
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 48 * root.s
                    height: 18 * root.s
                    radius: 9 * root.s
                    color: Qt.alpha(Theme.vermLit, 0.14)
                    border.width: 1
                    border.color: Qt.alpha(Theme.vermLit, 0.35)

                    Row {
                        anchors.centerIn: parent
                        spacing: 3 * root.s

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 5 * root.s
                            height: 5 * root.s
                            radius: 2.5 * root.s
                            color: root.isThinking ? Theme.onGlow : "#48c774"

                            SequentialAnimation on opacity {
                                running: root.isThinking
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 400 }
                                NumberAnimation { to: 1.0; duration: 400 }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isThinking ? "THINK" : "READY"
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 8 * root.s
                            font.weight: Font.Bold
                        }
                    }
                }
            }

            // Center Section: 2 Dropdown Pickers (Provider & Model)
            Row {
                id: centerDropdowns
                anchors.left: leftHead.right
                anchors.leftMargin: 12 * root.s
                anchors.right: rightControls.left
                anchors.rightMargin: 12 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                // 1st Dropdown: Provider Selector
                Rectangle {
                    id: providerBtn
                    height: 24 * root.s
                    width: Math.min(130 * root.s, (centerDropdowns.width - 8 * root.s) * 0.40)
                    radius: 7 * root.s
                    color: root.providerMenuOpen ? Qt.alpha(Theme.vermLit, 0.25) : (provArea.containsMouse ? Theme.frameBg : Qt.alpha(Theme.cream, 0.05))
                    border.width: 1
                    border.color: root.providerMenuOpen ? Theme.vermLit : Qt.alpha(Theme.cream, 0.14)

                    Row {
                        anchors.centerIn: parent
                        spacing: 5 * root.s

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 11 * root.s
                            height: 11 * root.s
                            name: "cpu"
                            color: Theme.vermLit
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.activeProvider
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 10.5 * root.s
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            width: Math.max(20, providerBtn.width - 34 * root.s)
                        }

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 9 * root.s
                            height: 9 * root.s
                            name: root.providerMenuOpen ? "chevron-up" : "chevron-down"
                            color: Theme.dim
                            stroke: 2
                        }
                    }

                    MouseArea {
                        id: provArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var willOpen = !root.providerMenuOpen;
                            root.closeAllMenus();
                            root.providerMenuOpen = willOpen;
                        }
                    }
                }

                // 2nd Dropdown: Model Selector
                Rectangle {
                    id: modelBtn
                    height: 24 * root.s
                    width: centerDropdowns.width - providerBtn.width - 8 * root.s
                    radius: 7 * root.s
                    color: root.modelMenuOpen ? Qt.alpha(Theme.vermLit, 0.25) : (modelArea.containsMouse ? Theme.frameBg : Qt.alpha(Theme.cream, 0.05))
                    border.width: 1
                    border.color: root.modelMenuOpen ? Theme.vermLit : Qt.alpha(Theme.cream, 0.14)

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8 * root.s
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5 * root.s

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 11 * root.s
                            height: 11 * root.s
                            name: "sparkles"
                            color: Theme.onGlow
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isFetchingModels ? "Fetching models..." : (root.activeModel || "Select Model")
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 10.5 * root.s
                            font.weight: Font.Medium
                            elide: Text.ElideMiddle
                            width: parent.width - 36 * root.s
                        }

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 9 * root.s
                            height: 9 * root.s
                            name: root.modelMenuOpen ? "chevron-up" : "chevron-down"
                            color: Theme.dim
                            stroke: 2
                        }
                    }

                    MouseArea {
                        id: modelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var willOpen = !root.modelMenuOpen;
                            root.closeAllMenus();
                            root.modelMenuOpen = willOpen;
                            if (willOpen) {
                                root.modelSearchQuery = "";
                                modelSearchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Right Section: Sessions, Connect, New, Clear, Dimensions, Close
            Row {
                id: rightControls
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5 * root.s

                // Sessions List Button (/sessions)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: root.sessionsModalOpen ? Qt.alpha(Theme.vermLit, 0.25) : (sessArea.containsMouse ? Theme.frameBg : "transparent")

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 12 * root.s
                        height: 12 * root.s
                        name: "history"
                        color: root.sessionsModalOpen ? Theme.vermLit : Theme.dim
                    }

                    MouseArea {
                        id: sessArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.sessionsModalOpen) root.closeAllMenus();
                            else root.openSessionsModal();
                        }
                    }
                }

                // Connect / API Keys Button (/connect)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: root.connectModalOpen ? Qt.alpha(Theme.vermLit, 0.25) : (connArea.containsMouse ? Theme.frameBg : "transparent")

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 12 * root.s
                        height: 12 * root.s
                        name: "key"
                        color: root.connectModalOpen ? Theme.vermLit : Theme.dim
                    }

                    MouseArea {
                        id: connArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.connectModalOpen) root.closeAllMenus();
                            else root.openConnectModal();
                        }
                    }
                }

                // New Chat Button (/new)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: newArea.containsMouse ? Theme.frameBg : "transparent"

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 12 * root.s
                        height: 12 * root.s
                        name: "plus"
                        color: newArea.containsMouse ? Theme.cream : Theme.dim
                    }

                    MouseArea {
                        id: newArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.triggerNewSession()
                    }
                }

                // Clear Chat Button (/clear)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: clearArea.containsMouse ? Theme.frameBg : "transparent"

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 12 * root.s
                        height: 12 * root.s
                        name: "trash"
                        color: clearArea.containsMouse ? Theme.vermLit : Theme.dim
                    }

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.triggerClearSession()
                    }
                }

                // Dimension Pill with quick resize buttons
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 22 * root.s
                    width: resRow.width + 10 * root.s
                    radius: 11 * root.s
                    color: Qt.alpha(Theme.cream, 0.05)
                    border.width: 1
                    border.color: Qt.alpha(Theme.cream, 0.12)

                    Row {
                        id: resRow
                        anchors.centerIn: parent
                        spacing: 4 * root.s

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Flags.chatbotWidth) + "×" + Math.round(Flags.chatbotHeight)
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 9.5 * root.s
                            font.features: { "tnum": 1 }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * root.s

                            Rectangle {
                                width: 13 * root.s
                                height: 13 * root.s
                                radius: 3 * root.s
                                color: wMinusArea.containsMouse ? Qt.alpha(Theme.cream, 0.15) : "transparent"
                                GlyphIcon {
                                    anchors.centerIn: parent
                                    width: 7 * root.s
                                    height: 7 * root.s
                                    name: "minus"
                                    color: Theme.dim
                                }
                                MouseArea {
                                    id: wMinusArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.adjustWidth(-40)
                                }
                            }

                            Rectangle {
                                width: 13 * root.s
                                height: 13 * root.s
                                radius: 3 * root.s
                                color: wPlusArea.containsMouse ? Qt.alpha(Theme.cream, 0.15) : "transparent"
                                GlyphIcon {
                                    anchors.centerIn: parent
                                    width: 7 * root.s
                                    height: 7 * root.s
                                    name: "plus"
                                    color: Theme.dim
                                }
                                MouseArea {
                                    id: wPlusArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.adjustWidth(40)
                                }
                            }
                        }
                    }
                }

                // Close button
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: closeArea.containsMouse ? Theme.frameBg : "transparent"

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 11 * root.s
                        height: 11 * root.s
                        name: "close"
                        color: closeArea.containsMouse ? Theme.cream : Theme.dim
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.requestClose()
                    }
                }
            }
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.hair
        }

        // ====================================================================
        // MESSAGE HISTORY & CONTENT AREA
        // ====================================================================
        Item {
            id: contentBody
            width: parent.width
            height: parent.height - header.height - inputContainer.height - 30 * root.s
            clip: true

            ListView {
                id: messageList
                anchors.fill: parent
                spacing: 12 * root.s
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: chatModel

                delegate: Item {
                    id: msgDelegate
                    required property int index
                    required property string sender
                    required property string text
                    required property string time
                    required property string status
                    required property string toolName
                    required property string toolPath
                    required property string toolCommand
                    required property string toolContent
                    required property string toolExplanation

                    readonly property bool isUser: sender === "user"
                    readonly property bool isStreaming: status === "streaming"
                    readonly property bool hasPermissionRequest: status === "pending_permission" && toolName.length > 0
                    width: messageList.width
                    height: bubbleRow.implicitHeight + 6 * root.s

                    TextMetrics {
                        id: textMeasure
                        font.family: Theme.font
                        font.pixelSize: 12.5 * root.s
                        text: msgDelegate.text
                    }

                    TextMetrics {
                        id: senderMeasure
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        font.weight: Font.Medium
                        text: msgDelegate.isUser ? "You" : "Assistant"
                    }

                    TextMetrics {
                        id: timeMeasure
                        font.family: Theme.font
                        font.pixelSize: 9 * root.s
                        text: msgDelegate.time
                    }

                    Row {
                        id: bubbleRow
                        anchors.right: msgDelegate.isUser ? parent.right : undefined
                        anchors.left: msgDelegate.isUser ? undefined : parent.left
                        spacing: 8 * root.s

                        // Assistant Avatar
                        Rectangle {
                            visible: !msgDelegate.isUser
                            anchors.top: parent.top
                            width: 26 * root.s
                            height: 26 * root.s
                            radius: 13 * root.s
                            color: Qt.alpha(Theme.vermLit, 0.18)
                            border.width: 1
                            border.color: Qt.alpha(Theme.vermLit, 0.35)

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 14 * root.s
                                height: 14 * root.s
                                name: "sparkles"
                                color: Theme.vermLit
                                stroke: 1.8
                            }
                        }

                        // Message Bubble Content
                        Rectangle {
                            id: bubbleRect
                            readonly property real headerRequiredW: senderMeasure.width + timeMeasure.width + 12 * root.s + (msgDelegate.isUser ? 0 : 28 * root.s)
                            readonly property real textRequiredW: textMeasure.width
                            readonly property real maxBubbleW: messageList.width * (msgDelegate.hasPermissionRequest ? 0.94 : 0.78)
                            readonly property real naturalW: msgDelegate.hasPermissionRequest ? maxBubbleW : (Math.max(headerRequiredW, textRequiredW) + 20 * root.s)
                            width: Math.min(maxBubbleW, naturalW)
                            implicitHeight: bubbleInner.implicitHeight + 16 * root.s
                            radius: 12 * root.s
                            color: msgDelegate.isUser
                                ? Qt.alpha(Theme.vermLit, 0.18)
                                : Qt.alpha(Theme.cream, 0.05)
                            border.width: 1
                            border.color: msgDelegate.isUser
                                ? Qt.alpha(Theme.vermLit, 0.40)
                                : Qt.alpha(Theme.cream, 0.10)

                            Column {
                                id: bubbleInner
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8 * root.s
                                spacing: 6 * root.s

                                // Header inside bubble
                                Item {
                                    id: headerItem
                                    width: parent.width
                                    height: 16 * root.s

                                    Row {
                                        id: senderRow
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6 * root.s

                                        Text {
                                            text: msgDelegate.isUser ? "You" : "Assistant"
                                            color: msgDelegate.isUser ? Theme.vermLit : Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: 10 * root.s
                                            font.weight: Font.Medium
                                        }

                                        Text {
                                            text: msgDelegate.time
                                            color: Theme.faint
                                            font.family: Theme.font
                                            font.pixelSize: 9 * root.s
                                            font.features: { "tnum": 1 }
                                        }
                                    }

                                    // Copy response button (for assistant)
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !msgDelegate.isUser && !msgDelegate.isStreaming
                                        width: 16 * root.s
                                        height: 16 * root.s
                                        radius: 3 * root.s
                                        color: copyArea.containsMouse ? Qt.alpha(Theme.cream, 0.15) : "transparent"

                                        GlyphIcon {
                                            anchors.centerIn: parent
                                            width: 10 * root.s
                                            height: 10 * root.s
                                            name: "copy"
                                            color: Theme.dim
                                        }

                                        MouseArea {
                                            id: copyArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.copyToClipboard(msgDelegate.text)
                                        }
                                    }
                                }

                                // Message text with blinking stream indicator
                                TextEdit {
                                    id: msgText
                                    width: parent.width
                                    text: msgDelegate.text + (msgDelegate.isStreaming ? " ▊" : "")
                                    color: msgDelegate.isUser ? Theme.bright : Theme.cream
                                    font.family: Theme.font
                                    font.pixelSize: 12.5 * root.s
                                    wrapMode: TextEdit.Wrap
                                    readOnly: true
                                    selectByMouse: true
                                    selectionColor: Theme.verm
                                    selectedTextColor: Theme.bright
                                }

                                // ====================================================
                                // SYSTEM PERMISSION CARD (For write_file, delete, cmd)
                                // ====================================================
                                Rectangle {
                                    id: permCard
                                    visible: msgDelegate.hasPermissionRequest
                                    width: parent.width
                                    implicitHeight: permCol.implicitHeight + 16 * root.s
                                    radius: 8 * root.s
                                    color: Qt.alpha(Theme.cardBot, 0.95)
                                    border.width: 1
                                    border.color: Theme.onGlow

                                    Column {
                                        id: permCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 8 * root.s
                                        spacing: 6 * root.s

                                        Row {
                                            spacing: 6 * root.s
                                            GlyphIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 14 * root.s
                                                height: 14 * root.s
                                                name: "cog"
                                                color: Theme.onGlow
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "SYSTEM PERMISSION REQUEST"
                                                color: Theme.onGlow
                                                font.family: Theme.font
                                                font.pixelSize: 10.5 * root.s
                                                font.weight: Font.Bold
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            text: "Action: " + msgDelegate.toolName + (msgDelegate.toolPath ? ("  ➔  " + msgDelegate.toolPath) : "") + (msgDelegate.toolCommand ? ("  ➔  `" + msgDelegate.toolCommand + "`") : "")
                                            color: Theme.cream
                                            font.family: Theme.font
                                            font.pixelSize: 11 * root.s
                                            font.weight: Font.Medium
                                            wrapMode: Text.Wrap
                                        }

                                        // Content Preview Box (if writing file or running command)
                                        Rectangle {
                                            visible: (msgDelegate.toolContent.length > 0 || msgDelegate.toolCommand.length > 0)
                                            width: parent.width
                                            height: Math.min(120 * root.s, Math.max(34 * root.s, previewText.contentHeight + 12 * root.s))
                                            radius: 6 * root.s
                                            color: Qt.rgba(0, 0, 0, 0.4)
                                            border.width: 1
                                            border.color: Theme.border
                                            clip: true

                                            Flickable {
                                                anchors.fill: parent
                                                anchors.margins: 6 * root.s
                                                contentWidth: width
                                                contentHeight: previewText.contentHeight
                                                clip: true

                                                TextEdit {
                                                    id: previewText
                                                    width: parent.width
                                                    text: msgDelegate.toolContent || msgDelegate.toolCommand
                                                    color: Theme.subtle
                                                    font.family: "Monospace"
                                                    font.pixelSize: 10 * root.s
                                                    wrapMode: TextEdit.Wrap
                                                    readOnly: true
                                                }
                                            }
                                        }

                                        // Action buttons ([Allow & Execute] and [Deny])
                                        Row {
                                            anchors.right: parent.right
                                            spacing: 8 * root.s

                                            // Deny Button
                                            Rectangle {
                                                height: 24 * root.s
                                                width: denyText.implicitWidth + 16 * root.s
                                                radius: 6 * root.s
                                                color: denyArea.containsMouse ? Qt.alpha(Theme.cream, 0.15) : Qt.alpha(Theme.cream, 0.06)
                                                border.width: 1
                                                border.color: Theme.border

                                                Text {
                                                    id: denyText
                                                    anchors.centerIn: parent
                                                    text: "✖ Deny"
                                                    color: Theme.dim
                                                    font.family: Theme.font
                                                    font.pixelSize: 10 * root.s
                                                    font.weight: Font.Medium
                                                }

                                                MouseArea {
                                                    id: denyArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.denyToolAction(msgDelegate.index)
                                                }
                                            }

                                            // Allow Button
                                            Rectangle {
                                                height: 24 * root.s
                                                width: allowText.implicitWidth + 18 * root.s
                                                radius: 6 * root.s
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: Theme.flameInk }
                                                    GradientStop { position: 1.0; color: Theme.verm }
                                                }

                                                Text {
                                                    id: allowText
                                                    anchors.centerIn: parent
                                                    text: "✔ Allow & Execute"
                                                    color: Theme.bright
                                                    font.family: Theme.font
                                                    font.pixelSize: 10 * root.s
                                                    font.weight: Font.DemiBold
                                                }

                                                MouseArea {
                                                    id: allowArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.allowToolAction(
                                                        msgDelegate.index,
                                                        msgDelegate.toolName,
                                                        msgDelegate.toolPath,
                                                        msgDelegate.toolCommand,
                                                        msgDelegate.toolContent
                                                    )
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

            // Quick Starter Chips (when empty)
            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 4 * root.s
                visible: chatModel.count <= 1
                spacing: 6 * root.s

                Repeater {
                    model: [
                        { label: "Hyprland Keybinds", query: "Explain my active Hyprland keybinds" },
                        { label: "Check System Performance", query: "Check current system performance" },
                        { label: "Paste Clipboard", query: "clip" }
                    ]

                    Rectangle {
                        required property var modelData
                        height: 24 * root.s
                        width: chipText.implicitWidth + 16 * root.s
                        radius: 12 * root.s
                        color: chipArea.containsMouse ? Qt.alpha(Theme.vermLit, 0.2) : Qt.alpha(Theme.cream, 0.06)
                        border.width: 1
                        border.color: chipArea.containsMouse ? Theme.vermLit : Qt.alpha(Theme.cream, 0.12)

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: chipArea.containsMouse ? Theme.bright : Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 10.5 * root.s
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.query === "clip")
                                    root.pasteClipboard();
                                else
                                    root.sendMessage(modelData.query);
                            }
                        }
                    }
                }
            }
        }

        // ====================================================================
        // INPUT AREA
        // ====================================================================
        Rectangle {
            id: inputContainer
            width: parent.width
            height: Math.min(120 * root.s, Math.max(68 * root.s, inputField.contentHeight + 42 * root.s))
            radius: 14 * root.s
            color: Theme.tileBg
            border.width: 1
            border.color: inputField.activeFocus ? Theme.vermLit : Theme.border

            Behavior on border.color { ColorAnimation { duration: Motion.fast } }

            Column {
                anchors.fill: parent
                anchors.margins: 8 * root.s
                spacing: 4 * root.s

                Flickable {
                    width: parent.width
                    height: parent.height - bottomControls.height - 4 * root.s
                    contentWidth: width
                    contentHeight: inputField.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextArea {
                        id: inputField
                        width: parent.width
                        padding: 0
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 13 * root.s
                        placeholderText: "Ask anything, run /connect, /sessions, /new, /clear..."
                        placeholderTextColor: Theme.faint
                        wrapMode: Text.Wrap
                        selectByMouse: true
                        selectionColor: Theme.verm
                        selectedTextColor: Theme.bright
                        background: null

                        Keys.onPressed: (e) => {
                            if (root.handleResizeKey(e))
                                return;

                            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                if (e.modifiers & Qt.ShiftModifier) {
                                    return;
                                }
                                root.sendMessage();
                                e.accepted = true;
                            } else if (e.key === Qt.Key_Escape) {
                                if (root.providerMenuOpen || root.modelMenuOpen || root.sessionsModalOpen || root.connectModalOpen) {
                                    root.closeAllMenus();
                                    e.accepted = true;
                                } else {
                                    root.requestClose();
                                    e.accepted = true;
                                }
                            }
                        }
                    }
                }

                // Input bottom row actions (Paste, Resize hints, Send button)
                Item {
                    id: bottomControls
                    width: parent.width
                    height: 24 * root.s

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * root.s

                        Rectangle {
                            height: 20 * root.s
                            width: pasteRow.width + 10 * root.s
                            radius: 10 * root.s
                            color: pasteArea.containsMouse ? Qt.alpha(Theme.cream, 0.15) : Qt.alpha(Theme.cream, 0.06)

                            Row {
                                id: pasteRow
                                anchors.centerIn: parent
                                spacing: 4 * root.s

                                GlyphIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10 * root.s
                                    height: 10 * root.s
                                    name: "file-text"
                                    color: Theme.dim
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Paste"
                                    color: Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: 9.5 * root.s
                                }
                            }

                            MouseArea {
                                id: pasteArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pasteClipboard()
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Ctrl++ / Ctrl+Shift++ to resize"
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 9 * root.s
                        }
                    }

                    // Send Button
                    Rectangle {
                        id: sendBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26 * root.s
                        height: 26 * root.s
                        radius: 13 * root.s
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.flameInk }
                            GradientStop { position: 1.0; color: Theme.verm }
                        }
                        opacity: inputField.text.trim().length > 0 ? 1.0 : 0.45

                        GlyphIcon {
                            anchors.centerIn: parent
                            width: 12 * root.s
                            height: 12 * root.s
                            name: "send"
                            color: Theme.bright
                            stroke: 2.0
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sendMessage()
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // POPUPS & MODALS (Z-INDEX 20)
    // ========================================================================

    // 1. PROVIDER DROPDOWN MENU
    Item {
        id: providerDropdown
        z: 20
        visible: root.providerMenuOpen
        anchors.top: parent.top
        anchors.topMargin: 46 * root.s
        anchors.left: parent.left
        anchors.leftMargin: 80 * root.s
        width: 160 * root.s
        height: Math.min(260 * root.s, root.availableProviders.length * 28 * root.s + 12 * root.s)

        Rectangle {
            anchors.fill: parent
            radius: 10 * root.s
            color: Theme.cardBot
            border.width: 1
            border.color: Theme.border

            ListView {
                anchors.fill: parent
                anchors.margins: 6 * root.s
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.availableProviders

                delegate: Rectangle {
                    id: provItem
                    required property var modelData
                    width: parent.width
                    height: 26 * root.s
                    radius: 6 * root.s
                    color: modelData === root.activeProvider ? Qt.alpha(Theme.vermLit, 0.20) : (pItemArea.containsMouse ? Theme.frameBg : "transparent")

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * root.s

                        Text {
                            text: provItem.modelData
                            color: provItem.modelData === root.activeProvider ? Theme.vermLit : Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            font.weight: provItem.modelData === root.activeProvider ? Font.Bold : Font.Normal
                        }
                    }

                    MouseArea {
                        id: pItemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.saveActiveProvider(provItem.modelData);
                            root.providerMenuOpen = false;
                        }
                    }
                }
            }
        }
    }

    // 2. MODEL DROPDOWN MENU (Searchable)
    Item {
        id: modelDropdown
        z: 20
        visible: root.modelMenuOpen
        anchors.top: parent.top
        anchors.topMargin: 46 * root.s
        anchors.left: parent.left
        anchors.leftMargin: 180 * root.s
        anchors.right: parent.right
        anchors.rightMargin: 40 * root.s
        height: 280 * root.s

        Rectangle {
            anchors.fill: parent
            radius: 10 * root.s
            color: Theme.cardBot
            border.width: 1
            border.color: Theme.border

            Column {
                anchors.fill: parent
                anchors.margins: 8 * root.s
                spacing: 6 * root.s

                // Search Box
                Rectangle {
                    width: parent.width
                    height: 26 * root.s
                    radius: 6 * root.s
                    color: Theme.tileBg
                    border.width: 1
                    border.color: modelSearchInput.activeFocus ? Theme.vermLit : Theme.border

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 6 * root.s
                        anchors.rightMargin: 6 * root.s
                        spacing: 6 * root.s

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 11 * root.s
                            height: 11 * root.s
                            name: "search"
                            color: Theme.dim
                        }

                        TextField {
                            id: modelSearchInput
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24 * root.s
                            background: null
                            padding: 0
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            placeholderText: "Search models..."
                            placeholderTextColor: Theme.faint
                            text: root.modelSearchQuery
                            onTextChanged: root.modelSearchQuery = text
                        }
                    }
                }

                // Filtered Models List
                ListView {
                    id: modelList
                    width: parent.width
                    height: parent.height - 36 * root.s
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: {
                        var list = root.availableModels;
                        if (!root.modelSearchQuery) return list;
                        var q = root.modelSearchQuery.toLowerCase();
                        return list.filter(function(m) { return m.toLowerCase().indexOf(q) !== -1; });
                    }

                    delegate: Rectangle {
                        id: mItem
                        required property var modelData
                        width: modelList.width
                        height: 26 * root.s
                        radius: 6 * root.s
                        color: modelData === root.activeModel ? Qt.alpha(Theme.vermLit, 0.20) : (mItemArea.containsMouse ? Theme.frameBg : "transparent")

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8 * root.s
                            anchors.right: parent.right
                            anchors.rightMargin: 8 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: mItem.modelData
                            color: mItem.modelData === root.activeModel ? Theme.vermLit : Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            font.weight: mItem.modelData === root.activeModel ? Font.Bold : Font.Normal
                            elide: Text.ElideMiddle
                        }

                        MouseArea {
                            id: mItemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.saveActiveModel(mItem.modelData);
                                root.modelMenuOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // 3. SESSIONS MODAL OVERLAY
    Rectangle {
        id: sessionsModal
        z: 25
        visible: root.sessionsModalOpen
        anchors.fill: parent
        radius: 16 * root.s
        color: Qt.alpha(Theme.cardBot, 0.98)
        border.width: 1
        border.color: Theme.border

        Column {
            anchors.fill: parent
            anchors.margins: 14 * root.s
            spacing: 10 * root.s

            // Modal Header
            Item {
                width: parent.width
                height: 28 * root.s

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * root.s

                    GlyphIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14 * root.s
                        height: 14 * root.s
                        name: "history"
                        color: Theme.vermLit
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CONVERSATION SESSIONS"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 13 * root.s
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: closeSessArea.containsMouse ? Theme.frameBg : "transparent"

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 12 * root.s
                        height: 12 * root.s
                        name: "close"
                        color: Theme.dim
                    }

                    MouseArea {
                        id: closeSessArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sessionsModalOpen = false
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            // Sessions List
            ListView {
                id: sessList
                width: parent.width
                height: parent.height - 48 * root.s
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 6 * root.s
                model: root.sessionsList

                delegate: Rectangle {
                    id: sRow
                    required property var modelData
                    width: sessList.width
                    height: 52 * root.s
                    radius: 8 * root.s
                    color: modelData.id === root.currentSessionId ? Qt.alpha(Theme.vermLit, 0.16) : (sRowArea.containsMouse ? Theme.frameBg : Qt.alpha(Theme.cream, 0.04))
                    border.width: 1
                    border.color: modelData.id === root.currentSessionId ? Theme.vermLit : Theme.border

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 10 * root.s
                        anchors.right: sActions.left
                        anchors.rightMargin: 8 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3 * root.s

                        Row {
                            spacing: 8 * root.s
                            Text {
                                text: sRow.modelData.title || "Conversation"
                                color: sRow.modelData.id === root.currentSessionId ? Theme.vermLit : Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 12 * root.s
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                text: sRow.modelData.updatedAt || sRow.modelData.createdAt || ""
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 9.5 * root.s
                            }
                        }

                        Text {
                            width: parent.width
                            text: sRow.modelData.preview || "No preview"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 10.5 * root.s
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        id: sActions
                        anchors.right: parent.right
                        anchors.rightMargin: 10 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * root.s

                        Rectangle {
                            width: 24 * root.s
                            height: 24 * root.s
                            radius: 6 * root.s
                            color: delSessArea.containsMouse ? Qt.alpha(Theme.vermLit, 0.3) : "transparent"

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 11 * root.s
                                height: 11 * root.s
                                name: "trash"
                                color: Theme.dim
                            }

                            MouseArea {
                                id: delSessArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.deleteSessionById(sRow.modelData.id)
                            }
                        }
                    }

                    MouseArea {
                        id: sRowArea
                        anchors.fill: parent
                        anchors.rightMargin: 40 * root.s
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchToSession(sRow.modelData.id)
                    }
                }
            }
        }
    }

    // 4. CONNECT / API KEYS MODAL
    Rectangle {
        id: connectModal
        z: 25
        visible: root.connectModalOpen
        anchors.fill: parent
        radius: 16 * root.s
        color: Qt.alpha(Theme.cardBot, 0.98)
        border.width: 1
        border.color: Theme.border

        Column {
            anchors.fill: parent
            anchors.margins: 14 * root.s
            spacing: 10 * root.s

            // Modal Header
            Item {
                width: parent.width
                height: 28 * root.s

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * root.s

                    GlyphIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14 * root.s
                        height: 14 * root.s
                        name: "key"
                        color: Theme.vermLit
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "API KEYS & ENDPOINTS"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 13 * root.s
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: closeConnArea.containsMouse ? Theme.frameBg : "transparent"

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 12 * root.s
                        height: 12 * root.s
                        name: "close"
                        color: Theme.dim
                    }

                    MouseArea {
                        id: closeConnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.connectModalOpen = false
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            // Provider Tab selector
            Row {
                spacing: 6 * root.s
                Repeater {
                    model: ["OpenRouter", "Gemini", "Claude", "Groq", "DeepSeek", "Mistral", "Ollama"]
                    Rectangle {
                        required property var modelData
                        height: 24 * root.s
                        width: tabText.implicitWidth + 14 * root.s
                        radius: 6 * root.s
                        color: modelData === root.connectSelectedProvider ? Theme.vermLit : (tabArea.containsMouse ? Theme.frameBg : Qt.alpha(Theme.cream, 0.05))

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData
                            color: modelData === root.connectSelectedProvider ? Theme.bright : Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 10.5 * root.s
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.connectSelectedProvider = modelData;
                                var keys = root.configData.keys || {};
                                root.connectKeyInput = keys[modelData] || "";
                                root.connectUrlInput = (modelData === "Ollama" ? root.configData.ollama_base_url : root.configData.custom_base_url) || "";
                            }
                        }
                    }
                }
            }

            // Key Input Box
            Text {
                text: "API Key for " + root.connectSelectedProvider + ":"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * root.s
            }

            Rectangle {
                width: parent.width
                height: 32 * root.s
                radius: 8 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: keyField.activeFocus ? Theme.vermLit : Theme.border

                TextField {
                    id: keyField
                    anchors.fill: parent
                    anchors.margins: 6 * root.s
                    background: null
                    color: Theme.cream
                    font.family: "Monospace"
                    font.pixelSize: 11 * root.s
                    placeholderText: "Enter " + root.connectSelectedProvider + " API Key..."
                    placeholderTextColor: Theme.faint
                    text: root.connectKeyInput
                    onTextChanged: root.connectKeyInput = text
                    echoMode: TextInput.PasswordEchoOnEdit
                }
            }

            // Optional Base URL for Ollama / Custom
            Column {
                visible: root.connectSelectedProvider === "Ollama" || root.connectSelectedProvider === "Custom"
                width: parent.width
                spacing: 4 * root.s

                Text {
                    text: "Base URL (e.g. http://localhost:11434):"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                }

                Rectangle {
                    width: parent.width
                    height: 32 * root.s
                    radius: 8 * root.s
                    color: Theme.tileBg
                    border.width: 1
                    border.color: urlField.activeFocus ? Theme.vermLit : Theme.border

                    TextField {
                        id: urlField
                        anchors.fill: parent
                        anchors.margins: 6 * root.s
                        background: null
                        color: Theme.cream
                        font.family: "Monospace"
                        font.pixelSize: 11 * root.s
                        placeholderText: "http://localhost:11434"
                        placeholderTextColor: Theme.faint
                        text: root.connectUrlInput
                        onTextChanged: root.connectUrlInput = text
                    }
                }
            }

            Item { width: 1; height: 10 * root.s }

            // Save Key Button
            Rectangle {
                anchors.right: parent.right
                height: 28 * root.s
                width: saveKeyText.implicitWidth + 24 * root.s
                radius: 7 * root.s
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.flameInk }
                    GradientStop { position: 1.0; color: Theme.verm }
                }

                Text {
                    id: saveKeyText
                    anchors.centerIn: parent
                    text: "Save & Connect"
                    color: Theme.bright
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.saveConnectModal()
                }
            }
        }
    }
}
