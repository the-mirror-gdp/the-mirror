var loadModules = function (modules, urlPrefix, doneCallback) { // eslint-disable-line no-unused-vars

  if (typeof modules === "undefined" || modules.length === 0) {
    // caller may depend on callback behaviour being async
    setTimeout(doneCallback);
  } else {
    let remaining = modules.length;
    const moduleLoaded = () => {
      if (--remaining === 0) {
        doneCallback();
      }
    };

    modules.forEach(function (m) {
      pc.WasmModule.setConfig(m.moduleName, {
        glueUrl: urlPrefix + m.glueUrl,
        wasmUrl: urlPrefix + m.wasmUrl,
        fallbackUrl: urlPrefix + m.fallbackUrl
      });

      if (!m.hasOwnProperty('preload') || m.preload) {
        if (m.moduleName === 'BASIS') {
          // preload basis transcoder
          pc.basisInitialize();
          moduleLoaded();
        } else if (m.moduleName === 'DracoDecoderModule') {
          // preload draco decoder
          if (pc.dracoInitialize) {
            // 1.63 onwards
            pc.dracoInitialize();
            moduleLoaded();
          } else {
            // 1.62 and earlier
            pc.WasmModule.getInstance(m.moduleName, () => { moduleLoaded(); });
          }
        } else {
          // load remaining modules in global scope
          pc.WasmModule.getInstance(m.moduleName, () => { moduleLoaded(); });
        }
      } else {
        moduleLoaded();
      }
    });
  }
};

window.loadModules = loadModules;
