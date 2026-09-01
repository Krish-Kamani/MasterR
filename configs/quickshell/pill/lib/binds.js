function readMod(luaText) {
    var m = luaText.match(/^\s*local\s+mod\s*=\s*"([^"]*)"/m);
    return m ? m[1] : "SUPER";
}

function isMouseCombo(combo) {
    return /mouse:|mouse_up|mouse_down/.test(combo);
}

function optsHasMouse(opts) {
    return /\bmouse\s*=\s*true\b/.test(opts);
}

function splitArgs(inner) {
    var args = [];
    var depth = 0;
    var inStr = false;
    var start = 0;
    for (var i = 0; i < inner.length; i++) {
        var c = inner[i];
        if (inStr) {
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === '(' || c === '{' || c === '[') depth++;
        else if (c === ')' || c === '}' || c === ']') depth--;
        else if (c === ',' && depth === 0) {
            args.push(inner.slice(start, i));
            start = i + 1;
        }
    }
    args.push(inner.slice(start));
    return args.map(function (a) { return a.trim(); });
}

function resolveCombo(firstArg, modValue) {
    var modMatch = firstArg.match(/^mod\s*\.\.\s*"([^"]*)"$/);
    if (modMatch) {
        return { combo: modValue + modMatch[1] };
    }
    var litMatch = firstArg.match(/^"([^"]*)"$/);
    if (litMatch) {
        return { combo: litMatch[1] };
    }
    return { combo: firstArg };
}

function deriveLabel(action, cmd) {
    if (cmd && cmd.length > 0) {
        if (/open-surface\.sh\s+launcher/i.test(cmd)) return "App Launcher";
        if (/open-surface\.sh\s+finder/i.test(cmd)) return "File Finder";
        if (/open-surface\.sh\s+clipboard/i.test(cmd)) return "Clipboard History";
        if (/open-surface\.sh\s+wallpaper/i.test(cmd)) return "Wallpaper Selector";
        if (/open-surface\.sh\s+gameMode/i.test(cmd)) return "Game Mode";
        if (/open-surface\.sh\s+packages/i.test(cmd)) return "Package Manager";
        if (/open-surface\.sh\s+keybinds/i.test(cmd)) return "System Keybinds";
        if (/open-surface\.sh\s+power/i.test(cmd)) return "Power Menu";
        if (/overview-toggle\.sh/i.test(cmd)) return "Workspace Overview";
        if (/float-toggle\.sh/i.test(cmd)) return "Toggle Floating Window";
        if (/float-window\.sh/i.test(cmd)) return "Float & Pin Window";
        if (/minimize-toggle\.sh/i.test(cmd)) return "Toggle Minimize Window";
        if (/special-toggle\.sh\s+private/i.test(cmd)) return "Private Workspace";
        if (/special-toggle\.sh\s+stash/i.test(cmd)) return "Stash Workspace";
        if (/lock\.sh/i.test(cmd)) return "Lock Screen";
        if (/record\.sh/i.test(cmd)) return "Screen Recorder";
        if (/hyprpicker/i.test(cmd)) return "Color Picker";
        if (/ghostty/i.test(cmd)) return "Terminal";
        if (/dolphin/i.test(cmd)) return "File Manager";
        if (/hyprctl\s+reload/i.test(cmd)) return "Reload Hyprland Config";
        if (/wpctl.*5%\+/i.test(cmd)) return "Volume Up";
        if (/wpctl.*5%-/i.test(cmd)) return "Volume Down";
        if (/wpctl.*toggle/i.test(cmd)) return "Mute Audio";
        if (/brightnessctl.*5%\+/i.test(cmd)) return "Brightness Up";
        if (/brightnessctl.*5%-/i.test(cmd)) return "Brightness Down";

        var script = cmd.match(/\/scripts\/([^\/]+)\.sh\b/);
        if (script) return script[1].replace(/-/g, " ");
        var binary = cmd.split(/\s+/)[0].replace(/^.*\//, "");
        if (binary) return binary.charAt(0).toUpperCase() + binary.slice(1);
    }

    if (/window\.kill\b/.test(action)) return "Kill Window";
    if (/window\.close\b/.test(action)) return "Close Active Window";
    if (/window\.fullscreen\b/.test(action)) return "Toggle Fullscreen";
    if (/window\.float\b/.test(action)) return "Toggle Float";
    if (/window\.drag\b/.test(action)) return "Drag Window";
    if (/window\.resize\b/.test(action)) return "Resize Window";

    var wsMove = action.match(/window\.move\({\s*workspace\s*=\s*(\d+)/);
    if (wsMove) return "Move Window to Workspace " + wsMove[1];

    var wsFocus = action.match(/focus\({\s*workspace\s*=\s*(\d+)/);
    if (wsFocus) return "Switch to Workspace " + wsFocus[1];

    var wsRel = action.match(/focus\({\s*workspace\s*=\s*"r([+-]\d+)"/);
    if (wsRel) return wsRel[1] === "+1" || wsRel[1] === "r+1" ? "Next Workspace" : "Previous Workspace";

    var special = action.match(/toggle_special\("([^"]+)"\)/);
    if (special) return "Toggle " + special[1].charAt(0).toUpperCase() + special[1].slice(1) + " Workspace";

    if (/quickshell:mediaToggle/.test(action)) return "Play / Pause Media";
    if (/quickshell:mediaNext/.test(action)) return "Next Track";
    if (/quickshell:mediaPrev/.test(action)) return "Previous Track";

    return action.replace(/^hl\.dsp\./, "").replace(/\(\)$/, "");
}

function categorize(combo, action, cmd) {
    if (/Audio|Brightness|wpctl|brightnessctl|quickshell:media/i.test(combo + action + cmd))
        return "Media";
    if (/workspace|toggle_special|focus\(|window\.move/i.test(action + cmd))
        return "Workspaces";
    if (/window\.close|window\.kill|fullscreen|float|drag|resize|minimize/i.test(action + cmd))
        return "Window";
    if (/ghostty|dolphin|hyprpicker|rishot/i.test(cmd))
        return "Apps";
    if (/open-surface|launcher|finder|clipboard|wallpaper|lock|record|overview|keybinds/i.test(cmd))
        return "Launchers";
    return "System";
}

function deriveWork(action, cmd) {
    if (cmd && cmd.length > 0) {
        var base = cmd.replace(/^.*\/scripts\//, "scripts/").replace(/\/home\/[^\/]+\/\.config\/hypr\//, "");
        return base;
    }
    return action.replace(/^hl\.dsp\./, "");
}

function nameComment(raw, closeIndex) {
    var rest = raw.slice(closeIndex + 1);
    var m = rest.match(/--\s?(.*)$/);
    return m ? m[1].trim() : "";
}

function isExecAction(action) {
    return /exec_cmd\s*\(/.test(action);
}

function execCmd(action) {
    var m = action.match(/exec_cmd\(\s*"((?:[^"\\]|\\.)*)"\s*\)/);
    if (m) return m[1].replace(/\\"/g, '"').replace(/\\\\/g, "\\");

    var mEnv = action.match(/exec_cmd\(\s*os\.getenv\([^)]*\)\s*\.\.\s*"([^"]*)"\s*\)/);
    if (mEnv) return (Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")) + mEnv[1];

    return "";
}

function parseLine(raw, lineIndex, modValue) {
    var open = raw.indexOf("hl.bind(");
    if (open === -1) return null;

    var depth = 0;
    var inStr = false;
    var startInner = open + "hl.bind(".length;
    var endInner = -1;
    for (var i = startInner - 1; i < raw.length; i++) {
        var c = raw[i];
        if (inStr) {
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === '(') depth++;
        else if (c === ')') {
            depth--;
            if (depth === 0) { endInner = i; break; }
        }
    }
    if (endInner === -1) return null;

    var inner = raw.slice(startInner, endInner);
    var args = splitArgs(inner);
    if (args.length < 2) return null;

    var resolved = resolveCombo(args[0], modValue);
    var action = args[1];
    var opts = args.length >= 3 ? args.slice(2).join(", ") : "";

    var explicitComment = nameComment(raw, endInner);
    var explicitCat = "";
    var cleanName = explicitComment;
    var catMatch = explicitComment.match(/^\[([^\]]+)\]\s*(.*)$/);
    if (catMatch) {
        explicitCat = catMatch[1].trim();
        cleanName = catMatch[2].trim();
    }

    var cmd = execCmd(action);
    var mouse = isMouseCombo(resolved.combo) || optsHasMouse(opts);
    var label = cleanName.length > 0 ? cleanName : deriveLabel(action, cmd);
    var work = deriveWork(action, cmd);
    var cat = explicitCat.length > 0 ? explicitCat : categorize(resolved.combo, action, cmd);

    return {
        combo: resolved.combo,
        label: label,
        name: cleanName.length > 0 ? cleanName : label,
        explicitName: cleanName,
        explicitCat: explicitCat,
        action: action,
        work: work,
        cmd: cmd,
        category: cat,
        isExec: isExecAction(action),
        isMouse: mouse,
        lineIndex: lineIndex
    };
}

function parse(luaText) {
    var modValue = readMod(luaText);
    var lines = luaText.split("\n");
    var out = [];
    for (var i = 0; i < lines.length; i++) {
        var entry = parseLine(lines[i], i, modValue);
        if (entry) out.push(entry);
    }
    return out;
}

function rebind(luaText, lineIndex, newCombo) {
    var modValue = readMod(luaText);
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length) {
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    }

    var raw = lines[lineIndex];
    var open = raw.indexOf("hl.bind(");
    if (open === -1) {
        return { text: luaText, ok: false, error: "no hl.bind on line" };
    }

    var startInner = open + "hl.bind(".length;
    var firstEnd = -1;
    var depth = 0;
    var inStr = false;
    for (var i = startInner; i < raw.length; i++) {
        var c = raw[i];
        if (inStr) {
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === '(' || c === '{' || c === '[') depth++;
        else if (c === ')' || c === '}' || c === ']') depth--;
        else if (c === ',' && depth === 0) { firstEnd = i; break; }
    }
    if (firstEnd === -1) {
        return { text: luaText, ok: false, error: "could not isolate first arg" };
    }

    var firstRaw = raw.slice(startInner, firstEnd);
    var leading = firstRaw.match(/^\s*/)[0];
    var trailing = firstRaw.match(/\s*$/)[0];

    var modPrefix = modValue + " + ";
    var firstArg;
    if (newCombo.indexOf(modPrefix) === 0) {
        firstArg = 'mod .. " + ' + newCombo.slice(modPrefix.length) + '"';
    } else {
        firstArg = '"' + newCombo + '"';
    }

    var newFirstRaw = leading + firstArg + trailing;
    var newLine = raw.slice(0, startInner) + newFirstRaw + raw.slice(firstEnd);
    lines[lineIndex] = newLine;

    return { text: lines.join("\n"), ok: true, error: "" };
}

function inUse(luaText, newCombo, exceptLineIndex) {
    var entries = parse(luaText);
    for (var i = 0; i < entries.length; i++) {
        if (entries[i].lineIndex === exceptLineIndex) continue;
        if (entries[i].combo.toLowerCase().replace(/\s+/g, "") === newCombo.toLowerCase().replace(/\s+/g, "")) return true;
    }
    return false;
}

function comboExpr(combo, modValue) {
    var modPrefix = modValue + " + ";
    if (combo.indexOf(modPrefix) === 0)
        return 'mod .. " + ' + combo.slice(modPrefix.length) + '"';
    return '"' + combo + '"';
}

function escapeCmd(cmd) {
    return cmd.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function closeParenIndex(raw, open) {
    var depth = 0;
    var inStr = false;
    for (var i = open + "hl.bind(".length - 1; i < raw.length; i++) {
        var c = raw[i];
        if (inStr) {
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === '(') depth++;
        else if (c === ')') {
            depth--;
            if (depth === 0) return i;
        }
    }
    return -1;
}

function argStart(raw, innerStart, nth) {
    var depth = 0;
    var inStr = false;
    var seen = -1;
    for (var i = innerStart; i < raw.length; i++) {
        var c = raw[i];
        if (inStr) {
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === '(' || c === '{' || c === '[') depth++;
        else if (c === ')' || c === '}' || c === ']') {
            if (depth === 0) return -1;
            depth--;
        } else if (c === ',' && depth === 0) {
            seen++;
            if (seen === nth) return i + 1;
        }
    }
    return -1;
}

function argRange(raw, argIndex) {
    var open = raw.indexOf("hl.bind(");
    if (open === -1) return null;
    var innerStart = open + "hl.bind(".length;
    var close = closeParenIndex(raw, open);
    if (close === -1) return null;

    var start = argIndex === 0 ? innerStart : argStart(raw, innerStart, argIndex - 1);
    if (start === -1) return null;

    var end = argStart(raw, start, 0);
    if (end === -1) end = close;
    else end = end - 1;
    return { start: start, end: end };
}

function add(luaText, combo, cmd, name, category) {
    if (!combo || !combo.length)
        return { text: luaText, ok: false, error: "empty combo" };
    if (!cmd || !cmd.length)
        return { text: luaText, ok: false, error: "empty command" };

    var modValue = readMod(luaText);
    var lines = luaText.split("\n");

    var first = comboExpr(combo, modValue);
    var line = "hl.bind(" + first + ', hl.dsp.exec_cmd("' + escapeCmd(cmd) + '"))';
    if (category && category.length && category !== "All") {
        line += " -- [" + category + "]" + (name && name.length ? " " + name : "");
    } else if (name && name.length) {
        line += " -- " + name;
    }

    var insertAt = lines.length;
    for (var i = lines.length - 1; i >= 0; i--) {
        if (lines[i].trim().length) { insertAt = i + 1; break; }
        insertAt = i;
    }
    lines.splice(insertAt, 0, line);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function del(luaText, lineIndex) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    lines.splice(lineIndex, 1);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function editCmd(luaText, lineIndex, cmd) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };

    var raw = lines[lineIndex];
    var range = argRange(raw, 1);
    if (!range)
        return { text: luaText, ok: false, error: "could not isolate dispatch arg" };

    var slice = raw.slice(range.start, range.end);
    var leading = slice.match(/^\s*/)[0];
    var trailing = slice.match(/\s*$/)[0];
    var dispatch = 'hl.dsp.exec_cmd("' + escapeCmd(cmd) + '")';

    lines[lineIndex] = raw.slice(0, range.start) + leading + dispatch + trailing + raw.slice(range.end);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function editName(luaText, lineIndex, name) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };

    var raw = lines[lineIndex];
    var open = raw.indexOf("hl.bind(");
    if (open === -1)
        return { text: luaText, ok: false, error: "no hl.bind on line" };
    var close = closeParenIndex(raw, open);
    if (close === -1)
        return { text: luaText, ok: false, error: "unterminated bind" };

    var head = raw.slice(0, close + 1);
    var rest = raw.slice(close + 1);
    var existingCat = "";
    var m = rest.match(/--\s?(.*)$/);
    if (m) {
        var catMatch = m[1].trim().match(/^\[([^\]]+)\]/);
        if (catMatch) existingCat = catMatch[1].trim();
    }

    var line = head;
    if (existingCat.length > 0 && name && name.length > 0) {
        line += " -- [" + existingCat + "] " + name;
    } else if (existingCat.length > 0) {
        line += " -- [" + existingCat + "]";
    } else if (name && name.length > 0) {
        line += " -- " + name;
    }

    lines[lineIndex] = line;
    return { text: lines.join("\n"), ok: true, error: "" };
}

function editCategory(luaText, lineIndex, newCategory) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };

    var raw = lines[lineIndex];
    var open = raw.indexOf("hl.bind(");
    if (open === -1)
        return { text: luaText, ok: false, error: "no hl.bind on line" };
    var close = closeParenIndex(raw, open);
    if (close === -1)
        return { text: luaText, ok: false, error: "unterminated bind" };

    var head = raw.slice(0, close + 1);
    var rest = raw.slice(close + 1);
    var comment = "";
    var m = rest.match(/--\s?(.*)$/);
    if (m) {
        var cText = m[1].trim();
        var catMatch = cText.match(/^\[([^\]]+)\]\s*(.*)$/);
        if (catMatch) {
            comment = catMatch[2].trim();
        } else {
            comment = cText;
        }
    }

    var line = head;
    if (newCategory && newCategory.length > 0) {
        line += " -- [" + newCategory + "]" + (comment.length > 0 ? " " + comment : "");
    } else if (comment.length > 0) {
        line += " -- " + comment;
    }

    lines[lineIndex] = line;
    return { text: lines.join("\n"), ok: true, error: "" };
}
