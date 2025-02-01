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
      {:ok,
             [
               select: [
                 %{from_clause: ["my_table"]},
                 %{from_clause: ["another_table"]}
               ]
             ]
      }
  end

  test "call/1 select returns from tables when the query is valid with join" do
    assert Breakdown.call("SELECT * FROM my_table JOIN another_table ON my_table.id = another_table.id") ==
      {:ok, [
        select: %{from_clause: ["my_table", "another_table"]}
      ]}
  end

  test "call/1 select returns from tables when the query is valid with multiple join" do
    assert Breakdown.call(
      "SELECT * FROM my_table JOIN another_table ON my_table.id = another_table.id JOIN one_another_table ON my_table.id = one_another_table.id"
    ) ==
      {:ok, [
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
    assert Breakdown.call("UPDATE my_table SET name = 'new_name', age = 30 WHERE id = 1 AND status = 'active'") == {
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

end
