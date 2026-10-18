# -*- coding: utf-8 -*-
"""
Utility functions for creating Sankey diagrams from Polars DataFrames
"""
import re
import plotly.graph_objects as go
import polars as pl


def create_sankey_from_polars(
    df, flow_columns,
    title="Sankey Diagram",
    column_color_map=None,
    node_align="justify",
    width=1500,
    height=1000
):
    """
    Function to create Sankey plot from Polars DataFrame (improved label version)
    
    Parameters:
    df: Polars DataFrame
    flow_columns: list - list of columns to represent the flow (from left to right)
    title: str - title of the graph
    column_color_map: dict - column name as key, color as value (e.g., {'col1': 'blue', 'col2': 'red'})
    node_align: str - alignment of nodes within each column. One of 'left', 'right', 'center', 'justify'. Default is 'justify'.
    """

    # data preparation
    all_nodes = []
    source_list = []
    target_list = []
    value_list = []
    node_to_column = {}

    # create flow for each step
    for i in range(len(flow_columns) - 1):
        source_col = flow_columns[i]
        target_col = flow_columns[i + 1]

        # group by and aggregate
        flow_data = (df
                    .group_by([source_col, target_col])
                    .agg(pl.len().alias("count"))
                    .filter(pl.col("count") > 0)  # exclude zero values
                    )

        # add step number to source and target to make them unique
        for row in flow_data.iter_rows(named=True):
            source_label = f"{row[source_col]}_S{i}"
            target_label = f"{row[target_col]}_S{i+1}"

            if source_label not in all_nodes:
                all_nodes.append(source_label)
                node_to_column[source_label] = source_col
            if target_label not in all_nodes:
                all_nodes.append(target_label)
                node_to_column[target_label] = target_col

            source_list.append(all_nodes.index(source_label))
            target_list.append(all_nodes.index(target_label))
            value_list.append(row["count"])

    # remove _S + number from label
    def clean_label(label):
        # use regular expression to remove _S + number from label
        return re.sub(r'_S\d+$', '', label)

    # color setting
    node_colors = []
    default_color = "rgba(201, 203, 207, 0.8)"  # default color

    if column_color_map is None:
        column_color_map = {}

    for node in all_nodes:
        column_name = node_to_column.get(node)
        color = column_color_map.get(column_name, default_color)
        node_colors.append(color)

    # create Sankey diagram
    fig = go.Figure(data=[go.Sankey(
        node=dict(
            pad=15,
            thickness=20,
            line=dict(color="black", width=0.5),
            label=[clean_label(node) for node in all_nodes],  # use clean label
            color=node_colors,
            align=node_align
        ),
        link=dict(
            source=source_list,
            target=target_list,
            value=value_list,
            color="rgba(128, 128, 128, 0.4)"  # link color
        )
    )])

    fig.update_layout(
        title_text=title,
        font_size=13,
        width=width,
        height=height

    )

    return fig
