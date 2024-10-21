import { Container, Label, Element as PcuiElement } from '@playcanvas/pcui'
import { Events } from '../events'
import { Splat } from '../splat'
import { Element, ElementType } from '../element'

import shownSvg from '../svg/shown.svg'
import hiddenSvg from '../svg/hidden.svg'
import deleteSvg from '../svg/delete.svg'

const createSvg = (): HTMLElement => {
  const svgString = `
    <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
    </svg>
  `
  return new DOMParser().parseFromString(svgString, 'image/svg+xml')
    .documentElement as HTMLElement
}

class SplatItem extends Container {
  getSelected: () => boolean
  setSelected: (value: boolean) => void
  getVisible: () => boolean
  setVisible: (value: boolean) => void
  destroy: () => void

  constructor(name: string, args = {}) {
    args = {
      ...args,
      class: ['splat-item', 'visible']
    }

    super(args)

    const text = new Label({
      class: 'splat-item-text',
      text: name
    })

    const visible = new PcuiElement({
      dom: createSvg(),
      class: 'splat-item-visible'
    })

    const invisible = new PcuiElement({
      dom: createSvg(),
      class: 'splat-item-visible',
      hidden: true
    })

    const remove = new PcuiElement({
      dom: createSvg(),
      class: 'splat-item-delete'
    })

    this.append(text)
    this.append(visible)
    this.append(invisible)
    this.append(remove)

    this.getSelected = () => {
      return this.class.contains('selected')
    }

    this.setSelected = (value: boolean) => {
      if (value !== this.selected) {
        if (value) {
          this.class.add('selected')
          this.emit('select', this)
        } else {
          this.class.remove('selected')
          this.emit('unselect', this)
        }
      }
    }

    this.getVisible = () => {
      return this.class.contains('visible')
    }

    this.setVisible = (value: boolean) => {
      if (value !== this.visible) {
        visible.hidden = !value
        invisible.hidden = value
        if (value) {
          this.class.add('visible')
          this.emit('visible', this)
        } else {
          this.class.remove('visible')
          this.emit('invisible', this)
        }
      }
    }

    const toggleVisible = (event: MouseEvent) => {
      event.stopPropagation()
      this.visible = !this.visible
    }

    const handleRemove = (event: MouseEvent) => {
      event.stopPropagation()
      this.emit('removeClicked', this)
    }

    // handle clicks
    visible.dom.addEventListener('click', toggleVisible)
    invisible.dom.addEventListener('click', toggleVisible)
    remove.dom.addEventListener('click', handleRemove)

    this.destroy = () => {
      visible.dom.removeEventListener('click', toggleVisible)
      invisible.dom.removeEventListener('click', toggleVisible)
      remove.dom.removeEventListener('click', handleRemove)
    }
  }

  get selected() {
    return this.getSelected()
  }

  set selected(value) {
    this.setSelected(value)
  }

  get visible() {
    return this.getVisible()
  }

  set visible(value) {
    this.setVisible(value)
  }
}

class SplatList extends Container {
  constructor(events: Events, args = {}) {
    args = {
      ...args,
      class: 'splat-list'
    }

    super(args)

    const items = new Map<Splat, SplatItem>()

    events.on('scene.elementAdded', (element: Element) => {
      if (element.type === ElementType.splat) {
        const splat = element as Splat
        const item = new SplatItem(splat.filename)
        this.append(item)
        items.set(splat, item)

        item.on('visible', () => {
          splat.visible = true

          // also select it if there is no other selection
          if (!events.invoke('selection')) {
            events.fire('selection', splat)
          }
        })
        item.on('invisible', () => (splat.visible = false))
      }
    })

    events.on('scene.elementRemoved', (element: Element) => {
      if (element.type === ElementType.splat) {
        const splat = element as Splat
        const item = items.get(splat)
        if (item) {
          this.remove(item)
          items.delete(splat)
        }
      }
    })

    events.on('selection.changed', (selection: Splat) => {
      items.forEach((value, key) => {
        value.selected = key === selection
      })
    })

    events.on('splat.visibility', (splat: Splat) => {
      const item = items.get(splat)
      if (item) {
        item.visible = splat.visible
      }
    })

    this.on('click', (item: SplatItem) => {
      for (const [key, value] of items) {
        if (item === value) {
          events.fire('selection', key)
          break
        }
      }
    })

    this.on('removeClicked', async (item: SplatItem) => {
      let splat
      for (const [key, value] of items) {
        if (item === value) {
          splat = key
          break
        }
      }

      if (!splat) {
        return
      }

      const result = await events.invoke('showPopup', {
        type: 'yesno',
        header: 'Remove Splat',
        message: `Are you sure you want to remove '${splat.filename}' from the scene? This operation can not be undone.`
      })

      if (result?.action === 'yes') {
        splat.destroy()
      }
    })
  }

  protected _onAppendChild(element: PcuiElement): void {
    super._onAppendChild(element)

    if (element instanceof SplatItem) {
      element.on('click', () => {
        this.emit('click', element)
      })

      element.on('removeClicked', () => {
        this.emit('removeClicked', element)
      })
    }
  }

  protected _onRemoveChild(element: PcuiElement): void {
    if (element instanceof SplatItem) {
      element.unbind('click')
      element.unbind('removeClicked')
    }

    super._onRemoveChild(element)
  }
}

export { SplatList, SplatItem }
