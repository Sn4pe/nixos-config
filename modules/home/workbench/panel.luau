--!nonstrict
-- Panel de workbench: novedades sin ver y contenedores caídos arriba (si los hay), y tus tickets de
-- AGOS agrupados por estado. Mismo estilo que el panel de sn4pe/octobar. "Por hacer" empieza plegado

local GROUPS = {
  { id = "review", title = "En revisión", glyph = "eye" },
  { id = "active", title = "En curso", glyph = "player-play" },
  { id = "todo", title = "Por hacer", glyph = "circle-dashed" },
}

local jira = {}
local docker = {}
local events = {}
local isOpen = false
local collapsed = { todo = true }

local render

local function groupOf(issue)
  if issue.status == "In Review" then
    return "review"
  elseif issue.category == "indeterminate" then
    return "active"
  end
  return "todo"
end

local function openUrl(url)
  noctalia.runAsync({ "xdg-open", url })
end

local function refresh()
  noctalia.state.set("refresh_requested", (noctalia.state.get("refresh_requested") or 0) + 1)
end

local function badge(text, color)
  return ui.row({
    fill = color .. "/0.2",
    border = color .. "/0.24",
    borderWidth = 1,
    radius = 8,
    paddingH = 7,
    paddingV = 2,
    align = "center",
  }, {
    ui.label({ text = text, fontSize = 11, fontWeight = "medium", color = color }),
  })
end

local function card(key, children)
  return ui.column({
    key = key,
    fill = "surface_container/0.10",
    border = "outline_variant/0.40",
    borderWidth = 1,
    radius = 11,
    align = "stretch",
  }, children)
end

local function separator()
  return ui.separator({ thickness = 1, color = "outline_variant/0.28", spacing = 0 })
end

-- Solo lo que se sale de lo normal: bloqueos y prioridad distinta de Medium
local function issueRow(issue, group)
  local extras = {}
  if group == "active" and issue.status ~= "En ejecución" then
    table.insert(extras, badge(issue.status, issue.status == "Bloqueado" and "error" or "tertiary"))
  end
  if issue.priority ~= "" and issue.priority ~= "Medium" then
    local high = issue.priority == "High" or issue.priority == "Highest"
    table.insert(extras, badge(issue.priority, high and "error" or "on_surface_variant"))
  end

  local row = {
    ui.label({ text = issue.key, fontSize = 12, fontWeight = "bold", color = "primary" }),
    ui.button({
      key = `open:{issue.key}`,
      text = issue.summary,
      variant = "ghost",
      contentAlign = "start",
      flexGrow = 1,
      onClick = function()
        openUrl(issue.url)
      end,
    }),
  }
  for _, extra in ipairs(extras) do
    table.insert(row, extra)
  end
  return ui.row({ key = issue.key, gap = 8, align = "center", paddingH = 11, paddingV = 4 }, row)
end

local function issueGroups()
  local byGroup = { review = {}, active = {}, todo = {} }
  for _, issue in ipairs(jira.issues or {}) do
    table.insert(byGroup[groupOf(issue)], issue)
  end

  local cards = {}
  for _, g in ipairs(GROUPS) do
    local issues = byGroup[g.id]
    if #issues > 0 then
      local id = g.id
      local children = {
        ui.row({
          key = `head:{id}`,
          gap = 8,
          align = "center",
          paddingH = 11,
          paddingV = 8,
          fill = "surface_container/0.24",
          onClick = function()
            collapsed[id] = not collapsed[id]
            render()
          end,
        }, {
          ui.glyph({ name = collapsed[id] and "chevron-right" or "chevron-down", size = 15, color = "primary" }),
          ui.glyph({ name = g.glyph, size = 16, color = "primary" }),
          ui.label({ text = g.title, fontSize = 13, fontWeight = "bold", color = "primary", flexGrow = 1 }),
          badge(tostring(#issues), "primary"),
        }),
      }
      if not collapsed[id] then
        for _, issue in ipairs(issues) do
          table.insert(children, separator())
          table.insert(children, issueRow(issue, id))
        end
      end
      table.insert(cards, card(`group:{id}`, children))
    end
  end
  return cards
end

local function eventsCard()
  local children = {
    ui.row({ gap = 8, align = "center", paddingH = 11, paddingV = 6, fill = "surface_container/0.24" }, {
      ui.glyph({ name = "bell", size = 16, color = "primary" }),
      ui.label({ text = "Novedades", fontSize = 13, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({
        text = "Marcar como visto",
        variant = "ghost",
        onClick = function()
          noctalia.state.set("ack_requested", (noctalia.state.get("ack_requested") or 0) + 1)
        end,
      }),
    }),
  }
  for i, e in ipairs(events) do
    local what = e.kind == "assigned" and "Te lo han asignado" or `{e.from} -> {e.to}`
    if (e.actor or "") ~= "" then
      what = `{e.actor}: {what}`
    end
    table.insert(children, separator())
    table.insert(children, ui.column({ key = `event:{i}`, gap = 2, paddingH = 11, paddingV = 4, align = "stretch" }, {
      ui.row({ gap = 8, align = "center" }, {
        ui.label({ text = e.key, fontSize = 12, fontWeight = "bold", color = "primary" }),
        ui.button({
          text = e.summary,
          variant = "ghost",
          contentAlign = "start",
          flexGrow = 1,
          onClick = function()
            openUrl(e.url)
          end,
        }),
      }),
      ui.label({ text = what, fontSize = 11, color = "on_surface_variant" }),
    }))
  end
  return card("events", children)
end

local function dockerCard()
  local children = {
    ui.row({ gap = 8, align = "center", paddingH = 11, paddingV = 8, fill = "surface_container/0.24" }, {
      ui.glyph({ name = "brand-docker", size = 16, color = "error" }),
      ui.label({ text = "Contenedores parados", fontSize = 13, fontWeight = "bold", color = "error", flexGrow = 1 }),
      ui.button({
        text = "lazydocker",
        variant = "ghost",
        onClick = function()
          noctalia.runAsync("uwsm app -- kitty lazydocker")
        end,
      }),
    }),
  }
  for _, name in ipairs(docker.names or {}) do
    table.insert(children, separator())
    table.insert(children, ui.row({ key = name, paddingH = 11, paddingV = 6 }, {
      ui.label({ text = name, fontSize = 12, color = "on_surface" }),
    }))
  end
  return card("docker", children)
end

local function body()
  local rows = {}
  if #events > 0 then
    table.insert(rows, eventsCard())
  end
  if docker.ok and (docker.down or 0) > 0 then
    table.insert(rows, dockerCard())
  end
  for _, c in ipairs(issueGroups()) do
    table.insert(rows, c)
  end

  if #rows == 0 then
    local text = jira.ok == false and "No se ha podido leer Jira" or (jira.ok and "Nada abierto en AGOS" or "Cargando…")
    return ui.column({ flexGrow = 1, align = "center", justify = "center" }, {
      ui.label({ text = text, color = jira.ok == false and "error" or "on_surface_variant" }),
    })
  end
  return ui.scroll({ flexGrow = 1, gap = 10, align = "stretch" }, rows)
end

render = function()
  if not isOpen then
    return
  end

  local header = {
    ui.glyph({ name = "ticket", size = 20, color = "primary" }),
    ui.label({ text = "AGOS", fontSize = 16, fontWeight = "bold", color = "on_surface" }),
  }
  if jira.issues then
    table.insert(header, badge(tostring(#jira.issues), "primary"))
  end

  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, {
      ui.row({ gap = 8, align = "center", flexGrow = 1 }, header),
      ui.button({
        text = "Backlog",
        variant = "ghost",
        enabled = jira.backlog ~= nil,
        onClick = function()
          openUrl(jira.backlog)
        end,
      }),
      ui.button({ glyph = "refresh", variant = "ghost", onClick = refresh }),
      ui.button({ glyph = "close", onClick = panel.close }),
    }),
    body(),
  }))
end

local function sync()
  jira = noctalia.state.get("jira") or {}
  docker = noctalia.state.get("docker") or {}
  events = noctalia.state.get("events") or {}
end

noctalia.state.watch("jira", function()
  sync()
  render()
end)

noctalia.state.watch("events", function()
  sync()
  render()
end)

noctalia.state.watch("docker", function()
  sync()
  render()
end)

function onOpen(_context)
  sync()
  isOpen = true
  render()
end

function onClose()
  isOpen = false
end
