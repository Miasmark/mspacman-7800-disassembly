-- Live check for the dot/power-pellet eating handler found via static
-- trace at rom:sub_D1E5/rom:L_D20D/rom:L_D1FD: watches Score (BCD, packed)
-- and the dots-eaten counter (ram_00AA) for the expected steady climb.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local lastScore, lastAA, lastAF = nil, nil, nil
emu.register_frame_done(function()
  F = F + 1
  local s0,s1,s2,s3 = mem:read_u8(0x46), mem:read_u8(0x47), mem:read_u8(0x48), mem:read_u8(0x49)
  local aa = mem:read_u8(0xAA)
  local af = mem:read_u8(0xAF)
  local score = string.format("%02X%02X%02X%02X", s3,s2,s1,s0)
  if score ~= lastScore or aa ~= lastAA or af ~= lastAF then
    print(string.format("frame %d Score=%s DotsEaten=%d ram_00AF=%d", F, score, aa, af))
    lastScore, lastAA, lastAF = score, aa, af
  end
  if F > 2300 then MACHINE:exit() end
end)
