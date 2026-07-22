-- ==============================================================================
-- 🔮 MATCHA 3D AURA SCRIPT (STANDALONE AURA SUITE)
-- Docs: https://huoadf.github.io/matcha-docs/
-- Repo: https://github.com/huoadf/matcha3d
-- ==============================================================================

-- 🎨 Custom Aura Mesh Configuration (User Override)
_G.customVerts = _G.customVerts or {
    {0,  2.2, 0},     -- Top Point
    {-1.5, 0, -1.5}, -- Corner 1
    {1.5,  0, -1.5}, -- Corner 2
    {1.5,  0,  1.5}, -- Corner 3
    {-1.5, 0,  1.5}, -- Corner 4
    {0, -2.2, 0}      -- Bottom Point
}

_G.customTris = _G.customTris or {
    {1, 2, 3}, {1, 3, 4}, {1, 4, 5}, {1, 5, 2}, -- Top Faces
    {6, 3, 2}, {6, 4, 3}, {6, 5, 4}, {6, 2, 5}  -- Bottom Faces
}

_G.customColor = _G.customColor or Color3.fromRGB(238, 138, 255)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local _WTS = WorldToScreen
local V2_ZERO = Vector2.new(0, 0)

local function WTS(pos)
    local s, on = _WTS(pos)
    if s then return s, on end
    return V2_ZERO, false
end

-- Config & State
local AURA_CFG = {
    FPS = 120,
    TRANSPARENCY = 0.45,
    RAINBOW_SPEED = 1.0,
    TARGET_MODE = "Closest", -- "LocalPlayer", "Closest", "Random"
    TARGET_LOCK_ON = false,
}

local AURA_KEYS = {
    "torus_shield",
    "trefoil_knot",
    "mobius_ring",
    "hyper_barrier",
    "sacred_gem",
    "orbit_satellites",
    "custom_aura"
}

local AURA_NAME = {
    torus_shield     = "Torus Energy Shield",
    trefoil_knot     = "Trefoil Knot Weave",
    mobius_ring      = "Möbius Ribbon Field",
    hyper_barrier    = "Hyperboloid Barrier",
    sacred_gem       = "Sacred Octahedron",
    orbit_satellites = "Orbiting Satellites",
    custom_aura      = "Custom Mesh Aura"
}

-- Feature State Tables
local EN, RB, WIRE = {}, {}, {}
local SPIN_ON, SPIN_SPD, SPIN_ANG = {}, {}, {}
local PULSE_ON, PULSE_SPD, PULSE_AMP = {}, {}, {}
local SCALE, RADIUS, OFF_Y = {}, {}, {}
local COL = {}

for _, k in ipairs(AURA_KEYS) do
    EN[k]        = (k == "torus_shield")
    RB[k]        = true
    WIRE[k]      = false
    SPIN_ON[k]   = true
    SPIN_SPD[k]  = 1.5
    SPIN_ANG[k]  = 0
    PULSE_ON[k]  = true
    PULSE_SPD[k] = 2.0
    PULSE_AMP[k] = 0.15
    SCALE[k]     = 1.0
    RADIUS[k]    = 2.0
    OFF_Y[k]     = 0.5
    COL[k]       = (k == "custom_aura") and _G.customColor or Color3.fromRGB(180, 100, 255)
end

-- ── Color Helpers ─────────────────────────────────────────────────────────────
local COLOR_NOW = 0
local function rainbowColor(offset)
    local h = ((COLOR_NOW * AURA_CFG.RAINBOW_SPEED) + (offset or 0)) % 1
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

-- ── 3D Projection Helpers ─────────────────────────────────────────────────────
local function rotateVec(x, y, z, rx, ry, rz)
    local cx,sx = math.cos(rx),math.sin(rx)
    local cy,sy = math.cos(ry),math.sin(ry)
    local cz,sz = math.cos(rz),math.sin(rz)
    y,z = y*cx-z*sx, y*sx+z*cx
    x,z = x*cy+z*sy, -x*sy+z*cy
    x,y = x*cz-y*sz, x*sz+y*cz
    return x,y,z
end

local function projLocal(key, ox, oy, oz, lx, ly, lz)
    local sc = SCALE[key] or 1.0
    local ry = SPIN_ANG[key] or 0
    local rx, rz = 0, 0
    local m11,m12,m13 = rotateVec(1,0,0,rx,ry,rz)
    local m21,m22,m23 = rotateVec(0,1,0,rx,ry,rz)
    local m31,m32,m33 = rotateVec(0,0,1,rx,ry,rz)

    local lx2, ly2, lz2 = lx * sc, ly * sc, lz * sc
    local wx = ox + m11*lx2 + m12*ly2 + m13*lz2
    local wy = oy + m21*lx2 + m22*ly2 + m23*lz2
    local wz = oz + m31*lx2 + m32*ly2 + m33*lz2

    local s, on = WTS(Vector3.new(wx, wy, wz))
    return {x = s.X, y = s.Y, on = on}
end

-- ── Triangle Pool Allocation ──────────────────────────────────────────────────
local TRIS = {}
local function makeTris(key, count)
    local arr = {}
    for i = 1, count do
        local t = Drawing.new("Triangle")
        t.Color = COL[key] or Color3.fromRGB(255,255,255)
        t.Filled = true
        t.Visible = false
        t.ZIndex = 5
        t.Transparency = AURA_CFG.TRANSPARENCY
        arr[i] = t
    end
    TRIS[key] = arr
end

makeTris("torus_shield",     256)
makeTris("trefoil_knot",     192)
makeTris("mobius_ring",      128)
makeTris("hyper_barrier",    320)
makeTris("sacred_gem",       8)
makeTris("orbit_satellites", 32)
makeTris("custom_aura",      512)

local function hidePool(pool)
    if not pool then return end
    for i = 1, #pool do pool[i].Visible = false end
end

local function setTriP(pool, idx, col, p1, p2, p3, wireframe)
    local t = pool[idx]
    if not t then return end
    if p1.on or p2.on or p3.on then
        t.PointA = Vector2.new(p1.x, p1.y)
        t.PointB = Vector2.new(p2.x, p2.y)
        t.PointC = Vector2.new(p3.x, p3.y)
        t.Color = col
        t.Filled = not wireframe
        t.Transparency = AURA_CFG.TRANSPARENCY
        t.Visible = true
    else
        t.Visible = false
    end
end

-- ── 3D Aura Render Functions ──────────────────────────────────────────────────
local function drawTorusShield(pool, ox, oy, oz, key, col, wire)
    local R = RADIUS[key] or 2.0
    local rTube = 0.45
    local segs, tubeSegs = 16, 8
    local ti = 1

    for i = 0, segs - 1 do
        local u1 = (i / segs) * math.pi * 2
        local u2 = ((i + 1) / segs) * math.pi * 2
        for j = 0, tubeSegs - 1 do
            local v1 = (j / tubeSegs) * math.pi * 2
            local v2 = ((j + 1) / tubeSegs) * math.pi * 2

            local function torusPoint(u, v)
                local x = (R + rTube * math.cos(v)) * math.cos(u)
                local y = rTube * math.sin(v)
                local z = (R + rTube * math.cos(v)) * math.sin(u)
                return projLocal(key, ox, oy, oz, x, y, z)
            end

            local p1 = torusPoint(u1, v1)
            local p2 = torusPoint(u2, v1)
            local p3 = torusPoint(u1, v2)
            local p4 = torusPoint(u2, v2)

            setTriP(pool, ti, col, p1, p2, p3, wire); ti = ti + 1
            setTriP(pool, ti, col, p2, p4, p3, wire); ti = ti + 1
        end
    end
    for i = ti, #pool do pool[i].Visible = false end
end

local function drawTrefoilKnot(pool, ox, oy, oz, key, col, wire)
    local R = RADIUS[key] or 2.0
    local w = 0.35
    local segs = 48
    local ti = 1

    for i = 1, segs do
        local t1 = ((i - 1) / segs) * math.pi * 2
        local t2 = (i / segs) * math.pi * 2

        local function knotCenter(t)
            local x = (math.sin(t) + 2 * math.sin(2 * t)) * R * 0.4
            local y = -math.sin(3 * t) * R * 0.4
            local z = (math.cos(t) - 2 * math.cos(2 * t)) * R * 0.4
            return x, y, z
        end

        local x1, y1, z1 = knotCenter(t1)
        local x2, y2, z2 = knotCenter(t2)

        local p1a = projLocal(key, ox, oy, oz, x1 - w, y1, z1 - w)
        local p1b = projLocal(key, ox, oy, oz, x1 + w, y1, z1 + w)
        local p2a = projLocal(key, ox, oy, oz, x2 - w, y2, z2 - w)
        local p2b = projLocal(key, ox, oy, oz, x2 + w, y2, z2 + w)

        setTriP(pool, ti, col, p1a, p1b, p2a, wire); ti = ti + 1
        setTriP(pool, ti, col, p1b, p2b, p2a, wire); ti = ti + 1
    end
    for i = ti, #pool do pool[i].Visible = false end
end

local function drawMobiusRing(pool, ox, oy, oz, key, col, wire)
    local R = RADIUS[key] or 2.0
    local w = 0.4
    local segs = 32
    local ti = 1

    for i = 0, segs - 1 do
        local u1 = (i / segs) * math.pi * 2
        local u2 = ((i + 1) / segs) * math.pi * 2

        local function mobiusPoint(u, v)
            local cosU, sinU = math.cos(u), math.sin(u)
            local cosHalf, sinHalf = math.cos(u / 2), math.sin(u / 2)
            local x = (R + v * cosHalf) * cosU
            local y = v * sinHalf
            local z = (R + v * cosHalf) * sinU
            return projLocal(key, ox, oy, oz, x, y, z)
        end

        local p1 = mobiusPoint(u1, -w)
        local p2 = mobiusPoint(u1,  w)
        local p3 = mobiusPoint(u2, -w)
        local p4 = mobiusPoint(u2,  w)

        setTriP(pool, ti, col, p1, p2, p3, wire); ti = ti + 1
        setTriP(pool, ti, col, p2, p4, p3, wire); ti = ti + 1
    end
    for i = ti, #pool do pool[i].Visible = false end
end

local function drawHyperBarrier(pool, ox, oy, oz, key, col, wire)
    local Rbase = RADIUS[key] or 2.2
    local Rwaist = 0.8
    local H = 2.5
    local rings, segs = 10, 16
    local ti = 1

    for ri = 0, rings - 1 do
        local t1 = (ri / rings) * 2 - 1
        local t2 = ((ri + 1) / rings) * 2 - 1
        local r1 = math.sqrt(Rwaist*Rwaist + (t1*t1)*(Rbase*Rbase - Rwaist*Rwaist))
        local r2 = math.sqrt(Rwaist*Rwaist + (t2*t2)*(Rbase*Rbase - Rwaist*Rwaist))
        local y1 = t1 * (H / 2)
        local y2 = t2 * (H / 2)

        for s = 0, segs - 1 do
            local a1 = (s / segs) * math.pi * 2
            local a2 = ((s + 1) / segs) * math.pi * 2

            local p1 = projLocal(key, ox, oy, oz, r1 * math.cos(a1), y1, r1 * math.sin(a1))
            local p2 = projLocal(key, ox, oy, oz, r1 * math.cos(a2), y1, r1 * math.sin(a2))
            local p3 = projLocal(key, ox, oy, oz, r2 * math.cos(a1), y2, r2 * math.sin(a1))
            local p4 = projLocal(key, ox, oy, oz, r2 * math.cos(a2), y2, r2 * math.sin(a2))

            setTriP(pool, ti, col, p1, p2, p3, wire); ti = ti + 1
            setTriP(pool, ti, col, p2, p4, p3, wire); ti = ti + 1
        end
    end
    for i = ti, #pool do pool[i].Visible = false end
end

local function drawSacredGem(pool, ox, oy, oz, key, col, wire)
    local R = RADIUS[key] or 1.5
    local H = 2.2

    local pTop = projLocal(key, ox, oy, oz,  0,  H,  0)
    local p1   = projLocal(key, ox, oy, oz, -R,  0, -R)
    local p2   = projLocal(key, ox, oy, oz,  R,  0, -R)
    local p3   = projLocal(key, ox, oy, oz,  R,  0,  R)
    local p4   = projLocal(key, ox, oy, oz, -R,  0,  R)
    local pBot = projLocal(key, ox, oy, oz,  0, -H,  0)

    setTriP(pool, 1, col, pTop, p1, p2, wire)
    setTriP(pool, 2, col, pTop, p2, p3, wire)
    setTriP(pool, 3, col, pTop, p3, p4, wire)
    setTriP(pool, 4, col, pTop, p4, p1, wire)
    setTriP(pool, 5, col, pBot, p2, p1, wire)
    setTriP(pool, 6, col, pBot, p3, p2, wire)
    setTriP(pool, 7, col, pBot, p4, p3, wire)
    setTriP(pool, 8, col, pBot, p1, p4, wire)
end

local function drawOrbitSatellites(pool, ox, oy, oz, key, col, wire)
    local R = RADIUS[key] or 2.5
    local nSats = 4
    local ti = 1

    for i = 1, nSats do
        local a = ((i - 1) / nSats) * math.pi * 2 + SPIN_ANG[key]
        local sx = math.cos(a) * R
        local sz = math.sin(a) * R
        local sy = math.sin(a * 2) * 0.5

        local pTop = projLocal(key, ox, oy, oz, sx, sy + 0.6, sz)
        local p1   = projLocal(key, ox, oy, oz, sx - 0.4, sy, sz - 0.4)
        local p2   = projLocal(key, ox, oy, oz, sx + 0.4, sy, sz - 0.4)
        local p3   = projLocal(key, ox, oy, oz, sx + 0.4, sy, sz + 0.4)
        local p4   = projLocal(key, ox, oy, oz, sx - 0.4, sy, sz + 0.4)
        local pBot = projLocal(key, ox, oy, oz, sx, sy - 0.6, sz)

        setTriP(pool, ti, col, pTop, p1, p2, wire); ti = ti + 1
        setTriP(pool, ti, col, pTop, p2, p3, wire); ti = ti + 1
        setTriP(pool, ti, col, pTop, p3, p4, wire); ti = ti + 1
        setTriP(pool, ti, col, pTop, p4, p1, wire); ti = ti + 1
        setTriP(pool, ti, col, pBot, p2, p1, wire); ti = ti + 1
        setTriP(pool, ti, col, pBot, p3, p2, wire); ti = ti + 1
        setTriP(pool, ti, col, pBot, p4, p3, wire); ti = ti + 1
        setTriP(pool, ti, col, pBot, p1, p4, wire); ti = ti + 1
    end
    for i = ti, #pool do pool[i].Visible = false end
end

local function drawCustomAura(pool, ox, oy, oz, key, col, wire)
    local verts = _G.customVerts
    local tris  = _G.customTris
    if not verts or not tris then hidePool(pool); return end

    local projected = {}
    for i, v in ipairs(verts) do
        if type(v) == "table" then
            local vx = type(v[1]) == "number" and v[1] or 0
            local vy = type(v[2]) == "number" and v[2] or 0
            local vz = type(v[3]) == "number" and v[3] or 0
            projected[i] = projLocal(key, ox, oy, oz, vx, vy, vz)
        end
    end

    local ti = 1
    for fIdx = 1, math.min(#tris, #pool) do
        local f = tris[fIdx]
        if type(f) == "table" and f[1] and f[2] and f[3] then
            local p1, p2, p3 = projected[f[1]], projected[f[2]], projected[f[3]]
            if p1 and p2 and p3 then
                setTriP(pool, ti, col, p1, p2, p3, wire); ti = ti + 1
            end
        end
    end
    for i = ti, #pool do pool[i].Visible = false end
end

local AURA_DRAW_FN = {
    torus_shield     = drawTorusShield,
    trefoil_knot     = drawTrefoilKnot,
    mobius_ring      = drawMobiusRing,
    hyper_barrier    = drawHyperBarrier,
    sacred_gem       = drawSacredGem,
    orbit_satellites = drawOrbitSatellites,
    custom_aura      = drawCustomAura
}

-- ── Target Selection Helper ───────────────────────────────────────────────────
local function getTargetHRP()
    if AURA_CFG.TARGET_MODE == "LocalPlayer" or not AURA_CFG.TARGET_LOCK_ON then
        local char = LocalPlayer and LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local myHRP = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local players = Players:GetPlayers()
    local candidates = {}
    for _, p in ipairs(players) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local dist = (hrp.Position - myHRP.Position).Magnitude
            candidates[#candidates + 1] = {hrp = hrp, dist = dist}
        end
    end

    if #candidates == 0 then return myHRP end

    if AURA_CFG.TARGET_MODE == "Closest" then
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
        return candidates[1].hrp
    elseif AURA_CFG.TARGET_MODE == "Random" then
        return candidates[math.random(1, #candidates)].hrp
    end

    return myHRP
end

-- ── Main Render Heartbeat Loop ────────────────────────────────────────────────
local RunService = game:GetService("RunService")
local lastTick = tick()

RunService.Heartbeat:Connect(function()
    local now = tick()
    local dt = math.clamp(now - lastTick, 0.001, 0.1)
    lastTick = now

    COLOR_NOW = (COLOR_NOW + dt * 0.25) % 1.0

    local targetHRP = getTargetHRP()
    if not targetHRP then
        for _, k in ipairs(AURA_KEYS) do hidePool(TRIS[k]) end
        return
    end

    local pos = targetHRP.Position

    for _, key in ipairs(AURA_KEYS) do
        local pool = TRIS[key]
        if EN[key] then
            -- Spin Animation
            if SPIN_ON[key] then
                SPIN_ANG[key] = (SPIN_ANG[key] + dt * SPIN_SPD[key]) % (math.pi * 2)
            end

            -- Pulse Animation
            if PULSE_ON[key] then
                SCALE[key] = 1.0 + math.sin(now * PULSE_SPD[key] * math.pi * 2) * PULSE_AMP[key]
            end

            -- Color Selection
            local resolvedCol = RB[key] and rainbowColor() or COL[key]

            -- Render 3D Aura
            local drawFn = AURA_DRAW_FN[key]
            if drawFn then
                drawFn(pool, pos.X, pos.Y + OFF_Y[key], pos.Z, key, resolvedCol, WIRE[key])
            end
        else
            hidePool(pool)
        end
    end
end)

-- ── INS-UI Menu Setup ─────────────────────────────────────────────────────────
local okUI, Lib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/huoadf/matcha3d/main/ins_uilib.lua"))()
end)

if okUI and Lib and Lib.CreateWindow then
    local Win = Lib:CreateWindow("Matcha 3D Aura Suite")
    local MainTab = Win:Tab("3D Auras")

    -- Target Selector
    local SecTarget = MainTab:Section("Target Lock & ESP")
    SecTarget:Toggle("Lock-On Target Player", false, function(v) AURA_CFG.TARGET_LOCK_ON = v end)
    SecTarget:Dropdown("Target Selection Mode", {"LocalPlayer", "Closest", "Random"}, "LocalPlayer", function(v)
        AURA_CFG.TARGET_MODE = v
    end)

    -- Auras Controls
    for _, key in ipairs(AURA_KEYS) do
        local Sec = MainTab:Section(AURA_NAME[key])
        Sec:Toggle("Enable Aura", EN[key], function(v) EN[key] = v end)
        Sec:Toggle("Rainbow Cycle", RB[key], function(v) RB[key] = v end)
        Sec:Toggle("Wireframe Mode", WIRE[key], function(v) WIRE[key] = v end)
        Sec:Slider("Radius / Scale", 0.5, 6.0, RADIUS[key], function(v) RADIUS[key] = v end)
        Sec:Slider("Height Offset", -3.0, 5.0, OFF_Y[key], function(v) OFF_Y[key] = v end)
        Sec:Slider("Spin Speed", 0.0, 10.0, SPIN_SPD[key], function(v) SPIN_SPD[key] = v end)
        Sec:Colorpicker("Aura Color", COL[key], function(v) COL[key] = v end)
    end

    Lib:Notify("Matcha 3D Aura", "Loaded Successfully!", 4)
else
    print("[Matcha 3D Aura]: Loaded! Controls set to _G / UI defaults.")
end
