defmodule PgSiphonManagement.Query.Breakdown do

  require Logger

  # TODO: add vacuum/analyze.

  def call(raw_query) do
    case PgQuery.parse(raw_query) do
      {:ok, parsed_query} ->
        {:ok, analyse_query(parsed_query)}

      {:error, _} ->
        Logger.warning("Invalid query: #{raw_query}")
        {:error, "invalid query"}
    end
  end

  defp analyse_query(%PgQuery.ParseResult{version: _version, stmts: stmts} = _parsed_query) do
    analyse_stmt(stmts)
  end

  defp analyse_stmt([%PgQuery.RawStmt{stmt: %PgQuery.Node{node: {:select_stmt, select_stmt}}} = _stmt | rest]) do
    [
      {:select, handle_select_stmt(select_stmt)}
      | analyse_stmt(rest)
    ]
  end

  defp analyse_stmt([%PgQuery.RawStmt{stmt: %PgQuery.Node{node: {:update_stmt, update_stmt}}} = _stmt | rest]) do
    [
      {:update, handle_update_stmt(update_stmt)}
      | analyse_stmt(rest)
    ]
  end

  defp analyse_stmt([%PgQuery.RawStmt{stmt: %PgQuery.Node{node: {:insert_stmt, insert_stmt}}} = _stmt | rest]) do
    [
      {:insert, handle_insert_stmt(insert_stmt)}
      | analyse_stmt(rest)
    ]
  end

  defp analyse_stmt([%PgQuery.RawStmt{stmt: %PgQuery.Node{node: {:delete_stmt, delete_stmt}}} = _stmt | rest]) do
    [
      {:delete, handle_delete_stmt(delete_stmt)}
      | analyse_stmt(rest)
    ]
  end

  defp analyse_stmt(node) do
    Logger.warning("I dont know what this is, or I havent planned for it chief: #{inspect(node)}")

    []
  end

  defp handle_select_stmt(%PgQuery.SelectStmt{target_list: _target_list, from_clause: [], larg: nil, rarg: nil} = _stmt) do
    IO.puts "has nothing select"

    %{
      from_clause: nil
    }
  end

  defp handle_select_stmt(%PgQuery.SelectStmt{target_list: _target_list, from_clause: [], larg: larg, rarg: rarg} = _stmt) do
    IO.puts "has larg and rarg"

    larg_extract = handle_select_stmt(larg)
    rarg_extract = handle_select_stmt(rarg)

    %{
      from_clause: [
        larg_extract.from_clause,
        rarg_extract.from_clause
      ]
      |> List.flatten()
    }
  end

  defp handle_select_stmt(%PgQuery.SelectStmt{target_list: _target_list, from_clause: from_clause} = stmt) do
    IO.puts "in select from"
    # IO.inspect stmt

    %{
      from_clause: extract_relnames(from_clause)
    }
  end

  defp handle_update_stmt(%PgQuery.UpdateStmt{relation: %PgQuery.RangeVar{relname: table_name}} = _stmt) do
    %{
      from_clause: table_name
    }
  end

  defp handle_update_stmt(%PgQuery.UpdateStmt{} = _stmt) do
    %{
      from_clause: nil
    }
  end

  defp handle_insert_stmt(%PgQuery.InsertStmt{relation: %PgQuery.RangeVar{relname: table_name}} = _stmt) do
    %{
      from_clause: table_name
    }
  end

  defp handle_insert_stmt(%PgQuery.InsertStmt{} = _stmt) do
    %{
      from_clause: nil
    }
  end

  defp handle_delete_stmt(%PgQuery.DeleteStmt{relation: %PgQuery.RangeVar{relname: table_name}} = _stmt) do
    %{
      from_clause: table_name
    }
  end

  defp handle_delete_stmt(%PgQuery.DeleteStmt{} = _stmt) do
    %{
      from_clause: nil
    }
  end

  defp extract_relnames(nodes) do
    results = for %PgQuery.Node{} = node <- nodes do
      extract_relname(node)
    end

    results
    |> List.flatten()
  end

  def extract_relname(%PgQuery.Node{} = node) do
    case node do
      %PgQuery.Node{node: {:range_var, %PgQuery.RangeVar{relname: rel}}} ->
        rel
      %PgQuery.Node{node: {:join_expr, %PgQuery.JoinExpr{larg: larg, rarg: rarg}}} ->
        l_tbl = extract_relname(larg)
        r_tbl = extract_relname(rarg)

        [l_tbl, r_tbl]
    end
  end
end
