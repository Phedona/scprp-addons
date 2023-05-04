--Luctus Disguise
--Made by OverlordAkise

util.AddNetworkString("luctus_disguise")

LuctusLog = LuctusLog or function()end

net.Receive("luctus_disguise",function(len,ply)
    if not LUCTUS_DISGUISE_ALLOWED_JOBS[team.GetName(ply:Team())] then return end
    local jobname = net.ReadString()
    local model = net.ReadString()
    LuctusLog("Disguise",ply:Nick().."("..ply:SteamID()..") disguised to job "..jobname.." ("..model..")")
    local _rankid = net.ReadString()
    if _rankid != "" and not tonumber(_rankid) then return end
    local jobID = -1
    for k,v in pairs(RPExtraTeams) do
        if v.name and v.name == jobname then
            jobID = k
            break
        end
    end
    if jobID == -1 then return end
    ply:setDarkRPVar("job",jobname)
    if ply:GetNWInt("disguiseTeam",-1) == -1 then
        ply.oldJob = ply:Team()
        ply.oldJobName = team.GetName(ply:Team())
    end
    ply:SetNWInt("disguiseTeam",jobID)
    ply:SetNWInt("jobrank", 0)
    ply:SetNWString("l_nametag","")
    ply:SetModel(model)
    if _rankid != "" then
        local rankid = tonumber(_rankid)
        LuctusDisguiseSetJobRank(ply,jobname,jobID,rankid)
    end
end)

function LuctusDisguiseSetJobRank(ply,jobname,jobid,rankid)
    if luctus_jobranks and luctus_jobranks[jobname] then
        ply:SetNWString("l_nametag",luctus_jobranks[jobname][rankid][1])
        ply:updateJob(ply:getDarkRPVar("job").." ("..luctus_jobranks[jobname][rankid][2]..")")
    elseif JobRanksConfig then
        local tbfyID = JobRanksConfig.JobsRankTables[jobid]
        if not tbfyID then return end
        local subTables = JobRanks[tbfyID]
        if not subTables then return end
        if not subTables.NameRanks or not istable(subTables.NameRanks) then return end
        if not subTables.NameRanks[rankid] then return end
        
        ply:setDarkRPVar("job", ply:JBR_GetJobName(jobid, subTables.NameRanks[rankid]))
        ply:SetNWInt("jobrank", rankid)
    end
end

hook.Add("PlayerSpawn","luctus_disguise_reset",function(ply)
    if ply:GetNWInt("disguiseTeam",-1) != -1 then
        if luctus_jobranks and luctus_jobranks[ply.oldJobName] then
            LuctusJobranksLoadPlayer(ply,ply.oldJob)
        elseif JobRanksConfig then
            LuctusJobranksTBFYRestore(ply,ply.oldJob)
        end
        ply.oldJob = nil
        ply.oldJobName = nil
    end
    ply:SetNWInt("disguiseTeam",-1)
end)

function LuctusJobranksTBFYRestore(Player,NewTeam)
    Player:ResetBGSkins()
	Player:SetNWInt("jobrank", 0)
	Player.JobRank = 0
	local JID = JobRanksConfig.JobsRankTables[NewTeam]
	local JobRankTBL = JobRanks[JID]

    if JobRankTBL then
		local SID = Player:SteamID()
		local Playtime = JBR_Data[SID][JID]
		if !Playtime and !Player.JBR_LoadedTeam[JID] then
			Playtime = 0
			JBR_Data[SID][JID] = 0
		end

		local CurrentRank = Player:Check_JobRank(Playtime, JobRankTBL.ReqRanks)

		Player:SetNWInt("jobrank", CurrentRank)
		Player.JobRank = CurrentRank
		local NameRank = JobRankTBL.NameRanks[CurrentRank]

		local JobName = Player:JBR_GetJobName(Player:Team(), NameRank)
		Player:setDarkRPVar("job", JobName)

		net.Start("jobranks_UpdatePT")
			net.WriteFloat(Playtime)
			net.WriteFloat(JID)
		net.Send(Player)
	end
end

print("[luctus_disguise] sv loaded")