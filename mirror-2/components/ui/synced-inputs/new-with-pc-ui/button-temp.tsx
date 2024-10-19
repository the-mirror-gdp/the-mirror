import { Button } from '@playcanvas/pcui/react'
import * as React from 'react'

const ButtonTemp = (props) => {
  return <Button {...props} />
}

export default ButtonTemp

// observer.on('input:set', (v) => {
//   console.log('set',v)
// // });
// const textInputLink = { observer, path: 'input' };

// // observer2.on('input2:set', (v) => {
// //   console.log('2set',v)
// // });
// const textInputLink2 = { observer: observer2, path: 'inpuasdfdsft1' };

// const test = new Element({
//   enabled: true
// })
// test.link(observer3, 'text')
// const label = new Label({
//   binding: new BindingObserversToElement()
// })
//
// label.link({
//   observer: observer3,
//   path: 'text'
// })
// label.link = (observer3, 'text')
// label.
