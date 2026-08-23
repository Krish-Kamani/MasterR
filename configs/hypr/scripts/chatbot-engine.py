#!/usr/bin/env python3
"""
MasterR Chatbot Engine
High-Performance Universal backend for Quickshell AI Pill Panel.
Features Real-time SSE token streaming (<1s TTFT), multi-provider APIs (Gemini, OpenRouter, Claude, Groq, DeepSeek, Mistral, OpenAI, Ollama),
dynamic model fetching, persistent session management across reboots, and safe system tool execution with permission staging.
"""

import sys
import os
import json
import time
import urllib.request
import urllib.error
import urllib.parse
import argparse
import subprocess
import pathlib
import shutil

STATE_DIR = pathlib.Path(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))) / "masterr" / "chatbot"
SESSIONS_DIR = STATE_DIR / "sessions"
CONFIG_FILE = STATE_DIR / "config.json"
BOOT_TRACK_FILE = STATE_DIR / "last_boot.txt"
API_KEYS_MD = pathlib.Path(os.path.expanduser("~/API-KEYs.md"))

DEFAULT_CONFIG = {
    "provider": "OpenRouter",
    "model": "deepseek/deepseek-chat",
    "keys": {
        "OpenRouter": "",
        "Gemini": "",
        "Claude": "",
        "Groq": "",
        "DeepSeek": "",
        "Mistral": "",
        "OpenAI": "",
        "NVIDIA": "",
        "Sarvam": "",
        "Custom": ""
    },
    "custom_base_url": "",
    "ollama_base_url": "http://localhost:11434"
}

FALLBACK_MODELS = {
    "OpenRouter": [
        "google/gemini-2.0-flash-exp:free",
        "meta-llama/llama-3.3-70b-instruct:free",
        "deepseek/deepseek-r1:free",
        "qwen/qwen-2.5-coder-32b-instruct:free",
        "google/gemma-2-9b-it:free",
        "mistralai/mistral-7b-instruct:free",
        "nvidia/nemotron-3-super-120b-a12b:free",
        "nvidia/nemotron-3-nano-30b-a3b:free"
    ],
    "Gemini": [
        "gemini-2.0-pro-exp-02-05",
        "gemini-2.0-pro-exp",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite-preview-02-05",
        "gemini-2.0-flash-thinking-exp-01-21",
        "gemini-2.0-flash-thinking-exp",
        "gemini-2.0-flash-exp",
        "gemini-1.5-pro",
        "gemini-1.5-pro-latest",
        "gemini-1.5-pro-002",
        "gemini-1.5-pro-001",
        "gemini-1.5-flash",
        "gemini-1.5-flash-latest",
        "gemini-1.5-flash-002",
        "gemini-1.5-flash-001",
        "gemini-1.5-flash-8b",
        "gemini-1.5-flash-8b-latest",
        "gemini-exp-1206",
        "gemini-exp-1121",
        "gemini-exp-1114",
        "gemini-1.0-pro",
        "gemma-2-27b-it",
        "gemma-2-9b-it",
        "gemma-2-2b-it",
        "codegemma-7b-it"
    ],
    "Groq": [
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant",
        "deepseek-r1-distill-llama-70b",
        "gemma2-9b-it",
        "mixtral-8x7b-32768"
    ],
    "Mistral": [
        "mistral-small-latest",
        "open-mistral-7b",
        "open-mixtral-8x7b",
        "open-mixtral-8x22b",
        "codestral-latest"
    ],
    "DeepSeek": [
        "deepseek-chat",
        "deepseek-reasoner"
    ],
    "NVIDIA": [
        "meta/llama-3.3-70b-instruct",
        "nvidia/llama-3.1-nemotron-70b-instruct",
        "deepseek-ai/deepseek-r1"
    ],
    "OpenAI": [
        "gpt-4o-mini",
        "gpt-3.5-turbo"
    ],
    "Claude": [
        "claude-3-5-haiku-20241022"
    ],
    "Ollama": [
        "llama3.2:latest",
        "deepseek-r1:8b",
        "qwen2.5-coder:latest"
    ],
    "Custom": [
        "default-model"
    ]
}

SYSTEM_INSTRUCTION = """You are the MasterR AI Desktop Assistant running on Arch Linux with Hyprland and Quickshell.
You are helpful, concise, technical, and accurate. Format responses in clean Markdown.

You have access to filesystem and system capabilities via tool calls.
When the user asks to inspect, read, write, create, delete files or execute system commands, use the following strict JSON block format:

```json_action
{
  "tool": "<read_file|list_directory|write_file|delete_file|execute_command>",
  "path": "<file_path if applicable>",
  "content": "<file content if writing>",
  "command": "<command string if executing>",
  "explanation": "<brief explanation of what will be done>"
}
```

Rules:
1. For read-only inspection (read_file, list_directory), propose them directly.
2. For state-modifying actions (write_file, delete_file, execute_command), provide a clear explanation. The user UI will prompt for confirmation with a preview before executing.
3. You can include conversational text outside the ```json_action block.
"""

def ensure_dirs():
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)

def parse_api_keys_md():
    keys = {}
    
    # Check standard environment variables first
    env_map = {
        "OpenRouter": "OPENROUTER_API_KEY",
        "Claude": "ANTHROPIC_API_KEY",
        "Gemini": "GEMINI_API_KEY",
        "Mistral": "MISTRAL_API_KEY",
        "Groq": "GROQ_API_KEY",
        "DeepSeek": "DEEPSEEK_API_KEY",
        "Sarvam": "SARVAM_API_KEY",
        "OpenAI": "OPENAI_API_KEY",
        "NVIDIA": "NVIDIA_API_KEY",
    }
    for provider, env_var in env_map.items():
        val = os.environ.get(env_var)
        if val:
            keys[provider] = val.strip()

    if not API_KEYS_MD.exists():
        return keys
    try:
        content = API_KEYS_MD.read_text(encoding="utf-8")
        for line in content.splitlines():
            line = line.strip()
            if not line:
                continue
            if line.startswith("OPENROUTER:-"):
                keys["OpenRouter"] = line.split(":-", 1)[1].strip()
            elif line.startswith("CLAUDE:-"):
                keys["Claude"] = line.split(":-", 1)[1].strip()
            elif line.startswith("Gemini:-"):
                keys["Gemini"] = line.split(":-", 1)[1].strip()
            elif line.startswith("MISTRAL:-"):
                keys["Mistral"] = line.split(":-", 1)[1].strip()
            elif line.startswith("GROQ:-"):
                keys["Groq"] = line.split(":-", 1)[1].strip()
            elif line.startswith("DEEPSEEK:-"):
                keys["DeepSeek"] = line.split(":-", 1)[1].strip()
            elif line.startswith("Sarvam:-"):
                keys["Sarvam"] = line.split(":-", 1)[1].strip()
            elif 'api_key = "' in line and "NVIDIA" in content:
                val = line.split('api_key = "', 1)[1].split('"', 1)[0]
                keys["NVIDIA"] = val
    except Exception:
        pass
    return keys

def load_config():
    ensure_dirs()
    cfg = DEFAULT_CONFIG.copy()
    if CONFIG_FILE.exists():
        try:
            loaded = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
            cfg.update(loaded)
            if "keys" in loaded:
                cfg["keys"] = {**DEFAULT_CONFIG["keys"], **loaded["keys"]}
        except Exception:
            pass

    parsed_keys = parse_api_keys_md()
    updated = False
    for k, v in parsed_keys.items():
        if v and not cfg["keys"].get(k):
            cfg["keys"][k] = v
            updated = True
    if updated or not CONFIG_FILE.exists():
        save_config(cfg)
    return cfg

def save_config(cfg):
    ensure_dirs()
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2), encoding="utf-8")

def get_current_boot_id():
    boot_id_file = pathlib.Path("/proc/sys/kernel/random/boot_id")
    if boot_id_file.exists():
        return boot_id_file.read_text().strip()
    return str(int(time.time()))

def get_current_session_id():
    ensure_dirs()
    cur_file = STATE_DIR / "current_session.txt"
    boot_id = get_current_boot_id()

    last_boot = BOOT_TRACK_FILE.read_text().strip() if BOOT_TRACK_FILE.exists() else ""
    is_new_boot = (last_boot != boot_id)
    if is_new_boot:
        BOOT_TRACK_FILE.write_text(boot_id)

    if cur_file.exists() and not is_new_boot:
        sid = cur_file.read_text().strip()
        if (SESSIONS_DIR / f"{sid}.json").exists():
            return sid

    new_sid = f"session_{int(time.time())}"
    cur_file.write_text(new_sid)
    session_data = {
        "id": new_sid,
        "title": "New Conversation",
        "createdAt": time.strftime("%Y-%m-%d %H:%M"),
        "updatedAt": time.strftime("%Y-%m-%d %H:%M"),
        "bootId": boot_id,
        "messages": [
            {
                "sender": "assistant",
                "text": "Hello! I am your MasterR AI Assistant.\nSelect a provider & model above, or type `/help` for commands.",
                "time": time.strftime("%H:%M"),
                "status": "done"
            }
        ]
    }
    (SESSIONS_DIR / f"{new_sid}.json").write_text(json.dumps(session_data, indent=2), encoding="utf-8")
    return new_sid

def load_session(sid=None):
    if not sid:
        sid = get_current_session_id()
    sess_file = SESSIONS_DIR / f"{sid}.json"
    if sess_file.exists():
        try:
            return json.loads(sess_file.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {
        "id": sid,
        "title": "New Conversation",
        "createdAt": time.strftime("%Y-%m-%d %H:%M"),
        "updatedAt": time.strftime("%Y-%m-%d %H:%M"),
        "messages": []
    }

def save_session(session_data):
    ensure_dirs()
    sid = session_data.get("id") or f"session_{int(time.time())}"
    session_data["updatedAt"] = time.strftime("%Y-%m-%d %H:%M")
    (SESSIONS_DIR / f"{sid}.json").write_text(json.dumps(session_data, indent=2), encoding="utf-8")
    (STATE_DIR / "current_session.txt").write_text(sid)

def create_new_session():
    ensure_dirs()
    sid = f"session_{int(time.time())}"
    (STATE_DIR / "current_session.txt").write_text(sid)
    session_data = {
        "id": sid,
        "title": "New Conversation",
        "createdAt": time.strftime("%Y-%m-%d %H:%M"),
        "updatedAt": time.strftime("%Y-%m-%d %H:%M"),
        "bootId": get_current_boot_id(),
        "messages": [
            {
                "sender": "assistant",
                "text": "Started a new conversation. How can I help you?",
                "time": time.strftime("%H:%M"),
                "status": "done"
            }
        ]
    }
    (SESSIONS_DIR / f"{sid}.json").write_text(json.dumps(session_data, indent=2), encoding="utf-8")
    return session_data

def list_all_sessions():
    ensure_dirs()
    sessions = []
    current_sid = (STATE_DIR / "current_session.txt").read_text().strip() if (STATE_DIR / "current_session.txt").exists() else ""
    for f in sorted(SESSIONS_DIR.glob("session_*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
            preview = ""
            for m in data.get("messages", []):
                if m.get("sender") == "user":
                    preview = m.get("text", "")[:60]
                    break
            if not preview and data.get("messages"):
                preview = data["messages"][-1].get("text", "")[:60]
            sessions.append({
                "id": data.get("id", f.stem),
                "title": data.get("title", "Conversation"),
                "createdAt": data.get("createdAt", ""),
                "updatedAt": data.get("updatedAt", ""),
                "msgCount": len(data.get("messages", [])),
                "preview": preview or "Empty conversation",
                "isCurrent": (data.get("id") == current_sid)
            })
        except Exception:
            continue
    return sessions

def delete_session(sid):
    f = SESSIONS_DIR / f"{sid}.json"
    if f.exists():
        f.unlink()
    cur = (STATE_DIR / "current_session.txt")
    if cur.exists() and cur.read_text().strip() == sid:
        sessions = list_all_sessions()
        if sessions:
            cur.write_text(sessions[0]["id"])
        else:
            create_new_session()
    return True

# ============================================================================
# DYNAMIC MODEL FETCHING
# ============================================================================

def fetch_models(provider, api_key=None, custom_url=None):
    cfg = load_config()
    key = api_key or cfg["keys"].get(provider, "")
    models = []
    headers = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"}

    try:
        if provider == "OpenRouter":
            url = "https://openrouter.ai/api/v1/models"
            if key:
                headers["Authorization"] = f"Bearer {key}"
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=6) as resp:
                data = json.loads(resp.read().decode())
                if "data" in data:
                    for m in data["data"]:
                        mid = m.get("id", "")
                        pricing = m.get("pricing", {})
                        try:
                            p_prompt = float(pricing.get("prompt", 1))
                            p_comp = float(pricing.get("completion", 1))
                        except Exception:
                            p_prompt, p_comp = 1, 1
                        # Free-tier only
                        if ":free" in mid or (p_prompt == 0 and p_comp == 0):
                            models.append(mid)

        elif provider == "Gemini":
            # Show ALL Google Gemini & Gemma models
            fetched = []
            if key:
                url = f"https://generativelanguage.googleapis.com/v1beta/models?key={key}"
                req = urllib.request.Request(url, headers=headers)
                with urllib.request.urlopen(req, timeout=6) as resp:
                    data = json.loads(resp.read().decode())
                    if "models" in data:
                        fetched = [m["name"].replace("models/", "") for m in data["models"] if "generateContent" in m.get("supportedGenerationMethods", [])]
            # Union of known Google catalog and live fetched models
            combined = FALLBACK_MODELS["Gemini"] + [m for m in fetched if m not in FALLBACK_MODELS["Gemini"]]
            models = combined

        elif provider == "Groq":
            # Groq free tier models
            models = FALLBACK_MODELS["Groq"]

        elif provider == "Mistral":
            # Mistral free tier models
            models = FALLBACK_MODELS["Mistral"]

        elif provider == "DeepSeek":
            models = FALLBACK_MODELS["DeepSeek"]

        elif provider == "NVIDIA":
            models = FALLBACK_MODELS["NVIDIA"]

        elif provider == "Claude":
            models = FALLBACK_MODELS["Claude"]

        elif provider == "OpenAI":
            models = FALLBACK_MODELS["OpenAI"]

        elif provider == "Ollama":
            base = custom_url or cfg.get("ollama_base_url", "http://localhost:11434")
            url = f"{base.rstrip('/')}/api/tags"
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=4) as resp:
                data = json.loads(resp.read().decode())
                if "models" in data:
                    models = [m["name"] for m in data["models"] if "name" in m]
    except Exception as e:
        sys.stderr.write(f"Model fetch error for {provider}: {e}\n")

    if not models:
        models = FALLBACK_MODELS.get(provider, ["default-model"])
    return models

# ============================================================================
# REAL-TIME SSE STREAMING INFERENCE
# ============================================================================

def stream_openai_compatible(endpoint, key, model, messages, extra_headers=None):
    openai_msgs = [{"role": "system", "content": SYSTEM_INSTRUCTION}]
    # Keep last 12 messages for lean payload & fast latency
    recent = messages[-12:] if len(messages) > 12 else messages
    for m in recent:
        role = "user" if m.get("sender") == "user" else "assistant"
        openai_msgs.append({"role": role, "content": m.get("text", "")})

    body = {
        "model": model,
        "messages": openai_msgs,
        "stream": True,
        "temperature": 0.7
    }
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"
    }
    if key:
        headers["Authorization"] = f"Bearer {key}"
    if extra_headers:
        headers.update(extra_headers)

    req = urllib.request.Request(endpoint, data=json.dumps(body).encode("utf-8"), headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        for line in resp:
            line = line.decode("utf-8").strip()
            if line.startswith("data: ") and line != "data: [DONE]":
                try:
                    chunk = json.loads(line[6:])
                    delta = chunk["choices"][0]["delta"].get("content", "")
                    if delta:
                        yield delta
                except Exception:
                    pass

def stream_anthropic(key, model, messages):
    anthropic_msgs = []
    recent = messages[-12:] if len(messages) > 12 else messages
    for m in recent:
        role = "user" if m.get("sender") == "user" else "assistant"
        anthropic_msgs.append({"role": role, "content": m.get("text", "")})

    body = {
        "model": model or "claude-3-5-haiku-20241022",
        "max_tokens": 4096,
        "system": SYSTEM_INSTRUCTION,
        "messages": anthropic_msgs,
        "stream": True
    }
    headers = {
        "Content-Type": "application/json",
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"
    }
    req = urllib.request.Request("https://api.anthropic.com/v1/messages", data=json.dumps(body).encode("utf-8"), headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        for line in resp:
            line = line.decode("utf-8").strip()
            if line.startswith("data: "):
                try:
                    event_data = json.loads(line[6:])
                    if event_data.get("type") == "content_block_delta":
                        delta = event_data.get("delta", {}).get("text", "")
                        if delta:
                            yield delta
                except Exception:
                    pass

def stream_gemini(key, model, messages):
    m_name = model or "gemini-2.0-flash"
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{m_name}:streamGenerateContent?alt=sse&key={key}"
    contents = []
    recent = messages[-12:] if len(messages) > 12 else messages
    for m in recent:
        role = "user" if m.get("sender") == "user" else "model"
        contents.append({"role": role, "parts": [{"text": m.get("text", "")}]})

    body = {
        "contents": contents,
        "systemInstruction": {"parts": [{"text": SYSTEM_INSTRUCTION}]}
    }
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"
    }
    req = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"), headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        for line in resp:
            line = line.decode("utf-8").strip()
            if line.startswith("data: "):
                try:
                    chunk = json.loads(line[6:])
                    parts = chunk["candidates"][0]["content"]["parts"]
                    for p in parts:
                        if "text" in p:
                            yield p["text"]
                except Exception:
                    pass

def get_stream_generator(provider, model, messages, cfg):
    key = cfg["keys"].get(provider, "")
    if provider == "OpenRouter":
        if not key:
            yield "Please configure your OpenRouter API Key using `/connect OpenRouter <your-key>`."
            return
        yield from stream_openai_compatible(
            "https://openrouter.ai/api/v1/chat/completions",
            key,
            model or "deepseek/deepseek-chat",
            messages,
            {"HTTP-Referer": "https://masterr.hyprland", "X-Title": "MasterR Pill Assistant"}
        )
    elif provider == "Mistral":
        if not key:
            yield "Please configure your Mistral API Key using `/connect Mistral <your-key>`."
            return
        yield from stream_openai_compatible(
            "https://api.mistral.ai/v1/chat/completions",
            key,
            model or "mistral-small-latest",
            messages
        )
    elif provider == "Claude":
        if not key:
            yield "Please configure your Claude API Key using `/connect Claude <your-key>`."
            return
        yield from stream_anthropic(key, model or "claude-3-5-haiku-20241022", messages)
    elif provider == "Gemini":
        if not key:
            yield "Please configure your Gemini API Key using `/connect Gemini <your-key>`."
            return
        yield from stream_gemini(key, model or "gemini-2.0-flash", messages)
    elif provider == "Groq":
        if not key:
            yield "Please configure your Groq API Key using `/connect Groq <your-key>`."
            return
        yield from stream_openai_compatible(
            "https://api.groq.com/openai/v1/chat/completions",
            key,
            model or "llama-3.3-70b-versatile",
            messages
        )
    elif provider == "DeepSeek":
        if not key:
            yield "Please configure your DeepSeek API Key using `/connect DeepSeek <your-key>`."
            return
        yield from stream_openai_compatible(
            "https://api.deepseek.com/chat/completions",
            key,
            model or "deepseek-chat",
            messages
        )
    elif provider == "OpenAI":
        if not key:
            yield "Please configure your OpenAI API Key using `/connect OpenAI <your-key>`."
            return
        yield from stream_openai_compatible(
            "https://api.openai.com/v1/chat/completions",
            key,
            model or "gpt-4o-mini",
            messages
        )
    elif provider == "NVIDIA":
        if not key:
            yield "Please configure your NVIDIA API Key using `/connect NVIDIA <your-key>`."
            return
        yield from stream_openai_compatible(
            "https://integrate.api.nvidia.com/v1/chat/completions",
            key,
            model or "meta/llama-3.3-70b-instruct",
            messages
        )
    elif provider == "Ollama":
        base = cfg.get("ollama_base_url", "http://localhost:11434").rstrip("/")
        yield from stream_openai_compatible(
            f"{base}/v1/chat/completions",
            None,
            model or "llama3.2:latest",
            messages
        )
    elif provider == "Custom":
        base = cfg.get("custom_base_url", "http://localhost:8000").rstrip("/")
        yield from stream_openai_compatible(
            f"{base}/v1/chat/completions",
            key,
            model or "default-model",
            messages
        )
    else:
        yield f"Unsupported provider: {provider}"

# ============================================================================
# TOOL EXECUTION
# ============================================================================

def execute_tool(tool_name, args):
    try:
        if tool_name == "read_file":
            path = pathlib.Path(os.path.expanduser(args.get("path", "")))
            if not path.exists():
                return f"Error: File '{path}' does not exist."
            if path.is_dir():
                return f"Error: '{path}' is a directory, not a file."
            content = path.read_text(encoding="utf-8", errors="replace")
            return content[:15000]

        elif tool_name == "list_directory":
            path = pathlib.Path(os.path.expanduser(args.get("path", ".") or "."))
            if not path.exists():
                return f"Error: Directory '{path}' does not exist."
            entries = []
            for item in sorted(path.iterdir()):
                kind = "DIR " if item.is_dir() else "FILE"
                entries.append(f"{kind}  {item.name}")
            return "\n".join(entries[:200])

        elif tool_name == "write_file":
            path = pathlib.Path(os.path.expanduser(args.get("path", "")))
            content = args.get("content", "")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
            return f"Successfully wrote {len(content)} bytes to {path}"

        elif tool_name == "delete_file":
            path = pathlib.Path(os.path.expanduser(args.get("path", "")))
            if not path.exists():
                return f"Error: Path '{path}' does not exist."
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()
            return f"Successfully deleted '{path}'"

        elif tool_name == "execute_command":
            cmd = args.get("command", "")
            if not cmd:
                return "Error: No command specified."
            res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
            out = res.stdout
            if res.stderr:
                out += f"\n[stderr]\n{res.stderr}"
            return out.strip() or "(Command completed with no output)"

        return f"Unknown tool: {tool_name}"
    except Exception as e:
        return f"Tool execution failed: {e}"

# ============================================================================
# CHAT HANDLERS (STREAMING & SYNC)
# ============================================================================

def emit_event(ev_type, **kwargs):
    payload = {"event": ev_type, **kwargs}
    sys.stdout.write(json.dumps(payload) + "\n")
    sys.stdout.flush()

def handle_stream_chat(user_msg, sid=None, provider_override=None, model_override=None):
    cfg = load_config()
    provider = provider_override or cfg.get("provider", "OpenRouter")
    model = model_override or cfg.get("model", "")
    session = load_session(sid)
    now_str = time.strftime("%H:%M")

    # Handle Slash Commands
    cmd_parts = user_msg.strip().split()
    cmd = cmd_parts[0].lower() if cmd_parts else ""

    if cmd == "/new":
        new_sess = create_new_session()
        emit_event("start", session_id=new_sess["id"])
        emit_event("chunk", text="Started a new conversation.")
        emit_event("done", session=new_sess)
        return

    if cmd == "/clear":
        session["messages"] = [{
            "sender": "assistant",
            "text": "Chat cleared. What would you like to explore next?",
            "time": now_str,
            "status": "done"
        }]
        save_session(session)
        emit_event("start", session_id=session["id"])
        emit_event("chunk", text="Chat cleared.")
        emit_event("done", session=session)
        return

    if cmd == "/sessions":
        sessions = list_all_sessions()
        emit_event("start", session_id=session["id"])
        emit_event("chunk", text=f"Found {len(sessions)} previous conversation sessions. Use the Sessions menu to switch.")
        emit_event("done", session=session, sessions=sessions)
        return

    if cmd == "/help":
        help_text = (
            "**MasterR AI Chatbot Commands:**\n"
            "- `/connect <provider> <key>` : Set provider API key\n"
            "- `/new` : Start a new conversation session\n"
            "- `/sessions` : Browse and resume past sessions\n"
            "- `/clear` : Clear current chat history\n"
            "- `/models` : Refresh available models list\n\n"
            "**Keybinds:**\n"
            "- `Ctrl + +` / `Ctrl + -` : Resize width\n"
            "- `Ctrl + Shift + +` / `Ctrl + Shift + -` : Resize height\n"
            "- `Enter` : Send message | `Shift + Enter` : Newline"
        )
        emit_event("start", session_id=session["id"])
        emit_event("chunk", text=help_text)
        emit_event("done", session=session)
        return

    if cmd == "/connect":
        if len(cmd_parts) >= 3:
            p_name = cmd_parts[1]
            key_val = cmd_parts[2]
            cfg["keys"][p_name] = key_val
            save_config(cfg)
            emit_event("start", session_id=session["id"])
            emit_event("chunk", text=f"Saved API Key for **{p_name}**.")
            emit_event("done", session=session)
            return

    # Add user message to session
    session["messages"].append({
        "sender": "user",
        "text": user_msg,
        "time": now_str,
        "status": "done"
    })

    if len(session["messages"]) <= 3:
        words = user_msg.strip().split()
        session["title"] = " ".join(words[:6]) if words else "Conversation"

    emit_event("start", session_id=session["id"])

    full_reply = ""
    try:
        for chunk in get_stream_generator(provider, model, session["messages"], cfg):
            full_reply += chunk
            emit_event("chunk", text=chunk)
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace") if hasattr(e, "read") else str(e)
        full_reply = f"**API Error ({e.code})**: {err_body}"
        emit_event("chunk", text=full_reply)
    except Exception as e:
        full_reply = f"**Connection Error**: {e}"
        emit_event("chunk", text=full_reply)

    # Parse for json_action tool calls
    tool_action = None
    if "```json_action" in full_reply:
        parts = full_reply.split("```json_action", 1)
        clean_text = parts[0].strip()
        json_part = parts[1].split("```", 1)[0].strip()
        try:
            action_data = json.loads(json_part)
            tool_name = action_data.get("tool")

            if tool_name in ["read_file", "list_directory"]:
                tool_out = execute_tool(tool_name, action_data)
                followup_msgs = session["messages"] + [
                    {"sender": "assistant", "text": full_reply, "time": now_str, "status": "done"},
                    {"sender": "user", "text": f"[System Observation from {tool_name}]:\n{tool_out}", "time": now_str, "status": "done"}
                ]
                emit_event("chunk", text=f"\n\n*(Inspected {action_data.get('path', 'files')})*\n\n")
                try:
                    for c in get_stream_generator(provider, model, followup_msgs, cfg):
                        full_reply += c
                        emit_event("chunk", text=c)
                except Exception:
                    pass
            else:
                tool_action = {
                    "tool": tool_name,
                    "path": action_data.get("path", ""),
                    "command": action_data.get("command", ""),
                    "content": action_data.get("content", ""),
                    "explanation": action_data.get("explanation", clean_text or f"Wants to execute {tool_name}")
                }
        except Exception as e:
            sys.stderr.write(f"Tool parse error: {e}\n")

    msg_entry = {
        "sender": "assistant",
        "text": full_reply,
        "time": now_str,
        "status": "pending_permission" if tool_action else "done",
        "toolAction": tool_action
    }
    session["messages"].append(msg_entry)
    save_session(session)

    emit_event("done", session=session, toolAction=tool_action)

def main():
    parser = argparse.ArgumentParser(description="MasterR Chatbot Engine")
    parser.add_argument("--stream-chat", type=str, help="Stream user message chunks in real time")
    parser.add_argument("--chat", type=str, help="Send user message synchronously")
    parser.add_argument("--session-id", type=str, help="Session ID")
    parser.add_argument("--provider", type=str, help="Provider name")
    parser.add_argument("--model", type=str, help="Model name")
    parser.add_argument("--list-models", action="store_true", help="List available models")
    parser.add_argument("--list-sessions", action="store_true", help="List sessions")
    parser.add_argument("--get-session", type=str, help="Get session by ID")
    parser.add_argument("--new-session", action="store_true", help="Start new session")
    parser.add_argument("--delete-session", type=str, help="Delete session ID")
    parser.add_argument("--get-config", action="store_true", help="Get current config")
    parser.add_argument("--set-config", type=str, help="Set config JSON")
    parser.add_argument("--execute-tool", type=str, help="Execute tool name")
    parser.add_argument("--tool-args", type=str, help="Tool arguments JSON")

    args = parser.parse_args()

    if args.stream_chat:
        handle_stream_chat(args.stream_chat, sid=args.session_id, provider_override=args.provider, model_override=args.model)
        return

    if args.get_config:
        cfg = load_config()
        print(json.dumps(cfg))
        return

    if args.set_config:
        try:
            new_cfg = json.loads(args.set_config)
            cfg = load_config()
            cfg.update(new_cfg)
            save_config(cfg)
            print(json.dumps({"status": "ok", "config": cfg}))
        except Exception as e:
            print(json.dumps({"status": "error", "error": str(e)}))
        return

    if args.list_models:
        provider = args.provider or load_config().get("provider", "OpenRouter")
        models = fetch_models(provider)
        print(json.dumps({"provider": provider, "models": models}))
        return

    if args.list_sessions:
        sessions = list_all_sessions()
        print(json.dumps(sessions))
        return

    if args.get_session:
        sess = load_session(args.get_session)
        print(json.dumps(sess))
        return

    if args.new_session:
        sess = create_new_session()
        print(json.dumps(sess))
        return

    if args.delete_session:
        delete_session(args.delete_session)
        print(json.dumps({"status": "ok"}))
        return

    if args.execute_tool:
        tool_args = json.loads(args.tool_args or "{}")
        res = execute_tool(args.execute_tool, tool_args)
        print(json.dumps({"status": "ok", "result": res}))
        return

    if args.chat:
        handle_stream_chat(args.chat, sid=args.session_id, provider_override=args.provider, model_override=args.model)
        return

    cfg = load_config()
    print(json.dumps({"status": "running", "provider": cfg.get("provider"), "model": cfg.get("model")}))

if __name__ == "__main__":
    main()
