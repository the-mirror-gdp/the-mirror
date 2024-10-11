import React, { useEffect, useState } from 'react';
import { ConfigProvider, Tree } from 'antd';
import type { TreeDataNode, TreeProps } from 'antd';
import { useParams } from 'next/navigation';
import { useGetAllScenesQuery } from '@/state/scenes';
import { useGetAllEntitiesQuery, useGetSingleEntityQuery, useUpdateEntityMutation, useBatchUpdateEntitiesMutation } from '@/state/entities';
import { skipToken } from '@reduxjs/toolkit/query';
import { TwoWayInput } from '@/components/two-way-input';
import { z } from 'zod';
import { addExpandedEntityIds, getCurrentScene, insertAutomaticallyExpandedSceneIds, selectAutomaticallyExpandedSceneIds, selectExpandedEntityIds, setCurrentEntity, setExpandedEntityIds } from '@/state/local';
import { useAppDispatch, useAppSelector } from '@/hooks/hooks';
import { current } from '@reduxjs/toolkit';
import EntityTreeItem from '@/components/entity-tree/tree-item';


type TreeDataNodeWithEntityData = TreeDataNode & { name: string, id: string, order_under_parent: number }

const findEntity = (treeData, entityId) => {
  // Base case: if treeData is empty or null, return null
  if (!treeData || treeData.length === 0) return null;

  // Loop through each item in the current level
  for (const item of treeData) {
    if (item.key === entityId) {
      // If the current item's key matches entityId, return the item
      return item;
    }

    // If this item has children, search within its children recursively
    if (item.children && item.children.length > 0) {
      const found = findEntity(item.children, entityId);
      if (found) {
        return found;
      }
    }
  }

  // Return null if not found at this level or in any children
  return null;
};

function transformDbEntityStructureToTree(entities): TreeDataNodeWithEntityData[] {
  const entityMap: any = {}; // Map to hold entities by their ID for quick lookup

  // Initialize the map and add a 'children' array to each entity
  entities.forEach(entity => {
    entityMap[entity.id] = { ...entity, children: [], key: entity.id };
  });

  // set root node not draggable
  entities.find(entity => {
    if (entity.parent_id === null) {
      entityMap[entity.id].draggable = false; // we don't want to set to "disabled" because then it can't be selected
      entityMap[entity.id].selectable = true;
    }
  });

  const tree: any[] = [];

  // Build the tree by linking parent and child entities
  entities.forEach(entity => {
    if (entity.parent_id) {
      // If the entity has a parent, add it to the parent's 'children' array
      const parentEntity = entityMap[entity.parent_id];
      if (parentEntity) {
        parentEntity.children.push(entityMap[entity.id]);
      } else {
        // Handle case where parent_id does not exist in the entityMap
        console.warn(`Parent entity with ID ${entity.parent_id} not found.`);
        tree.push(entityMap[entity.id]); // Treat as root if parent not found
      }
    } else {
      // If the entity has no parent, it's a root entity
      tree.push(entityMap[entity.id]);
    }
  });

  // Function to recursively sort children based on 'order_under_parent'
  function sortChildren(entity) {
    if (entity.children && entity.children.length > 0) {
      // Sort the children array based on 'order_under_parent'
      entity.children.sort((a, b) => {
        const orderA = a.order_under_parent ?? 0;
        const orderB = b.order_under_parent ?? 0;
        return orderA - orderB;
      });

      // Recursively sort the children's children
      entity.children.forEach(child => sortChildren(child));
    }
  }

  // Sort the root-level entities if needed
  tree.sort((a, b) => {
    const orderA = a.order_under_parent ?? 0;
    const orderB = b.order_under_parent ?? 0;
    return orderA - orderB;
  });

  // Recursively sort the entire tree
  tree.forEach(rootEntity => sortChildren(rootEntity));

  return tree;
}

const EntityTree: React.FC = () => {
  const [treeData, setTreeData] = useState<any>([]);
  const [expandedKeys, setExpandedKeys] = useState<string[]>([]);
  const dispatch = useAppDispatch()

  const params = useParams<{ spaceId: string }>()
  const currentScene = useAppSelector(getCurrentScene)
  const automaticallyExpandedSceneIds = useAppSelector(selectAutomaticallyExpandedSceneIds)
  const expandedEntityIds = useAppSelector(selectExpandedEntityIds)
  const { data: scenes, isLoading: isScenesLoading } = useGetAllScenesQuery(params.spaceId)
  const { data: entities, isFetching: isEntitiesFetching } = useGetAllEntitiesQuery(
    currentScene?.id || (scenes && scenes.length > 0 ? scenes.map(scene => scene.id) : skipToken)  // Conditional query
  );

  const [batchUpdateEntity] = useBatchUpdateEntitiesMutation();

  useEffect(() => {
    if (entities && entities.length > 0) {
      const data = transformDbEntityStructureToTree(entities)

      if (currentScene && !automaticallyExpandedSceneIds.includes(currentScene.id)) {
        // If the scene is not in the list of automatically expanded scenes, expand all and add it to the list
        // Recursive function to collect all keys from the node and its descendants
        const allExpandedKeys: any[] = []
        const collectExpandedKeys = (node) => {
          allExpandedKeys.push(node.key);
          if (node.children && node.children.length > 0) {
            node.children.forEach((child) => {
              collectExpandedKeys(child); // Recursively collect keys for all children
            });
          }
        };

        // Iterate over each node and recursively collect expanded keys
        data.forEach((node) => {
          collectExpandedKeys(node);
        });

        setExpandedKeys(allExpandedKeys);
        dispatch(insertAutomaticallyExpandedSceneIds({ sceneId: currentScene.id }))
      } else {
        // load expanded entity IDs from store
        setExpandedKeys(expandedEntityIds);
      }

      setTreeData(data)
    }
  }, [entities]);  // Re-run effect when 'entities' changes

  // whenever expandedKeys changes, update the store so it persists across component unmount
  useEffect(() => {
    dispatch(addExpandedEntityIds({ entityIds: expandedKeys.map(key => String(key)) }));
  }, [expandedKeys])


  const onDragEnter: TreeProps['onDragEnter'] = (info) => {
    console.log(info);
  };

  const onDrop: TreeProps['onDrop'] = (info) => {
    console.log(info);

    // check to ensure not creating new root. stop if so
    if (info.node['parent_id'] === null && info.dropToGap === true) {
      return
    }

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

      const entitiesUpdateArray: any[] = []
      const mainEntityId = info.dragNode['id']
      console.log('content drop to new parent', data)
      // Drop on the content
      let newPosition = 0
      loop(data, dropKey, (item) => {
        item.children = item.children || [];
        // where to insert. New item was inserted to the start of the array in this example, but can be anywhere
        item.children.unshift(dragObj);

        item.children.forEach((child, index) => {
          const order_under_parent = index
          let updateData = { id: child['id'], order_under_parent, name: child['name'] }
          if (child['id'] === mainEntityId) {
            updateData = Object.assign({}, updateData, {
              parent_id: info.node['id'] // should be info.node here, which is the node the dragNode is getting dropped under, so we want the ID of that node (note: different from getting the parent_id of it, below)
            })
          }
          entitiesUpdateArray.push(updateData)
        })
      });

      // do the same for data.children: this updates the order_under_parent of the list that the dragNode is being moved OUT of
      if (data && data[0] && data[0].children) {
        data[0].children.forEach((child, index) => {
          const order_under_parent = index
          let updateData = { id: child['id'], order_under_parent, name: child['name'] }
          if (child['id'] === mainEntityId) {
            updateData = Object.assign({}, updateData, {
              parent_id: info.node['id'] // should be info.node here, which is the node the dragNode is getting dropped under, so we want the ID of that node (note: different from getting the parent_id of it, below)
            })
          }
          entitiesUpdateArray.push(updateData)
        })
      }

      batchUpdateEntity({
        entities: entitiesUpdateArray
      })

    } else {
      console.log('gap drop', data)

      const entitiesUpdateArray: any[] = []
      const mainEntityId = info.dragNode['id']
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
      // get the new position from ar
      // updates order_under_parent of each
      ar.forEach((child, index) => {
        const order_under_parent = index
        let updateData = { id: child['id'], order_under_parent, name: child['name'] }
        if (child['id'] === mainEntityId) {
          updateData = Object.assign({}, updateData, {
            parent_id: info.node['parent_id'] // should be info.node here, which is the node the dragNode is getting dropped under, so we want the parent_id of THAT node
          })
        }
        entitiesUpdateArray.push(updateData)
      })

      batchUpdateEntity({
        entities: entitiesUpdateArray
      })
    }

    setTreeData(data);

  };

  const onExpand: TreeProps['onExpand'] = (expandedKeysValue) => {
    // Ensure it's a string array
    setExpandedKeys(expandedKeysValue.map(key => String(key))); // Convert to string[]
    dispatch(setExpandedEntityIds({ entityIds: expandedKeysValue.map(key => String(key)) }));
  };


  return (
    <ConfigProvider
      theme={{
        components: {
          Tree: {
            motionDurationFast: '0.025s',
            motionDurationSlow: '0.05s',
            motionDurationMid: '0.05s',
            colorText: '#FFFFFF',
            colorBgContainer: 'transparent',
            nodeSelectedBg: '#256BFB',
            nodeHoverBg: '#ffffff0d'
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
        onExpand={onExpand}
        expandedKeys={expandedKeys}
        autoExpandParent={false}
        onDragEnter={onDragEnter}
        onDrop={onDrop}
        treeData={treeData}
        onSelect={(selectedKeys) => {
          const entityId = selectedKeys[0];
          const entity = findEntity(treeData, entityId)
          if (!entity) {
            return
          }
          dispatch(setCurrentEntity(entity))
        }}
        titleRender={(nodeData: TreeDataNodeWithEntityData) => (
          <>
            <EntityTreeItem nodeData={nodeData} />
          </>
        )}
      />
    </ConfigProvider>
  );
};

export default EntityTree;
