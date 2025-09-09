local trackRef = ac.findNodes('trackRoot:yes')
local conesRef = trackRef:createNode('cones',false)
local point = vec3()
local pyronButton = ac.ControlButton("__EXT_ANYWHERE_PYRON_PUT")
local config = ac.storage{
    isActive = true,
    isPutMode = false
}

function windowMain()
    if ui.checkbox('##active',config.isActive) then
        config.isActive = not config.isActive
    end
    ui.sameLine()
    ui.dwriteText('Active')
    ui.sameLine()
    ui.offsetCursorX(50)
    if ui.checkbox('##putMode',config.isPutMode) then
        config.isPutMode = not config.isPutMode
    end
    ui.sameLine()
    ui.dwriteText('Mouse Put Mode')

    ui.offsetCursorY(20)
    if ui.button('Add One##addOne',vec2(100,30) ) then
        local wheels = ac.getCar(0).wheels 
        local pos=(( wheels[0].contactPoint + wheels[1].contactPoint )/2)  + ac.getCar(0).look*5
        addOne(pos)
    end
    ui.sameLine()
    ui.offsetCursorX(50)
    ui.dwriteText('KEY:')
    ui.sameLine()
    ui.offsetCursorX(5)
    pyronButton:control(vec2(100,30))

    ui.offsetCursorY(20)
    if ui.button('Delete ALL ##deleteAll',vec2(100,30) ) then
        deleteAll()
    end
end

function addOne(pos)
    local corn = conesRef:loadKN5('./cone.kn5')
    corn:setPosition(pos)
end

local time = 0
function addOneInterval(dt)
    time = time + dt
    if time >= 0.5 then 
        local wheels = ac.getCar(0).wheels 
        local pos=(( wheels[0].contactPoint + wheels[1].contactPoint )/2)  + ac.getCar(0).look*5
        addOne(pos)
        time = 0
    end
end

function deleteAll()
    conesRef:dispose()
    conesRef=trackRef:createNode('cones',false)
end

function update(dt)
    conesRef:setVisible(config.isActive)
    if config.isActive and config.isPutMode then 
        local ray = render.createMouseRay()
        local hitDistance = trackRef:raycast(ray,false)
        if hitDistance ~= -1 then
            if ac.getUI().isMouseLeftKeyClicked then
                point = ray.pos:addScaled(ray.dir,hitDistance)
                addOne(point)
            end
        end
    end
    if config.isActive then
        if pyronButton:pressed() then
            local wheels = ac.getCar(0).wheels 
            local pos=(( wheels[0].contactPoint + wheels[1].contactPoint )/2)  + ac.getCar(0).look*5
            addOne(pos)
        end
    end

end

