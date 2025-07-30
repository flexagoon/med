defmodule Med do
  @moduledoc """
  The main module of the application, provides the `check/1` function.
  """

  alias Med.Data.FDA
  alias Med.Data.LLM
  alias Med.Data.MedIQLab
  alias Med.Data.PubMed

  @spec check(String.t(), pid()) :: Med.Drug.t() | nil
  def check(name, live_pid) do
    name
    |> MedIQLab.fetch()
    |> fetch_info(live_pid)
  end

  def cache(nil), do: nil

  @seconds_in_half_year 6 * 30 * 24 * 60 * 60

  @spec cache(Med.Drug.t()) :: Med.Drug.t()
  def cache(drug) do
    data = :erlang.term_to_binary(drug)
    Redix.command!(:redix, ["SET", drug.name, data, "EX", @seconds_in_half_year])

    drug
  end

  defp get_cache(name) do
    case Redix.command!(:redix, ["GET", name]) do
      nil -> nil
      drug -> :erlang.binary_to_term(drug)
    end
  end

  defp fetch_info(nil, _live_pid), do: nil
  defp fetch_info(%{type: :homeopathy} = drug, _live_pid), do: drug
  defp fetch_info(%{active_ingredient: nil} = drug, _live_pid), do: drug

  defp fetch_info(drug, live_pid) do
    case get_cache(drug.name) do
      nil ->
        drug
        |> FDA.get_approval()
        |> PubMed.get_research()
        |> LLM.summarize_research(live_pid)
        |> cache()

      %{summary: "", research: [_hd | _tl]} = drug ->
        drug
        |> LLM.summarize_research(live_pid)
        |> cache()

      drug ->
        drug
    end
  end
end
