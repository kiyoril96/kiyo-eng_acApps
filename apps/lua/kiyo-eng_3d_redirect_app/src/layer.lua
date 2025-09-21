---@class Layer : ClassBase
---@field layerNum number @ リダイレクトレイヤーの番号
---@field followingType Layer.FollowingType
---@field posision vec3
---@field offset vec3 @ アプリのメッシュを配置する位置の原点からの相対座標
---@field look vec3
---@field up vec3
---@field side vec3
---@field layerSize vec2 @ レイヤーへ転送されたアプリ全体の大きさ
---@field rotationx number
---@field rotationy number
---@field rotationz number
---@field uiScale number @ 大きさ m単位
---@field brightness number @ 明るさ
---@field opacity number @ 不透明度
---@field apps string[] @ このレイヤーにあるアプリのリスト
---@field debugPoint boolean @ デバッグ表示
---@field canvas ui.ExtraCanvas @ テクスチャになるキャンバス
---@field obs boolean @ OBSへ転送するかどうか 未実装

Layer = class('Layer')

---@alias Layer.FollowingType
---| `FollowingType.driver`
---| `FollowingType.car`
-- ---| `FollowingType.chaserCamera`
---| `FollowingType.word`
Layer.FollowingType = {
    driver = 0
    ,car = 1
    --,chaserCamera = 2
    ,world = 3
}

function Layer:getState()
    local ret = {}
    ret.layerNum = self.layerNum
    ret.followingType = self.followingType
    self.offset:copyTo(ret.offset) 
    ret.rotationx = self.rotationx
    ret.rotationy = self.rotationy
    ret.rotationz = self.rotationz
    ret.uiScale = self.uiScale
    ret.brightness = self.brightness
    ret.opacity = self.opacity
    ret.appsNum = #self.apps
    return ret
end

---@return number
function Layer:getLayerNum() return self.layerNum end
---@return Layer.FollowingType
function Layer:getFollowingType() return self.followingType end
---@return vec3
function Layer:getOffset() return self.offset end
---@return number
function Layer:getRotationx() return self.rotationx end
---@return number
function Layer:getRotationy() return self.rotationy end
---@return number
function Layer:getRotationz() return self.rotationz end
---@return number
function Layer:getScale() return self.uiScale end
---@return number
function Layer:getBrightness() return self.brightness end
---@return number
function Layer:getOpacity() return self.opacity end
---@return string[]
function Layer:getApps() return self.apps end
---@return ui.ExtraCanvas
function Layer:getCanvas() return self.canvas end
-----@return boolean
--function Layer:isObsDuplicate() return self.obs end
---@return boolean
function Layer:isDebug() return self.debugPoint end


-- TODO setterでは関連するモノを更新したい
-- あと値チェックな
---@param followingType Layer.FollowingType
function Layer:setFollowingType(followingType)
    self.followingType = followingType
end
---@param offset vec3
function Layer:setOffset(offset)
    self.offset:set(offset)
end
---@param rotx number
function Layer:setRotationx(rotx)
    self.rotationx=rotx
end
---@param roty number
function Layer:setRotationy(roty)
    self.rotationy=roty
end
---@param rotz number
function Layer:setRotationz(rotz)
    self.rotationz=rotz
end
---@param scale number
function Layer:setScale(scale)
    self.uiScale =scale
end
---@param brightness number
function Layer:setBrightness(brightness) 
    self.brightness = brightness 
end
---@param opacity number
function Layer:setOpacity(opacity) 
    self.opacity = opacity 
end

---@param layerNum number 
---@param appname string
function Layer:initialize(layerNum,appname)
    self.layerNum = layerNum
    self.position = vec3()
    self.look = vec3()
    self.up = vec3()
    self.side = vec3()
    self.layerSize = vec2()
    self.obs = false
    self.offset = vec3()
    self.rotationx = 0 
    self.rotationy = 0 
    self.rotationz = 0 
    self.uiScale = 0.1
    self.brightness = 10
    self.opacity = 1
    self.apps = {}
    self.windowSize = ac.getSim().windowSize
    self.canvas = nil
    self.minPos = vec2()
    self.debugPoint = false

    self:addApp(appname)
    return self
end

---@param appname string @ アプリの名前
function Layer:addApp(appname)
    table.insert(self.apps, appname)
    self:layerUpdate()
end

---@param appname string @ アプリの名前
---@return number @ 更新されたレイヤー内アプリの件数 0件になったらインスタンス自体削除してほしい
function Layer:deleteApp(appname)
    table.removeItem( self.apps, appname )
    if #self.apps > 0 then
        self:layerUpdate()
    else
        self.canvas:dispose()
        self.canvas = nil
    end
    return #self.apps
end

-- function Layer:update()
--     self:layerUpdate()
--     self:canvasUpdate()
--     self:positionUpdate()
--     self:rotationUpdate()
-- end

function Layer:layerUpdate()
    -- layer.apps のアプリに対してPositionのMin、sizeのMaxを探す
    local layerSize = vec2()
    if #self.apps == 1 then
        local window = ac.accessAppWindow(self.apps[1])
        if window then 
            self.minPos:set(window:position())
            layerSize:set(window:size())
        end
    else
        local minPos = self.windowSize*2
        local maxSizeVec = vec2()
        for l=1 , #self.apps do
            local window = ac.accessAppWindow(self.apps[l])
            if window then 
                minPos = minPos:min(window:position())
                maxSizeVec = maxSizeVec:max( window:position()+window:size())
            end 
            self.minPos:set(minPos)
        end
        layerSize:set(maxSizeVec - minPos)
    end

    if layerSize ~= self.layerSize then 
        self.layerSize = layerSize
        if self.appCanvas then self.appCanvas:dispose() end
        self.canvas = ui.ExtraCanvas(
            self.layerSize
            ,1
            ,render.AntialiasingMode.None
            ,render.TextureFormat.R8G8B8A8.SNorm
            ,render.TextureFlags.None
        )
        self.canvas:setName('layer'..self.layerNum)
    end    
end

function Layer:canvasUpdate()
    self.canvas:clear()
    self.canvas:updateWithShader({
        p2 = self.windowSize,
        uv1 = self.minPos/self.windowSize,
        textures = {tx1 = 'dynamic::hud::redirected::'..self.layerNum},
        shader = [[
            float4 main(PS_IN pin){
                float4 ret = tx1.Sample(samLinear,pin.Tex);
                return float4(ret.rgba);
            }]]
    })
end

function Layer:positionUpdate()
    if self.followingType == Layer.FollowingType.world then
        self.position:set(self.offset)
        self.look:set(0,0,1)
        self.up:set(0,1,0)
        self.side:set(1,0,0)
    else
        local car = ac.getCar(0) or {look =vec3(0,0,1) ,up =vec3(0,1,0) ,side =vec3(1,0,0)}
        self.look:set(car.look)
        self.up:set(car.up)
        self.side:set(car.side)
        local pos = vec3()
        if self.followingType == Layer.FollowingType.driver then
            pos:set(car.driverEyesPosition)
        elseif self.followingType == Layer.FollowingType.car then
            pos:set(car.position)
        end
        self.position:set(pos +
            self.side*self.offset.x +
            self.up*self.offset.y +
            self.look*self.offset.z
        )
    end
end

function Layer:rotationUpdate()
    local axisx = vec3()
    local axisy = vec3()
    local axisz = vec3()

    if self.followingType == Layer.FollowingType.world then
        axisx:set(0,0,1)
        axisy:set(0,1,0)
        axisz:set(1,0,0)
    else
        local car = ac.getCar(0) or {look =vec3(0,0,1) ,up =vec3(0,1,0) ,side =vec3(1,0,0)}
        axisx:set(car.look)
        axisy:set(car.up)
        axisz:set(car.side)
    end

    local radx = math.radians(self.rotationx) or 0
    local rady = math.radians(self.rotationy) or 0
    local radz = math.radians(self.rotationz) or 0

    self.look:rotate(quat.fromAngleAxis(radz,axisz))
    self.side:rotate(quat.fromAngleAxis(radz,axisz))
    self.up:rotate(quat.fromAngleAxis(radz,axisz))
    self.look:rotate(quat.fromAngleAxis(radx,axisx))
    self.side:rotate(quat.fromAngleAxis(radx,axisx))
    self.up:rotate(quat.fromAngleAxis(radx,axisx))
    self.look:rotate(quat.fromAngleAxis(rady,axisy))
    self.side:rotate(quat.fromAngleAxis(rady,axisy))
    self.up:rotate(quat.fromAngleAxis(rady,axisy))
end

function Layer:getQuadPoints()
    local uiscale = (self.layerSize:normalize()*self.uiScale)
    local sideScaled = self.side*(uiscale.x)
    local upScaled = self.up*(uiscale.y)
    local quadPoints = {
        p1 = self.position + (sideScaled) + (upScaled)            
        ,p2 = self.position + (-sideScaled) + (upScaled)
        ,p3 = self.position + (-sideScaled) + (-upScaled)
        ,p4 = self.position + (sideScaled) + (-upScaled)
    }
    return quadPoints
end 

function Layer:drop()
    self.canvas:dispose()
end