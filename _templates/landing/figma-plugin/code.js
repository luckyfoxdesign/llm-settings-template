// Plugin sandbox code. No network, no disk access, no bundler — plain JS only.
// UI (ui.html) reads/writes files via the browser iframe and talks to this
// file through postMessage; this file only talks to the Figma document.

figma.showUI(__html__, { width: 420, height: 560 });

var PALETTE_COLLECTION_NAME = "Tailwind Palette";
var SEMANTIC_COLLECTION_NAME = "Semantic";
var PALETTE_INDEX_STORAGE_KEY = "luckyfox.paletteValueIndex.v1";

function normalizeHex(value) {
  return String(value).trim().toLowerCase();
}

function hexToRgb(hex) {
  var clean = normalizeHex(hex).replace("#", "");
  return {
    r: parseInt(clean.substring(0, 2), 16) / 255,
    g: parseInt(clean.substring(2, 4), 16) / 255,
    b: parseInt(clean.substring(4, 6), 16) / 255,
  };
}

function channelToHex(channel) {
  var value = Math.round(Math.max(0, Math.min(1, channel)) * 255);
  var hex = value.toString(16);
  return hex.length === 1 ? "0" + hex : hex;
}

function rgbToHex(rgb) {
  return "#" + channelToHex(rgb.r) + channelToHex(rgb.g) + channelToHex(rgb.b);
}

// Walks a DTCG colour subtree. Handles both shapes present in tokens/:
// flat ({ "black": { "$value": ... } }) and nested ({ "orange": { "50": { "$value": ... } } }).
function flattenColorTokens(node, path, out) {
  if (node && typeof node === "object" && Object.prototype.hasOwnProperty.call(node, "$value")) {
    out.push({ path: path.slice(), value: node.$value });
    return;
  }
  if (node && typeof node === "object") {
    for (var key in node) {
      if (!Object.prototype.hasOwnProperty.call(node, key) || key.charAt(0) === "$") continue;
      path.push(key);
      flattenColorTokens(node[key], path, out);
      path.pop();
    }
  }
}

async function findCollection(name) {
  var collections = await figma.variables.getLocalVariableCollectionsAsync();
  for (var i = 0; i < collections.length; i++) {
    if (collections[i].name === name) return collections[i];
  }
  return null;
}

async function findOrCreateCollection(name) {
  var existing = await findCollection(name);
  if (existing) return existing;
  return figma.variables.createVariableCollection(name);
}

async function getVariablesInCollection(collectionId) {
  var all = await figma.variables.getLocalVariablesAsync("COLOR");
  return all.filter(function (v) {
    return v.variableCollectionId === collectionId;
  });
}

// --- Import: Tailwind palette ------------------------------------------------
// Every palette token becomes its own variable, even when two tokens share a
// value (e.g. zinc-50 / neutral-50) — duplicates are reported, not skipped.
// The value -> variable-name index (first match in file order wins) is cached
// in clientStorage so a later, separate "Import semantic tokens" run can
// resolve aliases deterministically without re-selecting this file.
async function importPalette(json) {
  var collection = await findOrCreateCollection(PALETTE_COLLECTION_NAME);
  var modeId = collection.modes[0].modeId;

  var tokens = [];
  flattenColorTokens(json.color, [], tokens);

  var existingVars = await getVariablesInCollection(collection.id);
  var existingByName = {};
  existingVars.forEach(function (v) {
    existingByName[v.name] = v;
  });

  var seenNames = {};
  var valueIndex = {}; // hex -> variable name, first match in file order wins
  var report = { created: [], updated: [], stale: [], ambiguous: [] };

  for (var i = 0; i < tokens.length; i++) {
    var token = tokens[i];
    var name = "tailwind/" + token.path.join("/");
    var hex = normalizeHex(token.value);
    seenNames[name] = true;

    var variable = existingByName[name];
    var bucket = variable ? report.updated : report.created;
    if (!variable) {
      variable = figma.variables.createVariable(name, collection, "COLOR");
      existingByName[name] = variable;
    }
    variable.setValueForMode(modeId, hexToRgb(hex));
    bucket.push(name);

    if (Object.prototype.hasOwnProperty.call(valueIndex, hex)) {
      report.ambiguous.push({ value: hex, name: name, resolvesTo: valueIndex[hex] });
    } else {
      valueIndex[hex] = name;
    }
  }

  for (var existingName in existingByName) {
    if (Object.prototype.hasOwnProperty.call(existingByName, existingName) && !seenNames[existingName]) {
      report.stale.push(existingName);
    }
  }

  await figma.clientStorage.setAsync(PALETTE_INDEX_STORAGE_KEY, valueIndex);
  return report;
}

// --- Import: semantic layer ---------------------------------------------------
// Aliases a semantic token onto the palette variable of the same value
// (resolved via the cached value index from the last palette import); falls
// back to a literal, reported, when there is no exact match.
async function importSemantic(json) {
  var paletteIndex = (await figma.clientStorage.getAsync(PALETTE_INDEX_STORAGE_KEY)) || {};
  var paletteCollection = await findCollection(PALETTE_COLLECTION_NAME);
  var paletteVarsByName = {};
  if (paletteCollection) {
    (await getVariablesInCollection(paletteCollection.id)).forEach(function (v) {
      paletteVarsByName[v.name] = v;
    });
  }

  var collection = await findOrCreateCollection(SEMANTIC_COLLECTION_NAME);
  var modeId = collection.modes[0].modeId;

  var tokens = [];
  flattenColorTokens(json.color, [], tokens);

  var existingVars = await getVariablesInCollection(collection.id);
  var existingByName = {};
  existingVars.forEach(function (v) {
    existingByName[v.name] = v;
  });

  var seenNames = {};
  var report = { created: [], updated: [], stale: [], aliased: [], literal: [] };

  for (var i = 0; i < tokens.length; i++) {
    var token = tokens[i];
    var name = "semantic/" + token.path.join("/");
    var hex = normalizeHex(token.value);
    seenNames[name] = true;

    var variable = existingByName[name];
    var bucket = variable ? report.updated : report.created;
    if (!variable) {
      variable = figma.variables.createVariable(name, collection, "COLOR");
      existingByName[name] = variable;
    }

    var targetName = paletteIndex[hex];
    var targetVariable = targetName ? paletteVarsByName[targetName] : null;
    if (targetVariable) {
      variable.setValueForMode(modeId, { type: "VARIABLE_ALIAS", id: targetVariable.id });
      report.aliased.push({ name: name, target: targetName });
    } else {
      variable.setValueForMode(modeId, hexToRgb(hex));
      report.literal.push({ name: name, value: hex });
    }
    bucket.push(name);
  }

  for (var existingName in existingByName) {
    if (Object.prototype.hasOwnProperty.call(existingByName, existingName) && !seenNames[existingName]) {
      report.stale.push(existingName);
    }
  }

  return report;
}

// --- Export: variables actually bound to layers on the current page ----------
async function resolveAliasChain(variableId, resolved) {
  if (Object.prototype.hasOwnProperty.call(resolved, variableId)) return;
  var variable = await figma.variables.getVariableByIdAsync(variableId);
  if (!variable) return;
  var collection = await figma.variables.getVariableCollectionByIdAsync(variable.variableCollectionId);
  if (!collection) return;
  var modeId = collection.modes[0].modeId;
  var value = variable.valuesByMode[modeId];

  var isAlias = value && value.type === "VARIABLE_ALIAS";
  var resolvedHex = null;
  if (isAlias) {
    await resolveAliasChain(value.id, resolved);
    var target = resolved[value.id];
    resolvedHex = target ? target.value : null;
  } else if (value && typeof value.r === "number") {
    resolvedHex = rgbToHex(value);
  }

  resolved[variableId] = {
    name: variable.name,
    collection: collection.name,
    value: resolvedHex,
    aliasOf: isAlias ? (resolved[value.id] ? resolved[value.id].name : null) : null,
  };
}

function collectBoundPaintIds(paints, boundIds, unbound, node, kind) {
  if (paints === figma.mixed || !Array.isArray(paints)) return;
  paints.forEach(function (paint, index) {
    if (paint.type !== "SOLID" || paint.visible === false) return;
    var bound = paint.boundVariables && paint.boundVariables.color;
    if (bound && bound.type === "VARIABLE_ALIAS") {
      boundIds[bound.id] = true;
    } else {
      unbound.push({ nodeId: node.id, nodeName: node.name, kind: kind, index: index });
    }
  });
}

async function exportUsed() {
  // The current page is always fully loaded (unlike other pages under
  // "dynamic-page" access), so the sync findAll is safe here; findAllAsync
  // does not exist on PageNode. loadAsync() is a no-op safety net.
  await figma.currentPage.loadAsync();
  var nodes = figma.currentPage.findAll(function () {
    return true;
  });

  var boundIds = {};
  var unbound = [];

  nodes.forEach(function (node) {
    if ("fills" in node) collectBoundPaintIds(node.fills, boundIds, unbound, node, "fill");
    if ("strokes" in node) collectBoundPaintIds(node.strokes, boundIds, unbound, node, "stroke");
  });

  var resolved = {};
  var ids = Object.keys(boundIds);
  for (var i = 0; i < ids.length; i++) {
    await resolveAliasChain(ids[i], resolved);
  }

  var variables = Object.keys(resolved).map(function (id) {
    return resolved[id];
  });

  return {
    document: {
      $description:
        "Переменные, реально привязанные (boundVariables) к слоям страницы \"" +
        figma.currentPage.name +
        "\" на момент выгрузки.",
      $extensions: {
        "design.luckyfox.tokens": {
          exportedAt: new Date().toISOString(),
          page: figma.currentPage.name,
          count: variables.length,
        },
      },
      variables: variables,
    },
    unbound: unbound,
  };
}

figma.ui.onmessage = async function (msg) {
  try {
    if (msg.type === "import-palette") {
      var paletteReport = await importPalette(JSON.parse(msg.json));
      figma.ui.postMessage({ type: "import-report", collection: "palette", report: paletteReport });
    } else if (msg.type === "import-semantic") {
      var semanticReport = await importSemantic(JSON.parse(msg.json));
      figma.ui.postMessage({ type: "import-report", collection: "semantic", report: semanticReport });
    } else if (msg.type === "export-used") {
      var result = await exportUsed();
      figma.ui.postMessage({
        type: "export-result",
        fileName: "colors.used.json",
        content: JSON.stringify(result.document, null, 2),
        unbound: result.unbound,
      });
    }
  } catch (err) {
    console.error(err);
    var detail = (err && (err.stack || err.message)) || String(err);
    figma.ui.postMessage({ type: "error", message: detail });
  }
};
