defmodule Med.Drug do
  @moduledoc """
  The struct that stores all fetched information about a drug.
  """

  @type t :: %__MODULE__{}

  defstruct [
    :name,
    :active_ingredient,
    homeopathy: false,
    fda_approved: false,
    research: "",
    cochrane: 0,
    pubmed: 0,
    summary: "",
    research_score: 0
  ]
end
