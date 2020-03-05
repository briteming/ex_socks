defmodule Client.LocalWorker do
  @moduledoc """
  doc
  """

  require Logger
  use GenServer

  def start(pid, socket), do: GenServer.start(__MODULE__, socket: socket, pid: pid)

  def init(socket: socket, pid: pid) do
    :inet.setopts(socket, active: :once)
    {:ok, %{socket: socket, pid: pid}}
  end

  def handle_info({:tcp, socket, data}, state) do
    :inet.setopts(socket, active: :once)
    Client.RemoteWorker.send_message(state.pid, data)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.info("Socket closed")
    :poolboy.checkin(:worker, state.pid)
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}
end