-- Does anything actually READ dat_C000's regions during play?
--
-- Three taps, compared against each other:
--   FONT  $C0C0-$C317  the confirmed character set (positive control --
--                      if MARIA DMAs this block at all, this must light up)
--   TAIL  $C4E0-$CA1F  the 1,344 bytes beyond any possible 8-bit tile code
--   PRE   $C000-$C0BF  tiles $30-$4F (maze walls + 2nd digit set)
--
-- The Atari 7800 BIOS runs a cartridge-checksum sweep at boot (traced
-- previously to RAM-resident code around $23FF, frames ~14-160), which
-- touches every ROM page and would swamp the result. Everything before
-- FIRST_FRAME is therefore discarded, and pre/post counts are reported
-- separately so the exclusion can be checked rather than assumed.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local FIRST_FRAME = 400   -- well past the BIOS checksum window

local REGIONS = {
  {name="FONT", lo=0xC0C0, hi=0xC317},
  {name="TAIL", lo=0xC4E0, hi=0xCA1F},
  {name="PRE",  lo=0xC000, hi=0xC0BF},
}

local F = 0
local pre, post, firstF, lastF, pcs = {}, {}, {}, {}, {}
local TAPS = {}
for _, r in ipairs(REGIONS) do
  pre[r.name], post[r.name], pcs[r.name] = 0, 0, {}
  TAPS[r.name] = mem:install_read_tap(r.lo, r.hi, r.name, function(offset, data)
    if F < FIRST_FRAME then
      pre[r.name] = pre[r.name] + 1
    else
      post[r.name] = post[r.name] + 1
      if not firstF[r.name] then firstF[r.name] = F end
      lastF[r.name] = F
      local pc = cpu.state["GENPC"].value
      pcs[r.name][pc] = (pcs[r.name][pc] or 0) + 1
    end
    return data
  end)
end

local function report()
  print(string.format("=== after excluding frames < %d (BIOS checksum window) ===", FIRST_FRAME))
  for _, r in ipairs(REGIONS) do
    local n = r.hi - r.lo + 1
    print(string.format("%-5s $%04X-$%04X (%4d bytes): pre-cutoff=%-6d  AFTER=%-8d first=%s last=%s",
      r.name, r.lo, r.hi, n, pre[r.name], post[r.name],
      tostring(firstF[r.name]), tostring(lastF[r.name])))
    local list = {}
    for pc, c in pairs(pcs[r.name]) do list[#list+1] = {pc, c} end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    for i = 1, math.min(#list, 4) do
      print(string.format("        reader PC=$%04X x%d", list[i][1], list[i][2]))
    end
  end
end

emu.register_frame_done(function()
  F = F + 1
  if F > 6000 then report(); MACHINE:exit() end
end)
