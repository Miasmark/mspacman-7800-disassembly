-- Checks what actually lands in ram_2150-ram_216F (the maze color/attribute
-- copy destination) right after wave-start init, and specifically whether
-- ram_216C-ram_216F (the suspected mode-timer schedule bytes) get
-- overwritten by that same copy -- i.e. whether dat_DF21's per-variant
-- 32-byte blocks double as the scatter/chase duration schedule seed.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last216C, last216D, last216E, last216F = nil, nil, nil, nil
local lastMCV = nil
emu.register_frame_done(function()
  F = F + 1
  local mcv = mem:read_u8(0xA5)
  local c,d,e,g = mem:read_u8(0x216C), mem:read_u8(0x216D), mem:read_u8(0x216E), mem:read_u8(0x216F)
  if c~=last216C or d~=last216D or e~=last216E or g~=last216F or mcv~=lastMCV then
    print(string.format("frame %d MazeColorVariant=%d 216C=%02X 216D=%02X 216E=%02X 216F=%02X",
      F, mcv, c, d, e, g))
    last216C,last216D,last216E,last216F,lastMCV = c,d,e,g,mcv
  end
  if F > 3000 then MACHINE:exit() end
end)
