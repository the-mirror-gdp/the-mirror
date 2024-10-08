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


type TreeDataNodeWithEntityData = TreeDataNode & { name: string, id: string }

function transformDbEntityStructureWithPopulatedChildren(entities) {
  const entityMap = new Map();
  const assignedChildIds = new Set();

  // Step 1: Populate the map with entities and their child IDs
  entities.forEach(entity => {
    const entityWithChildren = {
      ...entity,
      children: [], // Will hold actual child objects
      key: entity.id,
      title: entity.name,
      childIds: Array.isArray(entity.children) ? [...entity.children] : [] // Clone to avoid mutation
    };
    entityMap.set(entity.id, entityWithChildren);
  });

  // Step 2: Assign children to their respective parents, preventing duplication
  entityMap.forEach(entity => {
    if (entity.childIds.length > 0) {
      entity.children = entity.childIds
        .filter(childId => {
          if (assignedChildIds.has(childId)) {
            console.warn(`Child with ID ${childId} is already assigned to another parent. Skipping assignment to parent ID ${entity.id}.`);
            return false; // Exclude to prevent duplication
          }
          return true; // Include this child
        })
        .map(childId => {
          assignedChildIds.add(childId); // Mark as assigned
          const childEntity = entityMap.get(childId);
          if (!childEntity) {
            console.warn(`Child entity with ID ${childId} not found.`);
            return null;
          }
          return childEntity;
        })
        .filter(child => child !== null); // Remove any nulls
    }
  });

  // Step 3: Identify root entities (those not assigned as children and marked as root)
  const rootEntities = Array.from(entityMap.values()).filter(
    entity => !assignedChildIds.has(entity.id) && entity.is_root
  );

  // Step 4: Clean up temporary fields recursively
  function cleanEntity(entity) {
    const { childIds, ...rest } = entity;
    if (rest.children.length > 0) {
      rest.children = rest.children.map(child => cleanEntity(child));
    }
    return rest;
  }

  const cleanedRootEntities = rootEntities.map(cleanEntity);

  return cleanedRootEntities;
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
      // debugger
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
    let dragParent: any = null;

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


    // Function to find the parent of the drag node
    const findParentNode = (data, childKey: React.Key) => {
      for (let i = 0; i < data.length; i++) {
        if (data && data[i] && data[i].children) {
          const children = data[i].children
          const hasChild = children?.some(child => child.key === childKey);
          if (hasChild) {
            dragParent = data[i]; // Found the parent node
            return; // Exit once found
          }
          findParentNode(children, childKey);
        }
      }
    };

    // Find the parent of the dragged node
    findParentNode(treeData, dragKey); // `treeData` is your current tree structure

    console.log('Parent of dragged node:', dragParent);

    const data = [...treeData];

    // Find dragObject
    let dragObj: TreeDataNode;
    loop(data, dragKey, (item, index, arr) => {
      arr.splice(index, 1);
      dragParent.children = arr
      dragObj = item;
    });

    if (!info.dropToGap) {
      console.log('content drop to new parent', data)
      // Drop on the content
      loop(data, dropKey, (item) => {
        item.children = item.children || [];
        // where to insert. New item was inserted to the start of the array in this example, but can be anywhere
        item.children.unshift(dragObj);
      });

      // update the node and dragnode in DB
      if (info.node && info.node['id'] && info.node.children) {
        const childIds = info.node.children.map(child => child['id'])
        // debugger
        updateEntity({ id: info.node['id'], updateData: { children: childIds } })
      }
      if (info.dragNode && info.dragNode['id'] && info.dragNode.children) {
        const childIds = info.dragNode.children.map(child => child['id'])
        // debugger
        updateEntity({ id: info.dragNode['id'], updateData: { children: childIds } })
      }


    } else {
      console.log('gap drop', data)

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
      // debugger // not yet
      // update the node and dragnode in DB
      if (info.node && info.node['id'] && info.node.children) {
        const childIds = info.node.children.map(child => child['id'])
        updateEntity({ id: info.node['id'], updateData: { children: childIds } })
      }
      if (info.dragNode && info.dragNode['id'] && info.dragNode.children) {
        const childIds = info.dragNode.children.map(child => child['id'])
        updateEntity({ id: info.dragNode['id'], updateData: { children: childIds } })
      }
    }

    // update the dragParent to remove the child from its children array
    const childIds = dragParent.children.map(child => child['id'])
    updateEntity({ id: dragParent.id, updateData: { children: childIds } })

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
