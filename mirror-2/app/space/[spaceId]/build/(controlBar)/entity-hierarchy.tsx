/**
 * @jsxRuntime classic
 * @jsx jsx
 */
"use client"
import { useCallback, useContext, useEffect, useMemo, useReducer, useRef, useState } from 'react';

// eslint-disable-next-line @atlaskit/ui-styling-standard/use-compiled -- Ignored via go/DSP-18766
import { css, jsx } from '@emotion/react';
import memoizeOne from 'memoize-one';
import invariant from 'tiny-invariant';

import { triggerPostMoveFlash } from '@atlaskit/pragmatic-drag-and-drop-flourish/trigger-post-move-flash';
import {
  type Instruction,
  type ItemMode,
} from '@atlaskit/pragmatic-drag-and-drop-hitbox/tree-item';
import * as liveRegion from '@atlaskit/pragmatic-drag-and-drop-live-region';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';
import { monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';

import { type TreeItem as TreeItemType, getInitialTreeState, tree, treeStateReducer } from "@/components/tree-view/tree"
import { type TreeContextValue, TreeContext, DependencyContext } from "@/components/tree-view/tree-context"
import TreeItem from '@/components/tree-view/tree-item';
import { cn } from '@/utils/cn';
import { Button } from '@/components/ui/button';
import { PlusCircleIcon } from 'lucide-react';

import { useAppSelector } from '@/hooks/hooks';
import { getCurrentScene } from '@/state/local';
import { useCreateEntityMutation, useGetAllEntitiesQuery, useUpdateEntityMutation } from '@/state/entities';
import { useGetSingleSpaceBuildModeQuery, useGetSingleSpaceQuery, useLazyGetSingleSpaceBuildModeQuery } from '@/state/spaces';
import { useParams } from 'next/navigation';
import { useGetAllScenesQuery } from '@/state/scenes';
import { skipToken } from '@reduxjs/toolkit/query';

// here for reference from boilerplate 2024-10-05 18:57:58
// const treeStyles = css({
//   display: 'flex',
//   boxSizing: 'border-box',
//   width: 280,
//   padding: 8,
//   flexDirection: 'column',
//   background: '#FFFFFF'
// });

type CleanupFn = () => void;

function createTreeItemRegistry() {
  const registry = new Map<string, { element: HTMLElement; actionMenuTrigger?: HTMLElement }>();

  const registerTreeItem = ({
    itemId,
    element,
    // actionMenuTrigger,
  }: {
    itemId: string;
    element: HTMLElement;
    // actionMenuTrigger: HTMLElement;
  }): CleanupFn => {
    registry.set(itemId, { element });
    return () => {
      registry.delete(itemId);
    };
  };

  return { registry, registerTreeItem };
}

export default function EntityHierarchy() {
  const currentScene = useAppSelector(getCurrentScene)
  const params = useParams<{ spaceId: string }>()
  // const { data: spaceBuildModeData, error } = useGetSingleSpaceBuildModeQuery(params.spaceId)
  const { data: space } = useGetSingleSpaceQuery(params.spaceId)
  const { data: scenes, isLoading: isScenesLoading } = useGetAllScenesQuery(params.spaceId)
  const { data: entities, isFetching: isEntitiesFetching } = useGetAllEntitiesQuery(
    scenes && scenes.length > 0 ? scenes.map(scene => scene.id) : skipToken  // Conditional query
  );

  const [updateEntity] = useUpdateEntityMutation();

  const [state, updateState] = useReducer(
    (state, action) => treeStateReducer(state, action, updateEntity), // Pass updateEntity to the reducer
    entities ? entities : [], // Fallback to an empty array before entities load
    getInitialTreeState
  );

  // useEffect(() => {
  //   debugger
  //   if (currentScene) {
  //     getSingleSpace(currentScene);
  //   }
  // }, [currentScene]);
  useEffect(() => {
    if (entities && entities.length > 0) {
      console.log('set-tree', entities)
      updateState({ tree: entities, itemId: '', type: 'set-tree' });
    }
  }, [entities]);  // Re-run effect when 'entities' changes
  const [createEntity, { data: createdEntity }] = useCreateEntityMutation();

  const ref = useRef<HTMLDivElement>(null);
  const { extractInstruction } = useContext(DependencyContext);

  const [{ registry, registerTreeItem }] = useState(createTreeItemRegistry);

  const { data, lastAction } = state;
  let lastStateRef = useRef<TreeItemType[]>(data);
  useEffect(() => {
    lastStateRef.current = data;
  }, [data]);

  useEffect(() => {
    if (lastAction === null) {
      return;
    }

    if (lastAction.type === 'modal-move') {
      const parentName = lastAction.targetId === '' ? 'the root' : `Item ${lastAction.targetId}`;

      liveRegion.announce(
        `You've moved Item ${lastAction.itemId} to position ${lastAction.index + 1
        } in ${parentName}.`,
      );

      const { element, actionMenuTrigger } = registry.get(lastAction.itemId) ?? {};
      if (element) {
        triggerPostMoveFlash(element);
      }

      /**
       * Only moves triggered by the modal will result in focus being
       * returned to the trigger.
       */
      actionMenuTrigger?.focus();

      return;
    }

    if (lastAction.type === 'instruction') {
      const { element } = registry.get(lastAction.itemId) ?? {};
      if (element) {
        triggerPostMoveFlash(element);
      }

      return;
    }
  }, [lastAction, registry]);

  useEffect(() => {
    return () => {
      liveRegion.cleanup();
    };
  }, []);

  /**
   * Returns the items that the item with `itemId` can be moved to.
   *
   * Uses a depth-first search (DFS) to compile a list of possible targets.
   */
  const getMoveTargets = useCallback(({ itemId }: { itemId: string }) => {
    const data = lastStateRef.current;

    const targets: any = [];

    const searchStack: any[] = Array.from(data);
    while (searchStack.length > 0) {
      const node = searchStack.pop();

      if (!node) {
        continue;
      }

      /**
       * If the current node is the item we want to move, then it is not a valid
       * move target and neither are its children.
       */
      if (node.id === itemId) {
        continue;
      }

      /**
       * Draft items cannot have children.
       */
      if (node.isDraft) {
        continue;
      }

      targets.push(node);

      node.children.forEach((childNode) => searchStack.push(childNode));
    }

    return targets;
  }, []);

  const getChildrenOfItem = useCallback((itemId: string) => {
    const data = lastStateRef.current;

    /**
     * An empty string is representing the root
     */
    if (itemId === '') {
      return data;
    }

    const item = tree.find(data, itemId);
    invariant(item);
    return item?.children || []
  }, []);

  const context = useMemo<TreeContextValue>(
    () => ({
      dispatch: updateState,
      uniqueContextId: Symbol('unique-id'),
      // memoizing this function as it is called by all tree items repeatedly
      // An ideal refactor would be to update our data shape
      // to allow quick lookups of parents
      getPathToItem: memoizeOne(
        (targetId: string) => tree.getPathToItem({ current: lastStateRef.current, targetId }) ?? [],
      ),
      getMoveTargets,
      getChildrenOfItem,
      registerTreeItem,
    }),
    [getChildrenOfItem, getMoveTargets, registerTreeItem],
  );

  useEffect(() => {
    invariant(ref.current);
    return combine(
      monitorForElements({
        canMonitor: ({ source }) => source.data.uniqueContextId === context.uniqueContextId,
        onDrop(args) {
          const { location, source } = args;
          // didn't drop on anything
          if (!location.current.dropTargets.length) {
            return;
          }

          if (source.data.type === 'tree-item') {
            const itemId = source.data.id as string;

            const target = location.current.dropTargets[0];
            const targetId = target.data.id as string;

            const instruction: Instruction | null = extractInstruction(target.data);

            if (instruction !== null) {
              updateState({
                type: 'instruction',
                instruction,
                itemId,
                targetId,
              });
            }
          }
        },
      }),
    );
  }, [context, extractInstruction]);


  return (
    <div>
      {/* Create Scene Button */}
      <Button className="w-full my-4" type="button" onClick={() => createEntity({ name: "New Entity", scene_id: currentScene })}>
        <PlusCircleIcon className="mr-2" />
        Create Entity
      </Button>
      <TreeContext.Provider value={context}>
        <div style={{ justifyContent: 'center' }}>
          <div id="tree" className={cn('')} ref={ref}>
            {data.map((item, index, array) => {
              const type: ItemMode = (() => {

                if (item.children?.length && item.isOpen) {
                  return 'expanded';
                }

                if (index === array.length - 1) {
                  return 'last-in-group';
                }

                return 'standard';
              })();

              return <TreeItem item={item} level={0} key={item.id} mode={type} index={index} />;
            })}
          </div>
        </div>
      </TreeContext.Provider>
    </div >
  );
}
