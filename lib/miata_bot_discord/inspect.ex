defimpl Inspect, for: Nostrum.Struct.Guild do
  def inspect(%{id: id}, _opts) do
    "#Guild<#{id}>"
  end
end
