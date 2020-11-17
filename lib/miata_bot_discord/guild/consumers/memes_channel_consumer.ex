def handle_event({:MESSAGE_CREATE, %{channel_id: @memes_channel_id} = message, _state}) do
  CopyPastaWorker.activity(message)
  :noop
end
