class QueueNode<T> {
  private _value: T
  public get value(): T {
    return this._value
  }
  public next: QueueNode<T> | null

  constructor(value: T) {
    this._value = value
    this.next = null
  }
}

class Queue<T> {
  private _first: QueueNode<T> | null = null
  public get first(): QueueNode<T> | null {
    return this._first
  }
  private _last: QueueNode<T> | null = null
  public get last(): QueueNode<T> | null {
    return this._last
  }
  private _size = 0
  public get size(): number {
    return this._size
  }

  public enqueue(value: T): number {
    const newNode = new QueueNode(value)
    if (!this._first) {
      this._first = newNode
      this._last = newNode
    } else {
      if (this._last) {
        this._last.next = newNode
      }
      this._last = newNode
    }

    return this._size++
  }

  public dequeue(): T | null {
    if (!this._first) {
      return null
    }

    const temp = this._first
    if (this._first === this._last) {
      this._last = null
    }

    this._first = this._first.next
    this._size--
    return temp.value
  }
}

export { Queue, QueueNode }
