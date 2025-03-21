Mix.install([
  {:postgrex, ">= 0.0.0"}
])

defmodule Demo do
  def connect_postgres do
    {:ok, conn} = Postgrex.start_link(
      hostname: "localhost",
      port: 1337,
      username: "postgres",
      password: "postgres",
      database: "postgres"
    )
    conn
  end

  def connect_employee_db do
    {:ok, conn} = Postgrex.start_link(
      hostname: "localhost",
      port: 1337,
      username: "postgres",
      password: "postgres",
      database: "employee_management"
    )
    conn
  end

  def create_database do
    conn = connect_postgres()
    case Postgrex.query(conn, "CREATE DATABASE employee_management", []) do
      {:ok, _} -> IO.puts("Database created")
      {:error, %{postgres: %{code: :duplicate_database}}} -> IO.puts("Database already exists")
      {:error, error} -> IO.inspect(error, label: "Error creating database")
    end
    GenServer.stop(conn)
  end

  def setup_schema do
    conn = connect_employee_db()

    Postgrex.query!(conn, """
    CREATE TABLE IF NOT EXISTS departments (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      location VARCHAR(100)
    )
    """, [])

    Postgrex.query!(conn, """
    CREATE TABLE IF NOT EXISTS employees (
      id SERIAL PRIMARY KEY,
      first_name VARCHAR(50) NOT NULL,
      last_name VARCHAR(50) NOT NULL,
      department_id INTEGER REFERENCES departments(id),
      salary DECIMAL(10,2),
      hire_date DATE
    )
    """, [])

    GenServer.stop(conn)
  end

  def insert_sample_data do
    conn = connect_employee_db()

    # Insert departments
    Postgrex.query!(conn, """
    INSERT INTO departments (name, location) VALUES
      ('Engineering', 'Building A'),
      ('Marketing', 'Building B'),
      ('Sales', 'Building C'),
      ('HR', 'Building A')
    ON CONFLICT DO NOTHING
    """, [])

    # Insert employees
    Postgrex.query!(conn, """
    INSERT INTO employees (first_name, last_name, department_id, salary, hire_date) VALUES
      ($1, $2, $3, $4, $5),
      ($6, $7, $8, $9, $10),
      ($11, $12, $13, $14, $15),
      ($16, $17, $18, $19, $20),
      ($21, $22, $23, $24, $25)
    ON CONFLICT DO NOTHING
    """, [
      "John", "Doe", 1, Decimal.new("75000.00"), ~D[2020-01-15],
      "Jane", "Smith", 1, Decimal.new("82000.00"), ~D[2019-03-20],
      "Bob", "Johnson", 2, Decimal.new("65000.00"), ~D[2021-06-10],
      "Alice", "Williams", 3, Decimal.new("71000.00"), ~D[2020-11-30],
      "Charlie", "Brown", 4, Decimal.new("55000.00"), ~D[2022-01-05]
    ])

    GenServer.stop(conn)
  end

  def run_complex_queries do
    conn = connect_employee_db()

    IO.puts("\n--- Department-wise average salary with employee count ---")
    {:ok, result} = Postgrex.query(conn, """
    SELECT
      d.name AS department,
      COUNT(e.id) AS employee_count,
      ROUND(AVG(e.salary), 2) AS avg_salary
    FROM departments d
    LEFT JOIN employees e ON d.id = e.department_id
    GROUP BY d.name
    HAVING COUNT(e.id) > 0
    ORDER BY avg_salary DESC
    """, [])
    print_result(result)

    IO.puts("\n--- Employees earning more than department average ---")
    {:ok, result} = Postgrex.query(conn, """
    WITH dept_avg AS (
      SELECT department_id, AVG(salary) AS avg_salary
      FROM employees
      GROUP BY department_id
    )
    SELECT
      e.first_name,
      e.last_name,
      e.salary,
      d.name AS department,
      ROUND(da.avg_salary, 2) AS dept_avg_salary
    FROM employees e
    JOIN departments d ON e.department_id = d.id
    JOIN dept_avg da ON e.department_id = da.department_id
    WHERE e.salary > da.avg_salary
    """, [])
    print_result(result)

    GenServer.stop(conn)
  end

  def use_prepared_statements do
    conn = connect_employee_db()

    # Prepare statements
    :ok = Postgrex.prepare(conn, "find_eng", """
      SELECT first_name, last_name, salary
      FROM employees e
      JOIN departments d ON e.department_id = d.id
      WHERE d.name = $1
    """)

    :ok = Postgrex.prepare(conn, "find_salary_range", """
      SELECT first_name, last_name, salary, d.name as department
      FROM employees e
      JOIN departments d ON e.department_id = d.id
      WHERE salary BETWEEN $1 AND $2
    """)

    IO.puts("\n--- Employees in Engineering department (using prepared statement) ---")
    {:ok, result} = Postgrex.execute(conn, "find_eng", ["Engineering"])
    print_result(result)

    IO.puts("\n--- Employees with salary between 60000 and 80000 (using prepared statement) ---")
    {:ok, result} = Postgrex.execute(conn, "find_salary_range", [
      Decimal.new("60000.00"),
      Decimal.new("80000.00")
    ])
    print_result(result)

    # Close prepared statements and connection
    :ok = Postgrex.close(conn, "find_eng")
    :ok = Postgrex.close(conn, "find_salary_range")
    GenServer.stop(conn)
  end

  defp print_result(result) do
    IO.puts(Enum.join(result.columns, " | "))
    IO.puts(String.duplicate("-", Enum.join(result.columns, " | ") |> String.length()))

    Enum.each(result.rows, fn row ->
      IO.puts(Enum.join(row, " | "))
    end)
  end
end

Demo.create_database()
Demo.setup_schema()
Demo.insert_sample_data()
Demo.run_complex_queries()
Demo.use_prepared_statements()
