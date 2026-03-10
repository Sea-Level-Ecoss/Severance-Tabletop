-- Severance Tabletop (TTS)
-- Milestone 1: deckbuilding flow + API hooks

local config = {
  apiBaseUrl = "http://localhost:8787",
  defaultStatus = "all",
  imageBaseUrl = "http://localhost:8787/images/ss_cards",
  imagePathMode = "auto",
  defaultCardBackUrl = "http://localhost:8787/images/ss_cards/card_back.png",
  fallbackCardFaceUrl = "http://localhost:8787/images/ss_cards/card_back.png",
  cacheTtlSeconds = 300,
  optionCountPerStep = 3,
  decisionBiasTransition = 30,
  baseDecisionBudget = 40,
  maxDecisionBudget = 47,
  maxSkips = 7,
  drawEligibleStatuses = {
    shippable = true,
    gameplay_ready = true,
  },
}

local rulebookGuides = {
  PresenceRulebook = {
    title = "Presence Rulebook",
    body = [[
SEVERANCE TABLETOP — PRESENCE GUIDE

Goal
- Build and pilot the Presence deck through the rank flow.

Quick Start
1) Click "Build Presence Deck".
2) Use "Search Cards" to inspect options.
3) Enter a card id in search input, then click "Pick Search ID".
4) Repeat until all taxon steps finish, then click "Finalize Deck".

Deck Import
- Paste one card id per line in Import input.
- Click "Import Decklist".

Manual Add
- Enter a card id in Search input.
- Click "Add Search ID Manually".

Notes
- "Refresh Cache" reloads cards from local API.
- Some cards may be manual-only until completion status is draw-eligible.
- Update this object text as rules evolve.
]],
  },
  AbsenceRulebook = {
    title = "Absence Rulebook",
    body = [[
SEVERANCE TABLETOP — ABSENCE GUIDE

Goal
- Build and pilot the Absence deck through reversed rank flow.

Quick Start
1) Click "Build Absence Deck".
2) Use "Search Cards" to inspect options.
3) Enter a card id in search input, then click "Pick Search ID".
4) Repeat until all taxon steps finish, then click "Finalize Deck".

Deck Import
- Paste one card id per line in Import input.
- Click "Import Decklist".

Manual Add
- Enter a card id in Search input.
- Click "Add Search ID Manually".

Notes
- "Refresh Cache" reloads cards from local API.
- Incomplete cards can still be tested via manual add when needed.
- Update this object text as rules evolve.
]],
  },
}

local state = {
  cards = {},
  lastFetch = 0,
  deckbuild = nil,
  roundValue = 1,
  statusText = "Ready. Open deckbuilder from a tagged opener object.",
  taxonSettings = {
    presence = { includeBinBasin = true },
    absence = { includeBinBasin = true },
  },
  setup = {
    phase = "base",
    byRole = {
      presence = { playerColor = nil, mode = "base", essaId = nil, startingHandResolved = false },
      absence = { playerColor = nil, mode = "base", essaId = nil, startingHandResolved = false },
    },
    firstPlayer = nil,
    startingManaSums = { presence = 0, absence = 0 },
    tieBreakApplied = false,
  },
}

local uiXml = nil
local uiState = {
  deckbuilderVisible = false,
  currentDeckbuilderRole = nil,
  lastPlayerColor = nil,
}
local zoneRefs = {
  presenceDeck = nil,
  presenceDiscard = nil,
  absenceDeck = nil,
  absenceDiscard = nil,
}

local tags = {
  presenceRulebook = "PresenceRulebook",
  absenceRulebook = "AbsenceRulebook",
  deckbuilderOpener = "DeckbuilderOpener",
  presenceDeckbuilder = "PresenceDeckbuilder",
  absenceDeckbuilder = "AbsenceDeckbuilder",
  presenceDeck = "PresenceDeck",
  absenceDeck = "AbsenceDeck",
  presenceTaxonCalc = "PresenceTaxonCalc",
  absenceTaxonCalc = "AbsenceTaxonCalc",
  presenceEssa = "PresenceEssa",
  absenceEssa = "AbsenceEssa",
}

local nameRegistry = {
  presenceDeck = { "Presence Deck" },
  absenceDeck = { "Absence Deck" },
  presenceRulebook = { "Presence Rulebook" },
  absenceRulebook = { "Absence Rulebook" },
  presenceTaxonCalc = { "Presence Taxon Calculator" },
  absenceTaxonCalc = { "Absence Taxon Calculator" },
  presencePlayZones = { "Presence Field", "Mean Field" },
  absencePlayZones = { "Absence Field", "Mean Field" },
}

local sceneValidationEntries = {
  { label = "Absence Deck", kind = "object", names = { "Absence Deck" }, tag = tags.absenceDeck },
  { label = "Presence Deck", kind = "object", names = { "Presence Deck" }, tag = tags.presenceDeck },
  { label = "Absence Deckbuilder", kind = "object", names = { "Absence Deckbuilder" }, tag = tags.absenceDeckbuilder },
  { label = "Presence Deckbuilder", kind = "object", names = { "Presence Deckbuilder" }, tag = tags.presenceDeckbuilder },
  { label = "Absence Taxon Calculator", kind = "object", names = { "Absence Taxon Calculator" }, tag = tags.absenceTaxonCalc },
  { label = "Presence Taxon Calculator", kind = "object", names = { "Presence Taxon Calculator" }, tag = tags.presenceTaxonCalc },
  { label = "Absence Rulebook", kind = "object", names = { "Absence Rulebook" }, tag = tags.absenceRulebook },
  { label = "Presence Rulebook", kind = "object", names = { "Presence Rulebook" }, tag = tags.presenceRulebook },
  { label = "Absence Right Split Deck", kind = "object", names = { "Absence Right Split Deck" } },
  { label = "Absence Right Split", kind = "object", names = { "Absence Right Split" } },
  { label = "Absence Essa Right Split", kind = "object", names = { "Absence Essa Right Split" } },
  { label = "Absence Center", kind = "object", names = { "Absence Center" } },
  { label = "Absence Essa", kind = "object", names = { "Absence Essa" }, tag = tags.absenceEssa },
  { label = "Absence Left Split Deck", kind = "object", names = { "Absence Left Split Deck" } },
  { label = "Absence Left Split", kind = "object", names = { "Absence Left Split" } },
  { label = "Absence Essa Left Split", kind = "object", names = { "Absence Essa Left Split" } },
  { label = "Presence Left Split", kind = "object", names = { "Presence Left Split" } },
  { label = "Presence Essa Left Split", kind = "object", names = { "Presence Essa Left Split" } },
  { label = "Presence Left Split Deck", kind = "object", names = { "Presence Left Split Deck" } },
  { label = "Presence Center", kind = "object", names = { "Presence Center" } },
  { label = "Presence Essa", kind = "object", names = { "Presence Essa" }, tag = tags.presenceEssa },
  { label = "Presence Right Split", kind = "object", names = { "Presence Right Split" } },
  { label = "Presence Essa Right Split", kind = "object", names = { "Presence Essa Right Split" } },
  { label = "Presence Right Split Deck", kind = "object", names = { "Presence Right Split Deck" } },
  { label = "Presence Field", kind = "zone", names = { "Presence Field" }, tags = { "PresencePlayZone", "PresencePlay", "PresenceInPlay" } },
  { label = "Mean Field", kind = "zone", names = { "Mean Field" } },
  { label = "Absence Field", kind = "zone", names = { "Absence Field" }, tags = { "AbsencePlayZone", "AbsencePlay", "AbsenceInPlay" } },
  { label = "Presence Hand", kind = "zone", names = { "Presence Hand" } },
  { label = "Absence Hand", kind = "zone", names = { "Absence Hand" } },
}

local taxonomyOrderByRole = {
  presence = { "Bin", "Basin", "Eco", "Kingdom", "Phylum", "Class", "Order", "Family", "Essa" },
  absence = { "Essa", "Family", "Order", "Class", "Phylum", "Kingdom", "Eco", "Basin", "Bin" },
}

local taxonRanks = taxonomyOrderByRole.presence

local uiRefs = {
  roundLabelButtonIndex = nil,
}

local roleZones = {
  presence = {
    deck = { -22, 1.2, -18 },
    discard = { -16, 1.2, -18 },
    rotation = { 0, 180, 0 },
  },
  absence = {
    deck = { 22, 1.2, 18 },
    discard = { 16, 1.2, 18 },
    rotation = { 0, 0, 0 },
  },
}

function onLoad(savedState)
  if savedState and savedState ~= "" then
    local ok, decoded = pcall(JSON.decode, savedState)
    if ok and decoded then
      state.cards = decoded.cards or {}
      state.lastFetch = decoded.lastFetch or 0
      state.deckbuild = decoded.deckbuild or nil
      state.roundValue = decoded.roundValue or 1
      state.statusText = decoded.statusText or state.statusText
      state.taxonSettings = decoded.taxonSettings or state.taxonSettings
      state.setup = decoded.setup or state.setup
    end
  end

  ensureSetupDefaults()

  safeRun("resolve ui xml", function()
    if self and self.getVar then
      uiXml = self.getVar("uiXml")
    end
  end)

  uiState.deckbuilderVisible = false

  safeRun("create round tracker", createRoundTrackerButtons)
  safeRun("add menu open", function()
    addContextMenuItem("Open Deckbuilder UI", onOpenDeckbuilderFromContext, false, true)
  end)
  safeRun("add menu hide", function()
    addContextMenuItem("Hide Deckbuilder UI", onHideDeckbuilderFromContext, false, true)
  end)
  safeRun("add menu rulebooks", function()
    addContextMenuItem("Refresh Rulebooks", onRefreshRulebooksFromContext, false, true)
  end)
  safeRun("add menu validate scene", function()
    addContextMenuItem("Validate Scene Wiring", onValidateSceneFromContext, false, true)
  end)
  safeRun("ensure zones", ensureZoneMarkers)
  safeRun("schedule refreshes", scheduleRulebookRefreshes)
  safeRun("ensure taxon calculators", ensureTaxonCalculators)
  safeRun("refresh taxon calculators", refreshTaxonCalculators)
  safeRun("update round ui", updateRoundTrackerUi)
  safeRun("update status", function()
    updateStatusUi(state.statusText or "Ready. Open deckbuilder from a tagged opener object.")
  end)

  safeRun("hide deckbuilder deferred", function()
    Wait.frames(function()
      closeDeckbuilderUi()
    end, 1)
  end)
end

function safeRun(label, fn)
  local ok, err = pcall(fn)
  if not ok then
    print("[Severance onLoad] " .. tostring(label) .. " failed: " .. tostring(err))
  end
end

function safeUiSetXml(xml)
  local ok, err = pcall(function()
    UI.setXml(xml)
  end)
  if not ok then
    print("[Severance UI] setXml failed: " .. tostring(err))
    return false
  end
  return true
end

function ensureSetupDefaults()
  state.setup = state.setup or {}
  state.setup.phase = state.setup.phase or "base"
  state.setup.byRole = state.setup.byRole or {}

  state.setup.byRole.presence = state.setup.byRole.presence or {}
  state.setup.byRole.presence.playerColor = state.setup.byRole.presence.playerColor
  state.setup.byRole.presence.mode = state.setup.byRole.presence.mode or "base"
  state.setup.byRole.presence.essaId = state.setup.byRole.presence.essaId
  state.setup.byRole.presence.startingHandResolved = state.setup.byRole.presence.startingHandResolved == true

  state.setup.byRole.absence = state.setup.byRole.absence or {}
  state.setup.byRole.absence.playerColor = state.setup.byRole.absence.playerColor
  state.setup.byRole.absence.mode = state.setup.byRole.absence.mode or "base"
  state.setup.byRole.absence.essaId = state.setup.byRole.absence.essaId
  state.setup.byRole.absence.startingHandResolved = state.setup.byRole.absence.startingHandResolved == true

  state.setup.firstPlayer = state.setup.firstPlayer
  state.setup.startingManaSums = state.setup.startingManaSums or { presence = 0, absence = 0 }
  state.setup.startingManaSums.presence = tonumber(state.setup.startingManaSums.presence or 0) or 0
  state.setup.startingManaSums.absence = tonumber(state.setup.startingManaSums.absence or 0) or 0
  state.setup.tieBreakApplied = state.setup.tieBreakApplied == true
end

function getRoleLabel(role)
  return role == "presence" and "Presence" or "Absence"
end

function getRoleSetup(role)
  ensureSetupDefaults()
  if role ~= "presence" and role ~= "absence" then
    return nil
  end
  return state.setup.byRole[role]
end

function isSetupHost(playerColor)
  if not playerColor or playerColor == "" then return false end
  local p = Player[playerColor]
  if not p then return false end
  if p.admin == true then return true end
  if p.promoted == true then return true end
  return false
end

function requireSetupHost(playerColor, actionLabel)
  if isSetupHost(playerColor) then
    return true
  end
  broadcastToColor((actionLabel or "Action") .. " is host-only during setup.", playerColor or "White", { 1, 0.6, 0.4 })
  return false
end

function resolveActiveRole(playerColor)
  if uiState.currentDeckbuilderRole == "presence" or uiState.currentDeckbuilderRole == "absence" then
    return uiState.currentDeckbuilderRole
  end

  ensureSetupDefaults()
  if playerColor and state.setup.byRole.presence.playerColor == playerColor then
    return "presence"
  end
  if playerColor and state.setup.byRole.absence.playerColor == playerColor then
    return "absence"
  end

  return nil
end

function validateDistinctRolePlayers(playerColor)
  local presenceColor = getRoleSetup("presence").playerColor
  local absenceColor = getRoleSetup("absence").playerColor
  if not presenceColor or not absenceColor then
    broadcastToColor("Both Presence and Absence roles must be claimed before this action.", playerColor or "White", { 1, 0.7, 0.4 })
    return false
  end
  if presenceColor == absenceColor then
    broadcastToColor("Presence and Absence must be assigned to different player colors.", playerColor or "White", { 1, 0.6, 0.4 })
    return false
  end
  return true
end

function refreshSetupStatus(role)
  ensureSetupDefaults()
  local text = "Status: Ready"
  local activeRole = role
  if activeRole ~= "presence" and activeRole ~= "absence" then
    activeRole = nil
  end

  if activeRole then
    local setup = getRoleSetup(activeRole)
    local roleLabel = getRoleLabel(activeRole)
    local mode = setup.mode or "base"
    local modeLabel = mode == "guided" and "Guided" or "Base"
    local essaLabel = setup.essaId and "yes" or "no"
    local progress = "0/0"
    local skips = "0/" .. tostring(config.maxSkips)
    local firstPlayer = state.setup.firstPlayer and getRoleLabel(state.setup.firstPlayer) or "pending"
    local manaPresence = state.setup.startingManaSums and state.setup.startingManaSums.presence or 0
    local manaAbsence = state.setup.startingManaSums and state.setup.startingManaSums.absence or 0

    if state.deckbuild and state.deckbuild.role == activeRole then
      local shown = tonumber(state.deckbuild.decisionsShown or 0) or 0
      local budget = tonumber(state.deckbuild.decisionBudget or config.baseDecisionBudget) or config.baseDecisionBudget
      progress = tostring(shown) .. "/" .. tostring(budget)
      skips = tostring(state.deckbuild.skipsUsed or 0) .. "/" .. tostring(state.deckbuild.maxSkips or config.maxSkips)
    end

    text = string.format(
      "Status: %s | mode %s | decision %s | skips %s | Essa %s | First %s | Mana P/A %d/%d",
      roleLabel,
      modeLabel,
      progress,
      skips,
      essaLabel,
      firstPlayer,
      tonumber(manaPresence or 0) or 0,
      tonumber(manaAbsence or 0) or 0
    )
  elseif state.statusText and state.statusText ~= "" then
    text = state.statusText
  end

  updateStatusUi(text)
  updateSetupUiActions(activeRole)
end

function updateSetupUiActions(role)
  if not uiState.deckbuilderVisible then return end
  local activeRole = role
  if activeRole ~= "presence" and activeRole ~= "absence" then
    activeRole = resolveActiveRole(uiState.lastPlayerColor)
  end

  local inGuided = false
  if activeRole then
    local setup = getRoleSetup(activeRole)
    inGuided = setup.mode == "guided"
  end

  local bothEssaSelected = getRoleSetup("presence").essaId ~= nil and getRoleSetup("absence").essaId ~= nil
  local bothHandsResolved = getRoleSetup("presence").startingHandResolved == true and getRoleSetup("absence").startingHandResolved == true

  pcall(function()
    UI.setAttribute("btnStartDeckbuildMode", "active", inGuided and "false" or "true")
  end)
  pcall(function()
    UI.setAttribute("btnReturnBaseMode", "active", inGuided and "true" or "false")
  end)
  pcall(function()
    UI.setAttribute("btnSelectEssa", "active", activeRole and "true" or "false")
  end)
  pcall(function()
    UI.setAttribute("btnResolveHands", "active", bothEssaSelected and "true" or "false")
  end)
  pcall(function()
    UI.setAttribute("btnResolveFirstPlayer", "active", bothHandsResolved and "true" or "false")
  end)
end

function onObjectSpawn(obj)
  Wait.frames(function()
    if not obj or obj.isDestroyed() then return end

    local role = detectDeckbuilderRole(obj)
    if role ~= nil then
      attachDeckbuilderPanelButton(obj, role)
    end

    if objectHasTag(obj, tags.presenceRulebook) or objectHasTag(obj, tags.absenceRulebook) then
      refreshRulebookObjects()
    end

    if objectHasTag(obj, tags.presenceTaxonCalc) or objectHasTag(obj, tags.absenceTaxonCalc)
      or objectHasTag(obj, tags.presenceEssa) or objectHasTag(obj, tags.absenceEssa)
    then
      ensureTaxonCalculators()
      refreshTaxonCalculators()
    end
  end, 1)
end

function onObjectEnterScriptingZone(zone, obj)
  if not zone or zone.isDestroyed() then return end
  if zoneHasAnyTagOrName(
    zone,
    { "PresencePlayZone", "AbsencePlayZone", tags.presenceEssa, tags.absenceEssa },
    { "Presence Field", "Absence Field", "Mean Field" }
  ) then
    refreshTaxonCalculators()
  end
end

function onObjectLeaveScriptingZone(zone, obj)
  if not zone or zone.isDestroyed() then return end
  if zoneHasAnyTagOrName(
    zone,
    { "PresencePlayZone", "AbsencePlayZone", tags.presenceEssa, tags.absenceEssa },
    { "Presence Field", "Absence Field", "Mean Field" }
  ) then
    refreshTaxonCalculators()
  end
end

function onOpenDeckbuilderFromContext(playerColor, menuPosition)
  openDeckbuilderUi(playerColor)
end

function onHideDeckbuilderFromContext(playerColor, menuPosition)
  closeDeckbuilderUi(playerColor)
end

function onValidateSceneFromContext(playerColor, menuPosition)
  onValidateScene(playerColor, nil)
end

function onCloseDeckbuilderUi(playerColor, value, id)
  closeDeckbuilderUi(playerColor)
end

function onDeckbuilderOpenerClicked(obj, playerColor, altClick)
  if uiState.deckbuilderVisible then
    closeDeckbuilderUi(playerColor)
    return
  end
  openDeckbuilderUi(playerColor)
end

function onPresenceDeckbuilderClicked(obj, playerColor, altClick)
  openDeckbuilderForRole("presence", playerColor)
end

function onAbsenceDeckbuilderClicked(obj, playerColor, altClick)
  openDeckbuilderForRole("absence", playerColor)
end

function openDeckbuilderForRole(role, playerColor)
  if role == "presence" or role == "absence" then
    uiState.currentDeckbuilderRole = role
    if playerColor and playerColor ~= "" then
      ensureSetupDefaults()
      state.setup.byRole[role].playerColor = playerColor
      uiState.lastPlayerColor = playerColor
    end
  end

  openDeckbuilderUi(playerColor)
  applyDeckbuilderRoleMode()

  if playerColor and uiState.currentDeckbuilderRole then
    local label = uiState.currentDeckbuilderRole == "presence" and "Presence" or "Absence"
    broadcastToColor(label .. " deckbuilder panel opened.", playerColor, { 0.8, 1, 0.8 })
  end
end

function openDeckbuilderUi(playerColor)
  if not uiXml or uiXml == "" then
    local rootActive = pcall(function()
      return UI.getAttribute("root", "active")
    end)
    if not rootActive then
      if playerColor then
        broadcastToColor("Deckbuilder UI XML is missing.", playerColor, { 1, 0.5, 0.5 })
      end
      return
    end
  end

  if not uiState.deckbuilderVisible then
    local showedExisting = pcall(function()
      UI.setAttribute("root", "active", "true")
    end)

    if not showedExisting and uiXml and uiXml ~= "" then
      showedExisting = safeUiSetXml(uiXml)
    end

    uiState.deckbuilderVisible = showedExisting == true
    if not uiState.deckbuilderVisible then
      return
    end
  end
  applyDeckbuilderRoleMode()
  if playerColor and playerColor ~= "" then
    uiState.lastPlayerColor = playerColor
  end
  refreshSetupStatus(uiState.currentDeckbuilderRole)
end

function closeDeckbuilderUi(playerColor)
  pcall(function()
    UI.setAttribute("root", "active", "false")
  end)

  if uiState.deckbuilderVisible then
    uiState.deckbuilderVisible = false
    uiState.currentDeckbuilderRole = nil
    if playerColor then
      broadcastToColor("Deckbuilder UI hidden.", playerColor, { 0.8, 1, 0.8 })
    end
  end
end

function ensureDeckbuilderOpeners()
  local allObjects = getObjects() or {}
  for _, obj in ipairs(allObjects) do
    local role = detectDeckbuilderRole(obj)
    if role ~= nil then
      attachDeckbuilderPanelButton(obj, role)
    elseif objectHasTag(obj, tags.deckbuilderOpener) then
      attachDeckbuilderOpenerButton(obj)
    end
  end
end

function detectDeckbuilderRole(obj)
  if not obj or obj.isDestroyed() then return nil end

  if objectHasTag(obj, tags.presenceDeckbuilder) then return "presence" end
  if objectHasTag(obj, tags.absenceDeckbuilder) then return "absence" end

  local name = string.lower(trim(obj.getName() or ""))
  if name == string.lower(tags.presenceDeckbuilder) then return "presence" end
  if name == string.lower(tags.absenceDeckbuilder) then return "absence" end

  return nil
end

function attachDeckbuilderPanelButton(obj, role)
  if not obj or obj.isDestroyed() then return end

  local clickFunction = role == "presence" and "onPresenceDeckbuilderClicked" or "onAbsenceDeckbuilderClicked"
  local buttonLabel = role == "presence" and "Presence Deckbuilder" or "Absence Deckbuilder"

  local existing = obj.getButtons() or {}
  for _, btn in ipairs(existing) do
    if btn and btn.click_function == clickFunction then
      return
    end
  end

  obj.createButton({
    label = buttonLabel,
    click_function = clickFunction,
    function_owner = self,
    position = { 0, 0.35, 0 },
    rotation = { 0, 180, 0 },
    width = 2600,
    height = 520,
    font_size = 250,
    color = role == "presence" and { 0.12, 0.2, 0.35 } or { 0.28, 0.12, 0.3 },
    font_color = { 0.95, 0.95, 0.95 },
    tooltip = "Left-click to open " .. buttonLabel,
  })
end

function attachDeckbuilderOpenerButton(obj)
  if not obj or obj.isDestroyed() then return end

  local existing = obj.getButtons() or {}
  for _, btn in ipairs(existing) do
    if btn and btn.click_function == "onDeckbuilderOpenerClicked" then
      return
    end
  end

  obj.createButton({
    label = "Deckbuilder",
    click_function = "onDeckbuilderOpenerClicked",
    function_owner = self,
    position = { 0, 0.35, 0 },
    rotation = { 0, 180, 0 },
    width = 2000,
    height = 500,
    font_size = 280,
    color = { 0.12, 0.12, 0.12 },
    font_color = { 0.95, 0.95, 0.95 },
    tooltip = "Left-click to open/close Severance Deckbuilder UI",
  })
end

function scheduleRulebookRefreshes()
  Wait.frames(function()
    refreshRulebookObjects()
    ensureDeckbuilderOpeners()
    ensureTaxonCalculators()
    refreshTaxonCalculators()
  end, 1)

  Wait.frames(function()
    refreshRulebookObjects()
    ensureDeckbuilderOpeners()
    ensureTaxonCalculators()
    refreshTaxonCalculators()
  end, 30)

  Wait.frames(function()
    refreshRulebookObjects()
    ensureDeckbuilderOpeners()
    ensureTaxonCalculators()
    refreshTaxonCalculators()
  end, 120)
end

function ensureTaxonCalculators()
  ensureTaxonCalculatorRole("presence")
  ensureTaxonCalculatorRole("absence")
end

function ensureTaxonCalculatorRole(roleKey)
  local tagName = roleKey == "presence" and tags.presenceTaxonCalc or tags.absenceTaxonCalc
  local tagged = getObjectsWithTag(tagName) or {}
  if #tagged == 0 then
    local fallbackNames = roleKey == "presence" and nameRegistry.presenceTaxonCalc or nameRegistry.absenceTaxonCalc
    tagged = getObjectsByNameList(fallbackNames)
  end
  for _, obj in ipairs(tagged) do
    attachTaxonCalculatorButtons(obj, roleKey)
  end
end

function attachTaxonCalculatorButtons(obj, roleKey)
  if not obj or obj.isDestroyed() then return end

  local toggleFn = roleKey == "presence" and "onTogglePresenceBinBasin" or "onToggleAbsenceBinBasin"
  local header = roleKey == "presence" and "Presence Taxon Calculator" or "Absence Taxon Calculator"

  pcall(function()
    obj.clearButtons()
  end)

  obj.createButton({
    label = header .. "\n(loading...)",
    click_function = "onRulebookTextNoop",
    function_owner = self,
    position = { 0, 0.32, 0 },
    rotation = { 0, 180, 0 },
    width = 2500,
    height = 1800,
    font_size = 120,
    color = { 0.06, 0.06, 0.08, 0.92 },
    font_color = { 0.95, 0.95, 0.95 },
    tooltip = header,
  })

  obj.createButton({
    label = "Toggle Bin/Basin",
    click_function = toggleFn,
    function_owner = self,
    position = { 0, 0.33, -0.95 },
    rotation = { 0, 180, 0 },
    width = 1400,
    height = 280,
    font_size = 120,
    color = { 0.18, 0.24, 0.32, 0.96 },
    font_color = { 1, 1, 1 },
    tooltip = "Toggle visibility and backend inclusion for Bin/Basin",
  })
end

function onTogglePresenceBinBasin(obj, playerColor, altClick)
  toggleBinBasin("presence", playerColor)
end

function onToggleAbsenceBinBasin(obj, playerColor, altClick)
  toggleBinBasin("absence", playerColor)
end

function toggleBinBasin(roleKey, playerColor)
  local settings = state.taxonSettings[roleKey] or { includeBinBasin = true }
  settings.includeBinBasin = not (settings.includeBinBasin == true)
  state.taxonSettings[roleKey] = settings
  refreshTaxonCalculatorRole(roleKey)

  if playerColor then
    local mode = settings.includeBinBasin and "ON" or "OFF"
    broadcastToColor(capitalize(roleKey) .. " Bin/Basin: " .. mode, playerColor, { 0.8, 1, 0.8 })
  end
end

function refreshTaxonCalculators()
  refreshTaxonCalculatorRole("presence")
  refreshTaxonCalculatorRole("absence")
end

function refreshTaxonCalculatorRole(roleKey)
  local calcTag = roleKey == "presence" and tags.presenceTaxonCalc or tags.absenceTaxonCalc
  local calculators = getObjectsWithTag(calcTag) or {}
  if #calculators == 0 then
    local fallbackNames = roleKey == "presence" and nameRegistry.presenceTaxonCalc or nameRegistry.absenceTaxonCalc
    calculators = getObjectsByNameList(fallbackNames)
  end
  if #calculators == 0 then return end

  local settings = state.taxonSettings[roleKey] or { includeBinBasin = true }
  local rankValues = calculateTaxonValues(roleKey, settings.includeBinBasin)
  local comboText = detectTaxonCombos(roleKey, rankValues, settings.includeBinBasin)

  for _, calcObj in ipairs(calculators) do
    if calcObj and not calcObj.isDestroyed() then
      renderTaxonCalculator(calcObj, roleKey, rankValues, comboText, settings.includeBinBasin)
    end
  end
end

function calculateTaxonValues(roleKey, includeBinBasin)
  local valuesByRank = {}
  for _, rank in ipairs(taxonRanks) do
    valuesByRank[rank] = {}
  end

  local playObjects = collectRolePlayObjects(roleKey)
  for _, source in ipairs(playObjects) do
    local extracted = extractTaxonomyFromSource(source)
    for _, rank in ipairs(taxonRanks) do
      local val = trim(extracted[rank] or "")
      if val ~= "" then
        table.insert(valuesByRank[rank], val)
      end
    end
  end

  local resolved = {}
  for _, rank in ipairs(taxonRanks) do
    if (rank == "Bin" or rank == "Basin") and not includeBinBasin then
      resolved[rank] = "-"
    else
      resolved[rank] = pickMostFrequent(valuesByRank[rank]) or "X"
    end
  end

  local essaPresent = hasEssaForRole(roleKey)
  resolved["Essa"] = essaPresent and "1" or "X"

  return resolved
end

function hasEssaForRole(roleKey)
  local essaTag = roleKey == "presence" and tags.presenceEssa or tags.absenceEssa
  local essaZones = getObjectsWithTag(essaTag) or {}
  for _, zone in ipairs(essaZones) do
    if zone and not zone.isDestroyed() then
      local ok, objs = pcall(function()
        return zone.getObjects(true)
      end)
      if ok and objs and #objs > 0 then
        return true
      end
    end
  end
  return false
end

function collectRolePlayObjects(roleKey)
  local zoneTags = roleKey == "presence"
    and { "PresencePlayZone", "PresencePlay", "PresenceInPlay" }
    or { "AbsencePlayZone", "AbsencePlay", "AbsenceInPlay" }
  local fallbackZoneNames = roleKey == "presence" and nameRegistry.presencePlayZones or nameRegistry.absencePlayZones

  local results = {}
  local seenGuids = {}

  local function addResult(obj)
    if not obj or obj.isDestroyed() then return end
    local guid = nil
    local okGuid, value = pcall(function() return obj.getGUID() end)
    if okGuid and value then
      guid = tostring(value)
    end
    if guid and seenGuids[guid] then
      return
    end
    if guid then
      seenGuids[guid] = true
    end
    table.insert(results, obj)
  end

  for _, tagName in ipairs(zoneTags) do
    local zones = getObjectsWithTag(tagName) or {}
    for _, zone in ipairs(zones) do
      if zone and not zone.isDestroyed() then
        local ok, objs = pcall(function()
          return zone.getObjects(true)
        end)
        if ok and objs then
          for _, o in ipairs(objs) do
            addResult(o)
          end
        end
      end
    end
  end

  if #results == 0 then
    local fallbackZones = getObjectsByNameList(fallbackZoneNames)
    for _, zone in ipairs(fallbackZones) do
      if zone and not zone.isDestroyed() then
        local ok, objs = pcall(function()
          return zone.getObjects(true)
        end)
        if ok and objs then
          for _, o in ipairs(objs) do
            addResult(o)
          end
        end
      end
    end
  end

  return results
end

function extractTaxonomyFromSource(source)
  local out = {}
  for _, rank in ipairs(taxonRanks) do
    out[rank] = ""
  end

  local text = ""
  if type(source) == "table" and source.getDescription then
    local okDesc, desc = pcall(function() return source.getDescription() end)
    if okDesc and desc then text = tostring(desc) end
  elseif type(source) == "table" and source.Description then
    text = tostring(source.Description)
  end

  local payload = parseBackendPayloadFromDescription(text)
  if payload then
    for _, rank in ipairs(taxonRanks) do
      local lower = string.lower(rank)
      local v = payload[lower] or payload[rank]
      if v == nil and payload.taxonomy then
        v = payload.taxonomy[lower] or payload.taxonomy[rank]
      end
      if type(v) == "table" then
        v = v.name or v.value or v.id or ""
      end
      out[rank] = trim(v or "")
    end
  end

  if out["Essa"] == "" then
    local essa = string.match(text or "", "Essa:%s*([^\n\r]+)")
    out["Essa"] = trim(essa or "")
  end

  return out
end

function parseBackendPayloadFromDescription(desc)
  local text = tostring(desc or "")
  if text == "" then return nil end

  local payloadText = nil
  local markerStart = string.find(text, "Backend Data:", 1, true)
  if markerStart then
    payloadText = string.sub(text, markerStart + string.len("Backend Data:"))
    payloadText = trim(payloadText)
  else
    payloadText = text
  end

  local ok, payload = pcall(JSON.decode, payloadText)
  if ok and payload then return payload end
  return nil
end

function pickMostFrequent(list)
  if not list or #list == 0 then return nil end
  local counts = {}
  local firstSeen = {}
  local order = 0
  for _, raw in ipairs(list) do
    local value = trim(raw)
    if value ~= "" then
      counts[value] = (counts[value] or 0) + 1
      if not firstSeen[value] then
        order = order + 1
        firstSeen[value] = order
      end
    end
  end

  local bestValue = nil
  local bestCount = -1
  local bestOrder = math.huge
  for value, count in pairs(counts) do
    local seen = firstSeen[value] or math.huge
    if count > bestCount or (count == bestCount and seen < bestOrder) then
      bestValue = value
      bestCount = count
      bestOrder = seen
    end
  end
  return bestValue
end

function detectTaxonCombos(roleKey, rankValues, includeBinBasin)
  local order = getTaxonOrder(roleKey)
  local chain = {}
  for _, rank in ipairs(order) do
    if includeBinBasin or (rank ~= "Bin" and rank ~= "Basin") then
      local v = trim(rankValues[rank] or "")
      table.insert(chain, { rank = rank, value = v })
    end
  end

  local hasThreeInRow = false
  local pairRuns = 0
  local runStart = 1
  while runStart <= #chain do
    local runEnd = runStart
    local runVal = chain[runStart].value
    while runEnd + 1 <= #chain and chain[runEnd + 1].value == runVal do
      runEnd = runEnd + 1
    end

    local runLen = runEnd - runStart + 1
    if runVal ~= "" and runVal ~= "X" and runVal ~= "-" then
      if runLen >= 3 then
        hasThreeInRow = true
      end
      if runLen >= 2 then
        pairRuns = pairRuns + math.floor(runLen / 2)
      end
    end
    runStart = runEnd + 1
  end

  local combos = {}
  if hasThreeInRow then
    table.insert(combos, "3 in a row")
  end
  if pairRuns >= 2 then
    table.insert(combos, "two sets of two")
  end

  if #combos == 0 then
    return "Combo: none"
  end
  return "Combo: " .. table.concat(combos, " | ")
end

function renderTaxonCalculator(calcObj, roleKey, rankValues, comboText, includeBinBasin)
  if not calcObj or calcObj.isDestroyed() then return end

  local lines = {}
  local roleLabel = roleKey == "presence" and "Presence" or "Absence"
  table.insert(lines, roleLabel .. " Taxon Calculator")
  table.insert(lines, "")

  for _, rank in ipairs(getTaxonOrder(roleKey)) do
    if includeBinBasin or (rank ~= "Bin" and rank ~= "Basin") then
      table.insert(lines, rank .. ": " .. tostring(rankValues[rank] or "X"))
    end
  end

  table.insert(lines, "")
  table.insert(lines, comboText)

  local display = table.concat(lines, "\n")

  local okMain = pcall(function()
    calcObj.editButton({
      index = 0,
      label = display,
      font_size = 118,
    })
  end)

  if not okMain then
    attachTaxonCalculatorButtons(calcObj, roleKey)
    pcall(function()
      calcObj.editButton({ index = 0, label = display, font_size = 118 })
    end)
  end

  pcall(function()
    calcObj.editButton({
      index = 1,
      label = includeBinBasin and "Toggle Bin/Basin (ON)" or "Toggle Bin/Basin (OFF)",
    })
  end)

  calcObj.setDescription(display)
end

function zoneHasAnyTag(zone, tagList)
  for _, t in ipairs(tagList or {}) do
    if objectHasTag(zone, t) then
      return true
    end
  end
  return false
end

function objectNameMatchesAny(obj, nameList)
  if not obj or obj.isDestroyed() then return false end
  local objName = string.lower(trim(obj.getName() or ""))
  if objName == "" then return false end

  for _, expected in ipairs(nameList or {}) do
    if objName == string.lower(trim(expected)) then
      return true
    end
  end
  return false
end

function getObjectsByNameList(nameList)
  local results = {}
  if not nameList or #nameList == 0 then
    return results
  end

  local allObjects = getObjects() or {}
  for _, obj in ipairs(allObjects) do
    if obj and not obj.isDestroyed() and objectNameMatchesAny(obj, nameList) then
      table.insert(results, obj)
    end
  end
  return results
end

function zoneHasAnyTagOrName(zone, tagList, nameList)
  if zoneHasAnyTag(zone, tagList) then
    return true
  end
  return objectNameMatchesAny(zone, nameList)
end

function getObjectsByAnyTags(tagList)
  local out = {}
  local seen = {}
  for _, tagName in ipairs(tagList or {}) do
    local tagged = getObjectsWithTag(tagName) or {}
    for _, obj in ipairs(tagged) do
      if obj and not obj.isDestroyed() then
        local guid = nil
        local okGuid, g = pcall(function() return obj.getGUID() end)
        if okGuid and g then
          guid = tostring(g)
        end
        if not guid or not seen[guid] then
          if guid then
            seen[guid] = true
          end
          table.insert(out, obj)
        end
      end
    end
  end
  return out
end

function resolveSceneEntryStatus(entry)
  local via = "missing"
  local count = 0

  local tagCandidates = {}
  if entry.tag then
    table.insert(tagCandidates, entry.tag)
  end
  for _, t in ipairs(entry.tags or {}) do
    table.insert(tagCandidates, t)
  end

  if #tagCandidates > 0 then
    local tagged = getObjectsByAnyTags(tagCandidates)
    if #tagged > 0 then
      return "tag", #tagged
    end
  end

  local named = getObjectsByNameList(entry.names or {})
  if #named > 0 then
    return "name", #named
  end

  return via, count
end

function onValidateScene(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)

  local lines = {}
  local tagCount = 0
  local nameCount = 0
  local missingCount = 0

  for _, entry in ipairs(sceneValidationEntries) do
    local via, count = resolveSceneEntryStatus(entry)
    if via == "tag" then
      tagCount = tagCount + 1
      table.insert(lines, string.format("[TAG] %s (%d)", entry.label, count))
    elseif via == "name" then
      nameCount = nameCount + 1
      table.insert(lines, string.format("[NAME] %s (%d)", entry.label, count))
    else
      missingCount = missingCount + 1
      table.insert(lines, string.format("[MISSING] %s", entry.label))
    end
  end

  local summary = string.format(
    "Scene wiring: %d via tag, %d via name fallback, %d missing",
    tagCount,
    nameCount,
    missingCount
  )

  local summaryColor = missingCount == 0 and { 0.75, 1, 0.75 } or { 1, 0.75, 0.4 }
  broadcastToColor(summary, playerColor, summaryColor)
  for _, line in ipairs(lines) do
    local c = { 0.85, 0.85, 0.85 }
    if string.sub(line, 1, 9) == "[MISSING]" then
      c = { 1, 0.6, 0.4 }
    elseif string.sub(line, 1, 6) == "[NAME]" then
      c = { 0.95, 0.9, 0.6 }
    elseif string.sub(line, 1, 5) == "[TAG]" then
      c = { 0.75, 0.95, 0.75 }
    end
    broadcastToColor(line, playerColor, c)
  end

  updateStatusUi(summary)
end

function onRefreshRulebooksFromContext(playerColor, menuPosition)
  refreshRulebookObjects(playerColor)
end

function refreshRulebookObjects(playerColor)
  local updatedCount = 0
  updatedCount = updatedCount + applyRulebookGuide(tags.presenceRulebook, rulebookGuides.PresenceRulebook, nameRegistry.presenceRulebook)
  updatedCount = updatedCount + applyRulebookGuide(tags.absenceRulebook, rulebookGuides.AbsenceRulebook, nameRegistry.absenceRulebook)

  if playerColor and type(playerColor) == "string" then
    if updatedCount > 0 then
      broadcastToColor("Rulebooks refreshed: " .. tostring(updatedCount) .. " object(s).", playerColor, { 0.8, 1, 0.8 })
    else
      broadcastToColor("No tagged rulebook objects found yet.", playerColor, { 1, 0.85, 0.55 })
    end
  end
end

function applyRulebookGuide(tagName, guide, fallbackNames)
  if not guide then return 0 end

  local tagged = getObjectsWithTag(tagName) or {}
  if #tagged == 0 then
    tagged = getObjectsByNameList(fallbackNames)
  end
  local count = 0
  for _, obj in ipairs(tagged) do
    if obj and not obj.isDestroyed() then
      obj.setName(guide.title or tagName)
      obj.setDescription(guide.body or "")
      renderRulebookText(obj, guide)
      count = count + 1
    end
  end
  return count
end

function renderRulebookText(obj, guide)
  if not obj or obj.isDestroyed() then return end

  local lines = {}
  for line in string.gmatch(tostring(guide.body or ""), "[^\r\n]+") do
    if trim(line) ~= "" then
      table.insert(lines, line)
    end
  end

  local preview = {}
  for i = 1, math.min(#lines, 16) do
    table.insert(preview, lines[i])
  end

  local displayText = (guide.title or "Rulebook") .. "\n\n" .. table.concat(preview, "\n")

  local width = 3000
  local height = 1800
  local fontSize = 120

  local okBounds, bounds = pcall(function()
    return obj.getBoundsNormalized()
  end)
  if okBounds and bounds and bounds.size then
    local sizeX = tonumber(bounds.size.x) or 4
    local sizeZ = tonumber(bounds.size.z) or 3
    width = math.max(2200, math.floor(sizeX * 480))
    height = math.max(1200, math.floor(sizeZ * 420))
    fontSize = math.max(72, math.floor(math.min(width, height) / 18))
  end

  pcall(function()
    obj.clearButtons()
  end)

  obj.createButton({
    label = displayText,
    click_function = "onRulebookTextNoop",
    function_owner = self,
    position = { 0, 0.32, 0 },
    rotation = { 0, 180, 0 },
    width = width,
    height = height,
    font_size = fontSize,
    color = { 0.08, 0.08, 0.08, 0.92 },
    font_color = { 0.95, 0.95, 0.95 },
    tooltip = guide.title or "Rulebook",
  })
end

function onRulebookTextNoop(obj, playerColor, altClick)
end

function applyDeckbuilderRoleMode()
  if not uiState.deckbuilderVisible then return end

  local role = uiState.currentDeckbuilderRole
  local titleText = "Severance Deckbuilder"
  local roleHint = "Choose a deckbuilder object to enter Presence/Absence mode."

  if role == "presence" then
    titleText = "Presence Deckbuilder"
    roleHint = "Presence mode active: build using Presence flow."
  elseif role == "absence" then
    titleText = "Absence Deckbuilder"
    roleHint = "Absence mode active: build using Absence flow."
  end

  pcall(function()
    UI.setAttribute("panelTitle", "text", titleText)
  end)
  pcall(function()
    UI.setAttribute("roleHint", "text", roleHint)
  end)
  pcall(function()
    UI.setAttribute("btnPresence", "active", role ~= "absence" and "true" or "false")
  end)
  pcall(function()
    UI.setAttribute("btnAbsence", "active", role ~= "presence" and "true" or "false")
  end)

  refreshSetupStatus(role)
end

function objectHasTag(obj, tagName)
  if not obj or obj.isDestroyed() then return false end
  local ok, result = pcall(function()
    return obj.hasTag(tagName)
  end)
  return ok and result == true
end

function onSave()
  return JSON.encode({
    cards = state.cards,
    lastFetch = state.lastFetch,
    deckbuild = state.deckbuild,
    roundValue = state.roundValue,
    statusText = state.statusText,
    taxonSettings = state.taxonSettings,
    setup = state.setup,
  })
end

function createButtons()
  local buttons = {
    { label = "Build Presence Deck", click = "onBuildPresence" },
    { label = "Build Absence Deck", click = "onBuildAbsence" },
    { label = "Import Decklist", click = "onImportDecklist" },
    { label = "Search Cards", click = "onSearchCards" },
    { label = "Pick Search ID", click = "onPickSearchId" },
    { label = "Add Search ID Manually", click = "onAddSearchIdManual" },
    { label = "Skip Step", click = "onSkipStep" },
    { label = "Reroll Step", click = "onRerollStep" },
    { label = "Refresh Cache", click = "onRefreshCards" },
    { label = "Finalize Deck", click = "onFinalizeDeck" },
  }

  local x = -35
  local y = 0.2
  local z = 20
  local width = 900
  local height = 200

  for i, btn in ipairs(buttons) do
    self.createButton({
      label = btn.label,
      click_function = btn.click,
      function_owner = self,
      position = { x, y, z - (i - 1) * 2.2 },
      width = width,
      height = height,
      font_size = 120,
      color = { 0.18, 0.18, 0.18 },
      font_color = { 1, 1, 1 },
    })
  end
end

function onBuildPresence(arg1, arg2)
  uiState.currentDeckbuilderRole = "presence"
  onStartDeckbuildMode(arg1, arg2)
end

function onBuildAbsence(arg1, arg2)
  uiState.currentDeckbuilderRole = "absence"
  onStartDeckbuildMode(arg1, arg2)
end

function onStartDeckbuildMode(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  if not requireSetupHost(playerColor, "Start Deckbuild Mode") then
    return
  end

  local role = resolveActiveRole(playerColor)
  if role == nil then
    broadcastToColor("Pick Presence or Absence deckbuilder first.", playerColor, { 1, 0.8, 0.4 })
    return
  end

  local setup = getRoleSetup(role)
  setup.mode = "guided"
  state.setup.phase = "deckbuild"
  setup.startingHandResolved = false
  state.setup.firstPlayer = nil
  state.setup.tieBreakApplied = false
  state.setup.startingManaSums = { presence = 0, absence = 0 }
  uiState.currentDeckbuilderRole = role
  uiState.lastPlayerColor = playerColor

  ensureCards(function()
    startDeckbuild(role, playerColor)
    broadcastToColor(getRoleLabel(role) .. " setup switched to guided deckbuild mode.", playerColor, { 0.8, 1, 0.8 })
    refreshSetupStatus(role)
  end)
end

function onReturnToBaseMode(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  if not requireSetupHost(playerColor, "Return to Base Mode") then
    return
  end

  local role = resolveActiveRole(playerColor)
  if role == nil then
    broadcastToColor("Pick Presence or Absence deckbuilder first.", playerColor, { 1, 0.8, 0.4 })
    return
  end

  local setup = getRoleSetup(role)
  setup.mode = "base"
  setup.startingHandResolved = false
  state.setup.firstPlayer = nil
  state.setup.tieBreakApplied = false
  state.setup.startingManaSums = { presence = 0, absence = 0 }
  if state.deckbuild and state.deckbuild.role == role then
    state.deckbuild = nil
  end

  local otherRole = role == "presence" and "absence" or "presence"
  if getRoleSetup(otherRole).mode ~= "guided" then
    state.setup.phase = "base"
  end

  broadcastToColor(getRoleLabel(role) .. " returned to base setup mode.", playerColor, { 1, 1, 1 })
  refreshSetupStatus(role)
end

function onSelectEssa(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  local role = resolveActiveRole(playerColor)
  if role == nil then
    broadcastToColor("Pick Presence or Absence deckbuilder first.", playerColor, { 1, 0.8, 0.4 })
    return
  end

  local roleSetup = getRoleSetup(role)
  if roleSetup.mode == "base" then
    broadcastToColor("Select Essa is only available after entering deckbuild/import mode.", playerColor, { 1, 0.8, 0.4 })
    return
  end

  local essaId = trim(UI.getAttribute("searchInput", "text") or "")
  if essaId == "" then
    broadcastToColor("Select Essa: enter an Essa card id in Search Cards input.", playerColor, { 1, 1, 1 })
    return
  end

  ensureCards(function()
    local card = findCardById(essaId)
    if not card then
      broadcastToColor("Essa not found: " .. essaId, playerColor, { 1, 0.6, 0.4 })
      return
    end

    if not equalsIgnoreCase(card.taxonomy_rank, "Essa") then
      broadcastToColor("Selected card is not rank Essa: " .. (card.id or essaId), playerColor, { 1, 0.7, 0.4 })
      return
    end

    roleSetup.essaId = card.id
    if getRoleSetup("presence").essaId and getRoleSetup("absence").essaId then
      state.setup.phase = "essa_select"
    end
    broadcastToColor(getRoleLabel(role) .. " Essa selected: " .. (card.display_name or card.id), playerColor, { 0.8, 1, 0.8 })
    refreshSetupStatus(role)
  end)
end

function onResolveStartingHands(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  if not requireSetupHost(playerColor, "Resolve Starting Hands") then
    return
  end

  ensureSetupDefaults()
  if not validateDistinctRolePlayers(playerColor) then
    return
  end

  local presenceSetup = getRoleSetup("presence")
  local absenceSetup = getRoleSetup("absence")
  if presenceSetup.mode == "base" or absenceSetup.mode == "base" then
    broadcastToColor("Both roles must enter deckbuild/import mode before resolving starting hands.", playerColor, { 1, 0.7, 0.4 })
    return
  end
  if not presenceSetup.essaId or not absenceSetup.essaId then
    broadcastToColor("Both roles must select Essa before dealing starting hands.", playerColor, { 1, 0.7, 0.4 })
    return
  end

  local presenceColor = presenceSetup.playerColor or "White"
  local absenceColor = absenceSetup.playerColor or "Black"
  local presenceDeck = resolvePlayableDeckForRole("presence")
  local absenceDeck = resolvePlayableDeckForRole("absence")
  if not presenceDeck or not absenceDeck then
    broadcastToColor("Resolve Starting Hands: place a playable deck stack on each deck marker plane.", playerColor, { 1, 0.6, 0.4 })
    return
  end

  if getDeckObjectQuantity(presenceDeck) < 7 or getDeckObjectQuantity(absenceDeck) < 7 then
    broadcastToColor("Resolve Starting Hands: each role needs at least 7 cards in its playable deck stack.", playerColor, { 1, 0.7, 0.4 })
    return
  end

  local okPresence = pcall(function() presenceDeck.deal(7, presenceColor) end)
  local okAbsence = pcall(function() absenceDeck.deal(7, absenceColor) end)
  if not okPresence or not okAbsence then
    broadcastToColor("Resolve Starting Hands failed. Ensure both deck objects are valid deck stacks.", playerColor, { 1, 0.5, 0.5 })
    return
  end

  presenceSetup.startingHandResolved = true
  absenceSetup.startingHandResolved = true
  state.setup.phase = "start_resolve"
  state.setup.firstPlayer = nil
  state.setup.tieBreakApplied = false
  state.setup.startingManaSums = { presence = 0, absence = 0 }
  broadcastToAll("Starting hands resolved (7 cards each).", { 0.8, 1, 0.8 })
  refreshSetupStatus(uiState.currentDeckbuilderRole)
end

function onResolveFirstPlayer(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  if not requireSetupHost(playerColor, "Resolve First Player") then
    return
  end

  if not validateDistinctRolePlayers(playerColor) then
    return
  end

  local presenceSetup = getRoleSetup("presence")
  local absenceSetup = getRoleSetup("absence")
  if not presenceSetup.startingHandResolved or not absenceSetup.startingHandResolved then
    broadcastToColor("Resolve First Player requires both starting hands to be resolved first.", playerColor, { 1, 0.7, 0.4 })
    return
  end

  local presenceColor = presenceSetup.playerColor or "White"
  local absenceColor = absenceSetup.playerColor or "Black"
  local presenceSum = getOpeningHandManaSum(presenceColor)
  local absenceSum = getOpeningHandManaSum(absenceColor)
  if presenceSum == 0 and absenceSum == 0 then
    broadcastToColor("Resolve First Player failed: both opening hands have 0 detected mana.", playerColor, { 1, 0.6, 0.4 })
    return
  end

  local winnerRole = "presence"
  local tieBreakApplied = false
  if absenceSum > presenceSum then
    winnerRole = "absence"
  elseif absenceSum == presenceSum then
    tieBreakApplied = true
  end

  state.setup.startingManaSums = { presence = presenceSum, absence = absenceSum }
  state.setup.firstPlayer = winnerRole
  state.setup.tieBreakApplied = tieBreakApplied
  state.setup.phase = "in_game"
  local msg = string.format("First player: %s (Presence=%d, Absence=%d%s)", getRoleLabel(winnerRole), presenceSum, absenceSum, tieBreakApplied and ", tie-break" or "")
  broadcastToAll(msg, { 0.85, 1, 0.85 })
  refreshSetupStatus(uiState.currentDeckbuilderRole)
end

function onImportDecklist(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  local raw = UI.getAttribute("importInput", "text") or ""
  local ids = parseLines(raw)
  if #ids == 0 then
    broadcastToColor("Import decklist: paste one id per line.", playerColor, { 1, 1, 1 })
    return
  end

  ensureCards(function()
    local role = resolveActiveRole(playerColor) or (state.deckbuild and state.deckbuild.role) or "absence"
    local roleSetup = getRoleSetup(role)
    if roleSetup then
      roleSetup.mode = "import"
      state.setup.phase = "deckbuild"
      roleSetup.startingHandResolved = false
      state.setup.firstPlayer = nil
      state.setup.tieBreakApplied = false
      state.setup.startingManaSums = { presence = 0, absence = 0 }
    end

    local resolvedCards, missing = resolveDecklist(ids)
    local msg = string.format("Import decklist: %d found, %d missing.", #resolvedCards, #missing)
    broadcastToColor(msg, playerColor, { 1, 1, 1 })
    if #missing > 0 then
      broadcastToColor("Missing: " .. table.concat(missing, ", "), playerColor, { 1, 0.8, 0.4 })
    end

    if #resolvedCards > 0 then
      spawnRoleDeck(role, resolvedCards, playerColor, "Imported Deck")
      refreshSetupStatus(role)
    end
  end)
end

function onSearchCards(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  local query = (UI.getAttribute("searchInput", "text") or "")
  query = string.lower(query)
  if query == "" then
    broadcastToColor("Search cards: enter a query.", playerColor, { 1, 1, 1 })
    return
  end

  ensureCards(function()
    local completeResults = {}
    local incompleteResults = {}
    for _, card in ipairs(state.cards) do
      local name = string.lower(card.display_name or "")
      local id = string.lower(card.id or "")
      if string.find(name, query, 1, true) or string.find(id, query, 1, true) then
        if isDrawEligibleCard(card) then
          if #completeResults < 10 then
            table.insert(completeResults, card)
          end
        else
          if #incompleteResults < 10 then
            table.insert(incompleteResults, card)
          end
        end
      end
    end

    if #completeResults == 0 and #incompleteResults == 0 then
      broadcastToColor("Search cards: no results.", playerColor, { 1, 1, 1 })
      return
    end

    if #completeResults > 0 then
      broadcastToColor("Search cards: draw-eligible", playerColor, { 0.7, 1, 0.7 })
    end
    for _, card in ipairs(completeResults) do
      broadcastToColor(string.format("- %s (%s)", card.display_name or "", card.id or ""), playerColor, { 0.8, 0.8, 0.8 })
    end

    if #incompleteResults > 0 then
      broadcastToColor("Search cards: incomplete/manual-only", playerColor, { 1, 0.85, 0.55 })
    end
    for _, card in ipairs(incompleteResults) do
      broadcastToColor(string.format("- %s (%s) [%s]", card.display_name or "", card.id or "", card.completion_status or "unknown"), playerColor, { 1, 0.8, 0.6 })
    end
  end)
end

function onPickSearchId(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  local id = UI.getAttribute("searchInput", "text") or ""
  id = trim(id)
  if id == "" then
    broadcastToColor("Pick Search ID: enter a card id in Search Cards input.", playerColor, { 1, 1, 1 })
    return
  end

  if not state.deckbuild then
    broadcastToColor("No active deckbuild. Start Presence/Absence deckbuilding first.", playerColor, { 1, 0.8, 0.4 })
    return
  end

  local ok = pickDeckbuildCard(id, playerColor)
  if not ok then
    broadcastToColor("Card id not in current draft options: " .. id, playerColor, { 1, 0.6, 0.4 })
  end
end

function onRefreshCards(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  fetchCards(function()
    local count = #state.cards
    local text = string.format("Card cache refreshed: %d cards", count)
    broadcastToColor(text, playerColor, { 0.7, 1, 0.7 })
    updateStatusUi(text)
  end)
end

function onAddSearchIdManual(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  local id = trim(UI.getAttribute("searchInput", "text") or "")
  if id == "" then
    broadcastToColor("Add Search ID Manually: enter a card id in Search Cards input.", playerColor, { 1, 1, 1 })
    return
  end

  ensureCards(function()
    local card = findCardById(id)
    if not card then
      broadcastToColor("Card not found: " .. id, playerColor, { 1, 0.5, 0.5 })
      return
    end

    local role = state.deckbuild and state.deckbuild.role or "absence"
    spawnManualCard(role, card, playerColor)
  end)
end

function onSkipStep(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  if not state.deckbuild then
    broadcastToColor("No active deckbuild. Start Presence/Absence deckbuilding first.", playerColor, { 1, 0.8, 0.4 })
    return
  end

  local previousSkips = state.deckbuild.skipsUsed or 0
  if previousSkips >= (state.deckbuild.maxSkips or config.maxSkips) then
    broadcastToColor("Skip rejected: maximum skips reached for this draft.", playerColor, { 1, 0.7, 0.4 })
    refreshSetupStatus(state.deckbuild and state.deckbuild.role or uiState.currentDeckbuilderRole)
    return
  end

  state.deckbuild.skipsUsed = math.min(previousSkips + 1, state.deckbuild.maxSkips or config.maxSkips)
  if previousSkips < (state.deckbuild.maxSkips or config.maxSkips)
    and state.deckbuild.decisionBudget and state.deckbuild.maxDecisionBudget
  then
    state.deckbuild.decisionBudget = math.min(state.deckbuild.decisionBudget + 1, state.deckbuild.maxDecisionBudget)
  end

  broadcastToColor("Decision skipped.", playerColor, { 1, 1, 1 })
  advanceDeckbuildStep(playerColor)
  refreshSetupStatus(state.deckbuild and state.deckbuild.role or uiState.currentDeckbuilderRole)
end

function onRerollStep(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  if not state.deckbuild then
    broadcastToColor("No active deckbuild. Start Presence/Absence deckbuilding first.", playerColor, { 1, 0.8, 0.4 })
    return
  end
  broadcastToColor("Decision rerolled.", playerColor, { 1, 1, 1 })
  prepareCurrentStepOptions(playerColor)
end

function onFinalizeDeck(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  if not state.deckbuild or not state.deckbuild.pickedCards then
    broadcastToColor("No active deckbuild to finalize.", playerColor, { 1, 0.8, 0.4 })
    return
  end

  if #state.deckbuild.pickedCards == 0 then
    broadcastToColor("No cards have been picked yet.", playerColor, { 1, 0.8, 0.4 })
    return
  end

  local role = state.deckbuild.role or resolveActiveRole(playerColor)
  local setup = getRoleSetup(role)
  if setup and not setup.essaId then
    broadcastToColor("Finalize blocked: select Essa first.", playerColor, { 1, 0.7, 0.4 })
    refreshSetupStatus(role)
    return
  end

  spawnRoleDeck(state.deckbuild.role, state.deckbuild.pickedCards, playerColor, "Draft Deck")
  refreshSetupStatus(role)
end

function startDeckbuild(role, playerColor)
  local order = getTaxonOrder(role)
  state.deckbuild = {
    role = role,
    mode = "guided",
    order = order,
    picksThisDecision = 0,
    picksPerDecision = 1,
    pickedIds = {},
    pickedCards = {},
    currentOptions = {},
    decisionsShown = 1,
    decisionBudget = config.baseDecisionBudget,
    maxDecisionBudget = config.maxDecisionBudget,
    skipsUsed = 0,
    maxSkips = config.maxSkips,
  }

  local label = role == "presence" and "Presence" or "Absence"
  broadcastToColor(label .. " deckbuilder started.", playerColor, { 1, 1, 1 })
  prepareCurrentStepOptions(playerColor)
  refreshSetupStatus(role)
end

function getTaxonOrder(role)
  if role == "absence" then
    return taxonomyOrderByRole.absence
  end
  return taxonomyOrderByRole.presence
end

function ensureCards(onReady)
  if isCacheFresh() and #state.cards > 0 then
    onReady()
    return
  end

  fetchCards(onReady)
end

function isCacheFresh()
  if state.lastFetch == 0 then return false end
  return os.time() - state.lastFetch <= config.cacheTtlSeconds
end

function fetchCards(onReady)
  local url = config.apiBaseUrl .. "/api/cards?status=" .. config.defaultStatus
  WebRequest.get(url, function(request)
    if request.is_error then
      broadcastToAll("Card fetch failed: " .. request.error, { 1, 0.4, 0.4 })
      return
    end

    local ok, payload = pcall(JSON.decode, request.text)
    if not ok or not payload or not payload.cards then
      broadcastToAll("Card fetch failed: invalid response", { 1, 0.4, 0.4 })
      return
    end

    state.cards = payload.cards
    state.lastFetch = os.time()
    updateStatusUi(string.format("Cards loaded: %d", #state.cards))
    onReady()
  end)
end

function getCardImageUrl(card)
  if config.imagePathMode == "path" and card.image_path then
    return card.image_path
  end
  if card.image_path and string.match(card.image_path, "^https?://") then
    return card.image_path
  end
  if config.imageBaseUrl ~= "" then
    return config.imageBaseUrl .. "/" .. card.id .. ".png"
  end
  return nil
end

function parseLines(raw)
  local lines = {}
  for line in string.gmatch(raw or "", "[^\r\n]+") do
    local trimmed = string.gsub(line, "^%s+", "")
    trimmed = string.gsub(trimmed, "%s+$", "")
    if trimmed ~= "" then
      table.insert(lines, trimmed)
    end
  end
  return lines
end

function indexCardsById(cards)
  local index = {}
  for _, card in ipairs(cards or {}) do
    if card.id then
      index[card.id] = card
    end
  end
  return index
end

function resolvePlayerColor(arg1, arg2)
  if type(arg1) == "string" then
    return arg1
  end
  if type(arg2) == "string" then
    return arg2
  end
  if type(arg1) == "table" and arg1.color then
    return arg1.color
  end
  return "White"
end

function trim(value)
  local s = tostring(value or "")
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  return s
end

function getCurrentRank()
  if not state.deckbuild then return nil end
  if (state.deckbuild.decisionsShown or 1) > (state.deckbuild.decisionBudget or config.baseDecisionBudget) then
    return nil
  end

  local decisionIndex = state.deckbuild.decisionsShown or 1
  local rankWeights = getRankWeightsForDecision(state.deckbuild.role, decisionIndex)
  if not rankWeights then
    return nil
  end
  return pickWeightedRank(rankWeights)
end

function getRankWeightsForDecision(role, decisionIndex)
  local order = taxonomyOrderByRole.presence
  local transition = config.decisionBiasTransition or 30
  local latePhase = decisionIndex > transition
  local earlyFactor = math.max(0, (transition + 1 - decisionIndex) / transition)

  local weights = {}
  for i, rank in ipairs(order) do
    local isPreferred = false
    if role == "presence" then
      isPreferred = i >= 5
    else
      isPreferred = i <= 5
    end

    local w = 1.0
    if latePhase then
      w = isPreferred and 1.1 or 0.9
    else
      w = isPreferred and (1.0 + (2.0 * earlyFactor)) or 1.0
    end
    weights[rank] = w
  end

  return weights
end

function pickWeightedRank(rankWeights)
  local total = 0
  for _, weight in pairs(rankWeights or {}) do
    total = total + (tonumber(weight) or 0)
  end
  if total <= 0 then return nil end

  local roll = math.random() * total
  local running = 0
  for _, rank in ipairs(taxonomyOrderByRole.presence) do
    local w = tonumber(rankWeights[rank] or 0) or 0
    running = running + w
    if roll <= running then
      return rank
    end
  end

  return taxonomyOrderByRole.presence[#taxonomyOrderByRole.presence]
end

function buildGuidedOptionPoolByRank()
  local byRank = {}
  for _, rank in ipairs(taxonomyOrderByRole.presence) do
    byRank[rank] = {}
  end

  for _, card in ipairs(state.cards or {}) do
    local rank = card.taxonomy_rank
    if rank and byRank[rank]
      and not state.deckbuild.pickedIds[card.id]
      and isDrawEligibleCard(card)
    then
      table.insert(byRank[rank], card)
    end
  end

  return byRank
end

function sampleGuidedDecisionOptions(role, decisionIndex, count)
  local poolByRank = buildGuidedOptionPoolByRank()
  local rankWeights = getRankWeightsForDecision(role, decisionIndex)
  local selected = {}
  local selectedIds = {}

  for _ = 1, count do
    local workingWeights = {}
    for rank, weight in pairs(rankWeights) do
      if poolByRank[rank] and #poolByRank[rank] > 0 then
        workingWeights[rank] = weight
      end
    end

    local rank = pickWeightedRank(workingWeights)
    if not rank then break end

    local cardsForRank = poolByRank[rank]
    local tries = 0
    local picked = nil
    while tries < 8 and cardsForRank and #cardsForRank > 0 do
      local idx = math.random(1, #cardsForRank)
      local candidate = cardsForRank[idx]
      if candidate and not selectedIds[candidate.id] then
        picked = candidate
        table.remove(cardsForRank, idx)
        break
      end
      table.remove(cardsForRank, idx)
      tries = tries + 1
    end

    if picked then
      selectedIds[picked.id] = true
      table.insert(selected, picked)
    end
  end

  if #selected < count then
    local fallbackPool = {}
    for _, rank in ipairs(taxonomyOrderByRole.presence) do
      for _, card in ipairs(poolByRank[rank] or {}) do
        if card and not selectedIds[card.id] then
          table.insert(fallbackPool, card)
        end
      end
    end

    local topUps = sampleCards(fallbackPool, count - #selected)
    for _, card in ipairs(topUps) do
      if card and not selectedIds[card.id] then
        selectedIds[card.id] = true
        table.insert(selected, card)
      end
    end
  end

  return selected
end

function prepareCurrentStepOptions(playerColor)
  if not state.deckbuild then return end

  if (state.deckbuild.decisionsShown or 1) > (state.deckbuild.decisionBudget or config.baseDecisionBudget) then
    broadcastToColor("Decision budget complete. Finalize deck when ready.", playerColor, { 0.7, 1, 0.7 })
    updateStatusUi("Deckbuild complete. Finalize deck.")
    refreshSetupStatus(state.deckbuild.role)
    return
  end

  local decisionIndex = state.deckbuild.decisionsShown or 1
  local rank = getCurrentRank() or "Mixed"
  state.deckbuild.currentOptions = sampleGuidedDecisionOptions(
    state.deckbuild.role,
    decisionIndex,
    config.optionCountPerStep
  )
  state.deckbuild.picksThisDecision = 0

  local header = string.format("Draft Decision %d/%d - %s", state.deckbuild.decisionsShown, state.deckbuild.decisionBudget, rank)
  broadcastToColor(header, playerColor, { 0.8, 0.9, 1 })

  if #state.deckbuild.currentOptions == 0 then
    broadcastToColor("No available cards for this decision. Advancing.", playerColor, { 1, 0.8, 0.4 })
    advanceDeckbuildStep(playerColor)
    return
  end

  for _, card in ipairs(state.deckbuild.currentOptions) do
    broadcastToColor(string.format("- %s (%s)", card.display_name or "", card.id or ""), playerColor, { 0.8, 0.8, 0.8 })
  end
  broadcastToColor("Pick by typing card id into Search Cards input and clicking Pick Search ID.", playerColor, { 1, 1, 1 })
  updateStatusUi(header)
end

function pickDeckbuildCard(cardId, playerColor)
  if not state.deckbuild then return false end

  local chosen = nil
  for _, card in ipairs(state.deckbuild.currentOptions or {}) do
    if equalsIgnoreCase(card.id, cardId) then
      chosen = card
      break
    end
  end
  if not chosen then return false end

  state.deckbuild.pickedIds[chosen.id] = true
  table.insert(state.deckbuild.pickedCards, chosen)
  state.deckbuild.picksThisDecision = (state.deckbuild.picksThisDecision or 0) + 1

  broadcastToColor("Picked: " .. (chosen.display_name or chosen.id), playerColor, { 0.7, 1, 0.7 })

  if state.deckbuild.picksThisDecision >= (state.deckbuild.picksPerDecision or 1) then
    advanceDeckbuildStep(playerColor)
    return true
  end

  local remaining = {}
  for _, card in ipairs(state.deckbuild.currentOptions) do
    if not state.deckbuild.pickedIds[card.id] then
      table.insert(remaining, card)
    end
  end
  state.deckbuild.currentOptions = remaining

  if #state.deckbuild.currentOptions == 0 then
    advanceDeckbuildStep(playerColor)
    return true
  end

  broadcastToColor("Remaining options this decision:", playerColor, { 1, 1, 1 })
  for _, card in ipairs(state.deckbuild.currentOptions) do
    broadcastToColor(string.format("- %s (%s)", card.display_name or "", card.id or ""), playerColor, { 0.8, 0.8, 0.8 })
  end
  return true
end

function advanceDeckbuildStep(playerColor)
  if not state.deckbuild then return end
  state.deckbuild.decisionsShown = (state.deckbuild.decisionsShown or 0) + 1
  prepareCurrentStepOptions(playerColor)
  refreshSetupStatus(state.deckbuild.role)
end

function resolveDecklist(ids)
  local cardIndex = indexCardsById(state.cards)
  local resolved = {}
  local missing = {}
  for _, id in ipairs(ids) do
    local found = cardIndex[id]
    if found then
      table.insert(resolved, found)
    else
      table.insert(missing, id)
    end
  end
  return resolved, missing
end

function spawnRoleDeck(role, cards, playerColor, deckName)
  local roleKey = role == "presence" and "presence" or "absence"
  local spawnTransform = resolveDeckSpawnTransform(roleKey)

  local ttsCards = {}
  for _, card in ipairs(cards) do
    local faceUrl = getCardImageUrl(card)
    if faceUrl then
      table.insert(ttsCards, {
        id = card.id,
        name = card.display_name or card.id,
        description = buildCardHoverDescription(card),
        faceUrl = faceUrl,
      })
    end
  end

  if #ttsCards == 0 then
    broadcastToColor("No spawnable cards found (missing image URLs).", playerColor, { 1, 0.5, 0.5 })
    return
  end

  local deckJson = buildDeckJson(ttsCards, deckName or "Severance Deck")
  spawnObjectJSON({
    json = JSON.encode(deckJson),
    position = spawnTransform.position,
    rotation = spawnTransform.rotation,
    callback_function = function(obj)
      obj.setName((deckName or "Deck") .. " - " .. capitalize(roleKey))
    end,
  })

  broadcastToColor(string.format("Spawned %d-card %s deck.", #ttsCards, roleKey), playerColor, { 0.7, 1, 0.7 })
  updateStatusUi(string.format("Last deck spawn: %s (%d cards)", roleKey, #ttsCards))
end

function buildDeckJson(cards, deckName)
  local customDeck = {}
  local contained = {}
  local deckIds = {}
  local deckIndex = 1

  for i, card in ipairs(cards) do
    local customId = 100 + i
    local cardId = customId * 100

    customDeck[tostring(customId)] = {
      FaceURL = card.faceUrl,
      BackURL = config.defaultCardBackUrl,
      NumWidth = 1,
      NumHeight = 1,
      BackIsHidden = true,
      UniqueBack = false,
      Type = 0,
    }

    table.insert(contained, {
      Name = "CardCustom",
      Transform = {
        posX = 0,
        posY = 0,
        posZ = 0,
        rotX = 0,
        rotY = 180,
        rotZ = 180,
        scaleX = 1,
        scaleY = 1,
        scaleZ = 1,
      },
      Nickname = card.name,
      Description = card.description,
      CardID = cardId,
      CustomDeck = customDeck,
      LuaScript = "",
      LuaScriptState = "",
      XmlUI = "",
    })

    table.insert(deckIds, cardId)
  end

  return {
    Name = "DeckCustom",
    Transform = {
      posX = 0,
      posY = 1,
      posZ = 0,
      rotX = 0,
      rotY = 180,
      rotZ = 180,
      scaleX = 1,
      scaleY = 1,
      scaleZ = 1,
    },
    Nickname = deckName or "Severance Deck",
    Description = "",
    DeckIDs = deckIds,
    CustomDeck = customDeck,
    ContainedObjects = contained,
    LuaScript = "",
    LuaScriptState = "",
    XmlUI = "",
    GUID = "",
  }
end

function spawnManualCard(role, card, playerColor)
  local roleKey = role == "presence" and "presence" or "absence"
  local spawnTransform = resolveDeckSpawnTransform(roleKey)
  local faceUrl = getCardImageUrl(card)
  if not faceUrl then
    broadcastToColor("Unable to resolve card image/fallback for: " .. (card.id or "unknown"), playerColor, { 1, 0.5, 0.5 })
    return
  end

  local customId = 1001
  local cardId = customId * 100
  local cardJson = {
    Name = "CardCustom",
    Transform = {
      posX = 0,
      posY = 1,
      posZ = 0,
      rotX = 0,
      rotY = 180,
      rotZ = 180,
      scaleX = 1,
      scaleY = 1,
      scaleZ = 1,
    },
    Nickname = (card.display_name or card.id or "Card") .. " [Manual]",
    Description = buildCardHoverDescription(card),
    CardID = cardId,
    CustomDeck = {
      [tostring(customId)] = {
        FaceURL = faceUrl,
        BackURL = config.defaultCardBackUrl,
        NumWidth = 1,
        NumHeight = 1,
        BackIsHidden = true,
        UniqueBack = false,
        Type = 0,
      }
    },
    LuaScript = "",
    LuaScriptState = "",
    XmlUI = "",
    GUID = "",
  }

  spawnObjectJSON({
    json = JSON.encode(cardJson),
    position = {
      spawnTransform.position[1] + 2.2,
      spawnTransform.position[2],
      spawnTransform.position[3],
    },
    rotation = spawnTransform.rotation,
  })

  local status = card.completion_status or "unknown"
  broadcastToColor(string.format("Manual add: %s (%s)", card.display_name or card.id or "Card", status), playerColor, { 0.75, 0.95, 1 })
end

function resolveDeckSpawnTransform(roleKey)
  local fallback = {
    position = roleZones[roleKey].deck,
    rotation = roleZones[roleKey].rotation,
  }

  local targetTag = roleKey == "presence" and tags.presenceDeck or tags.absenceDeck
  local tagged = getObjectsWithTag(targetTag) or {}
  local target = tagged[1]

  if not target or target.isDestroyed() then
    return fallback
  end

  local okPos, worldPos = pcall(function()
    return target.getPosition()
  end)
  if not okPos or not worldPos then
    return fallback
  end

  local spawnY = worldPos.y + 1.2
  local okBounds, bounds = pcall(function()
    return target.getBoundsNormalized()
  end)
  if okBounds and bounds and bounds.size and bounds.size.y then
    spawnY = worldPos.y + (tonumber(bounds.size.y) or 0) / 2 + 1.2
  end

  local rotation = fallback.rotation
  local okRot, worldRot = pcall(function()
    return target.getRotation()
  end)
  if okRot and worldRot then
    rotation = { worldRot.x or fallback.rotation[1], worldRot.y or fallback.rotation[2], worldRot.z or fallback.rotation[3] }
  end

  return {
    position = { worldPos.x, spawnY, worldPos.z },
    rotation = rotation,
  }
end

function findFirstTaggedObject(tagName, fallbackNames)
  local tagged = getObjectsWithTag(tagName) or {}
  if #tagged == 0 then
    tagged = getObjectsByNameList(fallbackNames)
  end
  for _, obj in ipairs(tagged) do
    if obj and not obj.isDestroyed() then
      return obj
    end
  end
  return nil
end

function resolveRoleDeckMarker(roleKey)
  if roleKey == "presence" then
    return findFirstTaggedObject(tags.presenceDeck, nameRegistry.presenceDeck)
  end
  return findFirstTaggedObject(tags.absenceDeck, nameRegistry.absenceDeck)
end

function getObjectTagValue(obj)
  if not obj or obj.isDestroyed() then return nil end
  local ok, tag = pcall(function() return obj.tag end)
  if ok then
    return tostring(tag or "")
  end
  return nil
end

function isPlayableDeckObject(obj)
  local tagValue = getObjectTagValue(obj)
  return tagValue == "Deck" or tagValue == "Card"
end

function getDeckObjectQuantity(obj)
  if not obj or obj.isDestroyed() then return 0 end
  local ok, qty = pcall(function() return obj.getQuantity() end)
  if ok and qty then
    return tonumber(qty) or 0
  end

  if isPlayableDeckObject(obj) then
    return 1
  end
  return 0
end

function resolvePlayableDeckForRole(roleKey)
  local marker = resolveRoleDeckMarker(roleKey)
  if not marker or marker.isDestroyed() then
    return nil
  end

  if isPlayableDeckObject(marker) then
    return marker
  end

  local okPos, markerPos = pcall(function() return marker.getPosition() end)
  if not okPos or not markerPos then
    return nil
  end

  local bestObj = nil
  local bestDist = math.huge
  local allObjects = getObjects() or {}
  for _, obj in ipairs(allObjects) do
    if obj and not obj.isDestroyed() and isPlayableDeckObject(obj) then
      local okObjPos, objPos = pcall(function() return obj.getPosition() end)
      if okObjPos and objPos then
        local dx = (objPos.x or 0) - (markerPos.x or 0)
        local dz = (objPos.z or 0) - (markerPos.z or 0)
        local dy = math.abs((objPos.y or 0) - (markerPos.y or 0))
        local dist2 = (dx * dx) + (dz * dz)
        if dy <= 4 and dist2 <= (5 * 5) and dist2 < bestDist then
          bestDist = dist2
          bestObj = obj
        end
      end
    end
  end

  return bestObj
end

function getOpeningHandManaSum(playerColor)
  local p = Player[playerColor]
  if not p then return 0 end

  local handObjects = {}
  local ok, result = pcall(function()
    return p.getHandObjects()
  end)
  if ok and result then
    handObjects = result
  end

  local total = 0
  for _, obj in ipairs(handObjects) do
    total = total + extractManaFromObject(obj)
  end
  return total
end

function extractManaFromObject(obj)
  if not obj or obj.isDestroyed() then return 0 end
  local description = ""
  local okDesc, value = pcall(function()
    return obj.getDescription()
  end)
  if okDesc and value then
    description = tostring(value)
  end

  local mana = string.match(description, '"mana_cost"%s*:%s*(%d+)')
  if not mana then
    mana = string.match(description, '"mana"%s*:%s*(%d+)')
  end
  return tonumber(mana or 0) or 0
end

function ensureZoneMarkers()
  if zoneRefs.presenceDeck == nil then
    zoneRefs.presenceDeck = spawnZoneMarker("Presence Deck Zone", roleZones.presence.deck, { 0.45, 0.1, 0.1 })
  end
  if zoneRefs.presenceDiscard == nil then
    zoneRefs.presenceDiscard = spawnZoneMarker("Presence Discard Zone", roleZones.presence.discard, { 0.35, 0.1, 0.1 })
  end
  if zoneRefs.absenceDeck == nil then
    zoneRefs.absenceDeck = spawnZoneMarker("Absence Deck Zone", roleZones.absence.deck, { 0.1, 0.1, 0.45 })
  end
  if zoneRefs.absenceDiscard == nil then
    zoneRefs.absenceDiscard = spawnZoneMarker("Absence Discard Zone", roleZones.absence.discard, { 0.1, 0.1, 0.35 })
  end
end

function createRoundTrackerButtons()
  self.createButton({
    label = "R-",
    click_function = "onRoundPrev",
    function_owner = self,
    position = { -2.2, 0.2, 4.8 },
    width = 320,
    height = 200,
    font_size = 110,
    color = { 0.2, 0.2, 0.2 },
    font_color = { 1, 1, 1 },
  })

  self.createButton({
    label = "R:1",
    click_function = "onRoundReset",
    function_owner = self,
    position = { 0, 0.2, 4.8 },
    width = 520,
    height = 200,
    font_size = 110,
    color = { 0.12, 0.12, 0.12 },
    font_color = { 0.8, 1, 0.8 },
  })

  local okButtons, buttons = pcall(function()
    return self.getButtons()
  end)
  if okButtons and buttons and #buttons > 0 then
    uiRefs.roundLabelButtonIndex = #buttons - 1
  else
    uiRefs.roundLabelButtonIndex = nil
  end

  self.createButton({
    label = "R+",
    click_function = "onRoundNext",
    function_owner = self,
    position = { 2.2, 0.2, 4.8 },
    width = 320,
    height = 200,
    font_size = 110,
    color = { 0.2, 0.2, 0.2 },
    font_color = { 1, 1, 1 },
  })
end

function onRoundPrev(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  state.roundValue = math.max(1, (state.roundValue or 1) - 1)
  updateRoundTrackerUi()
  broadcastToColor("Round set to " .. tostring(state.roundValue), playerColor, { 0.8, 1, 0.8 })
end

function onRoundNext(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  state.roundValue = math.min(99, (state.roundValue or 1) + 1)
  updateRoundTrackerUi()
  broadcastToColor("Round set to " .. tostring(state.roundValue), playerColor, { 0.8, 1, 0.8 })
end

function onRoundReset(arg1, arg2)
  local playerColor = resolvePlayerColor(arg1, arg2)
  state.roundValue = 1
  updateRoundTrackerUi()
  broadcastToColor("Round tracker reset to 1", playerColor, { 0.8, 1, 0.8 })
end

function spawnZoneMarker(label, position, color)
  local guid = nil
  spawnObject({
    type = "BlockSquare",
    position = { position[1], 1.02, position[3] },
    scale = { 2.2, 0.1, 3.2 },
    sound = false,
    callback_function = function(obj)
      obj.setName(label)
      obj.setColorTint(color)
      obj.setLock(true)
      guid = obj.getGUID()
    end,
  })
  return guid
end

function equalsIgnoreCase(a, b)
  return string.lower(tostring(a or "")) == string.lower(tostring(b or ""))
end

function findCardById(id)
  local target = string.lower(trim(id))
  for _, card in ipairs(state.cards or {}) do
    if string.lower(card.id or "") == target then
      return card
    end
  end
  return nil
end

function isDrawEligibleCard(card)
  local status = string.lower(card and card.completion_status or "")
  return config.drawEligibleStatuses[status] == true
end

function buildCardHoverDescription(card)
  local status = card.completion_status or "unknown"
  local isIncomplete = not isDrawEligibleCard(card)
  local prefix = isIncomplete and "[INCOMPLETE / MANUAL-ONLY]" or "[DRAW-ELIGIBLE]"
  local description = card.description or ""
  local payload = JSON.encode(card) or "{}"
  return table.concat({
    prefix,
    "Status: " .. status,
    "",
    "Card Text:",
    description,
    "",
    "Backend Data:",
    payload,
  }, "\n")
end

function sampleCards(source, count)
  local copy = {}
  for _, card in ipairs(source or {}) do
    table.insert(copy, card)
  end

  local result = {}
  for i = 1, count do
    if #copy == 0 then break end
    local idx = math.random(1, #copy)
    table.insert(result, copy[idx])
    table.remove(copy, idx)
  end
  return result
end

function capitalize(value)
  local text = tostring(value or "")
  if text == "" then return text end
  return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

function updateStatusUi(text)
  state.statusText = text or state.statusText or ""
  if UI then
    if uiState.deckbuilderVisible then
      UI.setAttribute("statusText", "text", state.statusText)
    end
  end
end

function updateRoundTrackerUi()
  if uiRefs.roundLabelButtonIndex ~= nil then
    self.editButton({
      index = uiRefs.roundLabelButtonIndex,
      label = "R:" .. tostring(state.roundValue or 1),
    })
  end
end
