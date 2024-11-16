defmodule Med.Drug do
  defstruct [
    :name,
    :active_ingredient,
    homeopathy: false,
    fda_approved: false
  ]
end
