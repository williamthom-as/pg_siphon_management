defmodule PgSiphonManagement.Query.Breakdown do

  def call(raw_query) do
    case PgQuery.parse(raw_query) do
      {:ok, parsed_query} ->
        {:ok, analyse_query(parsed_query)}

      {:error, _} ->
        {:error, "invalid query"}
    end
  end

  defp analyse_query(%PgQuery.ParseResult{version: _version, stmts: stmts} = _parsed_query) do
    IO.inspect stmts
    analyse_stmt(stmts)
  end

  defp analyse_stmt([%PgQuery.RawStmt{stmt: %PgQuery.Node{node: {:select_stmt, select_stmt}}} = _stmt | rest]) do
    [
      {:select, handle_select_stmt(select_stmt)}
      | analyse_stmt(rest)
    ]
  end

  defp analyse_stmt(_node), do: []

  defp handle_select_stmt(%PgQuery.SelectStmt{target_list: _target_list, from_clause: _from_clause}) do
    %{
      from_clause: "my_table"
    }
  end

  defp handle_select_stmt(%PgQuery.SelectStmt{target_list: _target_list, from_clause: _from_clause}) do
    %{
      from_clause: "my_table"
    }
  end

end
