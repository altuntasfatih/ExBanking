defmodule Util do
  @precison 2

  @spec round(number()) :: float
  def round(number) when is_float(number), do: Float.round(number, @precison)
  def round(number) when is_number(number), do: number / 1.0
end
