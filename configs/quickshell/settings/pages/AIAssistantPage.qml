import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    property int providerIndex: 0

    readonly property var providerModel: [
        { label: "Google Gemini (Gemini 2.5 Pro / Flash)", value: "Gemini" },
        { label: "Anthropic Claude (Claude 3.5 Sonnet)", value: "Claude" },
        { label: "OpenRouter (Unified Multi-Model Gateway)", value: "OpenRouter" },
        { label: "Groq (Ultra-Fast Llama 3.3 70B)", value: "Groq" },
        { label: "DeepSeek (DeepSeek-V3 / R1 Reasoner)", value: "DeepSeek" },
        { label: "OpenAI (GPT-4o / o1 / o3-mini)", value: "OpenAI" },
        { label: "Mistral AI (Mistral Large / Codestral)", value: "Mistral" },
        { label: "Local Ollama (Llama 3.2 / Qwen 2.5 Coder)", value: "Ollama" }
    ]

    Process {
        id: cmdProc
        command: ["true"]
    }

    Process {
        id: getConfigProc
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/chatbot-engine.py", "--get-config"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    if (data.provider) {
                        for (var i = 0; i < root.providerModel.length; i++) {
                            if (root.providerModel[i].value.toLowerCase() === data.provider.toLowerCase()) {
                                root.providerIndex = i;
                                break;
                            }
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "知"
            title: "Universal AI Desktop Assistant"
            subtitle: "Multi-provider LLMs, API keys, streaming SSE tokens, and autonomous tool calling safety."
        }

        // Provider Selector
        Card {
            title: "Active AI Engine / Provider"
            subtitle: "Select which LLM backend powers the desktop assistant overlay"
            icon: "bot"

            Dropdown {
                label: "AI Model Provider"
                description: "Supports cloud API keys and self-hosted local endpoints"
                model: root.providerModel
                currentIndex: root.providerIndex
                onSelected: (idx, val) => {
                    root.providerIndex = idx;
                    cmdProc.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/chatbot-engine.py", "--set-config", JSON.stringify({ "provider": val })];
                    cmdProc.running = true;
                }
            }
        }

        // Autonomous Safety Permissions
        Card {
            title: "Autonomous Tool Execution Permissions"
            subtitle: "Security gates before AI runs commands or modifies your files"
            icon: "lock"

            Switch {
                label: "Confirm Before Command Execution"
                description: "Display an interactive confirmation prompt before running shell commands"
                checked: Flags.aiConfirmCommand !== false
                icon: "terminal"
                onToggled: (st) => Flags.aiConfirmCommand = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Confirm Before File Modifications"
                description: "Require confirmation before writing, editing, or deleting local files"
                checked: Flags.aiConfirmFile !== false
                icon: "file-text"
                onToggled: (st) => Flags.aiConfirmFile = st
            }
        }

        // Assistant Window Geometry
        Card {
            title: "Overlay Window Dimensions"
            subtitle: "Default size of the AI desktop assistant panel in the Pill"
            icon: "scaling"

            Slider {
                label: "Panel Width"
                description: "Width in pixels (Default: 500px)"
                from: 400
                to: 800
                value: Flags.chatbotWidth || 500
                stepSize: 20
                unit: "px"
                onMoved: (v) => Flags.chatbotWidth = Math.round(v)
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Panel Height"
                description: "Height in pixels (Default: 540px)"
                from: 400
                to: 900
                value: Flags.chatbotHeight || 540
                stepSize: 20
                unit: "px"
                onMoved: (v) => Flags.chatbotHeight = Math.round(v)
            }
        }

        // API Key Storage Location
        Card {
            title: "API Credentials File"
            subtitle: "MasterR automatically loads keys from ~/API-KEYs.md and environment variables"
            icon: "key"

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "Open ~/API-KEYs.md in Editor"
                    icon: "file-text"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = ["xdg-open", Quickshell.env("HOME") + "/API-KEYs.md"];
                        cmdProc.running = true;
                    }
                }
            }
        }
    }
}
