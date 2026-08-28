-- Confirms whether sub_DE8B (the dat_DF21 -> ram_2150-216F copy) really
-- runs again at wave transitions (via the L_F6DA/sub_CC73 chain found
-- statically), by watching WaveCounter/MazeScheduleIndex/MazeColorVariant
-- alongside the mode-timer schedule bytes together.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last = {}
local function chk(name, addr)
  local v = mem:read_u8(addr)
  if v ~= last[name] then
    print(string.format("frame %d %s=%02X", F, name, v))
    last[name] = v
  end
end
emu.register_frame_done(function()
  F = F + 1
  chk("WaveCounter", 0xA6)
  chk("MazeScheduleIndex", 0xA7)
  chk("MazeColorVariant", 0xA5)
  chk("216C", 0x216C)
  chk("216D", 0x216D)
  chk("216E", 0x216E)
  chk("216F", 0x216F)
  if F > 7200 then MACHINE:exit() end
end)
