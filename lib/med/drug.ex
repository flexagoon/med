defmodule Med.Drug do
  @moduledoc """
  The struct that stores all fetched information about a drug.
  """

  @type t :: %__MODULE__{}

  defstruct [
    # Basic info
    :name,
    :active_ingredient,
    :type,
    proven: false,

    # Expert and AI descriptions
    description: "",
    summary: "",

    # Criteria:
    fda_approved: false,
    cochrane: 0,
    pubmed: 0,
    who_list: false,

    # Data passing
    research: []
  ]
end
