'use client'
import React, { useState, useEffect, useRef } from 'react'
import {
  Container,
  Element as PCUIElement,
  Label as PCUILabel,
  BooleanInput
} from '@playcanvas/pcui'
import { Events } from '../events'
import { MenuPanel } from './menu-panel'
import { localize } from './localization'

import logoSvg from '../svg/playcanvas-logo.svg'
import collapseSvg from '../svg/collapse.svg'
import arrowSvg from '../svg/arrow.svg'
import sceneNew from '../svg/new.svg'
import sceneOpen from '../svg/open.svg'
import sceneSave from '../svg/save.svg'
import sceneExport from '../svg/export.svg'
import sceneImport from '../svg/import.svg'
import selectAll from '../svg/select-all.svg'
import selectNone from '../svg/select-none.svg'
import selectInverse from '../svg/select-inverse.svg'
import selectLock from '../svg/select-lock.svg'
import selectUnlock from '../svg/select-unlock.svg'
import selectDelete from '../svg/delete.svg'

const createSvg = (svgString: any) => {
  return new PCUIElement({
    dom: new DOMParser().parseFromString(svgString, 'image/svg+xml')
      .documentElement
  })
}

const Menu = ({ events }: { events: any }) => {
  const [allDataToggle, setAllDataToggle] = useState(true)
  const [menuPanels, setMenuPanels] = useState({
    sceneMenuPanel: null,
    exportMenuPanel: null,
    selectionMenuPanel: null,
    helpMenuPanel: null
  })
  const menubarRef = useRef(null)

  useEffect(() => {
    const menubar = new Container({
      id: 'menu-bar'
    })

    menubar.dom.addEventListener('pointerdown', (event) => {
      event.stopPropagation()
    })

    const iconDom = document.createElement('img')
    iconDom.src = logoSvg
    iconDom.setAttribute('id', 'app-icon')
    iconDom.addEventListener('pointerdown', (event) => {
      window.open('https://playcanvas.com', '_blank').focus()
    })

    const icon = new PCUIElement({
      dom: iconDom
    })

    const scene = new PCUILabel({
      text: localize('scene'),
      class: 'menu-option'
    })

    const selection = new PCUILabel({
      text: localize('selection'),
      class: 'menu-option'
    })

    const help = new PCUILabel({
      text: localize('help'),
      class: 'menu-option'
    })

    const toggleCollapsed = () => {
      document.body.classList.toggle('collapsed')
    }

    if (document.body.clientWidth < 600) {
      toggleCollapsed()
    }

    const collapse = createSvg(collapseSvg)
    collapse.dom.classList.add('menu-icon')
    collapse.dom.setAttribute('id', 'menu-collapse')
    collapse.dom.addEventListener('click', toggleCollapsed)

    const arrow = createSvg(arrowSvg)
    arrow.dom.classList.add('menu-icon')
    arrow.dom.setAttribute('id', 'menu-arrow')
    arrow.dom.addEventListener('click', toggleCollapsed)

    const buttonsContainer = new Container({
      id: 'menu-options-container'
    })
    buttonsContainer.append(scene)
    buttonsContainer.append(selection)
    buttonsContainer.append(help)
    buttonsContainer.append(collapse)
    buttonsContainer.append(arrow)

    menubar.append(icon)
    menubar.append(buttonsContainer)

    const exportMenuPanel = new MenuPanel([
      {
        text: localize('scene.export.compressed-ply'),
        icon: createSvg(sceneExport),
        onSelect: () => events.invoke('scene.export', 'compressed-ply'),
        isEnabled: () => !events.invoke('scene.empty')
      },
      {
        text: localize('scene.export.splat'),
        icon: createSvg(sceneExport),
        onSelect: () => events.invoke('scene.export', 'splat'),
        isEnabled: () => !events.invoke('scene.empty')
      }
    ])

    const sceneMenuPanel = new MenuPanel([
      {
        text: localize('scene.new'),
        icon: createSvg(sceneNew),
        onSelect: () => events.invoke('scene.new')
      },
      {
        text: localize('scene.open'),
        icon: createSvg(sceneOpen),
        onSelect: async () => {
          if (await events.invoke('scene.new')) {
            events.fire('scene.open')
          }
        }
      },
      {
        text: localize('scene.import'),
        icon: createSvg(sceneImport),
        onSelect: () => events.fire('scene.open')
      },
      {
        text: localize('scene.load-all-data'),
        extra: new BooleanInput({ value: allDataToggle }),
        onSelect: () => {
          events.fire('toggleAllData')
          setAllDataToggle(!allDataToggle)
          sceneMenuPanel.hidden = false
        }
      },
      {
        text: localize('scene.save'),
        icon: createSvg(sceneSave),
        onSelect: () => events.fire('scene.save'),
        isEnabled: () => !events.invoke('scene.empty')
      },
      {
        text: localize('scene.save-as'),
        icon: createSvg(sceneSave),
        onSelect: () => events.fire('scene.saveAs'),
        isEnabled: () => !events.invoke('scene.empty')
      },
      {
        text: localize('scene.export'),
        icon: createSvg(sceneExport),
        subMenu: exportMenuPanel
      }
    ])

    const selectionMenuPanel = new MenuPanel([
      {
        text: localize('selection.all'),
        icon: createSvg(selectAll),
        extra: 'A',
        onSelect: () => events.fire('select.all')
      },
      {
        text: localize('selection.none'),
        icon: createSvg(selectNone),
        extra: 'Shift + A',
        onSelect: () => events.fire('select.none')
      },
      {
        text: localize('selection.invert'),
        icon: createSvg(selectInverse),
        extra: 'I',
        onSelect: () => events.fire('select.invert')
      },
      {
        text: localize('selection.lock'),
        icon: createSvg(selectLock),
        extra: 'H',
        onSelect: () => events.fire('select.hide')
      },
      {
        text: localize('selection.unlock'),
        icon: createSvg(selectUnlock),
        extra: 'U',
        onSelect: () => events.fire('select.unhide')
      },
      {
        text: localize('selection.delete'),
        icon: createSvg(selectDelete),
        extra: 'Delete',
        onSelect: () => events.fire('select.delete')
      },
      {
        text: localize('selection.reset'),
        onSelect: () => events.fire('scene.reset')
      }
    ])

    const helpMenuPanel = new MenuPanel([
      {
        text: localize('help.shortcuts'),
        icon: 'E136',
        onSelect: () => events.fire('show.shortcuts')
      },
      {
        text: localize('help.user-guide'),
        icon: 'E232',
        onSelect: () =>
          window
            .open(
              'https://github.com/playcanvas/supersplat/blob/main/docs/index.md#supersplat-user-guide',
              '_blank'
            )
            .focus()
      },
      {
        text: localize('help.log-issue'),
        icon: 'E336',
        onSelect: () =>
          window
            .open('https://github.com/playcanvas/supersplat/issues', '_blank')
            .focus()
      },
      {
        text: localize('help.github-repo'),
        icon: 'E259',
        onSelect: () =>
          window
            .open('https://github.com/playcanvas/supersplat', '_blank')
            .focus()
      },
      {
        text: localize('help.discord'),
        icon: 'E233',
        onSelect: () =>
          window.open('https://discord.gg/T3pnhRTTAY', '_blank').focus()
      },
      {
        text: localize('help.forum'),
        icon: 'E432',
        onSelect: () =>
          window.open('https://forum.playcanvas.com', '_blank').focus()
      },
      {
        text: localize('help.about'),
        icon: 'E138',
        onSelect: () => events.invoke('show.about')
      }
    ])

    setMenuPanels({
      sceneMenuPanel,
      exportMenuPanel,
      selectionMenuPanel,
      helpMenuPanel
    })

    menubarRef.current.appendChild(menubar.dom)
  }, [events, allDataToggle])

  useEffect(() => {
    const options = [
      {
        dom: menuPanels.sceneMenuPanel?.dom,
        menuPanel: menuPanels.sceneMenuPanel
      },
      {
        dom: menuPanels.selectionMenuPanel?.dom,
        menuPanel: menuPanels.selectionMenuPanel
      },
      {
        dom: menuPanels.helpMenuPanel?.dom,
        menuPanel: menuPanels.helpMenuPanel
      }
    ]

    const activate = (option) => {
      option.menuPanel.position(option.dom, 'bottom', 2)
      options.forEach((opt) => (opt.menuPanel.hidden = opt !== option))
    }

    options.forEach((option) => {
      option.dom?.addEventListener('pointerdown', (event) => {
        if (!option.menuPanel.hidden) {
          option.menuPanel.hidden = true
        } else {
          activate(option)
        }
      })

      option.dom?.addEventListener('pointerenter', (event) => {
        if (!options.every((opt) => opt.menuPanel.hidden)) {
          activate(option)
        }
      })
    })

    const checkEvent = (event) => {
      if (!menubarRef.current.contains(event.target)) {
        options.forEach((opt) => (opt.menuPanel.hidden = true))
      }
    }

    window.addEventListener('pointerdown', checkEvent, true)
    window.addEventListener('pointerup', checkEvent, true)

    return () => {
      window.removeEventListener('pointerdown', checkEvent, true)
      window.removeEventListener('pointerup', checkEvent, true)
    }
  }, [menuPanels])

  return <div ref={menubarRef}></div>
}

export { Menu }
