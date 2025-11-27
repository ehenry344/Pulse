--!strict

-- try to coalesce these probe objects into one

-- // Types //
local Types = require(script.Parent.Types)

local ClientProbe: Types.ClientProbeProto = {} :: Types.ClientProbeProto
ClientProbe.__index = ClientProbe

function ClientProbe.new(name: string, stream: Types.ClientStream, config: Types.ProbeConfig?)
	local self = {
		_name = name,
		_stream = stream,
		
		_updateCooldown = config and config.cooldown or 0,
		
		_timestamp = os.clock()
	}
	
	return setmetatable(self, ClientProbe)
end

function ClientProbe:TakeReading(v: number)
	local currentTime = os.clock()

	
	if currentTime - self._timestamp > self._updateCooldown then
		self._timestamp = currentTime
		
		local packet: Types.ProbeDataPacket = {
			probeName = self._name,
			timestamp = currentTime,
			payload = v
		}
		
		self._stream:WriteData(packet)
	end
end

return ClientProbe

