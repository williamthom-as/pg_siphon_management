# Script to run against the proxy to monitor traffic

Mix.install([
  {:ecto_sql, "~> 3.10"},
  {:postgrex, ">= 0.0.0"}
])

defmodule Demo do
  def repo do
    Ecto.Repo.init(
      adapter: Ecto.Adapters.Postgres,
      database: "employee_management",
      username: "postgres",
      password: "postgres",
      hostname: "localhost"
    )
  end

  def create_database do
    {:ok, _} = Postgrex.start_link(
      hostname: "localhost",
      username: "postgres",
      password: "postgres",
      database: "postgres"
    )
    |> elem(1)
    |> Postgrex.query("CREATE DATABASE employee_management", [])
  rescue
    Postgrex.Error -> IO.puts("Demo already exists")
  end

  def setup_schema do
    repo = repo()

    Ecto.Adapters.SQL.query!(repo, """
    CREATE TABLE IF NOT EXISTS departments (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      location VARCHAR(100)
    )
    """)

    Ecto.Adapters.SQL.query!(repo, """
    CREATE TABLE IF NOT EXISTS employees (
      id SERIAL PRIMARY KEY,
      first_name VARCHAR(50) NOT NULL,
      last_name VARCHAR(50) NOT NULL,
      department_id INTEGER REFERENCES departments(id),
      salary DECIMAL(10,2),
      hire_date DATE
    )
    """)
  end

  def insert_sample_data do
    repo = repo()

    # Insert departments
    Ecto.Adapters.SQL.query!(repo, """
    INSERT INTO departments (name, location) VALUES
      ('Engineering', 'Building A'),
      ('Marketing', 'Building B'),
      ('Sales', 'Building C'),
      ('HR', 'Building A')
    ON CONFLICT DO NOTHING
    """)

    # Insert employees
    Ecto.Adapters.SQL.query!(repo, """
    INSERT INTO employees (first_name, last_name, department_id, salary, hire_date) VALUES
      ('John', 'Doe', 1, 75000.00, '2020-01-15'),
      ('Jane', 'Smith', 1, 82000.00, '2019-03-20'),
      ('Bob', 'Johnson', 2, 65000.00, '2021-06-10'),
      ('Alice', 'Williams', 3, 71000.00, '2020-11-30'),
      ('Charlie', 'Brown', 4, 55000.00, '2022-01-05')
    ON CONFLICT DO NOTHING
    """)
  end

  def run_complex_queries do
    repo = repo()

    IO.puts("\n--- Department-wise average salary with employee count ---")
    {:ok, result} = Ecto.Adapters.SQL.query(repo, """
    SELECT
      d.name AS department,
      COUNT(e.id) AS employee_count,
      ROUND(AVG(e.salary), 2) AS avg_salary
    FROM departments d
    LEFT JOIN employees e ON d.id = e.department_id
    GROUP BY d.name
    HAVING COUNT(e.id) > 0
    ORDER BY avg_salary DESC
    """)
    print_result(result)

    IO.puts("\n--- Employees earning more than department average ---")
    {:ok, result} = Ecto.Adapters.SQL.query(repo, """
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
    """)
    print_result(result)
  end

  def use_prepared_statements do
    repo = repo()

    IO.puts("\n--- Employees in Engineering department (using prepared statement) ---")
    {:ok, result} = Ecto.Adapters.SQL.query(repo,
      "SELECT first_name, last_name, salary FROM employees e JOIN departments d ON e.department_id = d.id WHERE d.name = $1",
      ["Engineering"]
    )
    print_result(result)

    IO.puts("\n--- Employees with salary between 60000 and 80000 (using prepared statement) ---")
    {:ok, result} = Ecto.Adapters.SQL.query(repo,
      "SELECT first_name, last_name, salary, d.name as department FROM employees e JOIN departments d ON e.department_id = d.id WHERE salary BETWEEN $1 AND $2",
      [60000, 80000]
    )
    print_result(result)
  end

  defp print_result(result) do
    IO.puts(Enum.join(result.columns, " | "))
    IO.puts(String.duplicate("-", Enum.join(result.columns, " | ") |> String.length()))

    # Print rows
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
