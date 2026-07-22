-- ==============================================================================
-- 🔮 MATCHA 3D AURA SYSTEM (Converted from Photon API to Matcha LuaVM)
-- Docs: https://huoadf.github.io/matcha-docs/
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration Table
local aura_config = {
    enabled = true,
    main_color = Color3.fromRGB(235, 8, 255),
    spark_color = Color3.fromRGB(255, 20, 255),
    particle_count = 30,
    spark_count = 15,
    radius = 4.0,
    inner_radius = 1.5,
    particle_size = 3.0,
    spark_size = 1.5,
    rotation_speed = 2.0,
    wave_speed = 2.0,
    filled_particles = false,
    glow_intensity = 0.3,
    opacity = 1.0
}

-- Drawing Pools (Pre-allocated for maximum performance)
local MAX_PARTICLES = 80
local MAX_SPARKS = 40

local particle_pool = {}
local spark_pool = {}
local glow_pool = {}

for i = 1, MAX_PARTICLES do
    local c = Drawing.new("Circle")
    c.Visible = false
    c.Thickness = 1.5
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

-- Helper Functions
local function hideAll()
    for i = 1, MAX_PARTICLES do particle_pool[i].Visible = false end
    for i = 1, MAX_SPARKS do
        spark_pool[i].Visible = false
        glow_pool[i].Visible = false
    end
end

local function get_clamped_radius(base_radius, inner, outer)
    return math.max(inner, math.min(outer, base_radius))
end

-- Render Loop
local time = 0
local connection

connection = RunService.Heartbeat:Connect(function(dt)
    if not aura_config.enabled then
        hideAll()
        return
    end

    local character = LocalPlayer and LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        hideAll()
        return
    end

    local root_pos = root.Position
    time = time + dt

    local main_color = aura_config.main_color
    local spark_color = aura_config.spark_color
    local opacity = aura_config.opacity
    local filled = aura_config.filled_particles
    local inner = aura_config.inner_radius
    local outer = aura_config.radius

    -- 1. Main Particles (Orbiting around character)
    local pCount = math.min(math.floor(aura_config.particle_count), MAX_PARTICLES)
    for i = 1, pCount do
        local c = particle_pool[i]
        local angle = (i / pCount) * math.pi * 2 + time * aura_config.rotation_speed
        local r = get_clamped_radius(
            outer - 0.5 + math.sin(time * aura_config.wave_speed + i * 0.5) * 0.5,
            inner,
            outer
        )

        local x = root_pos.X + math.cos(angle) * r
        local z = root_pos.Z + math.sin(angle) * r
        local y = root_pos.Y + 0.5 + math.sin(time * 1.5 + i * 0.3) * 0.5

        local screen_pos, onScreen = WorldToScreen(Vector3.new(x, y, z))

        if onScreen then
            local size = aura_config.particle_size + math.sin(time * 2.5 + i * 0.5) * 0.5
            local alpha = 0.3 + math.sin(time * 2.0 + i * 0.3) * 0.3

            c.Position = Vector2.new(screen_pos.X, screen_pos.Y)
            c.Radius = math.max(size, 0.5)
            c.Color = main_color
            c.Transparency = math.clamp(alpha * opacity, 0, 1)
            c.Filled = filled
            c.Visible = true
        else
            c.Visible = false
        end
    end
    for i = pCount + 1, MAX_PARTICLES do particle_pool[i].Visible = false end

    -- 2. Spark Particles (Fast orbiting sparks + optional glow)
    local sCount = math.min(math.floor(aura_config.spark_count), MAX_SPARKS)
    for i = 1, sCount do
        local s = spark_pool[i]
        local g = glow_pool[i]
        local angle = (i / sCount) * math.pi * 2 + time * (aura_config.rotation_speed * 1.3)
        local r = get_clamped_radius(
            outer * 0.6 + math.sin(time * 2.0 + i * 0.5) * 0.8,
            inner + 0.3,
            outer * 0.9
        )

        local x = root_pos.X + math.cos(angle) * r
        local z = root_pos.Z + math.sin(angle) * r
        local y = root_pos.Y + 0.5 + math.sin(time * 2.5 + i * 0.4) * 1.2

        local screen_pos, onScreen = WorldToScreen(Vector3.new(x, y, z))

        if onScreen then
            local size = aura_config.spark_size + math.sin(time * 4.0 + i * 1.5) * 0.3
            local alpha = 0.4 + math.sin(time * 3.0 + i * 0.7) * 0.3

            s.Position = Vector2.new(screen_pos.X, screen_pos.Y)
            s.Radius = math.max(size, 0.3)
            s.Color = spark_color
            s.Transparency = math.clamp(alpha * opacity, 0, 1)
            s.Visible = true

            -- Spark Glow
            if aura_config.glow_intensity > 0 then
                local glow_size = size * 2.5
                local glow_alpha = aura_config.glow_intensity * alpha * opacity * 0.3
                g.Position = Vector2.new(screen_pos.X, screen_pos.Y)
                g.Radius = glow_size
                g.Color = spark_color
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
end)

-- INS-UI Interface Setup
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
    local Win = Lib:CreateWindow("Aura Configuration")
    local Tab = Win:Tab("Main")

    local SecGen = Tab:Section("General")
    SecGen:Toggle("Enable Aura", aura_config.enabled, function(v) aura_config.enabled = v end)
    SecGen:Toggle("Filled Particles", aura_config.filled_particles, function(v) aura_config.filled_particles = v end)

    local SecCol = Tab:Section("Colors")
    SecCol:Colorpicker("Main Color", aura_config.main_color, function(v) aura_config.main_color = v end)
    SecCol:Colorpicker("Spark Color", aura_config.spark_color, function(v) aura_config.spark_color = v end)

    local SecSize = Tab:Section("Sizes & Radius")
    SecSize:Slider("Outer Radius", 20, 2, 4, 100, "", function(v) aura_config.radius = v / 10 end)
    SecSize:Slider("Inner Radius", 5, 0, 1.5, 30, "", function(v) aura_config.inner_radius = v / 10 end)
    SecSize:Slider("Particle Size", 5, 0, 3, 60, "", function(v) aura_config.particle_size = v / 10 end)
    SecSize:Slider("Spark Size", 3, 0, 1.5, 30, "", function(v) aura_config.spark_size = v / 10 end)

    local SecSpd = Tab:Section("Counts & Speeds")
    SecSpd:Slider("Particle Count", 5, 5, 30, 80, "", function(v) aura_config.particle_count = v end)
    SecSpd:Slider("Spark Count", 2, 2, 15, 40, "", function(v) aura_config.spark_count = v end)
    SecSpd:Slider("Rotation Speed", 1, 0, 2, 50, "", function(v) aura_config.rotation_speed = v / 10 end)
    SecSpd:Slider("Wave Speed", 1, 0, 2, 40, "", function(v) aura_config.wave_speed = v / 10 end)
    SecSpd:Slider("Glow Intensity", 0, 0, 0.3, 10, "", function(v) aura_config.glow_intensity = v / 10 end)
    SecSpd:Slider("Opacity", 1, 0, 1, 10, "", function(v) aura_config.opacity = v / 10 end)

    Lib:Notify("Aura System", "Loaded! Particles + Sparks active.", 4)
end

-- External Global Controls
_G.set_aura_color = function(r, g, b)
    aura_config.main_color = Color3.fromRGB(r * 255, g * 255, b * 255)
end

_G.set_aura_enabled = function(enabled)
    aura_config.enabled = enabled
end

_G.get_aura_config = function()
    return aura_config
end

print("[Matcha Aura]: Loaded successfully! (Particles + Sparks)")
