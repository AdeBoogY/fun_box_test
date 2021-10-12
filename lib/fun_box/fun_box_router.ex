defmodule FunBox.Router do
  use Plug.Router
  use Plug.Debugger
  require Logger

plug(Plug.Logger, log: :debug)

plug(:match)

plug(:dispatch)


get "/visited_domains" do
	response = 
	try do
		{:ok, redis_conn} = Redix.start_link(host: "localhost", port: 6379)
		query_stat = Plug.Conn.fetch_query_params(conn, [])
		query_params = Map.get(query_stat, :params)
		from = String.to_integer(Map.get(query_params,"from"))
		to = String.to_integer(Map.get(query_params,"to"))
		domains = get_domains(from, to, redis_conn)
		Poison.encode!(%{"domains" => domains, "status" => "ok"})
	rescue
		error ->
		IO.inspect(error)
		Poison.encode!(%{"status" => "error"})
	end
    send_resp(conn, 200, response)
end


post "/visited_links" do
	{:ok, body, conn} = read_body(conn)
	response =
	try do
		{:ok, redis_conn} = Redix.start_link(host: "localhost", port: 6379)
		body = Poison.decode!(body)
		request_time = :os.system_time(:second)
		links_list = Map.get(body, "links")
		take_domains(links_list, request_time, redis_conn)
		Poison.encode!(%{"status" => "ok"})
	rescue
		_ -> 
		Poison.encode!(%{"status" => "error"}) 
	end
	send_resp(conn, 201, response)
end


match _ do

	send_resp(conn, 404, "not found")

end

def take_domains(list, request_time, redis_conn) do
	take_domains(list, request_time , redis_conn, [])
end

def take_domains([], request_time, redis_conn, accum) do
	Redix.command!(redis_conn, ["SET", request_time, accum])
	accum
end

def take_domains([head | tail], request_time, redis_conn, accum) do
	decoded_url = URI.parse(head)
	domain = 
	case Map.get(decoded_url, :host) do
		:nil -> Map.get(decoded_url, :path)
		value -> value	
	end
	new_accum = 
	case Enum.member?(accum, domain) do
		true -> 
			accum
		false -> 
			case tail == [] do
				true -> accum ++ [domain]
				false -> accum ++ [domain] ++ ["/"]
			end
	end
	take_domains(tail, request_time, redis_conn, new_accum)
end

def get_domains(from, to, redis_conn) do
	keys = Redix.command!(redis_conn, ["KEYS", "*"])
	scan_domains(from, to, keys, redis_conn, [])
end

def scan_domains(_, _, [], _, accum) do
	accum
end

def scan_domains(from, to, [head | tail], redis_conn, accum) do
	time = 
	try do
		String.to_integer(head)
	rescue
		_ -> 0	
	end
	case time >= from and time <= to do
		true -> 
			domains = Redix.command!(redis_conn, ["GET", time])
			domains_splited = 
				case domains == :nil do
					true -> []
					false -> String.split(domains, "/")
				end
			new_accum = remove_dublicates(domains_splited, accum)
			scan_domains(from, to, tail, redis_conn, new_accum)
		false -> 
			scan_domains(from, to, tail, redis_conn, accum)
	end
end

def remove_dublicates([], accum) do
	accum
end

def remove_dublicates([head | tail], accum) do
	case Enum.member?(accum, head) do
		true -> remove_dublicates(tail, accum)
		false -> remove_dublicates(tail, accum ++ [head])	
	end
end

end
