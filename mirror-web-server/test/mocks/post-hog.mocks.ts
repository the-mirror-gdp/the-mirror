import { vi } from 'vitest'

export const PostHogServiceMock = {
  createQueryBuilder: vi.fn(() => ({
    execute: vi.fn()
  })),
  captureEvent: vi.fn()
}

export const HogQLQueryBuilderMock = (value) => {
  const mock = {
    select: vi.fn(() => mock),
    where: vi.fn(() => mock),
    andWhere: vi.fn(() => mock),
    orWhere: vi.fn(() => mock),
    from: vi.fn(() => mock),
    offset: vi.fn(() => mock),
    limit: vi.fn(() => mock),
    sort: vi.fn(() => mock),
    execute: vi.fn(() => Promise.resolve(value)),
    getRawQuery: vi.fn(() => '')
  }
  return mock
}
