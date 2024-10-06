'use client';

import { useState, useEffect } from 'react';
import { Tree, TreePassThroughOptions, TreeProps, TreeTogglerTemplateOptions } from 'primereact/tree';
import { Button } from 'primereact/button';
import { NodeService } from './NodeService';
import { PrimeReactProvider } from 'primereact/api';
import Tailwind from 'primereact/passthrough/tailwind';
import { cn } from '@/utils/cn';
import { ChevronDown, ChevronLeft, ChevronRight } from 'lucide-react';

export interface TreeNode {
  /**
   * Unique identifier of the element.
   */
  id?: string | undefined;
  /**
   * Unique key of the node.
   */
  key?: string | number | undefined;
  /**
   * Label of the node.
   */
  label?: string | undefined;
  /**
   * Data represented by the node.
   */
  data?: any | undefined;
  /**
   * Icon of the node to display next to content.
   */
  icon?: any
  /**
   * Used to get the child elements of the component.
   * @readonly
   */
  children?: TreeNode[] | undefined;
  /**
   * Inline style of the node.
   */
  style?: React.CSSProperties | undefined;
  /**
   * Style class of the node.
   */
  className?: string | undefined;
  /**
   * Whether the node is droppable when dragdrop is enabled.
   * @defaultValue true
   */
  droppable?: boolean | undefined;
  /**
   * Whether the node is draggable when dragdrop is enabled.
   * @defaultValue true
   */
  draggable?: boolean | undefined;
  /**
   * Whether the node is selectable when selection mode is enabled.
   */
  selectable?: boolean | undefined;
  /**
   * Specifies if the node has children. Used in lazy loading.
   */
  leaf?: boolean | undefined;
  /**
   * Visibility of node.
   */
  expanded?: boolean | undefined;
}


export default function ControlledDemo() {
  const [nodes, setNodes] = useState<any>([]);
  const [expandedKeys, setExpandedKeys] = useState<any>({ '0': true, '0-0': true });
  const [selectedKeys, setSelectedKeys] = useState<any>(null);
  const [hoveredNodeKey, setHoveredNodeKey] = useState<string | null>(null); // State for hovered node during drag

  // Function to expand all nodes
  const expandAll = () => {
    let _expandedKeys = {};
    for (let node of nodes) {
      expandNode(node, _expandedKeys);
    }
    setExpandedKeys(_expandedKeys);
  };

  // Function to collapse all nodes
  const collapseAll = () => {
    setExpandedKeys({});
  };

  // Function to expand individual nodes
  const expandNode = (node, _expandedKeys) => {
    if (node.children && node.children.length) {
      _expandedKeys[node.key] = true;
      for (let child of node.children) {
        expandNode(child, _expandedKeys);
      }
    }
  };

  // Fetch tree nodes data
  useEffect(() => {
    NodeService.getTreeNodes().then((data) => setNodes(data));
  }, []);

  // Customizing the Tree component's appearance using Tailwind
  const pt: TreePassThroughOptions = {
    // node: {
    //   className: ({ props, context }) => `cursor-pointer items-center p-2 rounded-lg transition-all hover:bg-accent`,
    // },
    // label: {
    //   header: "<h1>hi</h1>",
    //   className: ({ props, context }) => `cursor-pointer items-center p-2 rounded-lg transition-all text-green-500 ${true ? 'text-red-500' : ''
    //     }`,
    // },
    // toggler: {
    //   className: 'mr-1', // Add spacing for the toggle icons
    // },

  };

  const togglerTemplate = (node: TreeNode, options: TreeTogglerTemplateOptions) => {
    if (!node) {
      return null;
    }

    // Determine if the node is a leaf node
    const isNodeLeafFn = options.props['isNodeLeaf'];
    const isNodeLeaf = isNodeLeafFn(node);

    // Calculate depth based on the number of dashes (-) in the path
    let depth = 0;
    if (!isNodeLeaf) {
      depth = (options.props['path'].match(/-/g) || []).length;
    }

    // Calculate the margin in rem based on the depth
    // const marginLeft = `${depth * 2}rem`;
    const marginLeft = `${depth}rem`;

    const expanded = options.expanded;
    const hasChildren = node?.children && node.children.length > 0;

    // Use Tailwind for styling, and apply dynamic margin with inline styles
    const className = cn(
      'hover:bg-primary rounded-lg transition-all duration-100'
    );
    return (
      hasChildren && (
        <button
          type="button"
          className={className}
          style={{ 'marginLeft': marginLeft }}
          tabIndex={-1}
          onClick={options.onClick}
        >
          {expanded ? <ChevronDown /> : <ChevronRight />}
        </button>
      )
    );
  };

  const handleDragOver = (e, nodeKey) => {
    e.preventDefault(); // Necessary to allow the drop
    setHoveredNodeKey(nodeKey); // Set the hovered node
  };

  // Function to handle drag leave event and remove highlight
  const handleDragLeave = () => {
    setHoveredNodeKey(null); // Clear the hovered node
  };
  // TreeProps & { label: string } is hacky here but the types don't seem to be importing correctly
  const nodeTemplate = (node: TreeNode, options) => {
    const expanded = options.expanded;

    // Determine if the node is a leaf node
    const isNodeLeafFn = options.props['isNodeLeaf'];
    const isNodeLeaf = isNodeLeafFn(node);

    // Calculate depth based on the number of dashes (-) in the path
    let depth = 0;
    if (isNodeLeaf) {
      depth = (options.props.path.match(/-/g) || []).length;
    }

    // Calculate the margin in rem based on the depth
    const marginLeft = `${depth * 1.5}rem`;

    // Use Tailwind for styling, but apply dynamic margin with inline styles
    const className = cn(
      'cursor-pointer items-center rounded-lg transition-all',
      hoveredNodeKey === node.key && 'bg-primary text-white' // Highlight on hover during drag
    );

    return (
      <div className={className} style={{ marginLeft }}
        onDragOver={(e) => handleDragOver(e, node.key)} // Highlight on drag over
        onDragLeave={handleDragLeave} // Remove highlight on drag leave
      >
        {node.label}
      </div>
    );
  };

  return (
    <PrimeReactProvider value={{ unstyled: true, pt: Tailwind }}>
      <div className="p-4 mb-4">
        {/* Expand/Collapse Buttons */}
        <Button type="button" icon="pi pi-plus" label="Expand All" onClick={expandAll} />
        <Button type="button" icon="pi pi-minus" label="Collapse All" onClick={collapseAll} />
        {/* Tree Component */}
        <Tree
          pt={pt}
          value={nodes}
          // metaKeySelection: true means CMD/CTRL is required for multiple select
          metaKeySelection={true}
          selectionKeys={selectedKeys}
          selectionMode="multiple"
          expandedKeys={expandedKeys}
          onSelectionChange={(e) => {
            console.log('setting selected', e.value)
            setSelectedKeys(e.value)
          }}
          onToggle={(e) => setExpandedKeys(e.value)}
          className="w-full md:w-96"
          nodeTemplate={nodeTemplate}
          togglerTemplate={togglerTemplate}
          dragdropScope="hierarchy"
          onDragDrop={(e) => {
            setHoveredNodeKey(null)
            setNodes(e.value)
          }} // Handle the drop complete event

        />
      </div>
    </PrimeReactProvider>
  );
}
