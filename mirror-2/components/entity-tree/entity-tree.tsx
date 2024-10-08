import React, { useEffect, useState } from 'react';
import { ConfigProvider, Tree } from 'antd';
import type { TreeDataNode, TreeProps } from 'antd';
import { useAppSelector } from '@/hooks/hooks';
import { useParams } from 'next/navigation';
import { useGetSingleSpaceQuery } from '@/state/spaces';
import { useGetAllScenesQuery } from '@/state/scenes';
import { useCreateEntityMutation, useGetAllEntitiesQuery, useGetSingleEntityQuery, useUpdateEntityMutation } from '@/state/entities';
import { getCurrentScene } from '@/state/local';
import { skipToken } from '@reduxjs/toolkit/query';
import { Database } from '@/utils/database.types';
import { DataNode } from 'antd/es/tree';
import { TwoWayInput } from '@/components/two-way-input';
import { z } from 'zod';
import { PlusCircle } from 'lucide-react';

type Entity = Database['public']['Tables']['entities']['Row'];
type EntityWithPopulatedChildren = Omit<Entity, 'children'> & {
  key: string,
  title: string,
  icon?: any,
  children: EntityWithPopulatedChildren[]; // children now contain an array of Entity objects
};

type TreeDataNodeWithEntityData = TreeDataNode & { name: string, id: string }

function transformDbEntityStructureWithPopulatedChildren(entities: Entity[]): TreeDataNodeWithEntityData[] {
  const entityMap = new Map<string, EntityWithPopulatedChildren & { childIds: string[] }>();
  const assignedChildIds = new Set<string>(); // Track all child IDs to remove from the main array

  // Create a map for easy lookup of entities by ID, and keep the original children as string IDs
  entities.forEach((entity) => {
    const entityWithChildren: EntityWithPopulatedChildren & { childIds: string[] } = {
      ...entity,
      children: [], // Initialize as an empty array for the populated children
      key: entity.id,
      title: entity.name,
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

const EntityTree: React.FC = () => {
  const [treeData, setTreeData] = useState<any>([]);

  const currentScene = useAppSelector(getCurrentScene)
  const params = useParams<{ spaceId: string }>()
  // const { data: spaceBuildModeData, error } = useGetSingleSpaceBuildModeQuery(params.spaceId)
  const { data: space } = useGetSingleSpaceQuery(params.spaceId)
  const { data: scenes, isLoading: isScenesLoading } = useGetAllScenesQuery(params.spaceId)
  const { data: entities, isFetching: isEntitiesFetching } = useGetAllEntitiesQuery(
    scenes && scenes.length > 0 ? scenes.map(scene => scene.id) : skipToken  // Conditional query
  );

  const [updateEntity] = useUpdateEntityMutation();
  const [createEntity, { data: createdEntity }] = useCreateEntityMutation();

  // useEffect(() => {
  //   debugger
  //   if (currentScene) {
  //     getSingleSpace(currentScene);
  //   }
  // }, [currentScene]);
  useEffect(() => {
    if (entities && entities.length > 0) {
      const data = transformDbEntityStructureWithPopulatedChildren(entities)
      setTreeData(data)
      // updateState({ entities, type: 'set-tree', itemId: '' });
    }
  }, [entities]);  // Re-run effect when 'entities' changes


  const onDragEnter: TreeProps['onDragEnter'] = (info) => {
    console.log(info);
  };

  const onDrop: TreeProps['onDrop'] = (info) => {
    console.log(info);
    const dropKey = info.node.key;
    const dragKey = info.dragNode.key;
    const dropPos = info.node.pos.split('-');
    const dropPosition = info.dropPosition - Number(dropPos[dropPos.length - 1]); // the drop position relative to the drop node, inside 0, top -1, bottom 1

    const loop = (
      data: TreeDataNode[],
      key: React.Key,
      callback: (node: TreeDataNode, i: number, data: TreeDataNode[]) => void,
    ) => {
      for (let i = 0; i < data.length; i++) {
        if (data[i].key === key) {
          return callback(data[i], i, data);
        }
        if (data[i].children) {
          loop(data[i].children!, key, callback);
        }
      }
    };
    const data = [...treeData];

    // Find dragObject
    let dragObj: TreeDataNode;
    loop(data, dragKey, (item, index, arr) => {
      arr.splice(index, 1);
      dragObj = item;
    });

    if (!info.dropToGap) {
      // Drop on the content
      loop(data, dropKey, (item) => {
        item.children = item.children || [];
        // where to insert. New item was inserted to the start of the array in this example, but can be anywhere
        item.children.unshift(dragObj);
      });
    } else {
      let ar: TreeDataNode[] = [];
      let i: number;
      loop(data, dropKey, (_item, index, arr) => {
        ar = arr;
        i = index;
      });
      if (dropPosition === -1) {
        // Drop on the top of the drop node
        ar.splice(i!, 0, dragObj!);
      } else {
        // Drop on the bottom of the drop node
        ar.splice(i! + 1, 0, dragObj!);
      }
    }
    // debugger
    setTreeData(data);
  };

  return (
    <ConfigProvider
      theme={{
        components: {
          Tree: {
            colorText: '#FFFFFF',
            colorBgContainer: 'transparent',
            fontFamily: 'montserrat',
            // @ts-ignore using rem instead of number is working..
            fontSize: '0.9rem',
            nodeSelectedBg: '#3B82F6',
            nodeHoverBg: '#256BFB',
            directoryNodeSelectedBg: 'green'
          },
        },
      }}
    >
      <Tree
        className="draggable-tree"
        draggable={{ icon: false }}
        blockNode
        defaultExpandAll={true}
        showLine={false}
        showIcon
        autoExpandParent={true}
        onDragEnter={onDragEnter}
        onDrop={onDrop}
        treeData={treeData}
        titleRender={(nodeData: TreeDataNodeWithEntityData) => (
          <>
            <TwoWayInput
              id={nodeData.id}
              defaultValue={nodeData.name}
              // className={'p-0 m-0 h-8 '}
              fieldName="name" formSchema={z.object({
                name: z.string().min(1, { message: "Entity name must be at least 1 character long" }),
              })}
              useGeneralGetEntityQuery={useGetSingleEntityQuery}
              useGeneralUpdateEntityMutation={useUpdateEntityMutation} />
          </>
        )}
      />
    </ConfigProvider>
  );
};

export default EntityTree;
