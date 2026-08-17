# typed: true

# CRU over the token's game's pages, addressed by slug. Pages are readable by
# any non-banned member and writable only by the GM (PagePolicy), so #show
# lets `authorize @page` decide per-record (draft pages stay GM-only even
# though the resource as a whole is member-readable) while #create/#update
# are GM-only. Strong params permit only title and body — the slug is
# server-assigned and drafting is out of this API's scope.
module Api
  class PagesController < Api::BaseController
    extend T::Sig

    sig { void }
    def index
      authorize current_game.pages.new, :index?
      @pages = T.let(visible_pages.to_a, T.nilable(T::Array[Page]))
    end

    sig { void }
    def show
      @page = T.let(find_page, T.nilable(Page))
      authorize @page
    end

    sig { void }
    def create
      @page = T.let(current_game.pages.new(page_params), T.nilable(Page))
      page = T.must(@page)
      authorize page

      if page.save
        render :create, status: :created
      else
        render_errors(page)
      end
    end

    sig { void }
    def update
      @page = T.let(find_page, T.nilable(Page))
      page = T.must(@page)
      authorize page

      if page.update(page_params)
        render :update
      else
        render_errors(page)
      end
    end

    private

    # The pages this token's user may see: a GM sees every page including drafts;
    # any other member sees only published pages, so an in-progress draft never
    # leaks through the list even though the list itself is member-readable. This
    # mirrors GameShowPresenter#visible_pages — the list-level draft gate that the
    # per-record PagePolicy#show? enforces for a single page.
    sig { returns(T.untyped) }
    def visible_pages
      scope = current_game.pages
      PagePolicy.new(current_data_user, scope.new).manage? ? scope : scope.published
    end

    sig { returns(Page) }
    def find_page
      current_game.pages.find_by!(slug: params[:slug])
    end

    sig { returns(ActionController::Parameters) }
    def page_params
      params.require(:page).permit(:title, :body)
    end
  end
end
