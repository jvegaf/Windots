return {
    "akinsho/toggleterm.nvim",
    keys = {
        { "<A-1>", "<cmd>ToggleTerm size=20<cr>", desc = "Toggle Terminal", mode = "n" },
        { "<A-1>", "<cmd>ToggleTerm<cr>",         desc = "Toggle Terminal", mode = "t" },
    },
    opts = {
        shade_terminals = false,
        float_opts = {
            -- Hide border
            border = "none",
        },
    },
}
