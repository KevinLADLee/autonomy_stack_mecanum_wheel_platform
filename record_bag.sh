#!/bin/bash

# ROS2 Bag Record Script for TARE Planner Ground Configuration
# This script records all topics visible in the rviz configuration
# Uses MCAP format for storage

# Default output directory (can be overridden with command line argument)
OUTPUT_DIR="${1:-tare_planner_bag_$(date +%Y%m%d_%H%M%S)}"

echo "Starting ROS2 bag recording..."
echo "Output directory: $OUTPUT_DIR"
echo "Storage format: mcap"
echo ""

# Record all topics from rviz configuration
ros2 bag record \
  --output "$OUTPUT_DIR" \
  --storage mcap \
  /keypose_graph_cloud \
  /keypose_graph_edge_marker \
  /tare_visualizer/exploring_subspaces \
  /global_path \
  /planner_cloud \
  /overall_map \
  /explored_areas \
  /navigation_boundary \
  /tare_visualizer/local_planning_horizon \
  /viewpoint_vis_cloud \
  /selected_viewpoint_vis_cloud \
  /lookahead_point_cloud \
  /local_path \
  /uncovered_cloud \
  /uncovered_frontier_cloud \
  /way_point \
  /free_paths \
  /path \
  /camera/d435_camera/color/camera_info \
  /camera/d435_camera/color/image_raw/compressed \
  /registered_scan \
  /tf \
  /tf_static

