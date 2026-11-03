--!nonstrict
-- Panel de workbench: novedades sin ver y contenedores caídos arriba (si los hay), y tus tickets de
-- AGOS agrupados por estado. Mismo estilo que el panel de sn4pe/octobar. "Por hacer" empieza plegado

local GROUPS = {
  { id = "review", title = "En revisión", glyph = "eye" },
  { id = "active", title = "En curso", glyph = "player-play" },
  { id = "todo", title = "Por hacer", glyph = "circle-dashed" },
}

local CARD_FILL = "surface_container/0.24"

local jira = {}
local docker = {}
local events = {}
local updated = ""
local failed = false
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

-- Pastilla solo para estados; los contadores van como texto
local function badge(text, color)
  return ui.row({ fill = color .. "/0.2", radius = 8, paddingH = 7, paddingV = 2, align = "center" }, {
    ui.label({ text = text, fontSize = 11, fontWeight = "medium", color = color }),
  })
end

local function counter(n)
  return ui.label({ text = tostring(n), fontSize = 12, color = "on_surface_variant" })
end

local function card(key, children)
  return ui.column({ key = key, fill = CARD_FILL, radius = 11, align = "stretch" }, children)
end

local function header(id, children)
  local row = {
    ui.glyph({ name = collapsed[id] and "chevron-right" or "chevron-down", size = 15, color = "on_surface_variant" }),
  }
  for _, c in ipairs(children) do
    table.insert(row, c)
  end
  return ui.row({
    gap = 8,
    align = "center",
    paddingH = 11,
    paddingV = 8,
    onClick = function()
      collapsed[id] = not collapsed[id]
      render()
    end,
  }, row)
end

local function footerButton(text, onClick)
  return ui.row({ paddingH = 6, paddingV = 4 }, {
    ui.button({ text = text, variant = "ghost", onClick = onClick }),
  })
end

-- PR enlazado: icono y número sin pastilla, para que no se confunda con los estados, que no se pulsan
local function prLink(pr)
  local bad = pr.ci == "FAILURE" or pr.ci == "ERROR" or pr.reviewDecision == "CHANGES_REQUESTED"
  local color = bad and "error" or "primary"
  return ui.row({
    key = `pr:{pr.url}`,
    gap = 3,
    align = "center",
    paddingH = 4,
    onClick = function()
      openUrl(pr.url)
    end,
  }, {
    ui.glyph({ name = "git-pull-request", size = 13, color = color }),
    ui.label({ text = `#{pr.number}`, fontSize = 11, fontWeight = "medium", color = color }),
  })
end

-- Dos líneas como en octobar: el título no choca con las insignias. En la segunda, solo lo que se
-- sale de lo normal (bloqueos, prioridad distinta de Medium) y los PRs enlazados
local function issueRow(issue, group)
  local meta = {}
  if group == "active" and issue.status ~= "En ejecución" then
    table.insert(meta, badge(issue.status, issue.status == "Bloqueado" and "error" or "tertiary"))
  end
  if issue.priority ~= "" and issue.priority ~= "Medium" then
    local high = issue.priority == "High" or issue.priority == "Highest"
    table.insert(meta, badge(issue.priority, high and "error" or "on_surface_variant"))
  end
  for _, pr in ipairs(issue.prs or {}) do
    table.insert(meta, prLink(pr))
  end

  local rows = {
    ui.row({ gap = 8, align = "center" }, {
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
    }),
  }
  if #meta > 0 then
    table.insert(rows, ui.row({ gap = 7, align = "center", paddingH = 24 }, meta))
  end
  return ui.column({ key = issue.key, gap = 2, paddingH = 11, paddingV = 5, align = "stretch" }, rows)
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
      local children = {
        header(g.id, {
          ui.glyph({ name = g.glyph, size = 16, color = "on_surface" }),
          ui.label({ text = g.title, fontSize = 13, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
          counter(#issues),
        }),
      }
      if not collapsed[g.id] then
        for _, issue in ipairs(issues) do
          table.insert(children, issueRow(issue, g.id))
        end
      end
      table.insert(cards, card(`group:{g.id}`, children))
    end
  end
  return cards
end

local function eventsCard()
  local children = {
    header("events", {
      ui.glyph({ name = "bell", size = 16, color = "primary" }),
      ui.label({ text = "Novedades", fontSize = 13, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      counter(#events),
    }),
  }
  if collapsed.events then
    return card("events", children)
  end
  for i, e in ipairs(events) do
    local what = e.kind == "assigned" and "Te lo han asignado" or `{e.from} -> {e.to}`
    if (e.actor or "") ~= "" then
      what = `{e.actor}: {what}`
    end
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
      ui.row({ paddingH = 24 }, {
        ui.label({ text = what, fontSize = 11, color = "on_surface_variant" }),
      }),
    }))
  end
  table.insert(children, footerButton("Marcar como visto", function()
    noctalia.state.set("ack_requested", (noctalia.state.get("ack_requested") or 0) + 1)
  end))
  return card("events", children)
end

local function dockerCard()
  local names = docker.names or {}
  local children = {
    header("docker", {
      ui.glyph({ name = "brand-docker", size = 16, color = "error" }),
      ui.label({ text = "Contenedores parados", fontSize = 13, fontWeight = "bold", color = "error", flexGrow = 1 }),
      counter(#names),
    }),
  }
  if not collapsed.docker then
    for _, name in ipairs(names) do
      table.insert(children, ui.row({ key = name, paddingH = 34, paddingV = 4 }, {
        ui.label({ text = name, fontSize = 12, color = "on_surface" }),
      }))
    end
    table.insert(children, footerButton("Abrir lazydocker", function()
      noctalia.runAsync("uwsm app -- kitty lazydocker")
    end))
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
    local text = failed and "No se ha podido leer Jira" or (jira.ok and "Nada abierto en AGOS" or "Cargando…")
    return ui.column({ flexGrow = 1, align = "center", justify = "center" }, {
      ui.label({ text = text, color = failed and "error" or "on_surface_variant" }),
    })
  end
  return ui.scroll({ flexGrow = 1, gap = 10, align = "stretch" }, rows)
end

render = function()
  if not isOpen then
    return
  end

  local title = {
    ui.glyph({ name = "ticket", size = 20, color = "primary" }),
    ui.label({ text = "AGOS", fontSize = 16, fontWeight = "bold", color = "on_surface" }),
  }
  if jira.issues then
    table.insert(title, counter(#jira.issues))
  end

  -- Si la última pasada falló se ve aquí aunque sigan en pantalla los datos de antes
  local status = failed and "No se ha podido leer Jira" or (updated ~= "" and `Actualizado {updated}` or "")

  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, {
      ui.row({ gap = 8, align = "center", flexGrow = 1 }, title),
      ui.label({ text = status, fontSize = 11, color = failed and "error" or "on_surface_variant" }),
      ui.button({
        text = "Backlog",
        variant = "ghost",
        enabled = jira.backlog ~= nil,
        onClick = function()
          openUrl(jira.backlog)
        end,
      }),
      ui.button({ glyph = "refresh", variant = "ghost", onClick = refresh }),
      ui.button({ glyph = "close", variant = "ghost", onClick = panel.close }),
    }),
    body(),
  }))
end

local function sync()
  jira = noctalia.state.get("jira") or {}
  docker = noctalia.state.get("docker") or {}
  events = noctalia.state.get("events") or {}
  updated = noctalia.state.get("updated") or ""
  failed = noctalia.state.get("jira_failed") == true
end

for _, key in ipairs({ "jira", "docker", "events", "updated", "jira_failed" }) do
  noctalia.state.watch(key, function()
    sync()
    render()
  end)
end

function onOpen(_context)
  sync()
  isOpen = true
  render()
end

function onClose()
  isOpen = false
end
