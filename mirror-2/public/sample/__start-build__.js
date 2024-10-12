// Boilerplate from PC; it's recommended on docs to modify this, so ts-nocheck since it comes as JS file for initial boilerplate. https://developer.playcanvas.com/user-manual/publishing/web/communicating-webpage/
// import * as pc from 'playcanvas'
// import initSettings from './__settings__'
// import loadModules from './__modules__'

// initSettings()

// (function () {
// Shared Lib
// export var CANVAS_ID = 'application-canvas';
var CANVAS_ID = 'application-canvas';

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
    canvas.className = "transition-all duration-1000 opacity-0"
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
var canvas = pcBootstrap.createCanvas();
// export var app = new pc.AppBase(canvas);
var app = new pc.AppBase(canvas);

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
        ? [pc.DEVICETYPE_WEBGL1, pc.DEVICETYPE_WEBGL2]
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

function initApp(device) {
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
      pc.script.legacy
        ? pc.ScriptLegacyComponentSystem
        : pc.ScriptComponentSystem,
      pc.AudioSourceComponentSystem,
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

    if (window.INPUT_SETTINGS === undefined) {
      debugger
    }
    createOptions.elementInput = new pc.ElementInput(canvas, {
      useMouse: window.INPUT_SETTINGS.useMouse,
      useTouch: window.INPUT_SETTINGS.useTouch,
    });
    createOptions.keyboard = window.INPUT_SETTINGS.useKeyboard
      ? new pc.Keyboard(window)
      : null;
    createOptions.mouse = window.INPUT_SETTINGS.useMouse ? new pc.Mouse(canvas) : null;
    createOptions.gamepads = window.INPUT_SETTINGS.useGamepads
      ? new pc.GamePads()
      : null;
    createOptions.touch =
      window.INPUT_SETTINGS.useTouch && pc.platform.touch
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

function configure() {
  app.configure(window.CONFIG_FILENAME, (err) => {
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

      app.preload(() => {
        app.scenes.loadScene(window.SCENE_PATH, (err) => {
          if (err) {
            console.error(err);
            return;
          }

          app.start();

          if (window.location.href.includes("build")) {
            setFillMode(pc.FILLMODE_NONE)
          } else if (window.location.href.includes("play")) {
            setFillMode(pc.FILLMODE_FILL_WINDOW)
          }

        });
      });
    });
  });
}

function mainInit() {
  createGraphicsDevice((device) => {
    if (!device) {
      return;
    }

    if (!initApp(device)) {
      return;
    }

    if (window.PRELOAD_MODULES.length) {
      loadModules(window.PRELOAD_MODULES, window.ASSET_PREFIX, () => {
        configure(() => {
          console.timeEnd('start');
        });
      });
    } else {
      configure();
    }
  });
  console.log('Completed engine mainInit()')
  return app
}
mainInit();
// })(); // Add scope to avoid polluting window scope



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
