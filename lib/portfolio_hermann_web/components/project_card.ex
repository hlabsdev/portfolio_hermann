defmodule PortfolioHermannWeb.ProjectCard do
  use Phoenix.Component

  attr :title, :string, required: true
  attr :tech, :string, required: true
  attr :desc, :string, required: true

  def project_card(assigns) do
    ~H"""
    <div class="card-soft hover:shadow-xl transition duration-300">
      <h2 class="text-xl font-bold mb-2"><%= @title %></h2>
      <p class="text-sm text-gray-600 mb-2 italic"><%= @tech %></p>
      <p class="text-base"><%= @desc %></p>
    </div>
    """
  end
end
