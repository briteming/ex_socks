defmodule Client.LocalWorker do
  @moduledoc """
  doc
  """

  require Logger
  use GenServer

  def start(pid, socket), do: GenServer.start(__MODULE__, socket: socket, pid: pid)

  def init(socket: socket, pid: pid) do
    :inet.setopts(socket, active: 500)
    Process.send_after(self(), :reset_active, 1000)
    {:ok, %{socket: socket, pid: pid}}
  end

  # 将本地流量转发至vps
  def handle_info({:tcp, socket, <<0x05, 0x01, 0x00>>}, state) do
    :gen_tcp.send(socket, <<0x05, 0x00>>)
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    Client.RemoteWorker.send_message(state.pid, data)
    {:noreply, state}
  end

  # 设置流量限额
  def handle_info(:reset_active, state) do
    :inet.setopts(state.socket, active: 500)
    Process.send_after(self(), :reset_active, 1000)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.warn("Socket closed")
    :poolboy.checkin(:worker, state.pid)
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}
end
