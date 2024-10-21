import { Button, Container, Element, Label } from '@playcanvas/pcui'
import { Events } from '../events'
import { Tooltips } from './tooltips'
import { localize } from './localization'

import showHideSplatsSvg from '../svg/show-hide-splats.svg'
import frameSelectionSvg from '../svg/frame-selection.svg'
import centersSvg from '../svg/centers.svg'
import ringsSvg from '../svg/rings.svg'

const createSvg = (): HTMLElement => {
  const svgString = `
    <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
    </svg>
  `
  return new DOMParser().parseFromString(svgString, 'image/svg+xml')
    .documentElement as HTMLElement
}

class RightToolbar extends Container {
  constructor(events: Events, tooltips: Tooltips, args = {}) {
    args = {
      ...args,
      id: 'right-toolbar'
    }

    super(args)

    this.dom.addEventListener('pointerdown', (event) => {
      event.stopPropagation()
    })

    const ringsModeToggle = new Button({
      id: 'right-toolbar-mode-toggle',
      class: 'right-toolbar-toggle'
    })

    const showHideSplats = new Button({
      id: 'right-toolbar-show-hide',
      class: ['right-toolbar-toggle', 'active']
    })

    const frameSelection = new Button({
      id: 'right-toolbar-frame-selection',
      class: 'right-toolbar-button'
    })

    const options = new Button({
      id: 'right-toolbar-options',
      class: 'right-toolbar-toggle',
      icon: 'E283'
    })

    const centersDom = createSvg(centersSvg)
    const ringsDom = createSvg(ringsSvg)
    ringsDom.style.display = 'none'

    ringsModeToggle.dom.appendChild(centersDom)
    ringsModeToggle.dom.appendChild(ringsDom)
    showHideSplats.dom.appendChild(createSvg(showHideSplatsSvg))
    frameSelection.dom.appendChild(createSvg(frameSelectionSvg))

    this.append(ringsModeToggle)
    this.append(showHideSplats)
    this.append(new Element({ class: 'right-toolbar-separator' }))
    this.append(frameSelection)
    this.append(new Element({ class: 'right-toolbar-separator' }))
    this.append(options)

    tooltips.register(ringsModeToggle, localize('tooltip.splat-mode'), 'left')
    tooltips.register(showHideSplats, localize('tooltip.show-hide'), 'left')
    tooltips.register(
      frameSelection,
      localize('tooltip.frame-selection'),
      'left'
    )
    tooltips.register(options, localize('tooltip.view-options'), 'left')

    // add event handlers

    ringsModeToggle.on('click', () => {
      events.fire('camera.toggleMode')
      events.fire('camera.setOverlay', true)
    })
    showHideSplats.on('click', () => events.fire('camera.toggleOverlay'))
    frameSelection.on('click', () => events.fire('camera.focus'))
    options.on('click', () => events.fire('viewPanel.toggleVisible'))

    events.on('camera.mode', (mode: string) => {
      ringsModeToggle.class[mode === 'rings' ? 'add' : 'remove']('active')
      centersDom.style.display = mode === 'rings' ? 'none' : 'block'
      ringsDom.style.display = mode === 'rings' ? 'block' : 'none'
    })

    events.on('camera.overlay', (value: boolean) => {
      showHideSplats.class[value ? 'add' : 'remove']('active')
    })

    events.on('viewPanel.visible', (visible: boolean) => {
      options.class[visible ? 'add' : 'remove']('active')
    })
  }
}

export { RightToolbar }
