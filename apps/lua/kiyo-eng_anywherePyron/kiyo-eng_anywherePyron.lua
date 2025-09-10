local trackRef = ac.findNodes('trackRoot:yes')
local conesRef = trackRef:createNode('CONES',false)
local pyronButton = ac.ControlButton("__EXT_ANYWHERE_PYRON_PUT")
local config = ac.storage{
    isActive = true,
    isPutMode = false,
    isPhys = false,
    putOffsetX = 0,
    putOffsetY = 0,
    putOffsetZ = 5
}

function windowMain()
    if ui.checkbox('##active',config.isActive) then
        config.isActive = not config.isActive
    end
    ui.sameLine()
    ui.dwriteText('Active')
    ui.offsetCursorY(10)
    if ui.checkbox('##putMode',config.isPutMode) then
        config.isPutMode = not config.isPutMode
    end
    ui.sameLine()
    ui.dwriteText('Mouse put mode')
    ui.offsetCursorY(10)
    if ui.checkbox('##putPhys',config.isPhys) then
        config.isPhys = not config.isPhys
    end
    ui.sameLine()
    ui.dwriteText('Put physics cone')
    ui.offsetCursorY(10)
    if ui.button('Add One##addOne',vec2(100,30) ) then
        addOne(getPutPos())
    end
    ui.offsetCursorY(10)
    if ui.button('Delete one ##deleteAll',vec2(100,30) ) then
        deleteOne()
    end
    ui.offsetCursorY(5)
    if ui.button('Delete all ##deleteAll',vec2(100,30) ) then
        deleteAll()
    end

    ui.setCursor(vec2(180,30))

    ui.dwriteText('KEY:')
    ui.sameLine()
    ui.offsetCursorX(5)
    pyronButton:control(vec2(150,30))

    ui.setCursor(vec2(180,130))
    ui.dwriteText('Add one put offset')

    ui.setCursor(vec2(180,160))
    ui.dwriteText('  X :')
    ui.setCursor(vec2(220,160))
    ui.setNextItemWidth(100)
    local value, changed = ui.slider('##offsetX',config.putOffsetX,-20,20)
    if changed then config.putOffsetX = value end
    ui.sameLine()
    if ui.smallButton('R##resetx') then config.putOffsetX =0 end

    ui.setCursor(vec2(180,190))
    ui.dwriteText('  Y :')
    ui.setCursor(vec2(220,190))
    ui.setNextItemWidth(100)
    local value, changed = ui.slider('##offsetY',config.putOffsetY,-20,20)
    if changed then config.putOffsetY = value end
    ui.sameLine()
    if ui.smallButton('R##resety') then config.putOffsetY =0 end

    ui.setCursor(vec2(180,220))
    ui.dwriteText('  Z :')
    ui.setNextItemWidth(100)
    ui.setCursor(vec2(220,220))
    local value, changed = ui.slider('##offsetZ',config.putOffsetZ,-20,20)
    if changed then config.putOffsetZ = value end
    ui.sameLine()
    if ui.smallButton('R##resetz') then config.putOffsetZ =5 end

end

function getPutPos()
    local car = ac.getCar(0)
    local wheels = car.wheels 
    local offset = (car.side * config.putOffsetX) +(car.up *config.putOffsetY) +(car.look * config.putOffsetZ)
    vec3(config.putOffsetX,config.putOffsetY,config.putOffsetZ)
    return (( wheels[0].contactPoint + wheels[1].contactPoint )/2)  + offset
end

local cones = {}
function addOne(pos)
    local cone = conesRef:loadKN5('./cone.kn5')
    local rigitBody =nil
    if config.isPhys then
        local aa, bb = cone:getLocalAABB()
        local size = bb - aa
        local collider = physics.Collider.Box(size, vec3(0,size.y/2,0) ,vec3(0,0,1) ,vec3(0,1,0), false)
        local transform = cone:getTransformationRaw()
        local damping = 0.1 / ac.getSim().fps 
        rigitBody = physics.RigidBody(collider, 0.8 )
        transform.position = pos
        rigitBody:setTransformation(transform)
        rigitBody:setDamping(damping,damping,true)
        rigitBody:onCollision(function (c) 
            local dir = ac.getCar(c).velocity:normalize()
            local foce = -ac.getCar(c).acceleration 
            rigitBody:addForce(dir*foce , false, rigitBody:getLastHitPos(), false) 
            end)
    end
    cone:setPosition(pos)
    table.insert(cones,{cone,rigitBody})
end

function deleteOne()
    local latestCone = cones[#cones][1]
    latestCone:dispose()
    table.remove(cones,#cones)
end

function deleteAll()
    conesRef:dispose()
    conesRef=trackRef:createNode('CONES',false)
    table.clear(cones)
end

function update(dt)
    conesRef:setVisible(config.isActive)
    if config.isActive then 
        if config.isPutMode then 
            local ray = render.createMouseRay()
            local hitDistance = trackRef:raycast(ray,false)
            if hitDistance ~= -1 and ac.getUI().isMouseLeftKeyClicked then
                local pos = ray.pos:addScaled(ray.dir,hitDistance)
                addOne(pos)
            end
        end
        if pyronButton:pressed() then
            addOne(getPutPos())
        end
        for i = 1 ,#cones do
            if cones[i][2] then
                cones[i][1]:setTransformationFrom(cones[i][2])
            end
        end
    end
end

