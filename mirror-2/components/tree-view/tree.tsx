import { useAppDispatch } from '@/hooks/hooks';
import { useUpdateEntityMutation } from '@/state/entities';
import { Instruction } from '@atlaskit/pragmatic-drag-and-drop-hitbox/dist/types/tree-item';
import invariant from 'tiny-invariant';



export type TreeItem = {
  id: string;
  parentId?: string | null;
  isDraft?: boolean;
  children: TreeItem[];
  isOpen?: boolean;
  name: string;
};

export type TreeState = {
  lastAction: TreeAction | null;
  data: TreeItem[];
};

export function getInitialTreeState(initial): TreeState {
  console.log('initial', initial);
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
  | { type: 'set-tree'; tree: TreeItem[]; itemId?: string }
  ;

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
    return data.map((item) => {
      if (item.id === targetId) {
        return [newItem, item];
      }
      if (tree.hasChildren(item)) {
        return {
          ...item,
          children: tree.insertBefore(item.children, targetId, newItem).map(child => ({
            ...child,
            parentId: item.id, // Assign correct parentId for direct children
          })),
        };
      }
      return item;
    }).flat();
  },

  insertAfter(data: TreeItem[], targetId: string, newItem: TreeItem): TreeItem[] {
    return data.map((item) => {
      if (item.id === targetId) {
        return [item, newItem];
      }
      if (tree.hasChildren(item)) {
        return {
          ...item,
          children: tree.insertAfter(item.children, targetId, newItem).map(child => ({
            ...child,
            parentId: item.id, // Assign correct parentId for direct children
          })),
        };
      }
      return item;
    }).flat();
  },

  insertChild(data: TreeItem[], targetId: string, newItem: TreeItem): TreeItem[] {
    return data.map((item) => {
      if (item.id === targetId) {
        return {
          ...item,
          isOpen: true,
          children: [
            {
              ...newItem,
              parentId: item.id, // Assign parentId for new child
            },
            ...item.children.map(child => ({
              ...child,
              parentId: item.id, // Maintain parentId for existing children
            })),
          ],
        };
      }

      if (!tree.hasChildren(item)) {
        return item;
      }

      return {
        ...item,
        children: tree.insertChild(item.children, targetId, newItem).map(child => ({
          ...child,
          parentId: item.id, // Ensure correct parentId for all children in recursion
        })),
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
      const nested = tree.getPathToItem({
        current: item.children,
        targetId: targetId,
        parentIds: [...parentIds, item.id],
      });
      if (nested) {
        return nested;
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

  console.log('action', action);
  const item = tree.find(data, action.itemId as string);

  // Handle set-tree action
  if (action?.type === 'set-tree') {
    return action.tree;
  }

  if (!item) {
    return data;
  }

  if (action.type === 'instruction') {
    const instruction = action.instruction;

    // Reparenting: make an item a child of another item
    if (instruction.type === 'reparent') {
      const path = tree.getPathToItem({
        current: data,
        targetId: action.targetId,
      });
      invariant(path);
      const desiredId = path[instruction.desiredLevel];
      let result = tree.remove(data, action.itemId);
      result = tree.insertAfter(result, desiredId, {
        ...item,
        parentId: desiredId, // Update parentId during reparenting
      });
      console.log('tree result', result);

      // Dispatch to update entity's parentId in the backend
      updateEntity({ id: action.itemId, updateData: { parent_id: desiredId } })

      return result;
    }

    // Reordering above
    if (instruction.type === 'reorder-above') {
      const targetItem = tree.find(data, action.targetId);
      let result = tree.remove(data, action.itemId);
      result = tree.insertBefore(result, action.targetId, {
        ...item,
        parentId: targetItem?.parentId || null, // Update parentId to match the target item's parentId
      });
      console.log('tree result', result);

      // Dispatch to update entity's parentId in the backend
      updateEntity({ id: action.itemId, updateData: { parent_id: targetItem?.parentId || null } })

      return result;
    }

    // Reordering below
    if (instruction.type === 'reorder-below') {
      const targetItem = tree.find(data, action.targetId);
      let result = tree.remove(data, action.itemId);
      result = tree.insertAfter(result, action.targetId, {
        ...item,
        parentId: targetItem?.parentId || null, // Update parentId to match the target item's parentId
      });
      console.log('tree result', result);

      // Dispatch to update entity's parentId in the backend
      updateEntity({ id: action.itemId, updateData: { parent_id: targetItem?.parentId || null } })

      return result;
    }

    // Making an item a child of another
    if (instruction.type === 'make-child') {
      let result = tree.remove(data, action.itemId);
      result = tree.insertChild(result, action.targetId, {
        ...item,
        parentId: action.targetId, // Update parentId to reflect the new parent
      });
      console.log('tree result', result);

      // Dispatch to update entity's parentId in the backend
      updateEntity({ id: action.itemId, updateData: { parent_id: action.targetId } })

      return result;
    }

    console.warn('TODO: action not implemented', instruction);

    return data;
  }

  // Toggle open/close state of an item
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

  // Modal-move action
  if (action.type === 'modal-move') {
    let result = tree.remove(data, item.id);

    const siblingItems = getChildItems(result, action.targetId);

    if (siblingItems.length === 0) {
      if (action.targetId === '') {
        // If the target is the root level
        result = [{ ...item, parentId: null }]; // Update parentId to null if moved to root

        // Dispatch to update entity's parentId in the backend
        updateEntity({ id: item.id, updateData: { parent_id: null } })
      } else {
        result = tree.insertChild(result, action.targetId, {
          ...item,
          parentId: action.targetId, // Update parentId to targetId if moved as child
        });

        // Dispatch to update entity's parentId in the backend
        updateEntity({ id: item.id, updateData: { parent_id: action.targetId } })
      }
    } else if (action.index === siblingItems.length) {
      const relativeTo = siblingItems[siblingItems.length - 1];
      result = tree.insertAfter(result, relativeTo.id, {
        ...item,
        parentId: relativeTo?.parentId || null, // Update parentId to match the relative item's parentId
      });

      // Dispatch to update entity's parentId in the backend
      updateEntity({ id: item.id, updateData: { parent_id: relativeTo?.parentId || null } })
    } else {
      const relativeTo = siblingItems[action.index];
      result = tree.insertBefore(result, relativeTo.id, {
        ...item,
        parentId: relativeTo?.parentId || null, // Update parentId to match the relative item's parentId
      });

      // Dispatch to update entity's parentId in the backend
      updateEntity({ id: item.id, updateData: { parent_id: relativeTo?.parentId || null } })
    }

    return result;
  }

  return data;
};

function getChildItems(data: TreeItem[], targetId: string) {
  // If the targetId is empty, return the root-level items
  if (targetId === '') {
    return data;
  }

  const targetItem = tree.find(data, targetId);
  invariant(targetItem);

  return targetItem.children;
}
