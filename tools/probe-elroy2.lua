-- Re-check: ram_2144,X is ALSO written unconditionally by sub_DAC3 (fright
-- start, value 1) and sub_DAF8 (speed-cadence wrap cleanup, value 0) --
-- completely unrelated to Cruise Elroy. Watch ram_2144 slot 0 together with
-- GhostFrightFlag slot 0 and DotsEatenCount to see whether the earlier
-- "Elroy activation" at frame ~21685 was actually a fright-start event.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last2144, lastFright, lastAA = nil, nil, nil
emu.register_frame_done(function()
  F = F + 1
  local v = mem:read_u8(0x2144)
  local fr = mem:read_u8(0x2140)
  local aa = mem:read_u8(0xAA)
  if v ~= last2144 or fr ~= lastFright or aa ~= lastAA then
    print(string.format("frame %d ram_2144[0]=%d GhostFrightFlag[0]=%d DotsEatenCount=%d",
      F, v, fr, aa))
    last2144, lastFright, lastAA = v, fr, aa
  end
  if F > 22000 then MACHINE:exit() end
end)
