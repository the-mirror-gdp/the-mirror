import { Container, Element, Label } from '@playcanvas/pcui'
import { Events } from '../events'
import { Tooltips } from './tooltips'
import { localize } from './localization'

import centersSvg from '../svg/centers.svg'
import ringsSvg from '../svg/rings.svg'

const createSvg = () => {
  const svgString = `
    <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
    </svg>
  `
  return new Element({
    dom: new DOMParser().parseFromString(svgString, 'image/svg+xml')
      .documentElement
  })
}

class ModeToggle extends Container {
  constructor(events: Events, tooltips: Tooltips, args = {}) {
    args = {
      id: 'mode-toggle',
      class: 'centers-mode',
      ...args
    }

    super(args)

    const centersIcon = new Element({
      id: 'centers-icon',
      dom: createSvg(centersSvg)
    })

    const ringsIcon = new Element({
      id: 'rings-icon',
      dom: createSvg(ringsSvg)
    })

    const centersText = new Label({
      id: 'centers-text',
      text: localize('mode.centers')
    })

    const ringsText = new Label({
      id: 'rings-text',
      text: localize('mode.rings')
    })

    this.append(centersIcon)
    this.append(ringsIcon)
    this.append(centersText)
    this.append(ringsText)

    this.dom.addEventListener('pointerdown', (event) => {
      event.stopPropagation()
      events.fire('camera.toggleMode')
      events.fire('camera.setOverlay', true)
    })

    events.on('camera.mode', (mode: string) => {
      this.class[mode === 'centers' ? 'add' : 'remove']('centers-mode')
      this.class[mode === 'rings' ? 'add' : 'remove']('rings-mode')
    })

    tooltips.register(this, localize('tooltip.splat-mode'))
  }
}

export { ModeToggle }
