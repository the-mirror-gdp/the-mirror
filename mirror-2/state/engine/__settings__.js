// Boilerplate from PC; it's recommended on docs to modify this, so ts-nocheck since it comes as JS file for initial boilerplate. https://developer.playcanvas.com/user-manual/publishing/web/communicating-webpage/ 
import * as pc from 'playcanvas'

function initSettings() {
  window.ASSET_PREFIX = "";
  window.SCRIPT_PREFIX = "";
  window.SCENE_PATH = "2090304.json";
  window.CONTEXT_OPTIONS = {
    'antialias': true,
    'alpha': false,
    'preserveDrawingBuffer': false,
    'deviceTypes': [`webgl2`, `webgl1`],
    'powerPreference': "default"
  };
  window.SCRIPTS = [199420343, 199420345, 199420348, 199420342, 199420369];
  window.CONFIG_FILENAME = "config.json";
  window.INPUT_SETTINGS = {
    useKeyboard: true,
    useMouse: true,
    useGamepads: false,
    useTouch: true
  };
  pc.script.legacy = false;
  window.PRELOAD_MODULES = [
    // { 'moduleName': 'Ammo', 'glueUrl': 'files/assets/199420353/1/ammo.wasm.js', 'wasmUrl': 'files/assets/199420550/1/ammo.wasm.wasm', 'fallbackUrl': 'files/assets/199420349/1/ammo.js', 'preload': true },
  ];
}

export default initSettings
