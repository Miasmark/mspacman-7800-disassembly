-- Samples the CPU's PC at register_frame_done boundaries during the
-- confirmed cutscene window (frames ~13400-13560 in run-02.inp) to find
-- which routine(s) are executing the intermission, distinct from normal
-- gameplay or the maze-reload code already traced.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local cpu = MACHINE.devices[":maincpu"]
local F = 0
local START, STOP = 13350, 13560
emu.register_frame_done(function()
  F = F + 1
  if F >= START and F <= STOP then
    local pc = cpu.state["PC"].value
    print(string.format("frame %d pc=$%04X", F, pc))
  end
  if F > STOP then MACHINE:exit() end
end)
