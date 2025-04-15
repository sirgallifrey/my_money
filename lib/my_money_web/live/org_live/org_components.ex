defmodule MyMoneyWeb.OrgLive.OrgComponents do
  use Phoenix.Component

  attr :title, :string, doc: "Title or Name of the org"
  attr :description, :string, doc: "Description of the org"
  attr :to, :string, doc: "Path to navigate on click"
  attr :action, :string, doc: "Label of the navigate link"

  def org_card(assigns) do
    ~H"""
    <div class="card bg-base-100 card-xl shadow-sm">
      <div class="card-body">
        <h2 class="card-title">{@title}</h2>
        <p>
          {@description}
        </p>
        <div class="justify-end card-actions">
          <a class="btn btn-primary" href={@to}>{@action}</a>
        </div>
      </div>
    </div>
    """
  end
end
