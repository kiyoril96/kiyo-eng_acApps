-- Access OBS helper library:
local obs = require('shared/utils/obs')

local shot1
local shot2
local texture = obs.register(
  'OBS Texture App',
  'spectator view',
  obs.Flags.ManualUpdate + obs.Flags.ApplyCMAA + obs.Flags.UserSize,
  nil,
  function (canvas,size)
    local node = ac.findNodes('sceneRoot:yes')
    if shot1 then shot1:dispose() end
    if shot2 then shot2:dispose() end
    shot1 = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.None,render.TextureFlags.Shared)
    shot2 = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.None,render.TextureFlags.Shared)
    shot1:setShadersType(render.ShadersType.Main)
    shot1:setParticles(true)
    shot1:setTransparentPass(true)
    shot1:setSky(true)
    shot1:setMaxLayer(5)
    shot1:setOriginalLighting(true)

    shot1:updateWithTrackCamera(0)

    shot2:setShadersType(render.ShadersType.SimplifiedWithLights)
    shot2:setParticles(true)
    shot2:setTransparentPass(true)
    shot2:setSky(true)
    shot2:setMaxLayer(5)
    shot2:setOriginalLighting(true)

    shot2:updateWithTrackCamera(0)

    canvas:updateWithShader({
      textures = { tx1 = shot1 ,tx2 = shot2},
      shader = [[
        float4 main(PS_IN I){
          float4 r1 = tx1.Sample(samLinear,I.Tex);
          float4 r2 = tx2.Sample(samLinear,I.Tex);
          float4 ret = (r1*0.7) + (r2*0.3);
          ret = ret / (1+ret);
        return float4(ret.rgb,1);
      }]]
    })
  end
)

local cshot
local pos
local dir
local up 
local fov
local ccam = obs.register(
  'OBS Texture App',
  'ccam',
  obs.Flags.ManualUpdate + obs.Flags.ApplyCMAA + obs.Flags.UserSize,
  nil,
  function (canvas,size)
    local node = ac.findNodes('sceneRoot:yes')
    if cshot then cshot:dispose() end
    cshot = ac.GeometryShot(node, size, 1, false, render.AntialiasingMode.None,render.TextureFlags.Shared)
    cshot:setShadersType(render.ShadersType.Main)
    cshot:setParticles(true)
    cshot:setTransparentPass(true)
    cshot:setSky(true)
    cshot:setMaxLayer(5)
    cshot:setOriginalLighting(true)
    cshot:update(pos,dir,up,fov)

    canvas:updateWithShader({
      textures = { tx1 = cshot},
      shader = [[
        float4 main(PS_IN I){
          float4 r1 = tx1.Sample(samLinear,I.Tex);
          float4 ret = r1;
          ret = ret / (1+ret);
        return float4(ret.rgb,1);
      }]]
    })
  end
)

local car 
local simstate
function camera()
  local pos
  local dir
  local up 
  local fov = 70
  local carVelocity = smoothing(vec3(), 40)
  local lastCarPos = vec3()
  local lookDirection = smoothing(0, 10)
  local t1,t2,t3,t4 = car.wheels[0],car.wheels[1],car.wheels[2],car.wheels[3]
  local centpos = (t1.position+ t2.position+ t3.position+ t4.position)/4 
  local carPos = centpos --car.position
  local whlooks = ((t1.look+ t2.look+ t3.look+ t4.look )/4):normalize()
  local carDir = car.look
  local carUp = car.up
  local carRight = math.cross(carDir, carUp):normalize()
  local distance = 4
  local height =1
  local pitchAngle = -22

  --if calculateVelocityHere then
    -- Altenative approach, using coordinates and time delta
  if lastCarPos ~= carPos then
    if lastCarPos ~= vec3() then
      local delta = lastCarPos - carPos
      local deltaLength = #delta
      if deltaLength > 5 then delta = delta / deltaLength * 5 end
      carVelocity:update(-delta / dt)
    end
    lastCarPos = carPos
  end
  --else
  --  -- Update smoothing thing with velocity:
  --  -- Note: method `updateIfNew` would change value only if parameter is different from the one used last 
  --  -- time. This way, in replays camera will freeze.
  --  carVelocity:updateIfNew(ac.getCarVelocity())
  --end

  local carVelocityDir = math.normalize(carVelocity.val + carDir * 0.01)
  local velocityX = math.clamp(math.dot(carRight, carVelocityDir) * math.pow(#carVelocity.val, 0.5) / 10, -1, 1)
  local cameraAngle = -velocityX * math.radians(54)
  --lookDirection:update(math.sign(lookDirection.val))
  cameraAngle = cameraAngle + lookDirection.val * math.pi
  local sinAngle = math.sin(cameraAngle)
  local cosAngle = math.cos(cameraAngle)
  pos = (vec3(carPos.x ,carPos.y ,carPos.z )) + (carRight * sinAngle - carDir * cosAngle) * distance + vec3(0,height,0)
  local cameraLookPosOffset = carDir + carUp * (1-math.abs(lookDirection.val))
  local cameraLook = (carPos + cameraLookPosOffset - pos ):normalize()
  cameraLook:rotate(quat.fromAngleAxis(math.radians(pitchAngle), carRight))
  dir = cameraLook
  up = (carUp + vec3(0,3,0)):normalize()

  ac.forceVisibleHeadNodes(0, true)

  return {pos = pos , direction = dir , up = up  , fov = fov }
end

function script.simUpdate()
  texture:update()
  car= ac.getCar()
  simstate = ac.getSim()
  local params = camera()
  pos = params.pos 
  dir = params.direction
  up = params.up
  fov = params.fov
  ccam:update()
end

function update(dt)
  ac.debug('aa' , simstate.cameraPosition)
  
end