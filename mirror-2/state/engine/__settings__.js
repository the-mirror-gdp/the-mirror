// Boilerplate from PC; it's recommended on docs to modify this, so ts-nocheck since it comes as JS file for initial boilerplate. https://developer.playcanvas.com/user-manual/publishing/web/communicating-webpage/ 
import * as pc from 'playcanvas'

function initSettings() {
  window.ASSET_PREFIX = "";
  window.SCRIPT_PREFIX = "";
  window.SCENE_PATH = "2090341.json";
  window.CONTEXT_OPTIONS = {
    'antialias': true,
    'alpha': false,
    'preserveDrawingBuffer': false,
    'deviceTypes': [`webgl2`, `webgl1`],
    'powerPreference': "high-performance"
  };
  window.SCRIPTS = [];
  window.CONFIG_FILENAME = "config.json";
  window.INPUT_SETTINGS = {
    useKeyboard: true,
    useMouse: true,
    useGamepads: false,
    useTouch: true
  };
  pc.script.legacy = false;
  window.PRELOAD_MODULES = [
  ];
}

export default initSettings
