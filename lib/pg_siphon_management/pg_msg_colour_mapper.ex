defmodule PgMsgColourMapper do
  @fe_msg_colours %{
    "p" => "orange",
    "Q" => "sky",
    "P" => "emerald",
    "B" => "amber",
    "E" => "cyan",
    "D" => "violet",
    "C" => "fuschia",
    "H" => "rose",
    "S" => "red",
    "F" => "sky",
    "d" => "teal",
    "c" => "purple",
    "f" => "pink",
    "X" => "red",
    "0" => "gray"
  }

  def call(msg_type) do
    @fe_msg_colours[msg_type]
  end
end
