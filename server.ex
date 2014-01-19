defmodule Tcpserver do
  def listen(port) do
    tcp_options = [:list, {:packet, 0}, {:active, false}, {:reuseaddr, true}]
    {:ok, listen_socket} = :gen_tcp.listen(port, tcp_options)
    Logger.log("Listening on #{port}")
    do_listen(listen_socket)
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
    handle_data(socket)
  end

  def handle_data(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        parsed_request = RequestParser.parse(data)
        loaded_file = FileManager.load_file(parsed_request)
        respond_with_file(socket, loaded_file)
        :gen_tcp.close(socket)
      {:error, :closed} ->
        Logger.log("ERROR")
    end
  end

  defp respond_with_file(socket, {:ok, file_data}) do
    Logger.log("Responded 200 OK")
    :gen_tcp.send(socket, "HTTP/1.1 200 OK\nContent-Type: text;\n\n#{file_data}")
  end

  defp respond_with_file(socket, {:error, _}) do
    Logger.log("Responded 404 Not Found")
    :gen_tcp.send(socket, "HTTP/1.1 404 Not Found\nContent-Type: text;\n\nFile not found")
  end
end

defmodule FileManager do
  def load_file({:ok, path, verb}) do
    case path do
      "/" ->
        Logger.log("Loading root")
        File.read("public/index.html")
      other_path ->
        Logger.log("Loading #{other_path}")
        File.read("public#{other_path}")
    end
  end
end

defmodule RequestParser do
  def parse(request) do
    bitstring_request = list_to_bitstring(request)
    regex_captures = Regex.named_captures(%r/(?<verb>.*) (?<path>.*) .*/g, bitstring_request)
    path = Keyword.get regex_captures, :path
    verb = Keyword.get regex_captures, :verb
    {:ok, path, verb}
  end
end


defmodule Logger do
  def log(message) do
    {{year, month, day}, {hour, min, sec}} = :erlang.localtime
    IO.puts "#{year}/#{month}/#{day} #{hour}:#{min}:#{sec} #{message}"
  end
end
