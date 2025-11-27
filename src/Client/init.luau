--!strict

-- // Services //
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Dependencies //
local ClientProbe = require(script.ClientProbe)
local ClientStream = require(script.ClientStream)

-- // Types Module //
local Types = require(script.Types)

-- TEST DEPENDENCY
local UIController = require(script.UIController)

-- // Remotes //
local PulseLink = ReplicatedStorage:WaitForChild("PulseEngineLink")

local ClientMonitor = {}

local registry = {
	clientStreams = {} :: {[string]: Types.ClientStream},
	serverStreams = {} :: {[string]: Types.ClientStream}
}


function ClientMonitor.RegisterProbe(probeName: string)
	if not registry.clientStreams[probeName] then
		local probeOutput = UIController.CreateProbeOutput(probeName)
		
		local probeStream = ClientStream.new(probeName, probeOutput)
		
		local newProbe = ClientProbe.new(probeName, probeStream)
		
		registry.clientStreams[probeName] = probeStream
		
		return newProbe
	else
		error(string.format("probe registration fail, probe %q already exists", probeName))
	end
end

if PulseLink and PulseLink:IsA("RemoteEvent") then
	PulseLink.OnClientEvent:Connect(function(packet)	
		if packet.packetType == "RegisterProbe" then
			local probeName = packet.probeName
			
			if not registry.serverStreams[probeName] then
				local stream = ClientStream.new(
					"Serverprobe_"..probeName.."_Stream", 
					UIController.CreateProbeOutput(probeName)
				)
				
				registry.serverStreams[probeName] = stream
			end
		elseif packet.packetType == "DataPacket" then
			local stream = registry.serverStreams[packet.probeName]
			if stream then
				stream:WriteData({
					probeName = packet.probeName,
					timestamp = packet.timestamp, 
					payload = packet.payload
				})
			end
		end 
	end)
	
	-- poke network to get the link setup
	PulseLink:FireServer({packet_type="SetupLink"})
end

return ClientMonitor
