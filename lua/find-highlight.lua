local M = {}

---@param node TSNode
---@param startLine integer
---@param hlgroup string
---@param reverse boolean?
---@return TSNode|false
local function ckTSNode(node, startLine, hlgroup, reverse)
    reverse = reverse or false

    if node:child_count() == 0 then
        local sr, sc, er, ec = vim.treesitter.get_node_range(node)
        if reverse and sr > startLine then
            return false
        elseif not reverse and er < startLine then
            return false
        end

        local captures = vim.treesitter.get_captures_at_pos(0, sr, sc)

        for _, capture in pairs(captures) do
            -- the first condition handles scenarios such as
            -- hlgroup = @markup.heading, capture.capture = @markup.heading.1.markdown
            if vim.startswith('@' .. capture.capture, hlgroup .. '.') or '@' .. capture.capture == hlgroup then
                return node
            end
        end
    end

    local count = node:child_count()
    for i = 0, count do
        local c
        if reverse then
            c = node:child(count - 1 - i)
        else
            c = node:child(i)
        end
        if c ~= nil then
            local n = ckTSNode(c, startLine, hlgroup, reverse)
            if n ~= false then
                return n
            end
        end
    end
    return false
end

---@param hlgroup string
---@param startLine integer
function M.nexthl(hlgroup, startLine)
    local p = vim.treesitter.get_parser(0, "mmfml", {})
    if p == nil then
        vim.notify("Unable to get treesitter parser for buffer", vim.log.levels.ERROR, {})
        return
    end

    local trees = p:parse(true)
    if trees == nil then
        vim.notify("Unable to parse buffer", vim.log.levels.ERROR, {})
        return
    end

    for _, tree in pairs(trees) do
        local node = ckTSNode(tree:root(), startLine - 1, hlgroup)
        if node ~= false then
            return vim.treesitter.get_node_range(node)
        end
    end

    return nil
end

function M.prevhl(hlgroup, startLine)
    local p = vim.treesitter.get_parser(0, "mmfml", {})
    if p == nil then
        vim.notify("Unable to get treesitter parser for buffer", vim.log.levels.ERROR, {})
        return
    end

    local trees = p:parse(true)
    if trees == nil then
        vim.notify("Unable to parse buffer", vim.log.levels.ERROR, {})
        return
    end

    for _, tree in pairs(trees) do
        local node = ckTSNode(tree:root(), startLine - 1, hlgroup, true)
        if node ~= false then
            return vim.treesitter.get_node_range(node)
        end
    end

    return nil
end

return M
