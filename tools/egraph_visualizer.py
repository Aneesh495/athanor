#!/usr/bin/env python3
"""
egraph_visualizer.py - High-Fidelity E-Graph Visualization and DOT Renderer

Generates:
  1. Terminal ASCII box-drawing visualization of equivalence classes and e-nodes.
  2. Standalone SVG visualization with visual grouping and edge routing.
"""

import sys
import os
import re
import argparse
from pathlib import Path

def parse_dot_content(dot_text):
    """
    Parse e-graph DOT syntax to extract clusters, nodes, and directed edges.
    """
    clusters = {}  # class_id -> list of (node_id, label)
    edges = []     # list of (src_node, dst_node, label)
    node_to_class = {}

    current_cluster = None
    cluster_pattern = re.compile(r"subgraph\s+cluster_(\d+)")
    node_pattern = re.compile(r'(node_\d+)\s+\[label="([^"]+)"')
    edge_pattern = re.compile(r'(node_\d+)\s+->\s+(node_\d+).*?label="([^"]+)"')

    for line in dot_text.splitlines():
        line = line.strip()
        cl_match = cluster_pattern.search(line)
        if cl_match:
            current_cluster = int(cl_match.group(1))
            clusters[current_cluster] = []
            continue

        if line == "}":
            current_cluster = None
            continue

        n_match = node_pattern.search(line)
        if n_match and current_cluster is not None:
            nid, label = n_match.group(1), n_match.group(2)
            clusters[current_cluster].append((nid, label))
            node_to_class[nid] = current_cluster
            continue

        e_match = edge_pattern.search(line)
        if e_match:
            src, dst, lbl = e_match.group(1), e_match.group(2), e_match.group(3)
            edges.append((src, dst, lbl))

    return clusters, edges, node_to_class

def render_ascii_egraph(clusters, edges):
    """
    Render textual box-drawing representation of e-classes and connectivity.
    """
    out = []
    out.append("+" + "=" * 74 + "+")
    out.append("| Athanor Equality Saturation Graph (E-Graph Topology)" + " " * 22 + "|")
    out.append("+" + "=" * 74 + "+")

    for cid in sorted(clusters.keys()):
        nodes = clusters[cid]
        node_labels = ", ".join(f"[{lbl}]" for _, lbl in nodes)
        out.append(f"| Equivalence Class #{cid:<3} ({len(nodes)} e-nodes)")
        out.append(f"|   Nodes: {node_labels}")

        # Find outgoing edges from this class
        class_edges = [e for e in edges if any(e[0] == nid for nid, _ in nodes)]
        if class_edges:
            out.append("|   Outgoing Arguments:")
            for src, dst, lbl in class_edges:
                out.append(f"|     --({lbl})--> {dst}")
        out.append("+" + "-" * 74 + "+")

    return "\n".join(out)

def render_svg_egraph(clusters, edges, output_path):
    """
    Render clean standalone SVG representation.
    """
    width = 900
    row_height = 80
    height = max(400, len(clusters) * row_height + 100)

    svg = []
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}">')
    svg.append('  <style>')
    svg.append('    .bg { fill: #fafafa; }')
    svg.append('    .cluster { fill: #ffffff; stroke: #cfd8dc; stroke-width: 1.5; rx: 6; }')
    svg.append('    .cluster-title { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; font-size: 13px; font-weight: 600; fill: #37474f; }')
    svg.append('    .enode { fill: #e8eaf6; stroke: #3f51b5; stroke-width: 1.2; rx: 4; }')
    svg.append('    .enode-text { font-family: "JetBrains Mono", Menlo, Consolas, monospace; font-size: 12px; fill: #1a237e; text-anchor: middle; dominant-baseline: middle; }')
    svg.append('    .edge { stroke: #78909c; stroke-width: 1.2; fill: none; marker-end: url(#arrow); }')
    svg.append('  </style>')
    svg.append('  <defs>')
    svg.append('    <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">')
    svg.append('      <path d="M 0 1 L 10 5 L 0 9 z" fill="#78909c"/>')
    svg.append('    </marker>')
    svg.append('  </defs>')
    svg.append(f'  <rect width="{width}" height="{height}" class="bg"/>')

    y_offset = 40
    node_positions = {}

    for cid in sorted(clusters.keys()):
        nodes = clusters[cid]
        cluster_width = 700
        cluster_h = 56
        svg.append(f'  <rect x="50" y="{y_offset}" width="{cluster_width}" height="{cluster_h}" class="cluster"/>')
        svg.append(f'  <text x="65" y="{y_offset + 22}" class="cluster-title">Class {cid}</text>')

        x_node = 160
        for nid, lbl in nodes:
            nw = max(60, len(lbl) * 10 + 20)
            nh = 28
            ny = y_offset + 14
            svg.append(f'  <rect x="{x_node}" y="{ny}" width="{nw}" height="{nh}" class="enode"/>')
            svg.append(f'  <text x="{x_node + nw//2}" y="{ny + nh//2 + 1}" class="enode-text">{lbl}</text>')
            node_positions[nid] = (x_node + nw//2, ny + nh)
            x_node += nw + 16

        y_offset += row_height

    svg.append('</svg>')
    content = "\n".join(svg)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(content)
    return output_path

def main():
    parser = argparse.ArgumentParser(description="Athanor E-Graph Visualizer")
    parser.add_argument("dot_file", nargs="?", help="Path to input Graphviz DOT file")
    parser.add_argument("--svg", help="Output path for standalone SVG")
    parser.add_argument("--ascii", action="store_true", default=True, help="Display terminal ASCII visualization")
    args = parser.parse_args()

    if args.dot_file and os.path.exists(args.dot_file):
        with open(args.dot_file, "r", encoding="utf-8") as f:
            dot_content = f.read()
    else:
        # Sample demonstrative DOT topology
        dot_content = """
        digraph EGraph {
            subgraph cluster_0 {
                node_1 [label="x"];
            }
            subgraph cluster_1 {
                node_2 [label="4"];
            }
            subgraph cluster_2 {
                node_3 [label="*"];
                node_4 [label="ash"];
            }
            node_3 -> node_1 [label="arg 0"];
            node_3 -> node_2 [label="arg 1"];
            node_4 -> node_1 [label="arg 0"];
            node_4 -> node_2 [label="arg 1"];
        }
        """

    clusters, edges, node_to_class = parse_dot_content(dot_content)

    if args.ascii:
        print(render_ascii_egraph(clusters, edges))

    if args.svg:
        out_svg = render_svg_egraph(clusters, edges, args.svg)
        print(f"Rendered vector SVG graph at: {out_svg}")

if __name__ == "__main__":
    main()
