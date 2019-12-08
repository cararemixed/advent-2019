defprotocol Intcode.IOModule do
  @type io_result(state, error_reason) ::
          {:ok, Intcode.t(), state} | {:error, error_reason}
  @type io_result(return, state, error_reason) ::
          {:ok, return, Intcode.t(), state} | {:error, error_reason}
  @callback boot(Intcode.t(), keyword) :: io_result(term, term)
  @callback read(Intcode.t(), term) :: io_result(any, term, term)
  @callback write(Intcode.t(), term, any) :: io_result(term, term)
end
