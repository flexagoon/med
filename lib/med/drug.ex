defmodule Med.Drug do
  defstruct [
    :name,
    :active_ingredient,
    homeopathy: false,
    fda_approved: false,
    cochrane: 0,
    pubmed: 0,
    research: []
  ]
end
