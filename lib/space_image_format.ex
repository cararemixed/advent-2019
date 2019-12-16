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
        |> Tuple.to_list
        |> Enum.reduce(2, fn
          color, 2 -> color
          _, foreground -> foreground
        end)
      end)
    %{image | layers: [layer]}
  end

  def display(%{layers: [image], width: width}) do
    image |> Enum.with_index |> Enum.each(fn {pixel, index} ->
      if index > 0 && rem(index, width) == 0, do: IO.write("\n")
      case pixel do
        0 -> IO.write(" ")
        1 -> IO.write("#")
      end
    end)
    IO.write("\n")
  end

  def display(image) do
    image |> composite |> display
  end
end
