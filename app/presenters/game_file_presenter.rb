# typed: true

class GameFilePresenter < BasePresenter
  extend T::Sig
  include ActionView::Helpers::NumberHelper

  sig { returns(String) }
  def human_file_size
    return "" unless @model.file.attached?

    T.must(number_to_human_size(@model.file.byte_size))
  end
end
