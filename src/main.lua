DEBUG = false
local GraphModule = require 'graph'
local SparseGraph   = GraphModule.SparseGraph
local Search_DFS    = GraphModule.Search_DFS
local Search_BFS    = GraphModule.Search_BFS

local numUnitsX = 12
local numUnitsY = 9
local numUnits = numUnitsX * numUnitsY
local unitWidth
local unitHiehgt

local graph = SparseGraph:new(true)
graph:addNodesAsGrid(numUnitsX, numUnitsY)
local source
local target
local searchMap

local selectedSearch = 1

function love.load()
    unitWidth = love.window.getWidth() / numUnitsX
    unitHeight = love.window.getHeight() / numUnitsY

    love.graphics.setLineStyle('smooth')
end


--function love.update(dt)
--end


function love.draw()
    -- Nodes
    love.graphics.setLineWidth(1)
    for i = 1, numUnits do
        local x = (i-1) % numUnitsX * unitWidth
        local y = math.floor((i-1) / numUnitsX) * unitHeight

        if i ~= source and i ~= target then
            love.graphics.setColor(255, 255, 255, 127)
            love.graphics.rectangle("line", x, y, unitWidth, unitHeight)
        elseif i == source then
            love.graphics.setColor(0, 0, 255, 127)
            love.graphics.rectangle("fill", x, y, unitWidth, unitHeight)
        else
            love.graphics.setColor(255, 0, 0, 127)
            love.graphics.rectangle("fill", x, y, unitWidth, unitHeight)
        end

            love.graphics.setColor(255, 255, 255, 255)
        love.graphics.print(tostring(i), x, y)
    end

    -- Route
    love.graphics.setLineWidth(8)
    if route then
        --print("DRAW ROUTE")
        for node, parent in pairs(searchMap) do
            local nodeX = (node-1) % numUnitsX * unitWidth
            local nodeY = math.floor((node-1) / numUnitsX) * unitHeight
            local parentX = (parent-1) % numUnitsX * unitWidth
            local parentY = math.floor((parent-1) / numUnitsX) * unitHeight

            love.graphics.setColor(255, 255, 255, 127)
            love.graphics.line(
                unitWidth/2 + nodeX,
                unitHeight/2 + nodeY,
                unitWidth/2 + parentX,
                unitHeight/2 + parentY)
        end

        for i, pair in ipairs(route) do
            local nodeX = (pair[1]-1) % numUnitsX * unitWidth
            local nodeY = math.floor((pair[1]-1) / numUnitsX) * unitHeight
            local parentX = (pair[2]-1) % numUnitsX * unitWidth
            local parentY = math.floor((pair[2]-1) / numUnitsX) * unitHeight

            -- 255 - 170 = 85
            -- 85 / #route = hue increment

            love.graphics.setColor(HSL(255 - i * (85 / #route), 255, 127, 127))
            love.graphics.line(
                unitWidth/2 + nodeX,
                unitHeight/2 + nodeY,
                unitWidth/2 + parentX,
                unitHeight/2 + parentY)
        end
    end
end


function love.mousepressed(x, y, button)
    x = math.ceil(x / (love.window.getWidth() / numUnitsX))
    y = math.ceil(y / (love.window.getHeight() / numUnitsY))
    local node = x + (y-1) * numUnitsX

    if button == 'l' then
        source = node
        if target == node then
            target = nil
        end
    else
        target = node
        if source == node then
            source = nil
        end
    end

    if source and target then
        -- Get search map
        if selectedSearch == 1 then
            searchMap = Search_DFS(graph, source, target)
        elseif selectedSearch == 2 then
            searchMap = Search_BFS(graph, source, target)
        end

        -- Get route
        if searchMap then
            -- Get route from target back to source
            route = {}
            local node = target
            while node ~= source do
                table.insert(route, {node, searchMap[node]}) -- Add to route
                node, searchMap[node] = searchMap[node], nil -- funny swap
            end
        end
    end
end


function love.keypressed(key, isRepeat)
    if key == 'escape' then
        love.event.quit()
    elseif key == ' ' then
        selectedSearch = 1 + ((selectedSearch) % 2)
        if selectedSearch == 1 then
            print('selected search: Search_DFS')
        elseif selectedSearch == 2 then
            print('selected search: Search_BFS')
        end
    end
end

