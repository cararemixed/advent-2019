defprotocol Intcode.IOModule do
  @type boot_result(state) ::
          {:ok, Intcode.t(), state} | {:error, term}

  @type write_result(state) ::
          {:ok, Intcode.t(), state} | {:error, term}

  @type read_result(return, state) ::
          {:ok, return, Intcode.t(), state} | {:error, term}

  @callback boot(Intcode.t(), keyword) :: boot_result(term)
  @callback read(Intcode.t(), term) :: read_result(any, term)
  @callback write(Intcode.t(), term, any) :: write_result(term)
end
