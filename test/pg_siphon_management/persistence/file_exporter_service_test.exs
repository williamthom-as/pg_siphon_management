defmodule PgSiphonManagement.Persistence.FileExporterServiceTest do
  use ExUnit.Case, async: true

  alias PgSiphonManagement.Persistence.FileExporterService
  alias Phoenix.PubSub

  @pubsub_name :broadcaster
  @pubsub_topic "message_frames"

  @file_path "test.log"

  test "writes messages to the file" do
    assert {:ok, :started} == FileExporterService.start(@file_path)
    # check cant start twice
    {:error, :already_started_export} == FileExporterService.start(@file_path)

    # send msg
    PubSub.broadcast(@pubsub_name, @pubsub_topic, {:notify, "test message 1"})
    PubSub.broadcast(@pubsub_name, @pubsub_topic, {:notify, "test message 2"})

    # wait for a bit
    :timer.sleep(100)

    assert {:ok, :stopped} == FileExporterService.stop()
    assert {:error, :not_started} == FileExporterService.stop()

    {:ok, content} = File.read(@file_path)
    assert content =~ "test message 1\ntest message 2\n"

    File.rm(@file_path)
  end
end
