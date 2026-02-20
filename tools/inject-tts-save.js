const fs = require('fs');
const path = require('path');

const repo = 'c:/Users/broki/OneDrive/Desktop/Sea Level/Severance-Tabletop';
const saves = 'C:/Users/broki/OneDrive/Documents/My Games/Tabletop Simulator/Saves';
const saveInfosPath = path.join(saves, 'SaveFileInfos.json');
const defaultSaveName = '[DEV] Severance Playtest';
const requestedName = process.argv[3] || defaultSaveName;

function normalizeMaybeBom(text) {
  return String(text || '').replace(/^\uFEFF/, '');
}

function resolveSavePath() {
  const explicitPath = process.argv[2];

  if (explicitPath && fs.existsSync(explicitPath)) {
    return explicitPath;
  }

  if (fs.existsSync(saveInfosPath)) {
    try {
      const raw = fs.readFileSync(saveInfosPath, 'utf8');
      const infos = JSON.parse(normalizeMaybeBom(raw));
      const matches = (Array.isArray(infos) ? infos : [])
        .filter((entry) => {
          const name = String(entry && entry.Name || '').toLowerCase();
          return name.includes(String(requestedName).toLowerCase());
        })
        .sort((a, b) => Number(b.UpdateTime || 0) - Number(a.UpdateTime || 0));

      if (matches.length > 0) {
        const selected = String(matches[0].Directory || '').replace(/\\/g, '/');
        if (selected && fs.existsSync(selected)) {
          return selected;
        }
      }
    } catch (error) {
      console.warn('warn=failed_to_parse_SaveFileInfos');
    }
  }

  return path.join(saves, 'TS_AutoSave.json');
}

const savePath = resolveSavePath();
const backupPath = savePath.replace(/\.json$/i, '.backup.json');
const skipBackup = process.env.TTS_INJECT_SKIP_BACKUP === '1';

const lua = fs.readFileSync(path.join(repo, 'tts/scripts/Global.lua'), 'utf8');
const xml = fs.readFileSync(path.join(repo, 'tts/scripts/ui.xml'), 'utf8');

const raw = fs.readFileSync(savePath, 'utf8');
const normalized = normalizeMaybeBom(raw);
const data = JSON.parse(normalized);

if (!skipBackup) {
  fs.copyFileSync(savePath, backupPath);
}

data.SaveName = requestedName || defaultSaveName;
if (Object.prototype.hasOwnProperty.call(data, 'GameMode')) {
  data.GameMode = requestedName || defaultSaveName;
}
if (Object.prototype.hasOwnProperty.call(data, 'Note')) {
  data.Note = 'Severance Playtest DEV save with embedded Global.lua + ui.xml.';
}

data.LuaScript = lua;
data.LuaScriptState = '';
data.XmlUI = xml;

fs.writeFileSync(savePath, JSON.stringify(data, null, 2), 'utf8');

const check = JSON.parse(fs.readFileSync(savePath, 'utf8'));
console.log('save_path=' + savePath);
console.log('save_name=' + (check.SaveName || ''));
console.log('lua_len=' + String((check.LuaScript || '').length));
console.log('xml_len=' + String((check.XmlUI || '').length));
if (!skipBackup) {
  console.log('backup=' + backupPath);
}
