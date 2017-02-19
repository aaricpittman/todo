defmodule Todo.Server do
  use Supervisor

  alias Todo.List

  @index_name "index"

  def add_list(name) do
    Supervisor.start_child(__MODULE__, [name])

    get_index()
    |> List.add(name)
  end

  def find_list(name) do
    Enum.find lists(), fn(child) ->
      Todo.List.name(child) == name
    end
  end

  def delete_list(list) do
    Supervisor.terminate_child(__MODULE__, list)

    get_index
    |> List.delete(@index_name)
  end

  def get_index do
    find_list(@index_name)
  end

  def lists do
    __MODULE__
    |> Supervisor.which_children
    |> Enum.map(fn({_, child, _, _}) -> child end)
  end

  ###
  # Supervisor API
  ###

  def start_link do
    supervisor = Supervisor.start_link(__MODULE__, [], name: __MODULE__)

    Supervisor.start_child(__MODULE__, [@index_name])
    hydrate_lists

    supervisor
  end

  def init(_) do
    children = [
      worker(List, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp hydrate_lists do
    get_index()
    |> List.items
    |> Enum.each(fn(name) ->
      add_list(name)
    end)
  end
end
