-- Who reads dat_C000, separating the BIOS cartridge-checksum sweep from
-- the GAME's own reads by READER PC rather than by frame number.
--   BIOS checksum : runs from a RAM-resident copy (PC in $2000-$2FFF)
--   game          : runs from ROM  (PC >= $C000)
local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local cpu=M.devices[":maincpu"]
local R={{"PRE",0xC000,0xC0BF},{"TILEGRID",0xC0C0,0xC4DF},{"TAIL",0xC4E0,0xCA1F}}
local bios,game,pcs,firstf,lastf={},{},{},{},{}
local F=0
local T={}
for _,r in ipairs(R) do
  local n=r[1]; bios[n],game[n],pcs[n]=0,0,{}
  T[n]=mem:install_read_tap(r[2],r[3],n,function(off,data)
    local pc=cpu.state["GENPC"].value
    if pc>=0x2000 and pc<=0x2FFF then bios[n]=bios[n]+1
    else
      game[n]=game[n]+1; pcs[n][pc]=(pcs[n][pc] or 0)+1
      if not firstf[n] then firstf[n]=F end
      lastf[n]=F
    end
    return data
  end)
end
emu.register_frame_done(function()
  F=F+1
  if F>15000 then
    print("=== dat_C000 readers, split by reader PC ===")
    for _,r in ipairs(R) do
      local n=r[1]
      print(string.format("%-9s $%04X-$%04X : BIOS-checksum=%-6d  GAME=%-7d frames %s..%s",
        n,r[2],r[3],bios[n],game[n],tostring(firstf[n]),tostring(lastf[n])))
      local l={} ; for pc,c in pairs(pcs[n]) do l[#l+1]={pc,c} end
      table.sort(l,function(a,b) return a[2]>b[2] end)
      for i=1,math.min(#l,3) do print(string.format("        game reader PC=$%04X x%d",l[i][1],l[i][2])) end
    end
    M:exit()
  end
end)
