-- Checks whether Cruise Elroy ever actually activates (ram_2144 slot 0
-- going nonzero) in this recording, and what DotsEatenCount/thresholds
-- looked like at the time, to see if the mechanism found statically
-- (rom:sub_D777's speed-code set, rom:sub_DEF7's duty-cycle read) is
-- reachable in practice here.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last2144, lastAA = nil, nil
emu.register_frame_done(function()
  F = F + 1
  local v = mem:read_u8(0x2144)
  local aa = mem:read_u8(0xAA)
  if v ~= last2144 or aa ~= lastAA then
    print(string.format("frame %d ram_2144[0]=%d DotsEatenCount=%d F9=%02X FA=%02X",
      F, v, aa, mem:read_u8(0xF9), mem:read_u8(0xFA)))
    last2144, lastAA = v, aa
  end
  if F > 26000 then MACHINE:exit() end
end)
