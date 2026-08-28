-- Live spot-check for the static ghost-logic trace: GhostFrightFlag
-- (ram_2140,X) around power-pellet events, ChaseModeFlag (ram_00FF)
-- transitions over time, and GhostState (ram_2138,X) values seen.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local lastFright = {nil,nil,nil,nil}
local lastState = {nil,nil,nil,nil}
local lastChase = nil
emu.register_frame_done(function()
  F = F + 1
  local chase = mem:read_u8(0xFF)
  if chase ~= lastChase then
    print(string.format("frame %d ChaseModeFlag=%d", F, chase))
    lastChase = chase
  end
  for i=0,3 do
    local fr = mem:read_u8(0x2140+i)
    local st = mem:read_u8(0x2138+i)
    if fr ~= lastFright[i+1] then
      print(string.format("frame %d GhostFrightFlag[%d]=%d", F, i, fr))
      lastFright[i+1] = fr
    end
    if st ~= lastState[i+1] then
      print(string.format("frame %d GhostState[%d]=%d", F, i, st))
      lastState[i+1] = st
    end
  end
  if F > 26000 then MACHINE:exit() end
end)
