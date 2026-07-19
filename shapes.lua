local Players = game:GetService("Players")
local _WTS = WorldToScreen
local V2_ZERO = Vector2.new(0, 0)
local function WTS(pos)
    local s, on = _WTS(pos)
    if s then return s, on end
    return V2_ZERO, false
end
local CFG = {
    FPS           = 120,
    TRANSPARENCY  = 0.5,
    RAINBOW_SPEED = 1.0,
    SEGMENTS   = 24, HAT_RADIUS = 1.8, HAT_HEIGHT = 1.3,
    COL_CONE   = Color3.fromRGB(200, 200, 200),
    CUBE_SIZE  = 2.0,
    COL_CUBE   = Color3.fromRGB(80, 200, 255),
    SPHERE_RADIUS = 1.2, SPHERE_SEGS = 14, SPHERE_RINGS = 7,
    COL_SPHERE    = Color3.fromRGB(80, 180, 255),
    DIAM_RADIUS = 1.2, DIAM_HEIGHT = 2.2,
    COL_DIAM    = Color3.fromRGB(120, 220, 255),
    TORUS_RADIUS = 1.5, TORUS_TUBE = 0.45, TORUS_SEGS = 16, TORUS_TUBE_SEG = 8,
    COL_TORUS    = Color3.fromRGB(255, 80, 200),
    STAR_OUTER = 1.8, STAR_INNER = 0.7,
    COL_STAR   = Color3.fromRGB(255, 220, 0),
    CROWN_RADIUS = 1.4, CROWN_HEIGHT = 1.6, CROWN_N = 5,
    COL_CROWN    = Color3.fromRGB(255, 200, 30),
    PYRA_RADIUS = 1.5, PYRA_HEIGHT = 2.0,
    COL_PYRA    = Color3.fromRGB(200, 100, 50),
    CYLI_SEGS = 12, CYLI_RADIUS = 1.2, CYLI_HEIGHT = 1.8,
    COL_CYLI  = Color3.fromRGB(100, 180, 100),
    CAPS_SEGS = 12, CAPS_RADIUS = 1.0, CAPS_HEIGHT = 1.5,
    COL_CAPS  = Color3.fromRGB(180, 100, 200),
    HELIX_SEGS = 36, HELIX_RADIUS = 1.5, HELIX_TURNS = 2.5, HELIX_HEIGHT = 2.0,
    COL_HELIX  = Color3.fromRGB(255, 150, 50),
    ICOSA_RADIUS = 1.3,
    COL_ICOSA    = Color3.fromRGB(200, 50, 100),
    TETRA_RADIUS = 1.5,
    COL_TETRA    = Color3.fromRGB(100, 255, 100),
    PRISM_RADIUS = 1.3, PRISM_HEIGHT = 1.8,
    COL_PRISM    = Color3.fromRGB(255, 100, 100),
    ARROW_SEGS = 8, ARROW_RADIUS = 0.4, ARROW_HEAD_RADIUS = 0.9,
    ARROW_SHAFT_H = 1.5, ARROW_HEAD_H = 1.0,
    COL_ARROW = Color3.fromRGB(255, 200, 50),
    DISC_SEGS = 16, DISC_RADIUS = 2.0, DISC_THICK = 0.2,
    COL_DISC  = Color3.fromRGB(50, 150, 255),
    CROSS_ARM = 1.0, CROSS_WIDTH = 0.35, CROSS_HEIGHT = 2.4,
    COL_CROSS = Color3.fromRGB(255, 50, 50),
    MOBIUS_RADIUS = 1.5, MOBIUS_WIDTH = 0.8, MOBIUS_SEGS = 32,
    COL_MOBIUS = Color3.fromRGB(180, 100, 255),
    KNOT_SEGS = 48, KNOT_RADIUS = 2.0, KNOT_WIDTH = 0.4,
    COL_KNOT = Color3.fromRGB(255, 120, 200),
    HYPER_SEGS = 16, HYPER_RINGS = 10, HYPER_RADIUS = 1.6, HYPER_WAIST = 0.5, HYPER_HEIGHT = 2.5,
    COL_HYPER = Color3.fromRGB(80, 220, 180),
    COL_CUSTOM = Color3.fromRGB(255, 230, 80),
}
local CROSS_STYLE = "Cross"
local REFRESH_RATE = 1 / CFG.FPS
local SHAPE_KEYS = {
    "cone","cube","sphere","diam","torus","star","crown",
    "pyra","cyl","caps","helix","icosa","tetra",
    "prism","arrow","disc","cross","mobius","knot","hyper","custom",
}
local TARGET_LOCK_ON = false
local TARGET_LOCK_MODE = "Closest"
local TARGET_ON = {}
local TARGET_MODE = {}
local EN, RB = {}, {}
local SPIN_ON, SPIN_SPD, SPIN_ANG = {}, {}, {}
local ROT_X, ROT_Y, ROT_Z = {}, {}, {}
local OFF_X, OFF_Y, OFF_Z = {}, {}, {}
for _, k in ipairs(SHAPE_KEYS) do
    EN[k]=false; RB[k]=false
    SPIN_ON[k]=false; SPIN_SPD[k]=1.0; SPIN_ANG[k]=0
    ROT_X[k]=0; ROT_Y[k]=0; ROT_Z[k]=0
    OFF_X[k]=0; OFF_Y[k]=3.0; OFF_Z[k]=0
end
local LOCK_ROT      = false
local LOCK_CUBE_ROT = false
local HRP_EULER     = { x=0, y=0, z=0 }
local PLOCK_ROT, PLOCK_CUBE_ROT = {}, {}
local TRANSP     = {}
local PULSE_ON, PULSE_SPD, PULSE_AMP = {}, {}, {}
local ORBIT_ON, ORBIT_R, ORBIT_SPD, ORBIT_ANG = {}, {}, {}, {}
local SCALEP_ON, SCALEP_SPD, SCALEP_AMP, SCALE = {}, {}, {}, {}

-- NEW: per-shape feature state tables
local WIRE_ON        = {}  -- wireframe mode
local TRAIL_ON       = {}  -- trail/ghost effect
local TRAIL_LEN      = {}  -- number of trail ghosts
local TRAIL_FADE     = {}  -- trail fade strength
local BOUNCE_ON      = {}  -- Y bounce
local BOUNCE_SPD     = {}  -- bounce speed
local BOUNCE_AMP     = {}  -- bounce amplitude
local FIG8_ON        = {}  -- figure-8 orbit
local FIG8_R         = {}  -- figure-8 radius
local FIG8_SPD       = {}  -- figure-8 speed
local FIG8_ANG       = {}  -- figure-8 angle accumulator
local CSPIN_ON       = {}  -- counter-spin
local CSPIN_SPD      = {}  -- counter-spin speed
local CSPIN_ANG      = {}  -- counter-spin angle accumulator
local COLDIST_ON     = {}  -- color-by-distance
local COL_NEAR       = {}  -- near color
local COL_FAR        = {}  -- far color
local COLDIST_MAX    = {}  -- distance for full far color
local COLDIST_MAX_SQ = {}
local OUTLINE_ON     = {}  -- outline/edge glow
local OUTLINE_COL    = {}  -- outline color
local OUTLINE_SCALE  = {}  -- outline scale factor
local SHAKE_ON       = {}  -- shake/jitter
local SHAKE_AMP      = {}  -- shake amplitude
local SPEED_SCALE_ON = {}  -- size linked to speed
local SPEED_SCALE_MAX= {}  -- speed at which scale is maximum
local COLCYCLE_ON    = {}  -- dual-color ping-pong
local COLCYCLE_A     = {}  -- cycle color A
local COLCYCLE_B     = {}  -- cycle color B
local COLCYCLE_SPD   = {}  -- cycle speed

-- motion / velocity FX
local HEATMAP_ON     = {}  -- Y velocity heat map (blue fall, red rise)
local HEATMAP_RANGE  = {}
local LERP_ON        = {}  -- position lag / smooth follow
local LERP_SPD       = {}
local LERP_POS       = {}  -- smoothed world origin
local CHROMA_ON      = {}  -- RGB channel split
local CHROMA_OFF     = {}  -- screen-space X offset (px)
local DRIFT_ON       = {}  -- idle random walk
local DRIFT_AMP      = {}
local DRIFT_SPD      = {}
local DRIFT_OFF      = {}
local DRIFT_TGT      = {}
local ECHO_ON        = {}  -- expanding sonar ring
local ECHO_INT       = {}
local ECHO_SPD       = {}
local ECHO_MAXR      = {}
local ECHO_TIMER     = {}
local ECHO_RINGS     = {}  -- {age,x,y,z}

-- trail history: ring buffer of {x,y,z} world positions
local TRAIL_HIST     = {}  -- [key] = array of {x,y,z}
local TRAIL_IDX      = {}  -- [key] = current head index

-- speed tracking
local LAST_POS       = nil  -- last hrp position
local CUR_SPEED      = 0    -- smoothed speed magnitude
local CUR_YVEL       = 0    -- smoothed vertical speed
local SCREEN_OFF_X   = 0    -- chromatic aberration screen offset
local MAX_ECHO       = 5
local ACTIVE_KEYS    = {}
local ACTIVE_N       = 0
local XF             = {}
local COLOR_NOW      = 0

for _, k in ipairs(SHAPE_KEYS) do
    PLOCK_ROT[k]      = false
    PLOCK_CUBE_ROT[k] = false
    TRANSP[k]         = CFG.TRANSPARENCY
    PULSE_ON[k]       = false; PULSE_SPD[k] = 1.0; PULSE_AMP[k] = 0.4
    ORBIT_ON[k]       = false; ORBIT_R[k]   = 5.0; ORBIT_SPD[k] = 1.0; ORBIT_ANG[k] = 0
    SCALEP_ON[k]      = false; SCALEP_SPD[k]= 1.0; SCALEP_AMP[k]= 0.5; SCALE[k]     = 1.0

    WIRE_ON[k]        = false
    TRAIL_ON[k]       = false; TRAIL_LEN[k] = 5;  TRAIL_FADE[k] = 0.6
    BOUNCE_ON[k]      = false; BOUNCE_SPD[k]= 2.0; BOUNCE_AMP[k]= 1.0
    FIG8_ON[k]        = false; FIG8_R[k]    = 5.0; FIG8_SPD[k]  = 1.0; FIG8_ANG[k]  = 0
    CSPIN_ON[k]       = false; CSPIN_SPD[k] = 0.7; CSPIN_ANG[k] = 0
    COLDIST_ON[k]     = false
    COL_NEAR[k]       = Color3.fromRGB(0, 255, 0)
    COL_FAR[k]        = Color3.fromRGB(255, 0, 0)
    COLDIST_MAX[k]    = 50.0
    COLDIST_MAX_SQ[k] = 2500.0
    OUTLINE_ON[k]     = false
    OUTLINE_COL[k]    = Color3.fromRGB(255, 255, 255)
    OUTLINE_SCALE[k]  = 1.15
    SHAKE_ON[k]       = false; SHAKE_AMP[k] = 0.3
    SPEED_SCALE_ON[k] = false; SPEED_SCALE_MAX[k] = 30.0
    COLCYCLE_ON[k]    = false
    COLCYCLE_A[k]     = Color3.fromRGB(255, 80, 80)
    COLCYCLE_B[k]     = Color3.fromRGB(80, 80, 255)
    COLCYCLE_SPD[k]   = 1.0

    HEATMAP_ON[k]     = false; HEATMAP_RANGE[k] = 50.0
    LERP_ON[k]        = false; LERP_SPD[k]     = 8.0
    LERP_POS[k]       = {x=0, y=0, z=0, init=false}
    CHROMA_ON[k]      = false; CHROMA_OFF[k]   = 2.0
    DRIFT_ON[k]       = false; DRIFT_AMP[k]    = 0.4; DRIFT_SPD[k] = 2.0
    DRIFT_OFF[k]      = {x=0, y=0, z=0}
    DRIFT_TGT[k]      = {x=0, y=0, z=0}
    ECHO_ON[k]        = false; ECHO_INT[k]     = 1.2; ECHO_SPD[k] = 8.0; ECHO_MAXR[k] = 12.0
    ECHO_TIMER[k]     = 0
    ECHO_RINGS[k]     = {}

    -- trail history init (max 20 ghosts)
    TRAIL_HIST[k] = {}
    TRAIL_IDX[k]  = 1
    for i=1,20 do TRAIL_HIST[k][i] = {x=0,y=0,z=0} end
    TARGET_ON[k]   = false
    TARGET_MODE[k] = "Closest"
end

-- ── color helpers ────────────────────────────────────────────────────────────
local function rainbowColor(offset)
    local h = ((COLOR_NOW * CFG.RAINBOW_SPEED) + (offset or 0)) % 1
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

local function lerpColor(a, b, t)
    t = math.max(0, math.min(1, t))
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

-- Returns the effective color for a shape this frame.
local function getShapeColor(key, rbOff, distSq)
    if COLCYCLE_ON[key] then
        local t = 0.5 + 0.5 * math.sin(COLOR_NOW * COLCYCLE_SPD[key] * math.pi * 2)
        return lerpColor(COLCYCLE_A[key], COLCYCLE_B[key], t)
    end
    if RB[key] then
        return rainbowColor(rbOff or 0)
    end
    if COLDIST_ON[key] and distSq then
        local t = math.min(1, distSq / COLDIST_MAX_SQ[key])
        return lerpColor(COL_NEAR[key], COL_FAR[key], t)
    end
    if HEATMAP_ON[key] then
        local t = 0.5 + 0.5 * math.max(-1, math.min(1, CUR_YVEL / HEATMAP_RANGE[key]))
        return lerpColor(Color3.fromRGB(50, 120, 255), Color3.fromRGB(255, 60, 50), t)
    end
    return nil
end

-- ── geometry helpers ─────────────────────────────────────────────────────────
local function rotateVec(x, y, z, rx, ry, rz)
    local cx,sx = math.cos(rx),math.sin(rx)
    local cy,sy = math.cos(ry),math.sin(ry)
    local cz,sz = math.cos(rz),math.sin(rz)
    y,z = y*cx-z*sx, y*sx+z*cx
    x,z = x*cy+z*sy, -x*sy+z*cy
    x,y = x*cz-y*sz, x*sz+y*cz
    return x,y,z
end

local function prepXF(key)
    local lockCube = PLOCK_CUBE_ROT[key] or LOCK_CUBE_ROT
    local lockRot  = PLOCK_ROT[key] or LOCK_ROT
    local bx = lockCube and HRP_EULER.x or 0
    local by = (lockRot or lockCube) and HRP_EULER.y or 0
    local bz = lockCube and HRP_EULER.z or 0
    local sc = SCALE[key] or 1.0
    local csExtra = CSPIN_ON[key] and CSPIN_ANG[key] or 0
    local rx = bx + (ROT_X[key] or 0)
    local ry = by + (ROT_Y[key] or 0) + (SPIN_ANG[key] or 0) + csExtra
    local rz = bz + (ROT_Z[key] or 0)
    local m11,m12,m13 = rotateVec(1,0,0,rx,ry,rz)
    local m21,m22,m23 = rotateVec(0,1,0,rx,ry,rz)
    local m31,m32,m33 = rotateVec(0,0,1,rx,ry,rz)
    local xf = XF[key]
    if not xf then xf = {}; XF[key] = xf end
    xf.sc = sc
    xf.m11, xf.m12, xf.m13 = m11, m12, m13
    xf.m21, xf.m22, xf.m23 = m21, m22, m23
    xf.m31, xf.m32, xf.m33 = m31, m32, m33
end

local function worldFromLocal(key, ox, oy, oz, lx, ly, lz)
    local xf = XF[key]
    local sc = xf.sc
    local lx2, ly2, lz2 = lx*sc, ly*sc, lz*sc
    return Vector3.new(
        ox + xf.m11*lx2 + xf.m12*ly2 + xf.m13*lz2,
        oy + xf.m21*lx2 + xf.m22*ly2 + xf.m23*lz2,
        oz + xf.m31*lx2 + xf.m32*ly2 + xf.m33*lz2)
end

local function projLocal(key, ox, oy, oz, lx, ly, lz)
    local wp = worldFromLocal(key, ox, oy, oz, lx, ly, lz)
    local s, on = WTS(wp)
    return {x=s.X, y=s.Y, on=on}
end

local function ringPoints(key, ox, oy, oz, radius, yOff, n)
    local pts = {}
    for i = 1, n do
        local a = ((i-1)/n)*math.pi*2
        pts[i] = projLocal(key, ox, oy+yOff, oz, math.cos(a)*radius, 0, math.sin(a)*radius)
    end
    return pts
end

-- ── triangle pool ────────────────────────────────────────────────────────────
local TRIS = {}
-- Outline pool: same counts, drawn behind at outline scale
local TRIS_OUTLINE = {}
local TRIS_CHROMA_R  = {}
local TRIS_CHROMA_B  = {}
local TRIS_ECHO      = {}  -- [key][ringIdx] triangle pool

local function makeTris(key, col, count)
    local arr = {}
    for i = 1, count do
        local t = Drawing.new("Triangle")
        t.Color = col; t.Filled = true
        t.Visible = false; t.ZIndex = 5
        t.Transparency = CFG.TRANSPARENCY
        arr[i] = t
    end
    TRIS[key] = arr
end

local function makeOutlineTris(key, col, count)
    local arr = {}
    for i = 1, count do
        local t = Drawing.new("Triangle")
        t.Color = col; t.Filled = true
        t.Visible = false; t.ZIndex = 4  -- behind main shape
        t.Transparency = CFG.TRANSPARENCY + 0.2
        arr[i] = t
    end
    TRIS_OUTLINE[key] = arr
end

-- trail pools: 20 ghost copies per shape, each with same tri count
local TRIS_TRAIL = {}  -- [key][ghostIdx][triIdx]
local TRAIL_TRI_COUNTS = {
    cone=48, cube=12, sphere=196, diam=8, torus=256, star=20, crown=30,
    pyra=6, cyl=48, caps=240, helix=72, icosa=20, tetra=4,
    prism=8, arrow=40, disc=64, cross=12, mobius=64, knot=96, hyper=320, custom=500,
}

local SHAPE_COUNTS = {
    cone   = CFG.SEGMENTS * 2,
    cube   = 12,
    sphere = CFG.SPHERE_SEGS * CFG.SPHERE_RINGS * 2,
    diam   = 8,
    torus  = CFG.TORUS_SEGS * CFG.TORUS_TUBE_SEG * 2,
    star   = 20,
    crown  = CFG.CROWN_N*2*2 + CFG.CROWN_N*2,
    pyra   = 6,
    cyl    = CFG.CYLI_SEGS * 4,
    caps   = CFG.CAPS_SEGS * 20,
    helix  = CFG.HELIX_SEGS * 2,
    icosa  = 20,
    tetra  = 4,
    prism  = 8,
    arrow  = CFG.ARROW_SEGS * 5,
    disc   = CFG.DISC_SEGS * 4,
    cross  = 12,
    mobius = CFG.MOBIUS_SEGS * 2,
    knot   = CFG.KNOT_SEGS * 2,
    hyper  = CFG.HYPER_SEGS * CFG.HYPER_RINGS * 2,
    custom = 500,
}

makeTris("cone",   CFG.COL_CONE,   SHAPE_COUNTS.cone)
makeTris("cube",   CFG.COL_CUBE,   SHAPE_COUNTS.cube)
makeTris("sphere", CFG.COL_SPHERE, SHAPE_COUNTS.sphere)
makeTris("diam",   CFG.COL_DIAM,   SHAPE_COUNTS.diam)
makeTris("torus",  CFG.COL_TORUS,  SHAPE_COUNTS.torus)
makeTris("star",   CFG.COL_STAR,   SHAPE_COUNTS.star)
makeTris("crown",  CFG.COL_CROWN,  SHAPE_COUNTS.crown)
makeTris("pyra",   CFG.COL_PYRA,   SHAPE_COUNTS.pyra)
makeTris("cyl",    CFG.COL_CYLI,   SHAPE_COUNTS.cyl)
makeTris("caps",   CFG.COL_CAPS,   SHAPE_COUNTS.caps)
makeTris("helix",  CFG.COL_HELIX,  SHAPE_COUNTS.helix)
makeTris("icosa",  CFG.COL_ICOSA,  SHAPE_COUNTS.icosa)
makeTris("tetra",  CFG.COL_TETRA,  SHAPE_COUNTS.tetra)
makeTris("prism",  CFG.COL_PRISM,  SHAPE_COUNTS.prism)
makeTris("arrow",  CFG.COL_ARROW,  SHAPE_COUNTS.arrow)
makeTris("disc",   CFG.COL_DISC,   SHAPE_COUNTS.disc)
makeTris("cross",  CFG.COL_CROSS,  SHAPE_COUNTS.cross)
makeTris("mobius", CFG.COL_MOBIUS, SHAPE_COUNTS.mobius)
makeTris("knot",   CFG.COL_KNOT,   SHAPE_COUNTS.knot)
makeTris("hyper",  CFG.COL_HYPER,  SHAPE_COUNTS.hyper)
makeTris("custom", CFG.COL_CUSTOM, SHAPE_COUNTS.custom)

for _, k in ipairs(SHAPE_KEYS) do
    makeOutlineTris(k, Color3.fromRGB(255,255,255), SHAPE_COUNTS[k])
    makeTris("chroma_r_"..k, Color3.fromRGB(255,0,0), SHAPE_COUNTS[k])
    makeTris("chroma_b_"..k, Color3.fromRGB(0,0,255), SHAPE_COUNTS[k])
    TRIS_CHROMA_R[k] = TRIS["chroma_r_"..k]
    TRIS_CHROMA_B[k] = TRIS["chroma_b_"..k]
    TRIS["chroma_r_"..k] = nil
    TRIS["chroma_b_"..k] = nil
    TRIS_ECHO[k] = {}
    for r = 1, MAX_ECHO do
        makeTris("echo_"..k.."_"..r, CFG.COL_DISC, SHAPE_COUNTS.disc)
        TRIS_ECHO[k][r] = TRIS["echo_"..k.."_"..r]
        TRIS["echo_"..k.."_"..r] = nil
    end
    TRIS_TRAIL[k] = {}
    for g = 1, 20 do
        local arr = {}
        for i = 1, SHAPE_COUNTS[k] do
            local t = Drawing.new("Triangle")
            t.Color = Color3.fromRGB(200,200,200)
            t.Filled = true; t.Visible = false; t.ZIndex = 3
            t.Transparency = 0.85
            arr[i] = t
        end
        TRIS_TRAIL[k][g] = arr
    end
end

-- hide all tris in a generic pool (must be defined before hideAll + UI callbacks)
local function hidePool(pool)
    if not pool then return end
    for _, t in ipairs(pool) do t.Visible = false end
end

-- ── triangle write helpers ────────────────────────────────────────────────────
local function hideAll(key)
    for _, t in ipairs(TRIS[key]) do t.Visible = false end
    for _, t in ipairs(TRIS_OUTLINE[key]) do t.Visible = false end
    if TRIS_CHROMA_R[key] then for _, t in ipairs(TRIS_CHROMA_R[key]) do t.Visible = false end end
    if TRIS_CHROMA_B[key] then for _, t in ipairs(TRIS_CHROMA_B[key]) do t.Visible = false end end
    if TRIS_ECHO[key] then for r=1,MAX_ECHO do hidePool(TRIS_ECHO[key][r]) end end
    for g=1,20 do hidePool(TRIS_TRAIL[key][g]) end
end

local function setShapeEnabled(key, on)
    EN[key] = on
    if on then
        ACTIVE_N = ACTIVE_N + 1
        ACTIVE_KEYS[ACTIVE_N] = key
    else
        for i = 1, ACTIVE_N do
            if ACTIVE_KEYS[i] == key then
                ACTIVE_KEYS[i] = ACTIVE_KEYS[ACTIVE_N]
                ACTIVE_KEYS[ACTIVE_N] = nil
                ACTIVE_N = ACTIVE_N - 1
                break
            end
        end
        hideAll(key)
    end
end

local function applyColor(key, col)
    for _, t in ipairs(TRIS[key]) do t.Color = col end
end
local function applyTransp(key, v)
    for _, t in ipairs(TRIS[key]) do t.Transparency = v end
end
local function applyShapeTransp(key)
    local v = TRANSP[key]
    for _, t in ipairs(TRIS[key]) do t.Transparency = v end
end

-- setTri: if wireframe, draws only edges (Filled=false); otherwise filled
local function setTri(pool, idx, col, ax,ay, bx,by, cx,cy, aon,bon,con, wireframe, transp)
    local tri = pool[idx]
    if not tri then return end
    if aon and bon and con then
        local ox = SCREEN_OFF_X or 0
        tri.Color   = col
        tri.Filled  = not wireframe
        if transp then tri.Transparency = transp end
        tri.PointA  = Vector2.new(ax+ox,ay)
        tri.PointB  = Vector2.new(bx+ox,by)
        tri.PointC  = Vector2.new(cx+ox,cy)
        tri.Visible = true
    else
        tri.Visible = false
    end
end

local function setTriP(pool, idx, col, a, b, c, wireframe, transp)
    setTri(pool, idx, col, a.x,a.y, b.x,b.y, c.x,c.y, a.on,b.on,c.on, wireframe, transp)
end

-- ── draw functions (now accept pool, wire, transp args) ───────────────────────
local function drawStrip(pool, ti, rA, rB, col, n, wire, transp)
    for s = 1, n do
        local ns = (s%n)+1
        local a,b,c,d = rA[s],rA[ns],rB[s],rB[ns]
        setTriP(pool, ti, col, a, b, c, wire, transp); ti=ti+1
        setTriP(pool, ti, col, b, d, c, wire, transp); ti=ti+1
    end
    return ti
end

local function drawCone(pool, ox, oy, oz, key, col, wire, transp)
    local apex = projLocal(key, ox, oy, oz, 0, CFG.HAT_HEIGHT, 0)
    local base = ringPoints(key, ox, oy, oz, CFG.HAT_RADIUS, 0, CFG.SEGMENTS)
    local ti = 1
    for i = 1, CFG.SEGMENTS do
        local ni = (i%CFG.SEGMENTS)+1
        local p1, p2 = base[i], base[ni]
        setTriP(pool, ti, col, apex, p1, p2, wire, transp); ti=ti+1
        setTriP(pool, ti, col,
            {x=base[1].x,y=base[1].y,on=base[1].on}, p1, p2, wire, transp); ti=ti+1
    end
end

local CUBE_FACES = {
    {1,2,3},{1,3,4},{5,7,6},{5,8,7},
    {4,3,7},{4,7,8},{1,6,2},{1,5,6},
    {1,4,8},{1,8,5},{2,7,3},{2,6,7},
}
local function drawCube(pool, ox, oy, oz, key, col, wire, transp)
    local h = CFG.CUBE_SIZE/2
    local corners = {
        worldFromLocal(key,ox,oy,oz,-h,-h,-h), worldFromLocal(key,ox,oy,oz, h,-h,-h),
        worldFromLocal(key,ox,oy,oz, h,-h, h), worldFromLocal(key,ox,oy,oz,-h,-h, h),
        worldFromLocal(key,ox,oy,oz,-h, h,-h), worldFromLocal(key,ox,oy,oz, h, h,-h),
        worldFromLocal(key,ox,oy,oz, h, h, h), worldFromLocal(key,ox,oy,oz,-h, h, h),
    }
    local sc = {}
    for i=1,8 do local s,on=WTS(corners[i]); sc[i]={x=s.X,y=s.Y,on=on} end
    for i=1,12 do
        local f=CUBE_FACES[i]
        local a,b,c=sc[f[1]],sc[f[2]],sc[f[3]]
        setTriP(pool, i, col, a, b, c, wire, transp)
    end
end

local function drawSphere(pool, ox, oy, oz, key, col, wire, transp)
    local r, n = CFG.SPHERE_RADIUS, CFG.SPHERE_SEGS
    local rings = {}
    for ri = 0, CFG.SPHERE_RINGS do
        local lat = (ri/CFG.SPHERE_RINGS)*math.pi
        rings[ri] = ringPoints(key, ox, oy, oz, math.sin(lat)*r, math.cos(lat)*r, n)
    end
    local apex = projLocal(key, ox, oy, oz, 0, r, 0)
    local bot  = projLocal(key, ox, oy, oz, 0,-r, 0)
    local ti = 1
    for s=1,n do
        local ns=(s%n)+1
        setTriP(pool, ti, col, apex, rings[0][s], rings[0][ns], wire, transp); ti=ti+1
    end
    for ri=0,CFG.SPHERE_RINGS-2 do
        ti = drawStrip(pool, ti, rings[ri], rings[ri+1], col, n, wire, transp)
    end
    local lastR = rings[CFG.SPHERE_RINGS-1]
    for s=1,n do
        local ns=(s%n)+1
        setTriP(pool, ti, col, lastR[s], lastR[ns], bot, wire, transp); ti=ti+1
    end
end

local function drawDiamond(pool, ox, oy, oz, key, col, wire, transp)
    local h2 = CFG.DIAM_HEIGHT/2
    local top = projLocal(key, ox, oy, oz, 0, h2, 0)
    local bot = projLocal(key, ox, oy, oz, 0,-h2, 0)
    local eq = {}
    for i=1,4 do
        local a=((i-1)/4)*math.pi*2
        eq[i]=projLocal(key, ox, oy, oz, math.cos(a)*CFG.DIAM_RADIUS, 0, math.sin(a)*CFG.DIAM_RADIUS)
    end
    local ti=1
    for i=1,4 do
        local ni=(i%4)+1
        setTriP(pool, ti, col, top, eq[i], eq[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, eq[i], eq[ni], bot, wire, transp); ti=ti+1
    end
end

local function drawTorus(pool, ox, oy, oz, key, col, wire, transp)
    local ti = 1
    local lockRot = PLOCK_ROT[key] or LOCK_ROT or PLOCK_CUBE_ROT[key] or LOCK_CUBE_ROT
    local totalYaw = lockRot and HRP_EULER.y or 0
    local csExtra  = CSPIN_ON[key] and CSPIN_ANG[key] or 0
    local spinY = totalYaw + (ROT_Y[key] or 0) + (SPIN_ANG[key] or 0) + csExtra
    for maj=0,CFG.TORUS_SEGS-1 do
        local ma  = spinY + (maj/CFG.TORUS_SEGS)*math.pi*2
        local ma2 = spinY + ((maj+1)/CFG.TORUS_SEGS)*math.pi*2
        local cx1=ox+math.cos(ma)*CFG.TORUS_RADIUS;  local cz1=oz+math.sin(ma)*CFG.TORUS_RADIUS
        local cx2=ox+math.cos(ma2)*CFG.TORUS_RADIUS; local cz2=oz+math.sin(ma2)*CFG.TORUS_RADIUS
        local r1, r2 = {}, {}
        for min=0,CFG.TORUS_TUBE_SEG-1 do
            local mi=(min/CFG.TORUS_TUBE_SEG)*math.pi*2
            local dx,dy=math.cos(mi)*CFG.TORUS_TUBE, math.sin(mi)*CFG.TORUS_TUBE
            local s1,o1=WTS(Vector3.new(cx1+math.cos(ma)*dx,  oy+dy, cz1+math.sin(ma)*dx))
            local s2,o2=WTS(Vector3.new(cx2+math.cos(ma2)*dx, oy+dy, cz2+math.sin(ma2)*dx))
            r1[min]={x=s1.X,y=s1.Y,on=o1}; r2[min]={x=s2.X,y=s2.Y,on=o2}
        end
        for min=0,CFG.TORUS_TUBE_SEG-1 do
            local nmi=(min+1)%CFG.TORUS_TUBE_SEG
            local a,b,c,d=r1[min],r1[nmi],r2[min],r2[nmi]
            setTriP(pool, ti, col, a, b, c, wire, transp); ti=ti+1
            setTriP(pool, ti, col, b, d, c, wire, transp); ti=ti+1
        end
    end
end

local function drawStar(pool, ox, oy, oz, key, col, wire, transp)
    local NPTS=5
    local ctop=projLocal(key,ox,oy,oz,0, 0.08,0)
    local cbot=projLocal(key,ox,oy,oz,0,-0.08,0)
    local pts={}
    for i=0,NPTS*2-1 do
        local a=((i/(NPTS*2))*math.pi*2)-math.pi/2
        local r=(i%2==0) and CFG.STAR_OUTER or CFG.STAR_INNER
        pts[i+1]=projLocal(key,ox,oy,oz,math.cos(a)*r,0,math.sin(a)*r)
    end
    local ti=1
    for i=1,NPTS*2 do
        local ni=(i%(NPTS*2))+1
        setTriP(pool, ti, col, ctop, pts[i], pts[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, pts[i], pts[ni], cbot, wire, transp); ti=ti+1
    end
end

local function drawCrown(pool, ox, oy, oz, key, col, wire, transp)
    local SEGS = CFG.CROWN_N*2
    local bottom, top = {}, {}
    for i=1,SEGS do
        local a=((i-1)/SEGS)*math.pi*2
        bottom[i]=projLocal(key,ox,oy,oz,math.cos(a)*CFG.CROWN_RADIUS,0,math.sin(a)*CFG.CROWN_RADIUS)
        top[i]   =projLocal(key,ox,oy,oz,math.cos(a)*CFG.CROWN_RADIUS,CFG.CROWN_HEIGHT*0.42,math.sin(a)*CFG.CROWN_RADIUS)
    end
    local tips={}
    for i=1,CFG.CROWN_N do
        local a=((2*(i-1))/SEGS)*math.pi*2
        tips[i]=projLocal(key,ox,oy,oz,math.cos(a)*CFG.CROWN_RADIUS,CFG.CROWN_HEIGHT,math.sin(a)*CFG.CROWN_RADIUS)
    end
    local ti=1
    for i=1,SEGS do
        local ni=(i%SEGS)+1
        setTriP(pool, ti, col, bottom[i], bottom[ni], top[i], wire, transp); ti=ti+1
        setTriP(pool, ti, col, bottom[ni], top[ni], top[i], wire, transp); ti=ti+1
    end
    for i=1,CFG.CROWN_N do
        local si=2*i-1
        local lIdx=si==1 and SEGS or si-1
        local rIdx=(si%SEGS)+1
        setTriP(pool, ti, col, tips[i], top[si], top[lIdx], wire, transp); ti=ti+1
        setTriP(pool, ti, col, tips[i], top[si], top[rIdx], wire, transp); ti=ti+1
    end
end

local function drawPyramid(pool, ox, oy, oz, key, col, wire, transp)
    local top=projLocal(key,ox,oy,oz,0,CFG.PYRA_HEIGHT,0)
    local base={}
    for i=1,4 do
        local a=((i-1)/4)*math.pi*2
        base[i]=projLocal(key,ox,oy,oz,math.cos(a)*CFG.PYRA_RADIUS,0,math.sin(a)*CFG.PYRA_RADIUS)
    end
    local ti=1
    for i=1,4 do
        local ni=(i%4)+1
        setTriP(pool, ti, col, top, base[i], base[ni], wire, transp); ti=ti+1
    end
    setTriP(pool, ti, col, base[1], base[2], base[3], wire, transp); ti=ti+1
    setTriP(pool, ti, col, base[1], base[3], base[4], wire, transp)
end

local function drawCylinder(pool, ox, oy, oz, key, col, wire, transp)
    local n = CFG.CYLI_SEGS
    local topR = ringPoints(key, ox, oy, oz, CFG.CYLI_RADIUS, CFG.CYLI_HEIGHT, n)
    local botR = ringPoints(key, ox, oy, oz, CFG.CYLI_RADIUS, 0, n)
    local topC = projLocal(key, ox, oy+CFG.CYLI_HEIGHT, oz, 0,0,0)
    local botC = projLocal(key, ox, oy, oz, 0,0,0)
    local ti=1
    for i=1,n do
        local ni=(i%n)+1
        setTriP(pool, ti, col, topR[i], botR[i], topR[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, botR[i], botR[ni], topR[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, topC, topR[i], topR[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, botC, botR[i], botR[ni], wire, transp); ti=ti+1
    end
end

local function drawCapsule(pool, ox, oy, oz, key, col, wire, transp)
    local r, halfH, n, HEMI = CFG.CAPS_RADIUS, CFG.CAPS_HEIGHT/2, CFG.CAPS_SEGS, 4
    local topR = ringPoints(key, ox, oy, oz, r,  halfH, n)
    local botR = ringPoints(key, ox, oy, oz, r, -halfH, n)
    local ti=1
    for i=1,n do
        local ni=(i%n)+1
        setTriP(pool, ti, col, topR[i], botR[i], topR[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, botR[i], botR[ni], topR[ni], wire, transp); ti=ti+1
    end
    local topHemi={}
    for ri=0,HEMI do
        local lat=(ri/HEMI)*(math.pi/2)
        topHemi[ri]=ringPoints(key,ox,oy,oz,math.cos(lat)*r,halfH+math.sin(lat)*r,n)
    end
    local topPt=projLocal(key,ox,oy+halfH+r,oz,0,0,0)
    for i=1,n do local ni=(i%n)+1; setTriP(pool, ti, col, topPt, topHemi[0][i], topHemi[0][ni], wire, transp); ti=ti+1 end
    for ri=0,HEMI-1 do ti=drawStrip(pool, ti, topHemi[ri], topHemi[ri+1], col, n, wire, transp) end
    local botHemi={}
    for ri=0,HEMI do
        local lat=(ri/HEMI)*(math.pi/2)
        botHemi[ri]=ringPoints(key,ox,oy,oz,math.cos(lat)*r,-halfH-math.sin(lat)*r,n)
    end
    local botPt=projLocal(key,ox,oy-halfH-r,oz,0,0,0)
    for i=1,n do local ni=(i%n)+1; setTriP(pool, ti, col, botPt, botHemi[0][i], botHemi[0][ni], wire, transp); ti=ti+1 end
    for ri=0,HEMI-1 do ti=drawStrip(pool, ti, botHemi[ri], botHemi[ri+1], col, n, wire, transp) end
end

local function drawHelix(pool, ox, oy, oz, key, col, wire, transp)
    local n = CFG.HELIX_SEGS
    local ti = 1
    local lockRot = PLOCK_ROT[key] or LOCK_ROT or PLOCK_CUBE_ROT[key] or LOCK_CUBE_ROT
    local totalYaw = lockRot and HRP_EULER.y or 0
    local csExtra  = CSPIN_ON[key] and CSPIN_ANG[key] or 0
    local spinY = totalYaw + (ROT_Y[key] or 0) + (SPIN_ANG[key] or 0) + csExtra
    local prev = nil
    for i=0,n do
        local t  = i/n
        local a  = spinY + t*CFG.HELIX_TURNS*math.pi*2
        local wp = Vector3.new(ox+math.cos(a)*CFG.HELIX_RADIUS, oy+t*CFG.HELIX_HEIGHT, oz+math.sin(a)*CFG.HELIX_RADIUS)
        local s, on = WTS(wp)
        local curr = {x=s.X,y=s.Y,on=on}
        if prev and i>0 and ti<=#pool-1 then
            local offX=-(curr.y-prev.y); local offY=curr.x-prev.x
            local len=math.sqrt(offX*offX+offY*offY)
            if len>0 then
                local px,py=offX/len*3,offY/len*3
                local a1={x=prev.x-px,y=prev.y-py,on=prev.on}
                local b1={x=curr.x-px,y=curr.y-py,on=curr.on}
                local c1={x=curr.x+px,y=curr.y+py,on=curr.on}
                local a2={x=prev.x-px,y=prev.y-py,on=prev.on}
                local c2={x=curr.x+px,y=curr.y+py,on=curr.on}
                local d2={x=prev.x+px,y=prev.y+py,on=prev.on}
                setTriP(pool, ti, col, a1, b1, c1, wire, transp); ti=ti+1
                setTriP(pool, ti, col, a2, c2, d2, wire, transp); ti=ti+1
            end
        end
        prev=curr
    end
    for i=ti,#pool do pool[i].Visible=false end
end

local function drawIcosahedron(pool, ox, oy, oz, key, col, wire, transp)
    local r=CFG.ICOSA_RADIUS; local phi=(1+math.sqrt(5))/2
    local verts={{0,1,phi},{0,-1,phi},{0,1,-phi},{0,-1,-phi},{1,phi,0},{-1,phi,0},{1,-phi,0},{-1,-phi,0},{phi,0,1},{-phi,0,1},{phi,0,-1},{-phi,0,-1}}
    local faces={{1,2,9},{1,9,5},{1,5,6},{1,6,10},{1,10,2},{4,3,11},{4,11,7},{4,7,8},{4,8,12},{4,12,3},{2,8,7},{2,7,9},{9,7,11},{9,11,10},{10,11,12},{10,12,6},{6,12,3},{6,3,5},{5,3,11},{5,11,9}}
    local sv={}
    for i,v in ipairs(verts) do
        local len=math.sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])
        sv[i]=projLocal(key,ox,oy,oz,v[1]/len*r,v[2]/len*r,v[3]/len*r)
    end
    for i,f in ipairs(faces) do
        setTriP(pool, i, col, sv[f[1]], sv[f[2]], sv[f[3]], wire, transp)
    end
end

local function drawTetrahedron(pool, ox, oy, oz, key, col, wire, transp)
    local r=CFG.TETRA_RADIUS
    local v={{0,1,0},{math.sqrt(8/9),-1/3,0},{-math.sqrt(2/9),-1/3,math.sqrt(2/3)},{-math.sqrt(2/9),-1/3,-math.sqrt(2/3)}}
    local faces={{1,2,3},{1,2,4},{1,3,4},{2,3,4}}
    local sv={}
    for i,vt in ipairs(v) do sv[i]=projLocal(key,ox,oy,oz,vt[1]*r,vt[2]*r,vt[3]*r) end
    for i,f in ipairs(faces) do setTriP(pool, i, col, sv[f[1]], sv[f[2]], sv[f[3]], wire, transp) end
end

local function drawPrism(pool, ox, oy, oz, key, col, wire, transp)
    local top, bot = {}, {}
    for i=1,3 do
        local a=((i-1)/3)*math.pi*2
        top[i]=projLocal(key,ox,oy,oz,math.cos(a)*CFG.PRISM_RADIUS,CFG.PRISM_HEIGHT,math.sin(a)*CFG.PRISM_RADIUS)
        bot[i]=projLocal(key,ox,oy,oz,math.cos(a)*CFG.PRISM_RADIUS,0,math.sin(a)*CFG.PRISM_RADIUS)
    end
    local ti=1
    setTriP(pool, ti, col, top[1], top[2], top[3], wire, transp); ti=ti+1
    setTriP(pool, ti, col, bot[1], bot[2], bot[3], wire, transp); ti=ti+1
    for i=1,3 do
        local ni=(i%3)+1
        setTriP(pool, ti, col, top[i], bot[i], top[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, bot[i], bot[ni], top[ni], wire, transp); ti=ti+1
    end
end

local function drawArrow(pool, ox, oy, oz, key, col, wire, transp)
    local n=CFG.ARROW_SEGS
    local shaftB = ringPoints(key,ox,oy,oz,CFG.ARROW_RADIUS,0,n)
    local shaftT = ringPoints(key,ox,oy,oz,CFG.ARROW_RADIUS,CFG.ARROW_SHAFT_H,n)
    local headB  = ringPoints(key,ox,oy,oz,CFG.ARROW_HEAD_RADIUS,CFG.ARROW_SHAFT_H,n)
    local apex   = projLocal(key,ox,oy,oz,0,CFG.ARROW_SHAFT_H+CFG.ARROW_HEAD_H,0)
    local ti=1
    for i=1,n do
        local ni=(i%n)+1
        setTriP(pool, ti, col, shaftB[i], shaftT[i], shaftB[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, shaftT[i], shaftT[ni], shaftB[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, headB[i], apex, headB[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, shaftT[i], headB[i], headB[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, shaftT[i], headB[ni], shaftT[ni], wire, transp); ti=ti+1
    end
end

local function drawDisc(pool, ox, oy, oz, key, col, wire, transp)
    local n=CFG.DISC_SEGS; local h=CFG.DISC_THICK/2
    local topR=ringPoints(key,ox,oy,oz,CFG.DISC_RADIUS, h,n)
    local botR=ringPoints(key,ox,oy,oz,CFG.DISC_RADIUS,-h,n)
    local topC=projLocal(key,ox,oy+h,oz,0,0,0)
    local botC=projLocal(key,ox,oy-h,oz,0,0,0)
    local ti=1
    for i=1,n do
        local ni=(i%n)+1
        setTriP(pool, ti, col, topR[i], topR[ni], topC, wire, transp); ti=ti+1
        setTriP(pool, ti, col, botR[i], botR[ni], botC, wire, transp); ti=ti+1
        setTriP(pool, ti, col, topR[i], botR[i], topR[ni], wire, transp); ti=ti+1
        setTriP(pool, ti, col, botR[i], botR[ni], topR[ni], wire, transp); ti=ti+1
    end
end

local function drawEchoRing(pool, ox, oy, oz, key, col, wire, transp, radius)
    local origR, origT = CFG.DISC_RADIUS, CFG.DISC_THICK
    CFG.DISC_RADIUS = radius
    CFG.DISC_THICK  = math.max(0.05, origT * math.min(1, 2 / math.max(1, radius)))
    drawDisc(pool, ox, oy, oz, key, col, wire, transp)
    CFG.DISC_RADIUS = origR
    CFG.DISC_THICK  = origT
end

local function drawStarOfDavid(pool, ox, oy, oz, key, col, wire, transp)
    local R = CFG.CROSS_ARM
    local barW = CFG.CROSS_WIDTH
    local Rin = math.max(R * 0.12, R - barW * 2 / math.sqrt(3))
    local function pt(x, z) return projLocal(key, ox, oy, oz, x, 0, z) end
    local function vtx(ang, rad)
        return pt(math.cos(ang) * rad, math.sin(ang) * rad)
    end
    local function hollowTri(baseAng, ti)
        for e = 0, 2 do
            local a1 = baseAng + e * math.pi * 2 / 3
            local a2 = baseAng + (e + 1) * math.pi * 2 / 3
            local o0, o1 = vtx(a1, R), vtx(a2, R)
            local i1, i0 = vtx(a2, Rin), vtx(a1, Rin)
            setTriP(pool, ti, col, o0, o1, i1, wire, transp); ti = ti + 1
            setTriP(pool, ti, col, o0, i1, i0, wire, transp); ti = ti + 1
        end
        return ti
    end
    local ti = hollowTri(math.pi / 2, 1)
    ti = hollowTri(-math.pi / 2, ti)
    for j = ti, #pool do pool[j].Visible = false end
end

local function drawJesusCross(pool, ox, oy, oz, key, col, wire, transp)
    local arm = CFG.CROSS_ARM
    local hw  = CFG.CROSS_WIDTH / 2
    local vh  = CFG.CROSS_HEIGHT / 2
    local beamZ = vh * 0.35
    local function pt(x, z) return projLocal(key, ox, oy, oz, x, 0, z) end
    local v1, v2, v3, v4 = pt(-hw, -vh), pt(hw, -vh), pt(hw, vh), pt(-hw, vh)
    local h1, h2, h3, h4 = pt(-arm, beamZ - hw), pt(arm, beamZ - hw), pt(arm, beamZ + hw), pt(-arm, beamZ + hw)
    setTriP(pool, 1, col, v1, v2, v3, wire, transp)
    setTriP(pool, 2, col, v1, v3, v4, wire, transp)
    setTriP(pool, 3, col, h1, h2, h3, wire, transp)
    setTriP(pool, 4, col, h1, h3, h4, wire, transp)
    for j = 5, #pool do pool[j].Visible = false end
end

local function drawCross(pool, ox, oy, oz, key, col, wire, transp)
    if CROSS_STYLE == "Star of David" then
        drawStarOfDavid(pool, ox, oy, oz, key, col, wire, transp)
    else
        drawJesusCross(pool, ox, oy, oz, key, col, wire, transp)
    end
end

local function drawMobius(pool, ox, oy, oz, key, col, wire, transp)
    local n = CFG.MOBIUS_SEGS
    local R = CFG.MOBIUS_RADIUS
    local w = CFG.MOBIUS_WIDTH / 2
    local ti = 1
    for i = 1, n do
        local u1 = ((i - 1) / n) * math.pi * 2
        local u2 = (i / n) * math.pi * 2
        local cos_u1, sin_u1 = math.cos(u1), math.sin(u1)
        local cos_u2, sin_u2 = math.cos(u2), math.sin(u2)
        local cos_h1, sin_h1 = math.cos(u1 / 2), math.sin(u1 / 2)
        local cos_h2, sin_h2 = math.cos(u2 / 2), math.sin(u2 / 2)

        local a = projLocal(key, ox, oy, oz, (R - w * cos_h1) * cos_u1, -w * sin_h1, (R - w * cos_h1) * sin_u1)
        local b = projLocal(key, ox, oy, oz, (R + w * cos_h1) * cos_u1,  w * sin_h1, (R + w * cos_h1) * sin_u1)
        local c = projLocal(key, ox, oy, oz, (R - w * cos_h2) * cos_u2, -w * sin_h2, (R - w * cos_h2) * sin_u2)
        local d = projLocal(key, ox, oy, oz, (R + w * cos_h2) * cos_u2,  w * sin_h2, (R + w * cos_h2) * sin_u2)

        setTriP(pool, ti, col, a, b, c, wire, transp); ti = ti + 1
        setTriP(pool, ti, col, b, d, c, wire, transp); ti = ti + 1
    end
end

local function drawTorusKnot(pool, ox, oy, oz, key, col, wire, transp)
    local n = CFG.KNOT_SEGS
    local R = CFG.KNOT_RADIUS
    local w = CFG.KNOT_WIDTH
    local ti = 1

    local function knotPt(t)
        local x = (math.sin(t) + 2 * math.sin(2 * t)) * R * 0.4
        local y = -math.sin(3 * t) * R * 0.4
        local z = (math.cos(t) - 2 * math.cos(2 * t)) * R * 0.4
        return x, y, z
    end

    for i = 1, n do
        local t1 = ((i - 1) / n) * math.pi * 2
        local t2 = (i / n) * math.pi * 2

        local x1, y1, z1 = knotPt(t1)
        local x2, y2, z2 = knotPt(t2)

        local dt = 0.01
        local x1b, y1b, z1b = knotPt(t1 + dt)
        local tx, ty, tz = x1b - x1, y1b - y1, z1b - z1

        local x2b, y2b, z2b = knotPt(t2 + dt)
        local tx2, ty2, tz2 = x2b - x2, y2b - y2, z2b - z2

        local bx1, bz1 = -tz, tx
        local len1 = math.sqrt(bx1 * bx1 + bz1 * bz1)
        if len1 > 0 then bx1, bz1 = (bx1 / len1) * w, (bz1 / len1) * w else bx1, bz1 = w, 0 end

        local bx2, bz2 = -tz2, tx2
        local len2 = math.sqrt(bx2 * bx2 + bz2 * bz2)
        if len2 > 0 then bx2, bz2 = (bx2 / len2) * w, (bz2 / len2) * w else bx2, bz2 = w, 0 end

        local p1 = projLocal(key, ox, oy, oz, x1 - bx1, y1, z1 - bz1)
        local p2 = projLocal(key, ox, oy, oz, x1 + bx1, y1, z1 + bz1)
        local p3 = projLocal(key, ox, oy, oz, x2 - bx2, y2, z2 - bz2)
        local p4 = projLocal(key, ox, oy, oz, x2 + bx2, y2, z2 + bz2)

        setTriP(pool, ti, col, p1, p2, p3, wire, transp); ti = ti + 1
        setTriP(pool, ti, col, p2, p4, p3, wire, transp); ti = ti + 1
    end
end

local function drawHyperboloid(pool, ox, oy, oz, key, col, wire, transp)
    local n = CFG.HYPER_SEGS
    local ringsCount = CFG.HYPER_RINGS
    local Rbase = CFG.HYPER_RADIUS
    local Rwaist = CFG.HYPER_WAIST
    local H = CFG.HYPER_HEIGHT
    local halfH = H / 2
    local rings = {}

    for ri = 0, ringsCount do
        local t = (ri / ringsCount) * 2 - 1
        local r = math.sqrt(Rwaist * Rwaist + (t * t) * (Rbase * Rbase - Rwaist * Rwaist))
        local y = t * halfH
        rings[ri] = ringPoints(key, ox, oy + halfH, oz, r, y, n)
    end

    local ti = 1
    for ri = 0, ringsCount - 1 do
        ti = drawStrip(pool, ti, rings[ri], rings[ri + 1], col, n, wire, transp)
    end
end

-- ==============================================================================
-- 🎨 CUSTOM SHAPE DEFINITION (EDIT THIS TABLE DIRECTLY TO MAKE YOUR OWN SHAPE!)
-- ==============================================================================
-- Format:
--   verts = { {x1, y1, z1}, {x2, y2, z2}, ... }  -- 3D point coordinates
--   tris  = { {p1, p2, p3}, ... }                -- 1-based vertex index triplets
-- ==============================================================================
local CUSTOM_MESH = {
    verts = {
        {0, 2.2, 0},     -- P1 (Top Apex)
        {-1.5, 0, -1.5}, -- P2 (Corner 1)
        {1.5, 0, -1.5},  -- P3 (Corner 2)
        {1.5, 0, 1.5},   -- P4 (Corner 3)
        {-1.5, 0, 1.5},  -- P5 (Corner 4)
        {0, -2.2, 0}     -- P6 (Bottom Apex)
    },
    tris = {
        -- Top Pyramid Faces
        {1, 2, 3}, {1, 3, 4}, {1, 4, 5}, {1, 5, 2},
        -- Bottom Pyramid Faces
        {6, 3, 2}, {6, 4, 3}, {6, 5, 4}, {6, 2, 5}
    }
}

local function loadCustomMeshFromJSON(jsonStr)
    local HttpService = game:GetService("HttpService")
    local ok, data = pcall(function() return HttpService:JSONDecode(jsonStr) end)
    if ok and type(data) == "table" and (data.vertices or data.verts) and (data.triangles or data.tris) then
        CUSTOM_MESH = {
            verts = data.vertices or data.verts,
            tris  = data.triangles or data.tris
        }
        if data.color then
            CFG.COL_CUSTOM = Color3.fromRGB(data.color[1], data.color[2], data.color[3])
            applyColor("custom", CFG.COL_CUSTOM)
        end
        return true
    end
    return false
end

local function loadCustomMeshFromURL(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok then
        return loadCustomMeshFromJSON(body)
    end
    return false
end

_G.LoadCustomShape = function(vertsTable, trisTable, color3)
    local HttpService = game:GetService("HttpService")
    if type(vertsTable) == "string" then
        pcall(function() vertsTable = HttpService:JSONDecode(vertsTable) end)
    end
    if type(trisTable) == "string" then
        pcall(function() trisTable = HttpService:JSONDecode(trisTable) end)
    end

    if type(vertsTable) == "table" and type(trisTable) == "table" then
        CUSTOM_MESH = { verts = vertsTable, tris = trisTable }
        if color3 then
            CFG.COL_CUSTOM = color3
            applyColor("custom", color3)
        end
        setShapeEnabled("custom", true)
        return true
    end
    return false
end

local function drawCustomMesh(pool, ox, oy, oz, key, col, wire, transp)
    if not CUSTOM_MESH or not CUSTOM_MESH.verts or not CUSTOM_MESH.tris then
        hidePool(pool)
        return
    end
    local verts   = CUSTOM_MESH.verts
    local tris    = CUSTOM_MESH.tris
    local numTris = #tris

    local projected = {}
    for i, v in ipairs(verts) do
        projected[i] = projLocal(key, ox, oy, oz, v[1], v[2], v[3])
    end

    for ti = 1, math.min(numTris, #pool) do
        local f = tris[ti]
        local p1, p2, p3 = projected[f[1]], projected[f[2]], projected[f[3]]
        if p1 and p2 and p3 then
            setTriP(pool, ti, col, p1, p2, p3, wire, transp)
        else
            if pool[ti] then pool[ti].Visible = false end
        end
    end

    for ti = numTris + 1, #pool do
        if pool[ti] then pool[ti].Visible = false end
    end
end

local function getTargetHRP(key, selfHRP)
    if not (TARGET_LOCK_ON or TARGET_ON[key]) then
        return selfHRP
    end
    local mode = TARGET_MODE[key] or TARGET_LOCK_MODE
    local localPlayer = Players.LocalPlayer
    local selfPos = selfHRP.Position
    local bestHRP = nil

    if mode == "Random" then
        local candidates = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then table.insert(candidates, hrp) end
            end
        end
        if #candidates > 0 then return candidates[math.random(1, #candidates)] end
    else -- Closest
        local bestDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - selfPos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestHRP = hrp
                    end
                end
            end
        end
        if bestHRP then return bestHRP end
    end
    return selfHRP
end

-- ── rainbow offset + colKey lookup (populated in SHAPE_META loop below) ──────
local SHAPE_RBOFF  = {}
local SHAPE_COLKEY = {}  -- [key] -> CFG key string e.g. "COL_CONE"

-- ── unified draw dispatch table ───────────────────────────────────────────────
local DRAW_FN = {
    cone  = drawCone,   cube  = drawCube,    sphere = drawSphere, diam  = drawDiamond,
    torus = drawTorus,  star  = drawStar,    crown  = drawCrown,  pyra  = drawPyramid,
    cyl   = drawCylinder, caps = drawCapsule, helix  = drawHelix,
    icosa = drawIcosahedron, tetra = drawTetrahedron, prism = drawPrism,
    arrow = drawArrow,  disc  = drawDisc,    cross  = drawCross,  mobius = drawMobius,
    knot  = drawTorusKnot, hyper = drawHyperboloid, custom = drawCustomMesh,
}

-- outline scale: temporarily inflates SCALE[key] to draw the outline pass
local function drawOutlinePass(key, fn, ox, oy, oz, col)
    if not OUTLINE_ON[key] then return end
    local origScale = SCALE[key]
    SCALE[key] = origScale * OUTLINE_SCALE[key]
    prepXF(key)
    fn(TRIS_OUTLINE[key], ox, oy, oz, key, OUTLINE_COL[key], false,
       math.min(1, TRANSP[key] + 0.25))
    SCALE[key] = origScale
end

-- ── INS ui setup ─────────────────────────────────────────────────────────────
local Lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua"
))() or INSui
local win = Lib:CreateWindow({
    title      = "3D World Shapes",
    subtitle   = "v4.3",
    size       = Vector2.new(560, 920),
    menuKey    = "p",
    configName = "hrp_shapes_v43",
    startOpen  = true,
    autoSave   = true,
})

-- ── Global tab ───────────────────────────────────────────────────────────────
local gtab = win:Tab("Global", "sliders")
local gL   = gtab:Section("Lock & Target Options", "Left")
local gR   = gtab:Section("Global Settings", "Right")
gL:Toggle("Lock Rotation", false, function(on) LOCK_ROT = on end)
gL:Toggle("Lock Cube Rotation", false, function(on) LOCK_CUBE_ROT = on end)
gL:Divider("Target Lock / ESP")
gL:Toggle("Global Target Lock", false, function(on) TARGET_LOCK_ON = on end)
gL:Dropdown("Target Mode", {"Closest", "Random"}, {"Closest", "Random"}, false, function(v) TARGET_LOCK_MODE = v[1] end)
gR:Divider("Performance")
gR:Slider("FPS", 120, 1, 0, 300, "", function(v)
    CFG.FPS = v
    REFRESH_RATE = (v <= 0) and 0 or (1 / v)
end)
gR:Divider("Appearance")
gR:Slider("Transparency", 50, 1, 0, 100, "%", function(v)
    CFG.TRANSPARENCY = v/100
    for _, key in ipairs(SHAPE_KEYS) do applyTransp(key, CFG.TRANSPARENCY) end
end)
gR:Slider("Rainbow Speed", 10, 1, 1, 100, "", function(v)
    CFG.RAINBOW_SPEED = v/10
end)

-- ── Per-shape metadata ────────────────────────────────────────────────────────
local SHAPE_META = {
    {key="cone",  label="Cone",         rbOff=0,    colKey="COL_CONE",
     sliders={{"Radius",18,1,3000,function(v) CFG.HAT_RADIUS=v/10 end},{"Height",13,1,3000,function(v) CFG.HAT_HEIGHT=v/10 end}}},
    {key="cube",  label="Cube",         rbOff=0.14, colKey="COL_CUBE",
     sliders={{"Size",20,1,3000,function(v) CFG.CUBE_SIZE=v/10 end}}},
    {key="sphere",label="Sphere",       rbOff=0.28, colKey="COL_SPHERE",
     sliders={{"Radius",12,1,3000,function(v) CFG.SPHERE_RADIUS=v/10 end}}},
    {key="diam",  label="Diamond",      rbOff=0.42, colKey="COL_DIAM",
     sliders={{"Radius",12,1,3000,function(v) CFG.DIAM_RADIUS=v/10 end},{"Height",22,1,3000,function(v) CFG.DIAM_HEIGHT=v/10 end}}},
    {key="torus", label="Torus",        rbOff=0.56, colKey="COL_TORUS",
     sliders={{"Ring Radius",15,1,3000,function(v) CFG.TORUS_RADIUS=v/10 end},{"Tube",5,1,3000,function(v) CFG.TORUS_TUBE=v/10 end}}},
    {key="star",  label="Star",         rbOff=0.70, colKey="COL_STAR",
     sliders={{"Outer Radius",18,1,3000,function(v) CFG.STAR_OUTER=v/10 end},{"Inner Radius",7,1,3000,function(v) CFG.STAR_INNER=v/10 end}}},
    {key="crown", label="Crown",        rbOff=0.84, colKey="COL_CROWN",
     sliders={{"Radius",14,1,3000,function(v) CFG.CROWN_RADIUS=v/10 end},{"Height",16,1,3000,function(v) CFG.CROWN_HEIGHT=v/10 end}}},
    {key="pyra",  label="Pyramid",      rbOff=0.05, colKey="COL_PYRA",
     sliders={{"Radius",15,1,3000,function(v) CFG.PYRA_RADIUS=v/10 end},{"Height",20,1,3000,function(v) CFG.PYRA_HEIGHT=v/10 end}}},
    {key="cyl",   label="Cylinder",     rbOff=0.15, colKey="COL_CYLI",
     sliders={{"Radius",12,1,3000,function(v) CFG.CYLI_RADIUS=v/10 end},{"Height",18,1,3000,function(v) CFG.CYLI_HEIGHT=v/10 end}}},
    {key="caps",  label="Capsule",      rbOff=0.25, colKey="COL_CAPS",
     sliders={{"Radius",10,1,3000,function(v) CFG.CAPS_RADIUS=v/10 end},{"Height",15,1,3000,function(v) CFG.CAPS_HEIGHT=v/10 end}}},
    {key="helix", label="Helix",        rbOff=0.35, colKey="COL_HELIX",
     sliders={{"Radius",15,1,3000,function(v) CFG.HELIX_RADIUS=v/10 end},{"Height",20,1,3000,function(v) CFG.HELIX_HEIGHT=v/10 end},{"Turns",25,1,3000,function(v) CFG.HELIX_TURNS=v/10 end}}},
    {key="icosa", label="Icosahedron",  rbOff=0.55, colKey="COL_ICOSA",
     sliders={{"Radius",13,1,3000,function(v) CFG.ICOSA_RADIUS=v/10 end}}},
    {key="tetra", label="Tetrahedron",  rbOff=0.65, colKey="COL_TETRA",
     sliders={{"Radius",15,1,3000,function(v) CFG.TETRA_RADIUS=v/10 end}}},
    {key="prism", label="Prism",        rbOff=0.75, colKey="COL_PRISM",
     sliders={{"Radius",13,1,3000,function(v) CFG.PRISM_RADIUS=v/10 end},{"Height",18,1,3000,function(v) CFG.PRISM_HEIGHT=v/10 end}}},
    {key="arrow", label="Arrow",        rbOff=0.85, colKey="COL_ARROW",
     sliders={{"Shaft Radius",4,1,3000,function(v) CFG.ARROW_RADIUS=v/10 end},{"Head Radius",9,1,3000,function(v) CFG.ARROW_HEAD_RADIUS=v/10 end},{"Shaft Height",15,1,3000,function(v) CFG.ARROW_SHAFT_H=v/10 end},{"Head Height",10,1,3000,function(v) CFG.ARROW_HEAD_H=v/10 end}}},
    {key="disc",  label="Disc",         rbOff=0.92, colKey="COL_DISC",
     sliders={{"Radius",20,1,3000,function(v) CFG.DISC_RADIUS=v/10 end},{"Thickness",2,1,3000,function(v) CFG.DISC_THICK=v/10 end}}},
    {key="cross", label="Cross",        rbOff=0.99, colKey="COL_CROSS",
     sliders={{"Crossbar Length",10,1,3000,function(v) CFG.CROSS_ARM=v/10 end},{"Bar Width",4,1,3000,function(v) CFG.CROSS_WIDTH=v/10 end},{"Stem Height",24,1,3000,function(v) CFG.CROSS_HEIGHT=v/10 end}}},
    {key="mobius",label="Möbius Strip", rbOff=0.48, colKey="COL_MOBIUS",
     sliders={{"Radius",15,1,3000,function(v) CFG.MOBIUS_RADIUS=v/10 end},{"Width",8,1,3000,function(v) CFG.MOBIUS_WIDTH=v/10 end}}},
    {key="knot",  label="Torus Knot",   rbOff=0.62, colKey="COL_KNOT",
     sliders={{"Radius",20,1,3000,function(v) CFG.KNOT_RADIUS=v/10 end},{"Ribbon Width",4,1,3000,function(v) CFG.KNOT_WIDTH=v/10 end}}},
    {key="hyper", label="Hyperboloid",  rbOff=0.78, colKey="COL_HYPER",
     sliders={{"Base Radius",16,1,3000,function(v) CFG.HYPER_RADIUS=v/10 end},{"Waist Radius",5,1,3000,function(v) CFG.HYPER_WAIST=v/10 end},{"Height",25,1,3000,function(v) CFG.HYPER_HEIGHT=v/10 end}}},
    {key="custom",label="Custom Shape", rbOff=0.90, colKey="COL_CUSTOM", sliders={}},
}

for _, meta in ipairs(SHAPE_META) do
    SHAPE_RBOFF[meta.key]  = meta.rbOff
    SHAPE_COLKEY[meta.key] = meta.colKey
    local key   = meta.key
    local tab   = win:Tab(meta.label, "box")

    -- ── LEFT: shape core ──────────────────────────────────────────────────────
    local secShape = tab:Section(meta.label, "Left")

    secShape:Toggle("Enable", false, function(on)
        setShapeEnabled(key, on)
        Lib:Notify(meta.label, on and "ON" or "OFF", 2)
    end):AddKeybind("", "Toggle")

    if key == "cross" then
        secShape:Dropdown("Symbol", {"Cross"}, {"Cross", "Star of David"}, false, function(v)
            CROSS_STYLE = v[1]
        end)
    end

    if key == "custom" then
        secShape:Divider("Web / Custom JSON Loader")
        secShape:Button("Load from Clipboard URL", function()
            local clip = (getclipboard and getclipboard()) or ""
            if clip:match("^https?://") then
                local success = loadCustomMeshFromURL(clip)
                if success then
                    Lib:Notify("Custom Shape", "Loaded 3D mesh from clipboard URL!", 3)
                else
                    Lib:Notify("Custom Shape", "Failed to parse JSON from URL", 3)
                end
            else
                Lib:Notify("Custom Shape", "Copy a valid URL to clipboard first!", 3)
            end
        end)
        secShape:Button("Load from Clipboard JSON", function()
            local clip = (getclipboard and getclipboard()) or ""
            if clip ~= "" then
                local success = loadCustomMeshFromJSON(clip)
                if success then
                    Lib:Notify("Custom Shape", "Loaded 3D mesh from clipboard JSON!", 3)
                else
                    Lib:Notify("Custom Shape", "Failed to parse JSON from clipboard", 3)
                end
            else
                Lib:Notify("Custom Shape", "Copy JSON text to clipboard first!", 3)
            end
        end)
    end

    secShape:Divider("Color")
    secShape:Toggle("Rainbow", false, function(on) RB[key] = on end)
    secShape:Colorpicker("Color", CFG[meta.colKey], function(c)
        RB[key] = false
        CFG[meta.colKey] = c
        applyColor(key, c)
    end)
    secShape:Slider("Rainbow Speed", 10, 1, 1, 100, "", function(v) CFG.RAINBOW_SPEED = v/10 end)

    secShape:Divider("Size")
    for _, s in ipairs(meta.sliders) do
        secShape:Slider(s[1], s[2], 0.1, 0, s[4]/10, "u", s[5])
    end

    -- ── LEFT: visual / color effects ──────────────────────────────────────────
    local secVisual = tab:Section("Visual FX", "Left")

    secVisual:Divider("Look")
    secVisual:Slider("Transparency", 50, 1, 0, 100, "%", function(v)
        TRANSP[key] = v/100
        if not PULSE_ON[key] then applyShapeTransp(key) end
    end)
    secVisual:Toggle("Pulse", false, function(on)
        PULSE_ON[key] = on
        if not on then TRANSP[key] = CFG.TRANSPARENCY; applyShapeTransp(key) end
    end)
    secVisual:Slider("Pulse Speed", 10, 1, 1, 100, "", function(v) PULSE_SPD[key]=v/10 end)
    secVisual:Slider("Pulse Amount", 40, 1, 0, 100, "%", function(v) PULSE_AMP[key]=v/100 end)
    secVisual:Toggle("Wireframe", false, function(on) WIRE_ON[key]=on end)
    secVisual:Toggle("Outline", false, function(on)
        OUTLINE_ON[key]=on
        if not on then hidePool(TRIS_OUTLINE[key]) end
    end)
    secVisual:Colorpicker("Outline Color", Color3.fromRGB(255,255,255), function(c)
        OUTLINE_COL[key]=c
    end)
    secVisual:Slider("Outline Scale", 15, 1, 101, 200, "%", function(v) OUTLINE_SCALE[key]=v/100 end)

    secVisual:Divider("Color FX")
    secVisual:Toggle("Color by Distance", false, function(on) COLDIST_ON[key]=on end)
    secVisual:Colorpicker("Near Color", Color3.fromRGB(0,255,0), function(c) COL_NEAR[key]=c end)
    secVisual:Colorpicker("Far Color",  Color3.fromRGB(255,0,0), function(c) COL_FAR[key]=c end)
    secVisual:Slider("Fade Distance", 50, 1, 5, 500, "u", function(v)
        COLDIST_MAX[key] = v
        COLDIST_MAX_SQ[key] = v * v
    end)
    secVisual:Toggle("Color Cycle", false, function(on) COLCYCLE_ON[key]=on end)
    secVisual:Colorpicker("Cycle Color A", Color3.fromRGB(255,80,80), function(c) COLCYCLE_A[key]=c end)
    secVisual:Colorpicker("Cycle Color B", Color3.fromRGB(80,80,255), function(c) COLCYCLE_B[key]=c end)
    secVisual:Slider("Cycle Speed", 10, 1, 1, 100, "", function(v) COLCYCLE_SPD[key]=v/10 end)
    secVisual:Toggle("Heat Map", false, function(on) HEATMAP_ON[key]=on end)
    secVisual:Slider("Heat Y Range", 50, 1, 10, 200, "u/s", function(v) HEATMAP_RANGE[key]=v end)
    secVisual:Toggle("Chromatic Split", false, function(on)
        CHROMA_ON[key]=on
        if not on then
            hidePool(TRIS_CHROMA_R[key])
            hidePool(TRIS_CHROMA_B[key])
        end
    end)
    secVisual:Slider("Chroma Offset", 2, 1, 1, 12, "px", function(v) CHROMA_OFF[key]=v end)

    -- ── RIGHT: transform ──────────────────────────────────────────────────────
    local secTransform = tab:Section("Transform", "Right")

    secTransform:Divider("Position")
    secTransform:Slider("X Offset", 0, 0.1, -300, 300, "u", function(v) OFF_X[key]=v end)
    secTransform:Slider("Y Offset", 3, 0.1, -300, 300, "u", function(v) OFF_Y[key]=v end)
    secTransform:Slider("Z Offset", 0, 0.1, -300, 300, "u", function(v) OFF_Z[key]=v end)
    secTransform:Toggle("Position Lerp", false, function(on)
        LERP_ON[key]=on
        if not on then LERP_POS[key].init=false end
    end)
    secTransform:Slider("Lerp Speed", 8, 1, 1, 50, "", function(v) LERP_SPD[key]=v end)
    secTransform:Toggle("Idle Drift", false, function(on) DRIFT_ON[key]=on end)
    secTransform:Slider("Drift Amount", 4, 1, 1, 30, "u", function(v) DRIFT_AMP[key]=v/10 end)
    secTransform:Slider("Drift Speed", 20, 1, 1, 100, "", function(v) DRIFT_SPD[key]=v/10 end)

    secTransform:Divider("Rotation")
    secTransform:Toggle("Lock Rotation", false, function(on) PLOCK_ROT[key] = on end)
    secTransform:Toggle("Lock Cube Rotation", false, function(on) PLOCK_CUBE_ROT[key] = on end)
    secTransform:Toggle("Spin", false, function(on) SPIN_ON[key]=on end)
    secTransform:Slider("Spin Speed", 10, 1, 1, 300, "", function(v) SPIN_SPD[key]=v/10 end)
    secTransform:Toggle("Counter-Spin", false, function(on) CSPIN_ON[key]=on end)
    secTransform:Slider("Counter-Spin Speed", 7, 1, 1, 200, "", function(v) CSPIN_SPD[key]=v/10 end)
    secTransform:Slider("Rotation X", 0, 1, -180, 180, "°", function(v) ROT_X[key]=math.rad(v) end)
    secTransform:Slider("Rotation Y", 0, 1, -180, 180, "°", function(v) ROT_Y[key]=math.rad(v) end)
    secTransform:Slider("Rotation Z", 0, 1, -180, 180, "°", function(v) ROT_Z[key]=math.rad(v) end)

    -- ── RIGHT: motion / animation effects ─────────────────────────────────────
    local secMotion = tab:Section("Motion FX", "Right")

    secMotion:Divider("Orbit")
    secMotion:Toggle("Orbit", false, function(on) ORBIT_ON[key]=on end)
    secMotion:Slider("Orbit Radius", 50, 1, 0, 300, "u", function(v) ORBIT_R[key]=v/10 end)
    secMotion:Slider("Orbit Speed", 10, 1, 1, 100, "", function(v) ORBIT_SPD[key]=v/10 end)
    secMotion:Toggle("Figure-8 Orbit", false, function(on) FIG8_ON[key]=on end)
    secMotion:Slider("Fig-8 Radius", 50, 1, 5, 300, "u", function(v) FIG8_R[key]=v/10 end)
    secMotion:Slider("Fig-8 Speed", 10, 1, 1, 100, "", function(v) FIG8_SPD[key]=v/10 end)

    secMotion:Divider("Scale")
    secMotion:Toggle("Scale Pulse", false, function(on)
        SCALEP_ON[key] = on
        if not on then SCALE[key] = 1.0 end
    end)
    secMotion:Slider("Scale Speed", 10, 1, 1, 100, "", function(v) SCALEP_SPD[key]=v/10 end)
    secMotion:Slider("Scale Amount", 50, 1, 0, 100, "%", function(v) SCALEP_AMP[key]=v/100 end)
    secMotion:Toggle("Speed Scale", false, function(on) SPEED_SCALE_ON[key]=on end)
    secMotion:Slider("Max Speed", 30, 1, 5, 200, "u/s", function(v) SPEED_SCALE_MAX[key]=v end)

    secMotion:Divider("Physics")
    secMotion:Toggle("Bounce", false, function(on) BOUNCE_ON[key]=on end)
    secMotion:Slider("Bounce Speed", 20, 1, 1, 100, "", function(v) BOUNCE_SPD[key]=v/10 end)
    secMotion:Slider("Bounce Height", 10, 1, 1, 100, "u", function(v) BOUNCE_AMP[key]=v/10 end)

    secMotion:Divider("Trail & Pulse")
    secMotion:Toggle("Shake", false, function(on) SHAKE_ON[key]=on end)
    secMotion:Slider("Shake Amount", 3, 1, 1, 50, "", function(v) SHAKE_AMP[key]=v/10 end)
    secMotion:Toggle("Trail", false, function(on)
        TRAIL_ON[key]=on
        if not on then
            for g=1,20 do hidePool(TRIS_TRAIL[key][g]) end
        end
    end)
    secMotion:Slider("Trail Length", 5, 1, 1, 20, "", function(v) TRAIL_LEN[key]=math.floor(v) end)
    secMotion:Slider("Trail Fade", 60, 1, 10, 95, "%", function(v) TRAIL_FADE[key]=v/100 end)
    secMotion:Toggle("Echo Pulse", false, function(on)
        ECHO_ON[key]=on
        if not on then
            ECHO_RINGS[key] = {}
            for r=1,MAX_ECHO do hidePool(TRIS_ECHO[key][r]) end
        end
    end)
    secMotion:Slider("Echo Interval", 12, 1, 3, 100, "ds", function(v) ECHO_INT[key]=v/10 end)
    secMotion:Slider("Echo Expand", 80, 1, 10, 300, "u/s", function(v) ECHO_SPD[key]=v/10 end)
    secMotion:Slider("Echo Max Radius", 120, 1, 20, 500, "u", function(v) ECHO_MAXR[key]=v/10 end)

    secMotion:Divider("Target Lock / ESP")
    secMotion:Toggle("Target Lock", false, function(on) TARGET_ON[key]=on end)
    secMotion:Dropdown("Target Mode", {"Closest", "Random"}, {"Closest", "Random"}, false, function(v) TARGET_MODE[key]=v[1] end)
end

win:AddSettingsTab("cog")

-- ── main loop ─────────────────────────────────────────────────────────────────
task.spawn(function()
    local lastT = os.clock()
    local pi2 = math.pi * 2
    local COL_CHROMA_R = Color3.new(1, 0, 0)
    local COL_CHROMA_G = Color3.new(0, 1, 0)
    local COL_CHROMA_B = Color3.new(0, 0, 1)
    local COL_TRAIL_DIM = Color3.new(0.3, 0.3, 0.3)
    local COL_ECHO_MIX = Color3.new(1, 1, 1)
    while true do
        if REFRESH_RATE <= 0 then task.wait() else task.wait(REFRESH_RATE) end
        local now = os.clock()
        local dt  = now - lastT; lastT = now
        COLOR_NOW = now

        for i = 1, ACTIVE_N do
            local key = ACTIVE_KEYS[i]
            if SPIN_ON[key]  then SPIN_ANG[key]  = SPIN_ANG[key]  + SPIN_SPD[key]  * dt end
            if CSPIN_ON[key] then CSPIN_ANG[key] = CSPIN_ANG[key] - CSPIN_SPD[key] * dt end
            if ORBIT_ON[key] then ORBIT_ANG[key] = ORBIT_ANG[key] + ORBIT_SPD[key] * dt end
            if FIG8_ON[key]  then FIG8_ANG[key]  = FIG8_ANG[key]  + FIG8_SPD[key]  * dt end
            if SCALEP_ON[key] then
                SCALE[key] = 1.0 + SCALEP_AMP[key] * math.sin(now * SCALEP_SPD[key] * pi2)
            elseif not SPEED_SCALE_ON[key] then
                SCALE[key] = 1.0
            end
            if PULSE_ON[key] then
                local pulse = 0.5 + 0.5 * math.sin(now * PULSE_SPD[key] * pi2)
                TRANSP[key] = math.max(0, math.min(1, (1-PULSE_AMP[key]) + PULSE_AMP[key]*(1-pulse)))
                applyShapeTransp(key)
            end
        end

        if ACTIVE_N > 0 then
        local player = Players.LocalPlayer
        local char   = player and player.Character
        local hrp    = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local hpos = hrp.Position
            if LAST_POS then
                local ddx = hpos.X - LAST_POS.X
                local ddy = hpos.Y - LAST_POS.Y
                local ddz = hpos.Z - LAST_POS.Z
                local invDt = 1 / math.max(dt, 0.001)
                CUR_SPEED = CUR_SPEED * 0.8 + math.sqrt(ddx*ddx+ddy*ddy+ddz*ddz) * invDt * 0.2
                CUR_YVEL  = CUR_YVEL  * 0.8 + ddy * invDt * 0.2
            end
            LAST_POS = hpos

            local needEuler = LOCK_ROT or LOCK_CUBE_ROT
            local hrpCF, rvX, rvZ, lvX, lvZ
            if not needEuler then
                for i = 1, ACTIVE_N do
                    local key = ACTIVE_KEYS[i]
                    if PLOCK_ROT[key] or PLOCK_CUBE_ROT[key] then needEuler = true; break end
                end
            end
            if needEuler then
                hrpCF = hrp.CFrame
                local ex, ey, ez = hrpCF:ToEulerAnglesXYZ()
                HRP_EULER.x, HRP_EULER.y, HRP_EULER.z = ex, ey, ez
            end

            for i = 1, ACTIVE_N do
                local key = ACTIVE_KEYS[i]
                local shapeHRP = getTargetHRP(key, hrp)
                local shapePos = shapeHRP.Position
                local shapeCF  = shapeHRP.CFrame
                local lockRot  = PLOCK_ROT[key] or LOCK_ROT

                local baseOffY = OFF_Y[key]
                if BOUNCE_ON[key] then
                    baseOffY = baseOffY + BOUNCE_AMP[key] * math.sin(now * BOUNCE_SPD[key] * pi2)
                end

                local orbitDX, orbitDZ = 0, 0
                if ORBIT_ON[key] then
                    orbitDX = math.cos(ORBIT_ANG[key]) * ORBIT_R[key]
                    orbitDZ = math.sin(ORBIT_ANG[key]) * ORBIT_R[key]
                end
                if FIG8_ON[key] then
                    local t8 = FIG8_ANG[key]
                    local denom = 1 + math.sin(t8) * math.sin(t8)
                    orbitDX = FIG8_R[key] * math.cos(t8) / denom
                    orbitDZ = FIG8_R[key] * math.sin(t8) * math.cos(t8) / denom
                end

                local offX = OFF_X[key] + orbitDX
                local offZ = OFF_Z[key] + orbitDZ
                local wx, wy, wz
                if lockRot then
                    local ex, ey, ez = shapeCF:ToEulerAnglesXYZ()
                    HRP_EULER.x, HRP_EULER.y, HRP_EULER.z = ex, ey, ez
                    rvX, rvZ = shapeCF.RightVector.X, shapeCF.RightVector.Z
                    lvX, lvZ = shapeCF.LookVector.X, shapeCF.LookVector.Z
                    wx = shapePos.X + rvX * offX + lvX * offZ
                    wy = shapePos.Y + baseOffY
                    wz = shapePos.Z + rvZ * offX + lvZ * offZ
                else
                    wx = shapePos.X + offX
                    wy = shapePos.Y + baseOffY
                    wz = shapePos.Z + offZ
                end

                if SHAKE_ON[key] then
                    local amp = SHAKE_AMP[key]
                    wx = wx + (math.random() * 2 - 1) * amp
                    wy = wy + (math.random() * 2 - 1) * amp * 0.5
                    wz = wz + (math.random() * 2 - 1) * amp
                end

                if DRIFT_ON[key] then
                    local dof = DRIFT_OFF[key]
                    local dtgt = DRIFT_TGT[key]
                    if CUR_SPEED < 2.5 then
                        if math.random() < 0.03 then
                            local amp = DRIFT_AMP[key]
                            dtgt.x = (math.random() * 2 - 1) * amp
                            dtgt.y = (math.random() * 2 - 1) * amp * 0.35
                            dtgt.z = (math.random() * 2 - 1) * amp
                        end
                        local kDr = DRIFT_SPD[key] * dt
                        dof.x = dof.x + (dtgt.x - dof.x) * kDr
                        dof.y = dof.y + (dtgt.y - dof.y) * kDr
                        dof.z = dof.z + (dtgt.z - dof.z) * kDr
                    else
                        local fade = 1 - dt * 4
                        dof.x = dof.x * fade
                        dof.y = dof.y * fade
                        dof.z = dof.z * fade
                    end
                    wx = wx + dof.x
                    wy = wy + dof.y
                    wz = wz + dof.z
                end

                local dx, dy, dz = wx, wy, wz
                if LERP_ON[key] then
                    local lp = LERP_POS[key]
                    if not lp.init then
                        lp.x, lp.y, lp.z, lp.init = wx, wy, wz, true
                    end
                    local a = math.min(1, LERP_SPD[key] * dt)
                    lp.x = lp.x + (wx - lp.x) * a
                    lp.y = lp.y + (wy - lp.y) * a
                    lp.z = lp.z + (wz - lp.z) * a
                    dx, dy, dz = lp.x, lp.y, lp.z
                else
                    LERP_POS[key].init = false
                end

                if SPEED_SCALE_ON[key] then
                    local t = math.min(1, CUR_SPEED / SPEED_SCALE_MAX[key])
                    local base = SCALEP_ON[key] and SCALE[key] or 1.0
                    SCALE[key] = base * (1.0 + t * 1.5)
                end

                prepXF(key)

                local ddx2 = dx - hpos.X
                local ddz2 = dz - hpos.Z
                local distSq = ddx2 * ddx2 + ddz2 * ddz2
                local resolvedCol = getShapeColor(key, SHAPE_RBOFF[key], distSq)
                    or CFG[SHAPE_COLKEY[key]]
                    or Color3.new(1, 1, 1)

                local wire = WIRE_ON[key]
                local drawFn = DRAW_FN[key]

                if TRAIL_ON[key] then
                    local idx = TRAIL_IDX[key]
                    local hist = TRAIL_HIST[key][idx]
                    hist.x, hist.y, hist.z = dx, dy, dz
                    TRAIL_IDX[key] = (idx % 20) + 1

                    local len = TRAIL_LEN[key]
                    local trailPool = TRIS_TRAIL[key]
                    for g = 1, len do
                        local histIdx = ((idx - 1 - g + 20) % 20) + 1
                        local hp2 = TRAIL_HIST[key][histIdx]
                        local fadeT = g / len
                        local ghostTransp = math.min(0.99, TRANSP[key] + (1 - TRANSP[key]) * TRAIL_FADE[key] * fadeT)
                        local ghostCol = lerpColor(resolvedCol, COL_TRAIL_DIM, fadeT * 0.5)
                        drawFn(trailPool[g], hp2.x, hp2.y, hp2.z, key, ghostCol, wire, ghostTransp)
                    end
                    for g = len + 1, 20 do hidePool(trailPool[g]) end
                end

                if ECHO_ON[key] then
                    ECHO_TIMER[key] = ECHO_TIMER[key] + dt
                    if ECHO_TIMER[key] >= ECHO_INT[key] then
                        ECHO_TIMER[key] = 0
                        local rings = ECHO_RINGS[key]
                        rings[#rings + 1] = {age = 0, x = dx, y = dy - 2.8, z = dz}
                        if #rings > MAX_ECHO then table.remove(rings, 1) end
                    end
                    local rings = ECHO_RINGS[key]
                    local ringIdx = 0
                    local echoMaxR = ECHO_MAXR[key]
                    local echoSpd = ECHO_SPD[key]
                    for ri = #rings, 1, -1 do
                        local ring = rings[ri]
                        ring.age = ring.age + dt
                        if ring.age * echoSpd >= echoMaxR then
                            table.remove(rings, ri)
                        end
                    end
                    local echoCol = lerpColor(resolvedCol, COL_ECHO_MIX, 0.35)
                    local echoPool = TRIS_ECHO[key]
                    for ri = 1, #rings do
                        ringIdx = ringIdx + 1
                        if ringIdx <= MAX_ECHO then
                            local ring = rings[ri]
                            local rad = ring.age * echoSpd
                            local fade = 1 - rad / echoMaxR
                            local echoTransp = math.min(0.95, TRANSP[key] + (1 - fade) * 0.55)
                            drawEchoRing(echoPool[ringIdx], ring.x, ring.y, ring.z, key, echoCol, wire, echoTransp, rad)
                        end
                    end
                    for r = ringIdx + 1, MAX_ECHO do hidePool(echoPool[r]) end
                end

                if OUTLINE_ON[key] then
                    drawOutlinePass(key, drawFn, dx, dy, dz, resolvedCol)
                    prepXF(key)
                end

                if CHROMA_ON[key] then
                    local co = CHROMA_OFF[key]
                    SCREEN_OFF_X = -co
                    drawFn(TRIS_CHROMA_R[key], dx, dy, dz, key, COL_CHROMA_R, wire, nil)
                    SCREEN_OFF_X = 0
                    drawFn(TRIS[key], dx, dy, dz, key, COL_CHROMA_G, wire, nil)
                    SCREEN_OFF_X = co
                    drawFn(TRIS_CHROMA_B[key], dx, dy, dz, key, COL_CHROMA_B, wire, nil)
                    SCREEN_OFF_X = 0
                else
                    drawFn(TRIS[key], dx, dy, dz, key, resolvedCol, wire, nil)
                end
            end
        else
            for i = 1, ACTIVE_N do hideAll(ACTIVE_KEYS[i]) end
            LAST_POS = nil
            CUR_YVEL = 0
        end
        end
    end
end)

Lib:Notify("HRP Shapes", "v4.3 — Optimized render loop", 4)