import { useAppDispatch } from '@/hooks/hooks';
import { useUpdateEntityMutation } from '@/state/entities';
import { Database } from '@/utils/database.types';
import { Instruction } from '@atlaskit/pragmatic-drag-and-drop-hitbox/dist/types/tree-item';
import invariant from 'tiny-invariant';

export type TreeItem = {
  id: string;
  isDraft?: boolean;
  children: TreeItem[];
  isOpen?: boolean;
  name: string;
};

export type TreeState = {
  lastAction: TreeAction | null;
  data: TreeItem[];
};

type Entity = Database['public']['Tables']['entities']['Row'];
type EntityWithPopulatedChildren = Omit<Entity, 'children'> & {
  children: EntityWithPopulatedChildren[]; // children now contain an array of Entity objects
};

/**
 * For any entity.children: ["some-uuid"], this populates it so the entity.children property contains actual entity objects
 * and removes the duplicates from the main array.
 */
export function replaceDbEntityStructureWithPopulatedChildren(entities: Entity[]): EntityWithPopulatedChildren[] {
  const entityMap = new Map<string, EntityWithPopulatedChildren & { childIds: string[] }>();
  const assignedChildIds = new Set<string>(); // Track all child IDs to remove from the main array

  // Create a map for easy lookup of entities by ID, and keep the original children as string IDs
  entities.forEach((entity) => {
    const entityWithChildren: EntityWithPopulatedChildren & { childIds: string[] } = {
      ...entity,
      children: [], // Initialize as an empty array for the populated children
      childIds: entity.children ? (entity.children as string[]) : [] // Temporarily store child IDs
    };
    entityMap.set(entity.id, entityWithChildren);
  });

  // Now replace childIds with the actual EntityWithPopulatedChildren objects
  entityMap.forEach((entityWithChildren) => {
    if (entityWithChildren.childIds.length > 0) {
      entityWithChildren.children = entityWithChildren.childIds.map((childId) => {
        const childEntity = entityMap.get(childId)!;
        assignedChildIds.add(childId); // Mark this ID as assigned to a parent
        return childEntity; // Get the actual child entity
      });
    }
  });

  // Filter out entities that were assigned as children (remove duplicates)
  const rootEntities = Array.from(entityMap.values()).filter(
    (entity) => !assignedChildIds.has(entity.id) // Keep only the root-level entities
  );

  // Return the filtered entities without the temporary `childIds` field
  return rootEntities.map(({ childIds, ...entity }) => entity);
}

export function getInitialTreeState(initial): TreeState {
  return { data: getInitialData(), lastAction: null };
}

export function getInitialData(): TreeItem[] {
  return [
    //   {
    //     id: '1',
    //     isOpen: false,
    //     children: [
    //       {
    //         id: '1.3',
    //         isOpen: true,
    //         children: [
    //           {
    //             id: '1.3.1',
    //             children: [],
    //           },
    //           {
    //             id: '1.3.2',
    //             isDraft: true,
    //             children: [],
    //           },
    //         ],
    //       },
    //       { id: '1.4', children: [] },
    //     ],
    //   },
    //   {
    //     id: '2',
    //     isOpen: true,
    //     children: [
    //       {
    //         id: '2.3',
    //         isOpen: true,
    //         children: [
    //           {
    //             id: '2.3.1',
    //             children: [],
    //           },
    //           {
    //             id: '2.3.2',
    //             children: [],
    //           },
    //         ],
    //       },
    //     ],
    //   },
  ];
}

export type TreeAction =
  | {
    type: 'instruction';
    instruction: Instruction;
    itemId: string;
    targetId: string;
  }
  | {
    type: 'toggle';
    itemId: string;
  }
  | {
    type: 'expand';
    itemId: string;
  }
  | {
    type: 'collapse';
    itemId: string;
  }
  | { type: 'modal-move'; itemId: string; targetId: string; index: number }
  | { type: 'set-tree'; tree: TreeItem[]; itemId?: string };

export const tree = {
  remove(data: TreeItem[], id: string): TreeItem[] {
    return data
      .filter((item) => item.id !== id)
      .map((item) => {
        if (tree.hasChildren(item)) {
          return {
            ...item,
            children: tree.remove(item.children, id),
          };
        }
        return item;
      });
  },

  insertBefore(data: TreeItem[], targetId: string, newItem: TreeItem): TreeItem[] {
    return data
      .map((item) => {
        if (item.id === targetId) {
          return [newItem, item];
        }
        if (tree.hasChildren(item)) {
          return {
            ...item,
            children: tree.insertBefore(item.children, targetId, newItem),
          };
        }
        return item;
      })
      .flat();
  },

  insertAfter(data: TreeItem[], targetId: string, newItem: TreeItem): TreeItem[] {
    return data
      .map((item) => {
        if (item.id === targetId) {
          return [item, newItem];
        }
        if (tree.hasChildren(item)) {
          return {
            ...item,
            children: tree.insertAfter(item.children, targetId, newItem),
          };
        }
        return item;
      })
      .flat();
  },

  insertChild(data: TreeItem[], targetId: string, newItem: TreeItem): TreeItem[] {
    return data.map((item) => {
      if (item.id === targetId) {
        return {
          ...item,
          isOpen: true,
          children: [...item.children, newItem],
        };
      }

      if (!tree.hasChildren(item)) {
        return item;
      }

      return {
        ...item,
        children: tree.insertChild(item.children, targetId, newItem),
      };
    });
  },

  find(data: TreeItem[], itemId: string): TreeItem | undefined {
    for (const item of data) {
      if (item.id === itemId) {
        return item;
      }

      if (tree.hasChildren(item)) {
        const result = tree.find(item.children, itemId);
        if (result) {
          return result;
        }
      }
    }
  },

  getPathToItem({
    current,
    targetId,
    parentIds = [],
  }: {
    current: TreeItem[];
    targetId: string;
    parentIds?: string[];
  }): string[] | undefined {
    for (const item of current) {
      if (item.id === targetId) {
        return parentIds;
      }
      if (item?.children) {
        const nested = tree.getPathToItem({
          current: item.children,
          targetId: targetId,
          parentIds: [...parentIds, item.id],
        });
        if (nested) {
          return nested;
        }
      }
    }
  },

  hasChildren(item: TreeItem): boolean {
    return item.children && item.children.length > 0;
  },
};

export function treeStateReducer(state: TreeState, action: TreeAction, updateEntity): TreeState {
  return {
    data: dataReducer(state.data, action, updateEntity),
    lastAction: action,
  };
}

const dataReducer = (data: TreeItem[], action: TreeAction, updateEntity) => {
  const item = tree.find(data, action.itemId as string);

  if (action?.type === 'set-tree') {
    return action.tree;
  }

  if (!item) {
    return data;
  }

  if (action.type === 'instruction') {
    const instruction = action.instruction;

    if (instruction.type === 'reparent') {
      const path = tree.getPathToItem({
        current: data,
        targetId: action.targetId,
      });
      invariant(path);
      const desiredId = path[instruction.desiredLevel];
      let result = tree.remove(data, action.itemId);
      result = tree.insertAfter(result, desiredId, { ...item });

      // Dispatch to update entity's children in the backend
      updateEntity({ id: action.targetId, updateData: { children: result } });

      return result;
    }

    if (instruction.type === 'reorder-above') {
      const targetItem = tree.find(data, action.targetId);
      let result = tree.remove(data, action.itemId);
      result = tree.insertBefore(result, action.targetId, { ...item });

      updateEntity({ id: action.targetId, updateData: { children: result } });

      return result;
    }

    if (instruction.type === 'reorder-below') {
      const targetItem = tree.find(data, action.targetId);
      let result = tree.remove(data, action.itemId);
      result = tree.insertAfter(result, action.targetId, { ...item });

      updateEntity({ id: action.targetId, updateData: { children: result } });

      return result;
    }

    if (instruction.type === 'make-child') {
      let result = tree.remove(data, action.itemId);
      result = tree.insertChild(result, action.targetId, { ...item });
      // targetId = new parent id
      const parent = result.filter(item => item.id === action.targetId)[0]
      const childrenOfParentObjects = parent.children
      const childrenOfParentIds = childrenOfParentObjects.map(child => child.id)
      updateEntity({ id: action.targetId, updateData: { children: childrenOfParentIds } });

      return result;
    }

    console.warn('TODO: action not implemented', instruction);
    return data;
  }

  function toggle(item: TreeItem): TreeItem {
    if (!tree.hasChildren(item)) {
      return item;
    }

    if (item.id === action.itemId) {
      return { ...item, isOpen: !item.isOpen };
    }

    return { ...item, children: item.children.map(toggle) };
  }

  if (action.type === 'toggle') {
    return data.map(toggle);
  }

  if (action.type === 'expand') {
    if (tree.hasChildren(item) && !item.isOpen) {
      return data.map(toggle);
    }
    return data;
  }

  if (action.type === 'collapse') {
    if (tree.hasChildren(item) && item.isOpen) {
      return data.map(toggle);
    }
    return data;
  }

  if (action.type === 'modal-move') {
    let result = tree.remove(data, item.id);

    const siblingItems = getChildItems(result, action.targetId);

    if (siblingItems.length === 0) {
      if (action.targetId === '') {
        result = [{ ...item }];

        updateEntity({ id: item.id, updateData: { children: result } });
      } else {
        result = tree.insertChild(result, action.targetId, { ...item });

        updateEntity({ id: action.targetId, updateData: { children: result } });
      }
    } else if (action.index === siblingItems.length) {
      const relativeTo = siblingItems[siblingItems.length - 1];
      result = tree.insertAfter(result, relativeTo.id, { ...item });

      updateEntity({ id: relativeTo.id, updateData: { children: result } });
    } else {
      const relativeTo = siblingItems[action.index];
      result = tree.insertBefore(result, relativeTo.id, { ...item });

      updateEntity({ id: relativeTo.id, updateData: { children: result } });
    }

    return result;
  }

  return data;
};

function getChildItems(data: TreeItem[], targetId: string): TreeItem[] {
  if (targetId === '') {
    return data;
  }

  const targetItem = tree.find(data, targetId);
  invariant(targetItem);

  return targetItem.children;
}
