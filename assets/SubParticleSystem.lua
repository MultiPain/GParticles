--!NOEXEC

local ui = UI

SubParticleSystem = Core.class()

function SubParticleSystem:init()
	self.particles = Particles.new()
	
	local preview = Options.PREVIEW_SIZE
	self.view = RenderTarget.new(preview, preview)
	
	
end
--
function SubParticleSystem:draw()
	ui:text("Helo")
end