-- UDim2 class
UDim2 = {}
UDim2.__index = UDim2

function UDim2.new(scaleX, offsetX, scaleY, offsetY)
    local self = setmetatable({}, UDim2)
    self.scaleX = scaleX or 0
    self.offsetX = offsetX or 0
    self.scaleY = scaleY or 0
    self.offsetY = offsetY or 0
    return self
end

function UDim2:calculate(parentX, parentY, parentWidth, parentHeight)
    local x = parentX + (self.scaleX * parentWidth) + self.offsetX
    local y = parentY + (self.scaleY * parentHeight) + self.offsetY
    return x, y
end

-- UIElement class
UIElement = {}
UIElement.__index = UIElement

function UIElement.new(params)
    local self = setmetatable({}, UIElement)
    self.position = params.position or UDim2.new()
    self.size = params.size or UDim2.new()
    self.children = {}
    self.absolutePosition = {
        x = 0,
        y = 0
    }
    self.absoluteSize = {
        width = 0,
        height = 0
    }
    self.cornerRadius = params.cornerRadius or 0
    self.stroke = params.stroke or {
        width = 0,
        color = {0, 0, 0, 0}
    }
    return self
end

function UIElement:child(child)
    table.insert(self.children, child)
end

function UIElement:update(parentX, parentY, parentWidth, parentHeight, dt)
    local x, y = self.position:calculate(parentX, parentY, parentWidth, parentHeight)
    local width, height = self.size:calculate(0, 0, parentWidth, parentHeight)

    self.absolutePosition.x = x
    self.absolutePosition.y = y
    self.absoluteSize.width = width
    self.absoluteSize.height = height

    for _, child in ipairs(self.children) do
        child:update(x, y, width, height, dt)
    end
end

function UIElement:draw(parentX, parentY, parentWidth, parentHeight)
    local x, y = self.position:calculate(parentX, parentY, parentWidth, parentHeight)
    local width, height = self.size:calculate(0, 0, parentWidth, parentHeight)

    self:drawElement(x, y, width, height)

    for _, child in ipairs(self.children) do
        child:draw(x, y, width, height)
    end
end

function UIElement:drawScreen()
    local parentWidth, parentHeight = love.graphics.getDimensions()
    self:draw(0, 0, parentWidth, parentHeight)
end

function UIElement:drawElement(x, y, width, height)
    if self.stroke.width > 0 then
        love.graphics.setColor(self.stroke.color)
        love.graphics.setLineWidth(self.stroke.width)
        love.graphics.rectangle("line", x, y, width, height, self.cornerRadius, self.cornerRadius)
    end
end

function UIElement:mousepressed(mx, my, button, istouch, presses)
    if button == 1 and self:isInBounds(mx, my) then
        self:onMousePressed(mx, my, button, istouch, presses)
    end

    for _, child in ipairs(self.children) do
        child:mousepressed(mx, my, button, istouch, presses)
    end
end

function UIElement:onMousePressed(mx, my, button, istouch, presses)
    -- Override in subclasses to handle mouse pressed event
end

function UIElement:isInBounds(x, y)
    return x >= self.absolutePosition.x and x <= (self.absolutePosition.x + self.absoluteSize.width) and y >=
               self.absolutePosition.y and y <= (self.absolutePosition.y + self.absoluteSize.height)
end

-- UIFrame class
UIFrame = setmetatable({}, {
    __index = UIElement
})

function UIFrame.new(params)
    local self = UIElement.new(params)
    setmetatable(self, {
        __index = UIFrame
    })
    self.color = params.color or {1, 1, 1, 1}
    return self
end

function UIFrame:drawElement(x, y, width, height)
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", x, y, width, height, self.cornerRadius, self.cornerRadius)
    UIElement.drawElement(self, x, y, width, height)
end

-- UITextLabel class
UITextLabel = setmetatable({}, {
    __index = UIElement
})

function UITextLabel.new(params)
    local self = UIElement.new(params)
    setmetatable(self, {
        __index = UITextLabel
    })
    self.text = params.text or ""
    self.fontSize = params.fontSize or 12
    self.textColor = params.textColor or {1, 1, 1, 1}
    self.textScaled = params.textScaled or false
    return self
end

function UITextLabel:drawElement(x, y, width, height)
    love.graphics.setColor(self.textColor)

    if self.textScaled then
        -- Calculate the scale factor based on both width and height
        local fontHeight = height
        local fontWidth = width / #self.text * 1.6 -- The factor 1.6 is an approximation; adjust as needed

        -- Choose the smaller of the two to fit the text within the label
        local fontSize = math.min(fontHeight, fontWidth)

        local scaleFont = love.graphics.newFont(fontSize)
        love.graphics.setFont(scaleFont)
    else
        local font = love.graphics.newFont(self.fontSize)
        love.graphics.setFont(font)
    end

    love.graphics.printf(self.text, x, y, width, "center")
end

-- UITextButton class
UITextButton = setmetatable({}, {
    __index = UITextLabel
})

function UITextButton.new(params)
    local self = UITextLabel.new(params)
    setmetatable(self, {
        __index = UITextButton
    })
    self.color = params.color or {0.5, 0.5, 0.5, 1}
    self.callback = params.callback or function()
    end
    self.isMouseOver = false
    return self
end

function UITextButton:drawElement(x, y, width, height)
    local drawColor = self.color
    if self.isMouseOver then
        drawColor = {drawColor[1] * 0.9, drawColor[2] * 0.9, drawColor[3] * 0.9, drawColor[4]}
    end
    love.graphics.setColor(drawColor)
    love.graphics.rectangle("fill", x, y, width, height, self.cornerRadius, self.cornerRadius)
    UITextLabel.drawElement(self, x, y, width, height)
    UIElement.drawElement(self, x, y, width, height)
end

function UITextButton:onMousePressed(mx, my, button, istouch, presses)
    if button == 1 then
        self.callback()
    end
end

function UITextButton:isInBounds(x, y)
    local inBounds = UIElement.isInBounds(self, x, y)
    self.isMouseOver = inBounds
    return inBounds
end

-- Override mousemoved to track mouse hover state
function UIElement:mousemoved(mx, my, dx, dy, istouch)
    if self:isInBounds(mx, my) then
        if not self.isMouseOver then
            self.isMouseOver = true
        end
    else
        if self.isMouseOver then
            self.isMouseOver = false
        end
    end

    for _, child in ipairs(self.children) do
        child:mousemoved(mx, my, dx, dy, istouch)
    end
end

ScreenGui = UIElement.new({position = UDim2.new(0, 0, 0, 0), size = UDim2.new(1, 0, 1, 0)})