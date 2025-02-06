defmodule PgSiphonManagement.Query.BreakdownTest do
  use ExUnit.Case

  alias PgSiphonManagement.Query.Breakdown

  test "call/1 select returns from table when the query is valid" do
    assert Breakdown.call("SELECT * FROM my_table") == {
             :ok,
             [select: %{from_clause: ["my_table"]}]
           }
  end

  test "call/1 select returns from tables when the query is valid with union" do
    assert Breakdown.call("SELECT * FROM my_table UNION SELECT * FROM another_table") ==
             {
               :ok,
               [
                 select: %{from_clause: ["my_table", "another_table"]}
               ]
             }
  end

  test "call/1 select returns from tables when the query is valid with join" do
    assert Breakdown.call(
             "SELECT * FROM my_table JOIN another_table ON my_table.id = another_table.id"
           ) ==
             {:ok,
              [
                select: %{from_clause: ["my_table", "another_table"]}
              ]}
  end

  test "call/1 select returns from tables when the query is valid with multiple join" do
    assert Breakdown.call(
             "SELECT * FROM my_table JOIN another_table ON my_table.id = another_table.id JOIN one_another_table ON my_table.id = one_another_table.id"
           ) ==
             {:ok,
              [
                select: %{from_clause: ["my_table", "another_table", "one_another_table"]}
              ]}
  end

  test "call/1 selectreturns error when the query is invalid" do
    assert Breakdown.call("SELECT * FROM") == {:error, "invalid query"}
  end

  test "call/1 update returns from table when the query is valid" do
    assert Breakdown.call("UPDATE my_table SET name = 'new_name'") == {
             :ok,
             [update: %{from_clause: "my_table"}]
           }
  end

  test "call/1 update returns from table when the query is valid with multiple conditions" do
    assert Breakdown.call(
             "UPDATE my_table SET name = 'new_name', age = 30 WHERE id = 1 AND status = 'active'"
           ) == {
             :ok,
             [update: %{from_clause: "my_table"}]
           }
  end

  test "call/1 update returns error when the query is invalid" do
    assert Breakdown.call("UPDATE") == {:error, "invalid query"}
  end

  test "call/1 returns table for valid insert query" do
    assert Breakdown.call("INSERT INTO my_table (name, age) VALUES ('new_name', 30)") == {
             :ok,
             [insert: %{from_clause: "my_table"}]
           }
  end

  test "call/1 returns table for valid delete query" do
    assert Breakdown.call("DELETE FROM my_table WHERE id = 1") == {
             :ok,
             [delete: %{from_clause: "my_table"}]
           }
  end

  test "call/1 returns empty table for query that is valid, but doesnt reference a table" do
    assert Breakdown.call("SELECT 1") == {:ok, [select: %{from_clause: nil}]}
  end

  test "call/1 returns empty table for query that is valid, but doesnt reference a table with union" do
    assert Breakdown.call("SELECT 1 UNION SELECT 2") == {
             :ok,
             [select: %{from_clause: [nil, nil]}]
           }
  end

  test "call/1 returns empty table for vacuum" do
    assert Breakdown.call("ANALYZE VERBOSE my_table") == {:ok, []}
  end

  test "call/1 returns empty table for analydfdsfze" do
    assert Breakdown.call("SELECT
      COUNT(*)
    FROM
      (
        SELECT
          DISTINCT \"table_a\".\"id\"
        FROM
          \"table_a\"
          INNER JOIN \"table_b\" ON \"table_b\".\"id\" = \"table_a\".\"u_id\"
          LEFT OUTER JOIN \"table_c\" ON \"table_c\".\"id\" = \"table_a\".\"a_id\"
          LEFT OUTER JOIN \"table_d\" ON \"table_d\".\"discarded_at\" IS NULL
          AND \"table_d\".\"id\" = \"table_a\".\"py_id\"
          LEFT OUTER JOIN \"asa\" ON \"asa\".\"record_type\" = $1
          AND \"asa\".\"name\" = $2
          AND \"asa\".\"r_id\" = \"table_a\".\"id\"
          LEFT OUTER JOIN \"asb\" ON \"asb\".\"id\" = \"asa\".\"b_id\"
          LEFT OUTER JOIN \"table_e\" ON \"table_e\".\"d_at\" IS NULL
          AND \"table_e\".\"id\" = \"table_a\".\"pa_id\"
          LEFT OUTER JOIN \"table_d\" \"table_d_table_e\" ON \"table_d_table_e\".\"d_at\" IS NULL
          AND \"table_d_table_e\".\"id\" = \"table_e\".\"py_id\"
        WHERE
          \"table_a\".\"parent_id\" IS NULL
          AND \"table_a\".\"a_id\" = $3
      ) subquery_for_count") ==
             {:ok,
              [
                select: %{
                  from_clause: [
                    "table_a",
                    "table_b",
                    "table_c",
                    "table_d",
                    "asa",
                    "asb",
                    "table_e",
                    "table_d"
                  ]
                }
              ]}
  end
end
