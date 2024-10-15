// Custom from the boilerplate from PC; it's recommended on docs to modify this, so ts-nocheck since it comes as JS file for initial boilerplate. https://developer.playcanvas.com/user-manual/publishing/web/communicating-webpage/
import * as pc from 'playcanvas'

// Shared Lib
export var CANVAS_ID = 'application-canvas';

// Needed as we will have edge cases for particular versions of iOS
// returns null if not iOS
var getIosVersion = function () {
  if (/iP(hone|od|ad)/.test(navigator.platform)) {
    var v = navigator.appVersion.match(/OS (\d+)_(\d+)_?(\d+)?/);
    var version = [
      parseInt(v[1], 10),
      parseInt(v[2], 10),
      parseInt(v[3] || 0, 10),
    ];
    return version;
  }

  return null;
};

var lastWindowHeight = window.innerHeight;
var lastWindowWidth = window.innerWidth;
var windowSizeChangeIntervalHandler = null;

var pcBootstrap = {
  reflowHandler: null,
  iosVersion: getIosVersion(),

  createCanvas: function () {
    var canvas = document.createElement('canvas');
    canvas.setAttribute('id', CANVAS_ID);
    canvas.setAttribute('tabindex', 0);

    // Disable I-bar cursor on click+drag
    canvas.onselectstart = function () {
      return false;
    };

    // Disable long-touch select on iOS devices
    canvas.style['-webkit-user-select'] = 'none';
    canvas.className = "transition-opacity duration-1000 opacity-0"
    // document.body.appendChild(canvas);
    document.getElementById('direct-container').appendChild(canvas);

    setTimeout(() => {
      canvas.classList.add('opacity-100');  // This will smoothly transition to visible
      canvas.classList.remove('opacity-0');  // This will smoothly transition to visible
    }, 50);  // A slight delay to ensure the DOM is updated before applying the transition

    return canvas;
  },

  resizeCanvas: function (app, canvas) {
    // change to __start__ script here
    var fillMode = app._fillMode;

    canvas.style.width = '';
    canvas.style.height = '';
    if (fillMode === pc.FILLMODE_NONE) {
      // our change for build mode (see below too)
      const canvasContainer = document.getElementById('build-container')
      app.resizeCanvas(canvasContainer.offsetWidth, canvasContainer.offsetHeight);
    } else {
      // non-custom behavior
      app.resizeCanvas(canvas.width, canvas.height);
    }


    if (fillMode === pc.FILLMODE_NONE || fillMode === pc.FILLMODE_KEEP_ASPECT) {
      if (
        (fillMode === pc.FILLMODE_NONE &&
          canvas.clientHeight < window.innerHeight) ||
        canvas.clientWidth / canvas.clientHeight >=
        window.innerWidth / window.innerHeight
      ) {
        // old line here for posterity
        // canvas.style.marginTop = Math.floor((window.innerHeight - canvas.clientHeight) / 2) + 'px';
        const canvasContainer = document.getElementById('build-container')
        canvas.style.marginTop = canvasContainer.offsetTop + 'px'
        canvas.style.marginLeft = canvasContainer.offsetLeft + 'px'

      } else {
        canvas.style.marginTop = '';
      }
    }

    lastWindowHeight = window.innerHeight;
    lastWindowWidth = window.innerWidth;

    // Work around when in landscape to work on iOS 12 otherwise
    // the content is under the URL bar at the top
    if (this.iosVersion && this.iosVersion[0] <= 12) {
      window.scrollTo(0, 0);
    }
  },

  reflow: function (app, canvas) {
    this.resizeCanvas(app, canvas);

    // Poll for size changes as the window inner height can change after the resize event for iOS
    // Have one tab only, and rotate from portrait -> landscape -> portrait
    if (windowSizeChangeIntervalHandler === null) {
      windowSizeChangeIntervalHandler = setInterval(
        function () {
          if (
            lastWindowHeight !== window.innerHeight ||
            lastWindowWidth !== window.innerWidth
          ) {
            this.resizeCanvas(app, canvas);
          }
        }.bind(this),
        100
      );

      // Don't want to do this all the time so stop polling after some short time
      setTimeout(function () {
        if (!!windowSizeChangeIntervalHandler) {
          clearInterval(windowSizeChangeIntervalHandler);
          windowSizeChangeIntervalHandler = null;
        }
      }, 2000);
    }
  },
};

// Expose the reflow to users so that they can override the existing
// reflow logic if need be
window.pcBootstrap = pcBootstrap;
// })();

// (function () {
// template varants
var LTC_MAT_1 = [];
var LTC_MAT_2 = [];

// varants
var app;
var canvas;

function initCSS() {
  if (document.head.querySelector) {
    // css media query for aspect ratio changes
    // TODO: Change these from private properties
    var css = `@media screen and (min-aspect-ratio: ${app._width}/${app._height}) {
                #application-canvas.fill-mode-KEEP_ASPECT {
                    width: auto;
                    height: 100%;
                    margin: 0 auto;
                }
            }`;
    document.getElementById('import-style').innerHTML += css;  // Replace with getElementById for 'import-style'

  }

  // Configure resolution and resize event
  if (canvas.classList) {
    canvas.classList.add(`fill-mode-${app.fillMode}`);
  }
}

function displayError(html) {
  var div = document.createElement('div');
  div.innerHTML = `<table style="background-color: #8CE; width: 100%; height: 100%;">
        <tr>
            <td align="center">
                <div style="display: table-cell; vertical-align: middle;">
                    <div style="">${html}</div>
                </div>
            </td>
        </tr>
    </table>`;
  document.body.appendChild(div);
}

function createGraphicsDevice(callback) {
  var deviceOptions = window.CONTEXT_OPTIONS ? window.CONTEXT_OPTIONS : {};

  if (typeof window.Promise === 'function') {
    var LEGACY_WEBGL = 'webgl';
    var deviceTypes =
      deviceOptions.preferWebGl2 === false
        ? [pc.DEVICETYPE_WEBGL2] // DEVICETYPE_WEBGL1 was removed in engine 2.0
        : deviceOptions.deviceTypes;
    if (!deviceTypes) {
      deviceTypes = []
    }
    deviceTypes.push(LEGACY_WEBGL);

    var gpuLibPath = window.ASSET_PREFIX
      ? window.ASSET_PREFIX.replace(/\/$/g, '') + '/'
      : '';

    // new graphics device creation function with promises
    var gfxOptions = {
      deviceTypes: deviceTypes,
      glslangUrl: gpuLibPath + 'glslang.js',
      twgslUrl: gpuLibPath + 'twgsl.js',
      powerPreference: deviceOptions.powerPreference,
      antialias: deviceOptions.antialias !== false,
      alpha: deviceOptions.alpha === true,
      preserveDrawingBuffer: !!deviceOptions.preserveDrawingBuffer,
    };

    pc.createGraphicsDevice(canvas, gfxOptions)
      .then((device) => {
        callback(device);
      })
      .catch((e) => {
        console.error('Device creation error:', e);
        callback(null);
      });
  } else {
    var igl1 = deviceOptions.deviceTypes.indexOf('webgl1');
    var igl2 = deviceOptions.deviceTypes.indexOf('webgl2');

    // old webgl graphics device creation
    var options = {
      powerPreference: deviceOptions.powerPreference,
      antialias: deviceOptions.antialias !== false,
      alpha: deviceOptions.transparentCanvas !== false,
      preserveDrawingBuffer: !!deviceOptions.preserveDrawingBuffer,
      preferWebGl2: igl2 > igl1,
    };

    if (pc.platform.browser && !!navigator.xr) {
      options.xrCompatible = true;
    }

    callback(new pc.WebglGraphicsDevice(canvas, options));
  }
}

function initApp(device, inputSettings = {
  useKeyboard: true,
  useMouse: true,
  useGamepads: false,
  useTouch: true
}) {
  try {
    var createOptions = new pc.AppOptions();
    createOptions.graphicsDevice = device;

    createOptions.componentSystems = [
      pc.RigidBodyComponentSystem,
      pc.CollisionComponentSystem,
      pc.JointComponentSystem,
      pc.AnimationComponentSystem,
      pc.AnimComponentSystem,
      pc.ModelComponentSystem,
      pc.RenderComponentSystem,
      pc.CameraComponentSystem,
      pc.LightComponentSystem,
      pc.ScriptComponentSystem, // ScriptLegacyComponentSystem removed in engine 2.0
      // pc.AudioSourceComponentSystem, // removed in engine 2.0
      pc.SoundComponentSystem,
      pc.AudioListenerComponentSystem,
      pc.ParticleSystemComponentSystem,
      pc.ScreenComponentSystem,
      pc.ElementComponentSystem,
      pc.ButtonComponentSystem,
      pc.ScrollViewComponentSystem,
      pc.ScrollbarComponentSystem,
      pc.SpriteComponentSystem,
      pc.LayoutGroupComponentSystem,
      pc.LayoutChildComponentSystem,
      pc.ZoneComponentSystem,
      pc.GSplatComponentSystem,
    ].filter(Boolean);

    createOptions.resourceHandlers = [
      pc.RenderHandler,
      pc.AnimationHandler,
      pc.AnimClipHandler,
      pc.AnimStateGraphHandler,
      pc.ModelHandler,
      pc.MaterialHandler,
      pc.TextureHandler,
      pc.TextHandler,
      pc.JsonHandler,
      pc.AudioHandler,
      pc.ScriptHandler,
      pc.SceneHandler,
      pc.CubemapHandler,
      pc.HtmlHandler,
      pc.CssHandler,
      pc.ShaderHandler,
      pc.HierarchyHandler,
      pc.FolderHandler,
      pc.FontHandler,
      pc.BinaryHandler,
      pc.TextureAtlasHandler,
      pc.SpriteHandler,
      pc.TemplateHandler,
      pc.ContainerHandler,
      pc.GSplatHandler,
    ].filter(Boolean);

    createOptions.elementInput = new pc.ElementInput(canvas, {
      useMouse: inputSettings.useMouse,
      useTouch: inputSettings.useTouch,
    });
    createOptions.keyboard = inputSettings.useKeyboard
      ? new pc.Keyboard(window)
      : null;
    createOptions.mouse = inputSettings.useMouse ? new pc.Mouse(canvas) : null;
    createOptions.gamepads = inputSettings.useGamepads
      ? new pc.GamePads()
      : null;
    createOptions.touch =
      inputSettings.useTouch && pc.platform.touch
        ? new pc.TouchDevice(canvas)
        : null;
    createOptions.assetPrefix = window.ASSET_PREFIX || '';
    createOptions.scriptPrefix = window.SCRIPT_PREFIX || '';
    createOptions.scriptsOrder = window.SCRIPTS || [];
    createOptions.soundManager = new pc.SoundManager();
    createOptions.lightmapper = pc.Lightmapper;
    createOptions.batchManager = pc.BatchManager;
    createOptions.xr = pc.XrManager;

    app.init(createOptions);

    return true;
  } catch (e) {
    displayError('Could not initialize application. Error: ' + e);
    console.error(e);
    return false;
  }
}

/**
 * This retrieves the 3 properties in config.json: { application_properties, scenes, assets } THEN calls app.scenes.loadScene and app.start()
 */
function configureAndStart() {

  // app.configure(window.CONFIG_FILENAME, (err) => {

  // const props = response.application_properties;
  const props = {
    "i18nAssets": [],
    "useTouch": true,
    "layerOrder": [
      {
        "layer": 0,
        "enabled": true,
        "transparent": false
      },
      {
        "layer": 1,
        "enabled": true,
        "transparent": false
      },
      {
        "layer": 2,
        "enabled": true,
        "transparent": false
      },
      {
        "layer": 0,
        "enabled": true,
        "transparent": true
      },
      {
        "layer": 3,
        "enabled": true,
        "transparent": false
      },
      {
        "layer": 3,
        "enabled": true,
        "transparent": true
      },
      {
        "layer": 4,
        "enabled": true,
        "transparent": true
      }
    ],
    "externalScripts": [],
    "height": 720,
    "vr": false,
    "useModelV2": false,
    "antiAlias": true,
    "layers": {
      "0": {
        "transparentSortMode": 3,
        "opaqueSortMode": 2,
        "name": "World"
      },
      "1": {
        "transparentSortMode": 3,
        "opaqueSortMode": 2,
        "name": "Depth"
      },
      "2": {
        "transparentSortMode": 3,
        "opaqueSortMode": 0,
        "name": "Skybox"
      },
      "3": {
        "transparentSortMode": 3,
        "opaqueSortMode": 0,
        "name": "Immediate"
      },
      "4": {
        "transparentSortMode": 1,
        "opaqueSortMode": 1,
        "name": "UI"
      }
    },
    "width": 1280,
    "useDevicePixelRatio": true,
    "useKeyboard": true,
    "maxAssetRetries": 5,
    "powerPreference": "high-performance",
    "batchGroups": [],
    "preserveDrawingBuffer": false,
    "useLegacyScripts": false,
    "enableSharedArrayBuffer": false,
    "fillMode": "FILL_WINDOW",
    "scripts": [],
    "useMouse": true,
    "use3dPhysics": false,
    "transparentCanvas": false,
    "resolutionMode": "AUTO",
    "loadingScreenScript": null,
    "preferWebGl2": true,
    "useGamepads": false,
    "deviceTypes": [
      "webgl2",
      "webgl1"
    ],
    "libraries": []
  }
  // const scenes = response.scenes;
  const scenes = [
    {
      "name": "Untitled",
      "url": "2090341.json"
    }
  ]
  // const assets = response.assets;
  const assets = {
    "199423271": {
      "name": "sky",
      "type": "cubemap",
      "file": {
        "filename": "sky.png",
        "size": 147883,
        "hash": "9a07d61f34e67a5e96fb6e579ce5c813",
        "url": "files/assets/199423271/1/sky.png"
      },
      "data": {
        "name": "New Cubemap",
        "textures": [
          199423276,
          199423275,
          199423274,
          199423272,
          199423273,
          199423277
        ],
        "minFilter": 5,
        "magFilter": 1,
        "anisotropy": 1,
        "rgbm": true
      },
      "preload": true,
      "tags": [],
      "i18n": {},
      "id": "199423271"
    },
    "199423272": {
      "name": "sky_negy.png",
      "type": "texture",
      "file": {
        "filename": "sky_negy.png",
        "hash": "ff5cfefbc0d5d485bf9a0b9a31b25810",
        "size": 152642,
        "variants": {},
        "url": "files/assets/199423272/1/sky_negy.png"
      },
      "data": {
        "addressu": "repeat",
        "addressv": "repeat",
        "minfilter": "linear_mip_linear",
        "magfilter": "linear",
        "anisotropy": 1,
        "rgbm": true,
        "mipmaps": true
      },
      "preload": true,
      "tags": [],
      "i18n": {},
      "id": "199423272"
    },
    "199423273": {
      "name": "sky_posz.png",
      "type": "texture",
      "file": {
        "filename": "sky_posz.png",
        "hash": "53a9aab04b23a2e8f7be2d99115ca09d",
        "size": 198593,
        "variants": {},
        "url": "files/assets/199423273/1/sky_posz.png"
      },
      "data": {
        "addressu": "repeat",
        "addressv": "repeat",
        "minfilter": "linear_mip_linear",
        "magfilter": "linear",
        "anisotropy": 1,
        "rgbm": true,
        "mipmaps": true
      },
      "preload": true,
      "tags": [],
      "i18n": {},
      "id": "199423273"
    },
    "199423274": {
      "name": "sky_posy.png",
      "type": "texture",
      "file": {
        "filename": "sky_posy.png",
        "hash": "f11af8966b2e0fe99e343108d777403d",
        "size": 170046,
        "variants": {},
        "url": "files/assets/199423274/1/sky_posy.png"
      },
      "data": {
        "addressu": "repeat",
        "addressv": "repeat",
        "minfilter": "linear_mip_linear",
        "magfilter": "linear",
        "anisotropy": 1,
        "rgbm": true,
        "mipmaps": true
      },
      "preload": true,
      "tags": [],
      "i18n": {},
      "id": "199423274"
    },
    "199423275": {
      "name": "sky_negx.png",
      "type": "texture",
      "file": {
        "filename": "sky_negx.png",
        "hash": "34f64e48aa3125598094e24eeb02d574",
        "size": 155167,
        "variants": {},
        "url": "files/assets/199423275/1/sky_negx.png"
      },
      "data": {
        "addressu": "repeat",
        "addressv": "repeat",
        "minfilter": "linear_mip_linear",
        "magfilter": "linear",
        "anisotropy": 1,
        "rgbm": true,
        "mipmaps": true
      },
      "preload": true,
      "tags": [],
      "i18n": {},
      "id": "199423275"
    },
    "199423276": {
      "name": "sky_posx.png",
      "type": "texture",
      "file": {
        "filename": "sky_posx.png",
        "hash": "bb45a6c2eed8c3763777eaed6f44527f",
        "size": 172680,
        "variants": {},
        "url": "files/assets/199423276/1/sky_posx.png"
      },
      "data": {
        "addressu": "repeat",
        "addressv": "repeat",
        "minfilter": "linear_mip_linear",
        "magfilter": "linear",
        "anisotropy": 1,
        "rgbm": true,
        "mipmaps": true
      },
      "preload": true,
      "tags": [],
      "i18n": {},
      "id": "199423276"
    },
    "199423277": {
      "name": "sky_negz.png",
      "type": "texture",
      "file": {
        "filename": "sky_negz.png",
        "hash": "2be10e522c5e12bc0b791b48181895b9",
        "size": 147065,
        "variants": {},
        "url": "files/assets/199423277/1/sky_negz.png"
      },
      "data": {
        "addressu": "repeat",
        "addressv": "repeat",
        "minfilter": "linear_mip_linear",
        "magfilter": "linear",
        "anisotropy": 1,
        "rgbm": true,
        "mipmaps": true
      },
      "preload": true,
      "tags": [],
      "i18n": {},
      "id": "199423277"
    }
  }

  // this inits a ton of (good?) settings from application_properties; keep this for now
  app._parseApplicationProperties(props, (err) => {
    // app._parseScenes(scenes);
    // app._parseAssets(assets);
    if (err) {
      throw new Error(err)
    }

    if (err) {
      console.error(err);
      return;
    }

    initCSS(canvas, app._fillMode, app._width, app._height);

    if (
      LTC_MAT_1.length &&
      LTC_MAT_2.length &&
      app.setAreaLightLuts.length === 2
    ) {
      app.setAreaLightLuts(LTC_MAT_1, LTC_MAT_2);
    }

    // do the first reflow after a timeout because of
    // iOS showing a squished iframe sometimes
    setTimeout(() => {
      pcBootstrap.reflow(app, canvas);
      pcBootstrap.reflowHandler = function () {
        pcBootstrap.reflow(app, canvas);
      };

      window.addEventListener('resize', pcBootstrap.reflowHandler, false);
      window.addEventListener(
        'orientationchange',
        pcBootstrap.reflowHandler,
        false
      );

      // TODO add preloading after setting up assets
      // app.preload(() => {
      // TODO add in first scene loading
      // app.scenes.loadScene(window.SCENE_PATH, (err) => {
      // if (err) {
      //   console.error(err);
      //   return;
      // }

      app.start();

      if (window.location.href.includes("build")) {
        setFillMode(pc.FILLMODE_NONE)
      } else if (window.location.href.includes("play")) {
        setFillMode(pc.FILLMODE_FILL_WINDOW)
      }

      // });
      // });
    });
  });
}

function initEngine() {
  if (typeof window === 'undefined') {
    console.warn('initEngine called on the server side; returning');
    return; // Prevent the engine from initializing on the server side
  }

  // NOTE: I moved this out of the initial execution of the file to avoid a race condition. There may be a way to speed up loading though to bootstrap most things on page load. The issue was that the document.getElementById to append the canvas was failing because the viewport wasn't loaded yet.
  canvas = pcBootstrap.createCanvas();
  app = new pc.AppBase(canvas);

  createGraphicsDevice((device) => {
    if (!device) {
      return;
    }

    if (!initApp(device)) {
      return;
    }

    if (window && window.PRELOAD_MODULES && window.PRELOAD_MODULES.length) {
      loadModules(window.PRELOAD_MODULES, window.ASSET_PREFIX, () => {
        configureAndStart(() => {
          console.timeEnd('start');
        });
      });
    } else {
      configureAndStart();
    }
  });
  console.log('Completed initEngine()')
  return app
}



// update code called every frame
function setFillMode(mode) {
  const canvas = app.graphicsDevice.canvas;
  // if (this.app.keyboard.wasPressed(pc.KEY_1)) {
  if (mode === pc.FILLMODE_FILL_WINDOW) {
    updateCanvas(pc.FILLMODE_FILL_WINDOW);
  }

  // if (this.app.keyboard.wasPressed(pc.KEY_2)) {
  // Set the aspect ratio 
  if (mode === pc.FILLMODE_KEEP_ASPECT) {
    canvas.width = 1280;
    canvas.height = 720;
    updateCanvas(pc.FILLMODE_KEEP_ASPECT);
  }

  if (mode === pc.FILLMODE_NONE) {
    canvas.width = 1000;
    canvas.height = 500;
    updateCanvas(pc.FILLMODE_NONE);
  }
};


function updateCanvas(fillMode) {
  const previousFillMode = app.fillMode;

  app.setCanvasFillMode(fillMode);
  const canvas = app.graphicsDevice.canvas;

  // Update the CSS style on the canvas 
  if (canvas.classList) {
    canvas.classList.remove('fill-mode-' + previousFillMode);
    canvas.classList.add('fill-mode-' + fillMode);
  }

  // Invoke a resize from the boilerplate to move the canvas
  // into the right place
  pcBootstrap.resizeCanvas(app, canvas);

  // Have to correct the CSS due to bug in the pcBootstrap
  if (fillMode === pc.FILLMODE_FILL_WINDOW) {
    canvas.style.marginTop = '';
  }
};

export default initEngine
