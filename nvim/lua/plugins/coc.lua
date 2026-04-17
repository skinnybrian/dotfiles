return {
  "neoclide/coc.nvim",
  branch = "release",
  event = "VeryLazy",
  config = function()
    local set = vim.keymap.set

    set("", "gd", "<Plug>(coc-definition)", { silent = true })

    local function show_docs()
      local cw = vim.fn.expand("<cword>")
      if vim.fn.index({ "vim", "help" }, vim.bo.filetype) >= 0 then
        vim.cmd.help(cw)
        return
      end
      local ok, ready = pcall(vim.api.nvim_eval, "coc#rpc#ready()")
      if ok and ready == 1 then
        vim.fn.CocActionAsync("doHover")
      else
        vim.cmd("!" .. vim.o.keywordprg .. " " .. vim.fn.shellescape(cw))
      end
    end

    set("n", "K", show_docs, { silent = true })
  end,
}
