defmodule SpaceImageFormat do
  defstruct [:layers, :width, :height]

  def load_image(data, width, height) do
    layer_size = width * height

    layers =
      0..(div(byte_size(data), layer_size) - 1)
      |> Enum.map(fn n ->
        String.slice(data, n * layer_size, layer_size)
        |> String.to_charlist()
        |> Enum.map(fn digit -> digit - ?0 end)
      end)

    {:ok, %SpaceImageFormat{layers: layers, width: width, height: height}}
  end

  def composite(%{layers: layers} = image) do
    layer =
      Enum.zip(layers)
      |> Enum.map(fn pixels ->
        pixels
        |> Tuple.to_list()
        |> Enum.reduce(2, fn
          color, 2 -> color
          _, foreground -> foreground
        end)
      end)

    %{image | layers: [layer]}
  end

  def render(%{layers: [image], width: width}) do
    output =
      image
      |> Enum.with_index()
      |> Enum.map(fn {pixel, index} ->
        cell =
          case pixel do
            0 -> " "
            1 -> "#"
          end

        nl = if index > 0 && rem(index, width) == width - 1, do: "\n", else: ""
        [cell, nl]
      end)

    IO.iodata_to_binary(output)
  end

  def render(image) do
    image |> composite |> render
  end
end
