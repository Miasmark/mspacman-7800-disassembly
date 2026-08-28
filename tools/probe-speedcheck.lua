-- Tracks the per-wave "speed" plumbing: WaveCounter, the dat_DCF9-derived
-- period byte at ram_00F3, and the live movement-cadence counter at
-- ram_00DC, printing whenever any of them changes. Used to confirm that
-- starting a game on the Teddy Bear level-select option (WaveCounter=0)
-- loads a much larger cadence period than starting on a later fruit.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local lastA6, lastF3, lastDC = nil, nil, nil
emu.register_frame_done(function()
  F = F + 1
  local vA6 = mem:read_u8(0xA6)
  local vF3 = mem:read_u8(0xF3)
  local vDC = mem:read_u8(0xDC)
  if vA6 ~= lastA6 or vF3 ~= lastF3 or vDC ~= lastDC then
    print(string.format("frame %d WaveCounter=%d ram_00F3=%d ram_00DC=%d",
      F, vA6, vF3, vDC))
    lastA6, lastF3, lastDC = vA6, vF3, vDC
  end
  if F > 30000 then MACHINE:exit() end
end)
