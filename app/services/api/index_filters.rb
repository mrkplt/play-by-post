# typed: strict
# frozen_string_literal: true

module Api
  # Applies the /api index query params to a Page or NotebookEntry relation:
  # title search, creator/editor filters, a created-at floor, and sort order.
  # Shared by both index actions so the two surfaces filter identically; the
  # model-specific pieces are supplied by the model as the `title_matching`,
  # `created_by`, `edited_by` and `created_after` scopes this object chains —
  # each a no-op on a nil argument, so an absent param drops out of the chain.
  #
  # Params it reads (all optional):
  #   title      — case-insensitive substring match on title
  #   created_by — creator's user id (the editor of the record's first version)
  #   edited_by  — user id appearing anywhere in the record's version history
  #   since      — ISO-8601 timestamp; keep records created at/after it
  #   order      — "newest" (default) or "oldest", by created_at
  #
  # created_by and edited_by are independent and may be combined (records this
  # user created AND some — possibly other — user later touched, and so on).
  #
  # An unparseable `since` and an unrecognised `order` are ignored rather than
  # erroring: the surface degrades to the unfiltered/default-ordered list rather
  # than 400-ing a machine client on a malformed optional param.
  class IndexFilters
    extend T::Sig

    DEFAULT_ORDER = "newest"
    ORDER_DIRECTIONS = T.let({ "newest" => :desc, "oldest" => :asc }.freeze, T::Hash[String, Symbol])

    sig { params(relation: T.untyped, params: ActionController::Parameters).void }
    def initialize(relation, params)
      @relation = relation
      @params = params
    end

    # The filter scopes each no-op on a nil argument (an absent/blank param is no
    # filter), so the chain reads straight through with no per-param branching and
    # narrows only by what the client actually asked for.
    sig { returns(T.untyped) }
    def apply
      @relation
        .title_matching(title)
        .created_by(created_by)
        .edited_by(edited_by)
        .created_after(since)
        .order(created_at: direction)
    end

    private

    # Readers normalise a blank param to nil, so `apply` treats "no value" and
    # "empty string" identically — a `?title=` with nothing after it is not a
    # filter for the empty string, it is no filter at all.
    sig { returns(T.nilable(String)) }
    def title
      @params[:title].presence
    end

    sig { returns(T.nilable(String)) }
    def created_by
      @params[:created_by].presence
    end

    sig { returns(T.nilable(String)) }
    def edited_by
      @params[:edited_by].presence
    end

    # A parseable ISO-8601 timestamp, or nil when the param is absent, blank, or
    # unparseable — a missing/garbage timestamp is no filter rather than a 400.
    sig { returns(T.nilable(Time)) }
    def since
      Time.zone.iso8601(@params[:since])
    rescue ArgumentError
      nil
    end

    sig { returns(Symbol) }
    def direction
      ORDER_DIRECTIONS.fetch(@params[:order], ORDER_DIRECTIONS.fetch(DEFAULT_ORDER))
    end
  end
end
