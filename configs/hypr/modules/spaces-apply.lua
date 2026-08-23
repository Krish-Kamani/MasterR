-- Turns the user-defined spaces in modules.spaces into live Hyprland config: a
-- per-app window_rule routes a class into special:<id>, and a non-empty key binds
-- SUPER+<key> to toggle the space plus SUPER+SHIFT+<key> to send/retrieve the
-- focused window via the shared special-toggle.sh. Every field is guarded so a
-- malformed entry is skipped instead of breaking the whole config.

local ok, spaces = pcall(require, "modules.spaces")
if not ok or type(spaces) ~= "table" then
    return
end

for _, sp in ipairs(spaces) do
    if type(sp) == "table" and type(sp.id) == "string" and sp.id ~= "" then
        local id = sp.id

        if type(sp.apps) == "table" then
            for _, cls in ipairs(sp.apps) do
                if type(cls) == "string" and cls ~= "" then
                    hl.window_rule({
                        name      = "space-" .. id .. "-" .. cls,
                        match     = { class = cls },
                        workspace = "special:" .. id,
                    })
                end
            end
        end

        if type(sp.key) == "string" and sp.key ~= "" then
            hl.bind("SUPER + " .. sp.key, hl.dsp.workspace.toggle_special(id))
            hl.bind("SUPER + SHIFT + " .. sp.key,
                hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/special-toggle.sh " .. id))
        end
    end
end
