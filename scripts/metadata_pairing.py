# -*- coding: utf-8 -*-
"""
Utility functions for building paired (heat vs control) metadata DataFrames
from a flat per-sample metadata table.

This module centralizes the `create_paired_metadata` implementation that was
previously duplicated across multiple notebooks under notebooks/metadata/.
"""
from typing import Any
import polars as pl


def create_paired_metadata(
    combined_df: pl.DataFrame,
    defined_sample_pairs: list[tuple[str, str]],
    sample_id_column_name: str = "accession",
) -> pl.DataFrame | None:
    """
    based on the specified sample pairs, create a paired metadata dataframe.

    compare the metadata of each pair, and if the values are different, create a Struct like {'heat': heat_value, 'control': control_value}.
    Then, convert all Struct columns to a string in the format of 'heat_value vs control_value'.

    Args:
        combined_df: the input dataframe containing the metadata of all samples.
        defined_sample_pairs: a list of tuples, each tuple contains (heat_sample_id, control_sample_id).
        sample_id_column_name: the name of the column in combined_df that contains the sample IDs used in defined_sample_pairs.

    Returns:
        a Polars dataframe containing the paired metadata. None if no pairs are processed.
    """
    # Allow Any values in each row (so nested dict is OK)
    output_rows: list[dict[str, Any]] = []

    # determine the columns to compare (excluding the sample ID column used for pairing)
    columns_to_compare = [
        col_name for col_name in combined_df.columns
        if col_name != sample_id_column_name
    ]

    for heat_id, control_id in defined_sample_pairs:
        heat_sample_data = combined_df.filter(pl.col(sample_id_column_name) == heat_id)
        control_sample_data = combined_df.filter(pl.col(sample_id_column_name) == control_id)

        if heat_sample_data.height == 1 and control_sample_data.height == 1:
            new_row: dict[str, Any] = {
                "sample_heat_id": heat_id,
                "sample_control_id": control_id
            }

            for col_name in columns_to_compare:
                val_heat = heat_sample_data.select(pl.col(col_name)).item()
                val_control = control_sample_data.select(pl.col(col_name)).item()

                # Always store as a struct-like dictionary for consistent schema during DataFrame creation.
                # The subsequent transformation step will handle the final display format.
                new_row[col_name] = {"heat": val_heat, "control": val_control}
            output_rows.append(new_row)

    if not output_rows:
        return None

    paired_df = pl.DataFrame(output_rows, infer_schema_length=1000)

    # Transform Struct columns to desired string representation
    struct_columns_to_transform = []
    for col_name in paired_df.columns:
        # Check if the column dtype is Struct.
        # Using hasattr to check for 'fields' attribute is a robust way for Struct-like types.
        if hasattr(paired_df[col_name].dtype, 'fields'):
            struct_columns_to_transform.append(col_name)

    if struct_columns_to_transform:
        transform_expressions = []
        for col_name in struct_columns_to_transform:
            expr = (
                pl.when(
                    # Compare heat and control fields, considering nulls as equal
                    pl.col(col_name).struct.field("heat").eq_missing(pl.col(col_name).struct.field("control"))
                )
                .then(
                    # If equal, use the heat value (cast to Utf8, fill nulls with "null" string)
                    pl.col(col_name).struct.field("heat").cast(pl.Utf8).fill_null(pl.lit("null"))
                )
                .otherwise(
                    # If different, create "heat_value vs control_value" string
                    pl.col(col_name).struct.field("heat").cast(pl.Utf8).fill_null(pl.lit(None)) +
                    pl.lit(" vs ") +
                    pl.col(col_name).struct.field("control").cast(pl.Utf8).fill_null(pl.lit(None))
                )
                .alias(col_name)
            )
            transform_expressions.append(expr)

        paired_df = paired_df.with_columns(transform_expressions)

    return paired_df
