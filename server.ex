defmodule Tcpserver do
  def listen(port) do
    tcp_options = [:list, {:packet, 0}, {:active, false}, {:reuseaddr, true}]
    {:ok, listen_socket} = :gen_tcp.listen(port, tcp_options)
    do_listen(listen_socket)
    Logger.log("Listening on #{port}")
  end

  defp do_listen(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    spawn(fn() -> ConnectionManager.handle_request(socket) end)
    do_listen(listen_socket)
  end
end

defmodule ConnectionManager do
  def handle_request(socket) do
    Logger.log("Received connection")
    spawn(fn() -> receive_data(socket) end)
    respond(socket, "HTTP/1.1 200 OK\nContent-Type: text;\n\ntest")
  end

  def receive_data(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.log(data)
        receive_data(socket)
      {:error, :closed} -> :ok
    end
  end

  defp respond(socket, data) do
    :gen_tcp.send(socket, "#{data}\n")
    :gen_tcp.close(socket)
    Logger.log("Responded: #{data}")
  end
end

defmodule RequestParser do
end

defmodule Logger do
  def log(message) do
    {{year, month, day}, {hour, min, sec}} = :erlang.localtime
    IO.puts "#{year}/#{month}/#{day} #{hour}:#{min}:#{sec} #{message}"
  end
end
