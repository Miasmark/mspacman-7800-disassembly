-- Hunt for the lives-remaining counter: dump all of zero-page RAM
-- ($0080-$00FF, the low-RAM scratch/state region) right as the real
-- game begins (frame ~2144 in run-02.inp, already established), then
-- watch every byte in that range for the rest of the recording, flagging
-- any that changes exactly once or twice (a life lost is a rare event,
-- unlike the constantly-churning per-frame scratch bytes).
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local baseline = nil
local changeCount = {}

emu.register_frame_done(function()
  F = F + 1
  if F == 2144 then
    baseline = {}
    local line = {}
    for a = 0x40, 0xFF do
      baseline[a] = mem:read_u8(a)
      changeCount[a] = 0
      line[#line+1] = string.format("%02X", baseline[a])
    end
    print("BASELINE at frame 2144:")
    print(table.concat(line, " "))
  end
  if baseline and F > 2144 then
    for a = 0x40, 0xFF do
      local v = mem:read_u8(a)
      if v ~= baseline[a] then
        changeCount[a] = changeCount[a] + 1
        baseline[a] = v
      end
    end
  end
  if F > 26000 then
    print("=== bytes that changed only 1-4 times across the whole recording ===")
    for a = 0x40, 0xFF do
      if changeCount[a] and changeCount[a] >= 1 and changeCount[a] <= 4 then
        print(string.format("$%02X: changed %d times", a, changeCount[a]))
      end
    end
    MACHINE:exit()
  end
end)
