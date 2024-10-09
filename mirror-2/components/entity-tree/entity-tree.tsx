import React, { useEffect, useState } from 'react';
import { ConfigProvider, Tree } from 'antd';
import type { TreeDataNode, TreeProps } from 'antd';
import { useParams } from 'next/navigation';
import { useGetAllScenesQuery } from '@/state/scenes';
import { useGetAllEntitiesQuery, useGetSingleEntityQuery, useUpdateEntityMutation, useBatchUpdateEntitiesMutation } from '@/state/entities';
import { skipToken } from '@reduxjs/toolkit/query';
import { TwoWayInput } from '@/components/two-way-input';
import { z } from 'zod';
import { getCurrentScene, selectExpandedEntityIds, setExpandedEntityIds } from '@/state/local';
import { useAppDispatch, useAppSelector } from '@/hooks/hooks';


type TreeDataNodeWithEntityData = TreeDataNode & { name: string, id: string, order_under_parent: number }

function transformDbEntityStructureToTree(entities): TreeDataNodeWithEntityData[] {
  const entityMap: any = {}; // Map to hold entities by their ID for quick lookup

  // Initialize the map and add a 'children' array to each entity
  entities.forEach(entity => {
    entityMap[entity.id] = { ...entity, children: [], key: entity.id };
  });

  //disable the root node
  entities.find(entity => {
    if (entity.parent_id === null) {
      entityMap[entity.id].disabled = true;
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
  const expandedEntityIds = useAppSelector(selectExpandedEntityIds)
  const { data: scenes, isLoading: isScenesLoading } = useGetAllScenesQuery(params.spaceId)
  const { data: entities, isFetching: isEntitiesFetching } = useGetAllEntitiesQuery(
    currentScene?.id || (scenes && scenes.length > 0 ? scenes.map(scene => scene.id) : skipToken)  // Conditional query
  );

  const [batchUpdateEntity] = useBatchUpdateEntitiesMutation();

  useEffect(() => {
    if (entities && entities.length > 0) {
      const data = transformDbEntityStructureToTree(entities)
      if (currentScene) {

        // Recursive function to collect all keys from the node and its descendants
        // const collectExpandedKeys = (node) => {
        //   expandedKeys.push(node.key);
        //   if (node.children && node.children.length > 0) {
        //     node.children.forEach((child) => {
        //       collectExpandedKeys(child); // Recursively collect keys for all children
        //     });
        //   }
        // };

        // Iterate over each node and recursively collect expanded keys
        // data.forEach((node) => {
        //   collectExpandedKeys(node);
        // });

        let expandedKeysFromStore = expandedEntityIds
        setExpandedKeys(expandedKeysFromStore);
      }

      setTreeData(data)
    }
  }, [entities]);  // Re-run effect when 'entities' changes

  // if currentScene changes, reset hasInitialExpandedKeys to false
  // useEffect(() => {
  //   if (currentScene) {
  //     setHasInitialExpandedKeys(false)
  //   }
  // }, [currentScene])


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
    console.log('onExpand', expandedKeysValue);
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
        onExpand={onExpand}
        expandedKeys={expandedKeys}
        autoExpandParent={false}
        onDragEnter={onDragEnter}
        onDrop={onDrop}
        treeData={treeData}
        titleRender={(nodeData: TreeDataNodeWithEntityData) => (
          <>
            <TwoWayInput
              id={nodeData.id}
              generalEntity={nodeData}
              defaultValue={nodeData.name}
              className={'p-0 m-0 h-8 '}
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
