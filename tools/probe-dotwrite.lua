-- Uses a debugger memory watchpoint (not frame-boundary PC sampling, which
-- is known to only catch the idle vblank-wait loop) to find what code
-- actually writes to Score (ram_0046) and Score2 (ram_004C) -- looking for
-- a dot-eating call site distinct from the already-found fruit/ghost paths
-- (both of which stage through ScoreDeltaHi/Lo + sub_F61A).
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local cpu = MACHINE.devices[":maincpu"]
local mem = cpu.spaces["program"]
local F = 0
local hits = 0

local function onwrite(offset, data)
  hits = hits + 1
  if hits <= 60 then
    print(string.format("frame %d PC=%04X wrote %02X to %04X", F, cpu.state["PC"].value, data, offset))
  end
end

cpu.debug:wpset(mem, "w", 0x46, 1, "", onwrite)
cpu.debug:wpset(mem, "w", 0x4C, 1, "", onwrite)
cpu.debug:wpset(mem, "w", 0xBB, 1, "", onwrite)
cpu.debug:wpset(mem, "w", 0xBC, 1, "", onwrite)

emu.register_frame_done(function()
  F = F + 1
  if F > 4000 then MACHINE:exit() end
end)
