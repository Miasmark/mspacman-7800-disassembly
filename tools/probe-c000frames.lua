-- Which FRAMES read dat_C000's three regions? Cheap counter only (calling
-- cpu.state inside the tap hangs MAME). The BIOS cartridge-checksum sweep
-- is confined to boot (~frames 14-160, established earlier); anything
-- later is the game's own ROM->RAM graphics loading.
local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local R={{"PRE",0xC000,0xC0BF},{"TILEGRID",0xC0C0,0xC4DF},{"TAIL",0xC4E0,0xCA1F}}
local F,cur,hits=0,{},{}
local T={}
for _,r in ipairs(R) do
  local n=r[1]; cur[n]=0; hits[n]={}
  T[n]=mem:install_read_tap(r[2],r[3],n,function(o,d) cur[n]=cur[n]+1; return d end)
end
emu.register_frame_done(function()
  F=F+1
  for _,r in ipairs(R) do
    local n=r[1]
    if cur[n]>0 then hits[n][#hits[n]+1]={F,cur[n]}; cur[n]=0 end
  end
  if F>=16000 then
    for _,r in ipairs(R) do
      local n=r[1]; local h=hits[n]
      local boot,later,ltot=0,0,0
      for _,e in ipairs(h) do
        if e[1]<300 then boot=boot+e[2] else later=later+1; ltot=ltot+e[2] end
      end
      print(string.format("%-9s $%04X-$%04X : boot(<f300)=%d bytes | AFTER BOOT: %d frames, %d bytes",
        n,r[2],r[3],boot,later,ltot))
      local shown=0
      for _,e in ipairs(h) do
        if e[1]>=300 and shown<6 then print(string.format("        frame %6d : %d bytes",e[1],e[2])); shown=shown+1 end
      end
    end
    M:exit()
  end
end)
