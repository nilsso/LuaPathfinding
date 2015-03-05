require "helper"

local NODE_INVALID_INDEX = -1

-- ----------------------------------------------------------------------------
-- SparseGraph
-- ----------------------------------------------------------------------------
local SparseGraph = {}


--- Constructor
--  @param isDigraph Is graph a digraph (default false)
function SparseGraph:new(isDigraph)
    isDigraph = isDigraph or false
    assert(type(isDigraph) == "boolean",
        "<SparseGraph:new> isDigraph non-boolean")
    local o = {
        -- Members
        nodes = {},
        edges = {},
        firstFree = 1,
        isDigraph = isDigraph
    }
    setmetatable(o, self)
    self.__index = self
    setmetatable(o.nodes, {
        __len = function(o)
            local count = 0
            for i, v in ipairs(o) do
                if v.index ~= NODE_INVALID_INDEX then
                    count = count + 1
                end
            end
            return count
        end
    })

    DEBUG_MSG("<SparseGraph:new> isDigraph:%s", isDigraph)
    return o
end


--- Add node
--  @return New node index
function SparseGraph:addNode()
    local index = self.firstFree

    if not self.nodes[self.firstFree] then
        -- New node from scratch

        self.nodes[index] = {
            index = index,
            nextFree = nil
        }

        -- New node edges
        self.edges[index] = {}

        self.firstFree = index + 1
    else
        -- New node from deactivated node
        self.nodes[index].index = index
        self.firstFree = self.nodes[index].nextFree
        self.nodes[index].nextFree = nil
    end

    DEBUG_MSG("<SparseGraph:addNode> index:%d", index)
    return index
end


--- Add graph edge
--  @param from Edge origin node index
--  @param to Edge destination node index
function SparseGraph:addEdge(from, to, cost)
    assert(from > 0 and from <= #self.nodes,
        '<SparseGraph:addEdge> "from" node invalid')
    assert(self.nodes[from].index ~= NODE_INVALID_INDEX,
        '<SparseGraph:addEdge> "from" node innactive')

    cost = cost or 1
    assert(type(cost) == 'number',
        '<SparseGraph:addEdge> cost not numeric')

    local edge

    if to ~= NODE_INVALID_INDEX then
        -- To actual index
        assert(to > 0 and to <= #self.nodes,
            '<SparseGraph:addEdge> "to" node invalid')
        assert(self.nodes[to].index ~= NODE_INVALID_INDEX,
            '<SparseGraph:addEdge> "to" node innactive')

        -- Make edge if doesn't exist
        if not self.edges[from][to] then
            self.edges[from][to] = {
                from = from,
                to = to,
                cost = cost
            }
            DEBUG_MSG("<SparseGraph:addEdge> from:%d to:%d", from, to)
        else
            DEBUG_MSG('<SparseGraph:addEdge> from:%d to:%d (ignored, redundant)', from, to)
        end

        -- If digraph, make edge in opposite direction if doesn't exist
        if self.isDigraph and not self.edges[to][from] then
            self.edges[to][from] = {
                from = to,
                to = from,
                cost = cost
            }
            DEBUG_MSG("<SparseGraph:addEdge> from:%d to:%d (digraph edge)", to, from)
        else
            DEBUG_MSG('<SparseGraph:addEdge> from:%d to:%d (digraph edge) (ignored, redundant)', to, from)
        end
    else
        -- To nothing (invalid)
        if not self.edges[from][to] then
            self.edges[from][NODE_INVALID_INDEX] = {
                from = from,
                to = NODE_INVALID_INDEX,
                cost = cost
            }
            DEBUG_MSG("<SparseGraph:addEdge> from:%d to:NODE_INVALID_INDEX", from)
        else
            DEBUG_MSG('<SparseGraph:addEdge> from:%d to:NODE_INVALID_INDEX (ignored, redundant)', from)
        end
    end

    return self.edges[from][to]
end


--- Remove graph node
--  @param index Index of node to remove
function SparseGraph:removeNode(index)
    assert(index <= #self.nodes and
        self.nodes[index].index ~= NODE_INVALID_INDEX,
        "<SparseGraph:removeNode> Invalid index")

    DEBUG_MSG('<SparseGraph:removeNode> index:%d', index)

    -- If digraph, remove edges in opposite direction ("to" node)
    if self.isDigraph then
        for to, node in pairs(self.edges[index]) do
            self:removeEdge(to, index)
        end
    end

    self.nodes[index].index = NODE_INVALID_INDEX

    -- Remove edges ("from" node)
    for to, node in pairs(self.edges[index]) do
        self:removeEdge(index, to)
    end

    -- Set first free to removed index
    self.nodes[index].nextFree = self.firstFree
    self.firstFree = index
end


--- Remove graph edge
--  @param from Edge origin node index
--  @param to Edge destination node index
function SparseGraph:removeEdge(from, to)
    assert(from > 0 and from <= #self.nodes,
        '<SparseGraph:removeEdge> "from" node invalid')
    assert(self.nodes[from] ~= NODE_INVALID_INDEX,
        '<SparseGraph:removeEdge> "from" node innactive')

    if to ~= NODE_INVALID_INDEX then
        -- To actual index
        assert(to > 0 and to <= #self.nodes,
            '<SparseGraph:removeEdge> "to" node invalid')
        assert(self.nodes[to] ~= NODE_INVALID_INDEX,
            '<SparseGraph:removeEdge> "to" node innactive')

        -- Remove edge if exists
        if self.edges[from][to] then
            self.edges[from][to] = NODE_INVALID_INDEX
            DEBUG_MSG('<SparseGraph:removeEdge> from:%d to:%d', from, to)
        end

        -- If digraph, remove edge in opposite direction if exists
        if self.isDigraph and self.edges[to][from] then
            self.edges[to][from] = NODE_INVALID_INDEX
            DEBUG_MSG('<SparseGraph:removeEdge> from:%d to:%d (digraph edge)', to, from)
        end
    else
        -- To nothing (invalid)
        self.edges[from][NODE_INVALID_INDEX] = nil -- Completely remove
        DEBUG_MSG('<SparseGraph:removeEdge> from:%d to:NODE_INVALID_INDEX', from, to)
    end
end


--- Get total number of edges
--  @return Total number of edges
function SparseGraph:numEdges()
    local count = 0
    for i, v in pairs(self.edges) do
        count = count + #v
    end
    return count
end


function SparseGraph:addNodesAsGrid(xdivisions, ydivisions)
    DEBUG_MSG('<AddNodesAsGrid>')
    for i = 1, xdivisions * ydivisions do
        self:addNode()
    end

    local i
    for y = 1, ydivisions do

        DEBUG_MSG('<AddNodesAsGrid> new row (%s)', y)

        for x = 1, xdivisions do
            i = x + (y-1) * xdivisions
            if x <= xdivisions-1 then
                self:addEdge(i, i+1)
            end
            if y <= ydivisions-1 then
                self:addEdge(i, i+xdivisions)
            end
        end
    end
end


-- ----------------------------------------------------------------------------
-- Depth First Search (DFS)
-- ----------------------------------------------------------------------------


--- Sparse graph depth first search
--  @return if destination found, table of nodes to destination, else false
local function Search_DFS(graph, origin, target)
    assert(graph.__index == SparseGraph,
        '<Search_DFS> invalid graph type')
    assert(graph.nodes[origin] and graph.nodes[origin].index ~= NODE_INVALID_INDEX,
        '<Search_DFS> invalid "origin" node')
    assert(graph.nodes[target] and graph.nodes[target].index ~= NODE_INVALID_INDEX,
        '<Search_DFS> invalid "target" node')

    DEBUG_MSG(string.format('<Search_DFS> origin:%s target:%s', origin, target))

    local VISITED = true
    local UNVISITED = false

    local visited = {}
    local route = {}
    local stack = {}
    local found = false

    -- Dummy edge
    stack[1] = {
        from = origin,
        to = origin
    }

    -- Find route
    while #stack > 0 do
        -- Pop top edge from stack
        local currentEdge = table.remove(stack, 1)

        DEBUG_MSG('<Search_DFS> testing edge from:%s to:%s', currentEdge.from, currentEdge.to)
        DEBUG_MSG('<Search_DFS> number of edges: %s', table.maxn(graph.edges[currentEdge.to]))

        -- Take note of parent of node edge points to
        route[currentEdge.to] = currentEdge.from

        -- Mark as visited
        visited[currentEdge.to] = VISITED

        if currentEdge.to == target then
            found = true
            DEBUG_MSG('<Search_DFS> found target')
            break
        end

        -- Add edges in stack pattern
        for _, edge in pairs(graph.edges[currentEdge.to]) do
            if not visited[edge.to] then
                DEBUG_MSG('<Search_DFS> stack inserted edge from:%s to:%s', edge.from, edge.to)
                table.insert(stack, 1, edge)
            end
        end

        DEBUG_MSG('<Search_DFS> stack status:')
        for k, v in pairs(stack) do
            DEBUG_MSG('<Search_DFS>     edge from:%s to:%s', v.from, v.to)
        end
    end

    if found then
        return route
    else
        DEBUG_MSG('<Search_DFS> failed to find target')
        return false
    end
end


-- ----------------------------------------------------------------------------
-- Breadth First Search
-- ----------------------------------------------------------------------------


--- Sparse graph breadth first search
--  @return if destination found, table of nodes to destination, else false
local function Search_BFS(graph, origin, target)
    assert(graph.__index == SparseGraph,
        '<Search_DFS> invalid graph type')
    assert(graph.nodes[origin] and graph.nodes[origin].index ~= NODE_INVALID_INDEX,
        '<Search_DFS> invalid "origin" node')
    assert(graph.nodes[target] and graph.nodes[target].index ~= NODE_INVALID_INDEX,
        '<Search_DFS> invalid "target" node')

    DEBUG_MSG(string.format('<Search_DFS> origin:%s target:%s', origin, target))

    local VISITED = true
    local UNVISITED = false

    local visited = {}
    local route = {}
    local stack = {}
    local found = false

    -- Dummy edge
    stack[1] = {
        from = origin,
        to = origin
    }

    -- Find route
    while #stack > 0 do
        -- Pop top edge from stack
        local currentEdge = table.remove(stack, 1)

        DEBUG_MSG('<Search_DFS> testing edge from:%s to:%s', currentEdge.from, currentEdge.to)
        DEBUG_MSG('<Search_DFS> number of edges: %s', table.maxn(graph.edges[currentEdge.to]))

        -- Take note of parent of node edge points to
        route[currentEdge.to] = currentEdge.from

        -- Mark as visited
        visited[currentEdge.to] = VISITED

        if currentEdge.to == target then
            found = true
            DEBUG_MSG('<Search_DFS> found target')
            break
        end

        -- Add edges in queue pattern
        for _, edge in pairs(graph.edges[currentEdge.to]) do
            if not visited[edge.to] then
                DEBUG_MSG('<Search_DFS> stack inserted edge from:%s to:%s', edge.from, edge.to)
                stack[#stack+1] = edge
            end
        end

        DEBUG_MSG('<Search_DFS> stack status:')
        for k, v in pairs(stack) do
            DEBUG_MSG('<Search_DFS>     edge from:%s to:%s', v.from, v.to)
        end
    end

    if found then
        return route
    else
        DEBUG_MSG('<Search_DFS> failed to find target')
        return false
    end
end


-- ----------------------------------------------------------------------------
-- Dijkstra's Search
-- ----------------------------------------------------------------------------


--- Sparse graph Dijkstra search
--  @return if destination found, table of nodes to destination, else false
local function Search_Dijkstra(graph, origin, target)
    assert(graph.__index == SparseGraph,
        '<Search_DFS> invalid graph type')
    assert(graph.nodes[origin] and graph.nodes[origin].index ~= NODE_INVALID_INDEX,
        '<Search_DFS> invalid "origin" node')
    assert(graph.nodes[target] and graph.nodes[target].index ~= NODE_INVALID_INDEX,
        '<Search_DFS> invalid "target" node')

    DEBUG_MSG(string.format('<Search_DFS> origin:%s target:%s', origin, target))

    local VISITED = true
    local UNVISITED = false

    local visited = {}
    local route = {}
    local stack = {}
    local found = false

    -- Dummy edge
    stack[1] = {
        from = origin,
        to = origin
    }

    -- Find route
    while #stack > 0 do
        -- Pop top edge from stack
        local currentEdge = table.remove(stack, 1)

        DEBUG_MSG('<Search_DFS> testing edge from:%s to:%s', currentEdge.from, currentEdge.to)
        DEBUG_MSG('<Search_DFS> number of edges: %s', table.maxn(graph.edges[currentEdge.to]))

        -- Take note of parent of node edge points to
        route[currentEdge.to] = currentEdge.from

        -- Mark as visited
        visited[currentEdge.to] = VISITED

        if currentEdge.to == target then
            found = true
            DEBUG_MSG('<Search_DFS> found target')
            break
        end

        -- Add edges in queue pattern
        for _, edge in pairs(graph.edges[currentEdge.to]) do
            if not visited[edge.to] then
                DEBUG_MSG('<Search_DFS> stack inserted edge from:%s to:%s', edge.from, edge.to)
                stack[#stack+1] = edge
            end
        end

        DEBUG_MSG('<Search_DFS> stack status:')
        for k, v in pairs(stack) do
            DEBUG_MSG('<Search_DFS>     edge from:%s to:%s', v.from, v.to)
        end
    end

    if found then
        return route
    else
        DEBUG_MSG('<Search_DFS> failed to find target')
        return false
    end
end


-- ----------------------------------------------------------------------------
-- Helper functions
-- ----------------------------------------------------------------------------


-- Node printer helper
local function PrintNodes(graph)
    if #graph.nodes > 0 then
        for i = 1, rawlen(graph.nodes) do
            if graph.nodes[i].index ~= NODE_INVALID_INDEX then
                io.write('[ ]')
            else
                io.write(string.format('[%d]', graph.nodes[i].nextFree))
            end
        end
        io.write(string.format(' firstFree:%s size:%s\n', graph.firstFree, rawlen(graph.nodes)))
    else
        print('<PrintNodes> No nodes!')
    end
end


-- Edge printer helper
local function PrintEdges(graph)
    for from, edges in pairs(graph.edges) do
        for _, to in pairs(edges) do
            if to.index then
                -- Edge to valid
                if to.index == from then
                    -- Edge to self
                    for i = 1, from-1 do
                        io.write('   ')
                    end
                    io.write('[S]\n')
                else
                    -- Edge to other
                    if to.index > from then
                        -- "to" greater than "from"
                        for i = 1, from-1 do
                            io.write('   ')
                        end
                        io.write(string.format('[%s-', from))
                        for i = from, to.index-2 do
                            io.write('---')
                        end
                        io.write(string.format('>%d]', to.index))
                    else
                        -- "from" greater than "to"
                        for i = 1, to.index-1 do
                            io.write('   ')
                        end
                        io.write(string.format('[%s<', to.index))
                        for i = to.index, from-2 do
                            io.write('---')
                        end
                        io.write(string.format('-%d]', from))
                    end
                    io.write('\n')
                end
            else
                -- Edge to invalid
                for i = 1, from-1 do
                    io.write('   ')
                end
                io.write('[N]\n')
            end
        end
    end
end


local function RouteToFile(route)
    local fileName = 'route.txt'
    local file = io.open(fileName, 'w')
    for to, from in pairs(route) do
        file:write(string.format('%s %s\n', to, from))
    end
    io.close(file)
end


-- Module
return {
    SparseGraph = SparseGraph,
    Search_DFS = Search_DFS,
    Search_BFS = Search_BFS
}

