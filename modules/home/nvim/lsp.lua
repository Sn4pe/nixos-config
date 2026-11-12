local servers = {
  basedpyright = {
    settings = {
      basedpyright = {
        analysis = {
          diagnosticSeverityOverrides = { reportUndefinedVariable = false, reportUnusedVariable = false },
        },
      },
    },
  },
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
      },
    },
  },
  nil_ls = {},
  ruff = {},
  rust_analyzer = {},
  svelte = {},
  ts_ls = {
    filetypes = {
      "vue",
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    },
    init_options = {
      plugins = {
        {
          languages = { "vue" },
          location = vim.g.vue_language_server,
          name = "@vue/typescript-plugin",
        },
      },
    },
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
    end,
  },
  vue_ls = {},
}

for server, config in pairs(servers) do
  vim.lsp.config(server, config)
  vim.lsp.enable(server)
end
