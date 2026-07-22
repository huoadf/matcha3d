-- ==============================================================================
-- 🔮 MATCHA 3D AURA STUDIO (FULLY CUSTOMIZABLE PARTICLE & SPARK SUITE)
-- Docs: https://huoadf.github.io/matcha-docs/
-- Repo: https://github.com/huoadf/matcha3d
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Master Config Table
local AURA_CFG = {
    -- Master Toggles
    enabled            = true,
    target_lock_on     = false,
    target_mode        = "LocalPlayer", -- "LocalPlayer", "Closest", "Random"
    sparks_enabled     = true,
    glow_enabled       = true,
    filled_particles   = false,
    rainbow_main       = false,
    rainbow_sparks     = false,
    rainbow_speed      = 1.0,

    -- Counts
    particle_count     = 35,
    spark_count        = 20,

    -- Colors
    main_color         = Color3.fromRGB(238, 138, 255),
    spark_color        = Color3.fromRGB(80, 220, 255),
    glow_color         = Color3.fromRGB(255, 80, 200),

    -- Dimensions & Offsets
    radius             = 4.0,
    inner_radius       = 1.5,
    height_offset      = 0.5,
    particle_size      = 3.0,
    spark_size         = 1.5,
    glow_scale         = 2.5,
    thickness          = 1.5,

    -- Dynamic Speeds & Waves
    rotation_speed     = 2.0,
    spark_speed_mult   = 1.4,
    wave_speed         = 2.0,
    wave_amplitude     = 0.5,
    bobbing_speed      = 1.5,
    bobbing_amplitude  = 0.5,

    -- Opacity & Glow
    glow_intensity     = 0.35,
    opacity            = 0.85
}

-- Drawing Pools (Pre-allocated for maximum 120 FPS performance)
local MAX_PARTICLES = 80
local MAX_SPARKS    = 40

local particle_pool = {}
local spark_pool    = {}
local glow_pool     = {}

for i = 1, MAX_PARTICLES do
    local c = Drawing.new("Circle")
    c.Visible = false
    c.Thickness = AURA_CFG.thickness
    c.NumSides = 16
    c.ZIndex = 6
    particle_pool[i] = c
end

for i = 1, MAX_SPARKS do
    local s = Drawing.new("Circle")
    s.Visible = false
    s.Thickness = 1.0
    s.NumSides = 12
    s.ZIndex = 7
    s.Filled = true
    spark_pool[i] = s

    local g = Drawing.new("Circle")
    g.Visible = false
    g.Thickness = 1.0
    g.NumSides = 12
    g.ZIndex = 5
    g.Filled = true
    glow_pool[i] = g
end

local function hideAll()
    for i = 1, MAX_PARTICLES do particle_pool[i].Visible = false end
    for i = 1, MAX_SPARKS do
        spark_pool[i].Visible = false
        glow_pool[i].Visible = false
    end
end

-- Helper Color Functions
local COLOR_NOW = 0
local function rainbowColor(offset)
    local h = ((COLOR_NOW * AURA_CFG.rainbow_speed) + (offset or 0)) % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local q = 1 - f
    local r, g, b
    i = i % 6
    if     i == 0 then r,g,b = 1,f,0
    elseif i == 1 then r,g,b = q,1,0
    elseif i == 2 then r,g,b = 0,1,f
    elseif i == 3 then r,g,b = 0,q,1
    elseif i == 4 then r,g,b = f,0,1
    else               r,g,b = 1,0,q
    end
    return Color3.new(r, g, b)
end

local function get_clamped_radius(base_radius, inner, outer)
    return math.max(inner, math.min(outer, base_radius))
end

-- Target HRP Resolution
local function getTargetHRP()
    if AURA_CFG.target_mode == "LocalPlayer" or not AURA_CFG.target_lock_on then
        local char = LocalPlayer and LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local myHRP = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local candidates = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local dist = (hrp.Position - myHRP.Position).Magnitude
            candidates[#candidates + 1] = {hrp = hrp, dist = dist}
        end
    end

    if #candidates == 0 then return myHRP end

    if AURA_CFG.target_mode == "Closest" then
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
        return candidates[1].hrp
    elseif AURA_CFG.target_mode == "Random" then
        return candidates[math.random(1, #candidates)].hrp
    end

    return myHRP
end

-- Main Render Loop
local time = 0
RunService.Heartbeat:Connect(function(dt)
    if not AURA_CFG.enabled then
        hideAll()
        return
    end

    local targetHRP = getTargetHRP()
    if not targetHRP then
        hideAll()
        return
    end

    local root_pos = targetHRP.Position
    time = time + dt
    COLOR_NOW = (COLOR_NOW + dt * 0.25) % 1.0

    local main_color  = AURA_CFG.rainbow_main and rainbowColor() or AURA_CFG.main_color
    local spark_color = AURA_CFG.rainbow_sparks and rainbowColor(0.5) or AURA_CFG.spark_color
    local glow_color  = AURA_CFG.glow_color
    local opacity     = AURA_CFG.opacity
    local filled      = AURA_CFG.filled_particles
    local inner       = AURA_CFG.inner_radius
    local outer       = AURA_CFG.radius

    -- 1. Main Particles Orbit
    local pCount = math.min(math.floor(AURA_CFG.particle_count), MAX_PARTICLES)
    for i = 1, pCount do
        local c = particle_pool[i]
        local angle = (i / pCount) * math.pi * 2 + time * AURA_CFG.rotation_speed
        local waveOffset = math.sin(time * AURA_CFG.wave_speed + i * 0.5) * AURA_CFG.wave_amplitude
        local r = get_clamped_radius(outer - 0.5 + waveOffset, inner, outer)

        local x = root_pos.X + math.cos(angle) * r
        local z = root_pos.Z + math.sin(angle) * r
        local y = root_pos.Y + AURA_CFG.height_offset + math.sin(time * AURA_CFG.bobbing_speed + i * 0.3) * AURA_CFG.bobbing_amplitude

        local screen_pos, onScreen = WorldToScreen(Vector3.new(x, y, z))

        if onScreen then
            local size = AURA_CFG.particle_size + math.sin(time * 2.5 + i * 0.5) * 0.5
            local alpha = 0.3 + math.sin(time * 2.0 + i * 0.3) * 0.3

            c.Position = Vector2.new(screen_pos.X, screen_pos.Y)
            c.Radius = math.max(size, 0.5)
            c.Thickness = AURA_CFG.thickness
            c.Color = main_color
            c.Transparency = math.clamp(alpha * opacity, 0, 1)
            c.Filled = filled
            c.Visible = true
        else
            c.Visible = false
        end
    end
    for i = pCount + 1, MAX_PARTICLES do particle_pool[i].Visible = false end

    -- 2. Sparks & Glow Orbs
    if AURA_CFG.sparks_enabled then
        local sCount = math.min(math.floor(AURA_CFG.spark_count), MAX_SPARKS)
        for i = 1, sCount do
            local s = spark_pool[i]
            local g = glow_pool[i]
            local angle = (i / sCount) * math.pi * 2 + time * (AURA_CFG.rotation_speed * AURA_CFG.spark_speed_mult)
            local r = get_clamped_radius(
                outer * 0.6 + math.sin(time * 2.0 + i * 0.5) * 0.8,
                inner + 0.3,
                outer * 0.9
            )

            local x = root_pos.X + math.cos(angle) * r
            local z = root_pos.Z + math.sin(angle) * r
            local y = root_pos.Y + AURA_CFG.height_offset + math.sin(time * 2.5 + i * 0.4) * 1.2

            local screen_pos, onScreen = WorldToScreen(Vector3.new(x, y, z))

            if onScreen then
                local size = AURA_CFG.spark_size + math.sin(time * 4.0 + i * 1.5) * 0.3
                local alpha = 0.4 + math.sin(time * 3.0 + i * 0.7) * 0.3

                s.Position = Vector2.new(screen_pos.X, screen_pos.Y)
                s.Radius = math.max(size, 0.3)
                s.Color = spark_color
                s.Transparency = math.clamp(alpha * opacity, 0, 1)
                s.Visible = true

                -- Spark Glow
                if AURA_CFG.glow_enabled and AURA_CFG.glow_intensity > 0 then
                    local glow_size = size * AURA_CFG.glow_scale
                    local glow_alpha = AURA_CFG.glow_intensity * alpha * opacity * 0.35
                    g.Position = Vector2.new(screen_pos.X, screen_pos.Y)
                    g.Radius = glow_size
                    g.Color = glow_color
                    g.Transparency = math.clamp(glow_alpha, 0, 1)
                    g.Visible = true
                else
                    g.Visible = false
                end
            else
                s.Visible = false
                g.Visible = false
            end
        end
        for i = sCount + 1, MAX_SPARKS do
            spark_pool[i].Visible = false
            glow_pool[i].Visible = false
        end
    else
        for i = 1, MAX_SPARKS do
            spark_pool[i].Visible = false
            glow_pool[i].Visible = false
        end
    end
end)

-- ── INS-UI Menu Configuration ────────────────────────────────────────────────
local Lib = nil
pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/huoadf/matcha3d/main/ins_uilib.lua?v=3")
    if type(code) == "string" and code:find("CreateWindow") then
        Lib = loadstring(code)()
    end
end)

if not Lib then
    pcall(function()
        local code = game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua")
        if type(code) == "string" and code:find("CreateWindow") then
            Lib = loadstring(code)()
        end
    end)
end

Lib = Lib or _G.INSui or (getfenv and getfenv().INSui)

if Lib and Lib.CreateWindow then
    local Win = Lib:CreateWindow("Matcha 3D Aura Studio")

    -- Tab 1: Controls & Target
    local TabMain = Win:Tab("Main Controls")
    local SecMain = TabMain:Section("Master Toggles")
    SecMain:Toggle("Enable Aura", AURA_CFG.enabled, function(v) AURA_CFG.enabled = v end)
    SecMain:Toggle("Enable Sparks", AURA_CFG.sparks_enabled, function(v) AURA_CFG.sparks_enabled = v end)
    SecMain:Toggle("Enable Spark Glow", AURA_CFG.glow_enabled, function(v) AURA_CFG.glow_enabled = v end)
    SecMain:Toggle("Filled Particles", AURA_CFG.filled_particles, function(v) AURA_CFG.filled_particles = v end)

    local SecTarget = TabMain:Section("Target Lock & ESP")
    SecTarget:Toggle("Lock-On Target Player", AURA_CFG.target_lock_on, function(v) AURA_CFG.target_lock_on = v end)
    SecTarget:Dropdown("Target Selection Mode", {"LocalPlayer", "Closest", "Random"}, {"LocalPlayer"}, false, function(v)
        AURA_CFG.target_mode = v[1]
    end)

    -- Tab 2: Dimensions & Geometry
    local TabDim = Win:Tab("Dimensions")
    local SecRad = TabDim:Section("Radius & Spacing")
    SecRad:Slider("Outer Radius", 40, 1, 10, 150, "u", function(v) AURA_CFG.radius = v / 10 end)
    SecRad:Slider("Inner Radius", 15, 1, 1, 100, "u", function(v) AURA_CFG.inner_radius = v / 10 end)
    SecRad:Slider("Height Offset (Y)", 5, 1, -50, 50, "u", function(v) AURA_CFG.height_offset = v / 10 end)

    local SecSize = TabDim:Section("Particle & Spark Sizes")
    SecSize:Slider("Particle Size", 30, 1, 5, 120, "px", function(v) AURA_CFG.particle_size = v / 10 end)
    SecSize:Slider("Spark Size", 15, 1, 2, 80, "px", function(v) AURA_CFG.spark_size = v / 10 end)
    SecSize:Slider("Glow Scale", 25, 1, 10, 60, "x", function(v) AURA_CFG.glow_scale = v / 10 end)
    SecSize:Slider("Line Thickness", 15, 1, 10, 50, "px", function(v) AURA_CFG.thickness = v / 10 end)

    -- Tab 3: Speeds & Waves
    local TabSpd = Win:Tab("Dynamics & Motion")
    local SecCounts = TabSpd:Section("Particle Counts")
    SecCounts:Slider("Main Particle Count", 35, 1, 5, 80, "", function(v) AURA_CFG.particle_count = v end)
    SecCounts:Slider("Spark Particle Count", 20, 1, 2, 40, "", function(v) AURA_CFG.spark_count = v end)

    local SecMotion = TabSpd:Section("Rotation & Wave Speeds")
    SecMotion:Slider("Rotation Speed", 20, 1, 0, 100, "", function(v) AURA_CFG.rotation_speed = v / 10 end)
    SecMotion:Slider("Spark Speed Multiplier", 14, 1, 5, 30, "x", function(v) AURA_CFG.spark_speed_mult = v / 10 end)
    SecMotion:Slider("Wave Speed", 20, 1, 0, 100, "", function(v) AURA_CFG.wave_speed = v / 10 end)
    SecMotion:Slider("Wave Amplitude", 5, 1, 0, 30, "", function(v) AURA_CFG.wave_amplitude = v / 10 end)
    SecMotion:Slider("Vertical Bobbing Speed", 15, 1, 0, 100, "", function(v) AURA_CFG.bobbing_speed = v / 10 end)

    -- Tab 4: Colors & Opacity
    local TabCol = Win:Tab("Colors & FX")
    local SecCol = TabCol:Section("Colors & Rainbow")
    SecCol:Colorpicker("Main Particle Color", AURA_CFG.main_color, function(v) AURA_CFG.main_color = v end)
    SecCol:Colorpicker("Spark Color", AURA_CFG.spark_color, function(v) AURA_CFG.spark_color = v end)
    SecCol:Colorpicker("Glow Color", AURA_CFG.glow_color, function(v) AURA_CFG.glow_color = v end)
    SecCol:Toggle("Rainbow Main Color", AURA_CFG.rainbow_main, function(v) AURA_CFG.rainbow_main = v end)
    SecCol:Toggle("Rainbow Spark Color", AURA_CFG.rainbow_sparks, function(v) AURA_CFG.rainbow_sparks = v end)
    SecCol:Slider("Rainbow Speed", 10, 1, 1, 50, "x", function(v) AURA_CFG.rainbow_speed = v / 10 end)

    local SecFX = TabCol:Section("Opacity & Intensity")
    SecFX:Slider("Glow Intensity", 35, 1, 0, 100, "%", function(v) AURA_CFG.glow_intensity = v / 100 end)
    SecFX:Slider("Master Opacity", 85, 1, 10, 100, "%", function(v) AURA_CFG.opacity = v / 100 end)

    Lib:Notify("Matcha Aura Studio", "Full Customization Loaded!", 4)
end

-- External Global APIs
_G.set_aura_color = function(r, g, b)
    AURA_CFG.main_color = Color3.fromRGB(r * 255, g * 255, b * 255)
end

_G.set_spark_color = function(r, g, b)
    AURA_CFG.spark_color = Color3.fromRGB(r * 255, g * 255, b * 255)
end

_G.set_aura_enabled = function(enabled)
    AURA_CFG.enabled = enabled
end

_G.get_aura_config = function()
    return AURA_CFG
end

print("[Matcha 3D Aura Studio]: Loaded Successfully! Fully customizable INS-UI active.")
