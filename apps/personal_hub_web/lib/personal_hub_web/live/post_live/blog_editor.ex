defmodule PersonalHubWeb.PostLive.BlogEditor do
  @moduledoc """
  LiveComponent: split-pane Markdown blog editor with toolbar and live preview.
  """
  use PersonalHubWeb, :live_component

  alias PersonalHub.{Markdown, BlogThemes}

  @toolbar_items [
    %{id: "h1", icon: "H1", label: "Heading 1", syntax: "# ", hint: "# Heading text", type: :line_prefix},
    %{id: "h2", icon: "H2", label: "Heading 2", syntax: "## ", hint: "## Subheading", type: :line_prefix},
    %{id: "h3", icon: "H3", label: "Heading 3", syntax: "### ", hint: "### Sub-subheading", type: :line_prefix},
    %{id: "bold", icon: "B", label: "Bold", syntax: {"**", "**"}, hint: "**bold text**", type: :wrap},
    %{id: "italic", icon: "I", label: "Italic", syntax: {"*", "*"}, hint: "*italic text*", type: :wrap},
    %{id: "strike", icon: "S", label: "Strikethrough", syntax: {"~~", "~~"}, hint: "~~struck text~~", type: :wrap},
    %{id: "code", icon: "<>", label: "Inline Code", syntax: {"`", "`"}, hint: "`inline code`", type: :wrap},
    %{id: "codeblock", icon: "{ }", label: "Code Block", syntax: "```\n", hint: "```lang\\ncode\\n```", type: :block},
    %{id: "link", icon: "🔗", label: "Link", syntax: {"[", "](url)"}, hint: "[text](url)", type: :wrap},
    %{id: "image", icon: "🖼", label: "Image", syntax: "![alt](url)", hint: "![alt text](image-url)", type: :insert},
    %{id: "ul", icon: "•", label: "Bullet List", syntax: "- ", hint: "- List item", type: :line_prefix},
    %{id: "ol", icon: "1.", label: "Numbered List", syntax: "1. ", hint: "1. List item", type: :line_prefix},
    %{id: "quote", icon: "❝", label: "Blockquote", syntax: "> ", hint: "> Quoted text", type: :line_prefix},
    %{id: "hr", icon: "—", label: "Horizontal Rule", syntax: "\n---\n", hint: "--- (on its own line)", type: :insert},
    %{id: "table", icon: "⊞", label: "Table", syntax: "| Header | Header |\n| ------ | ------ |\n| Cell   | Cell   |", hint: "Pipe-delimited table", type: :insert},
    %{id: "video", icon: "▶", label: "Video Embed", syntax: "https://youtube.com/watch?v=ID", hint: "Paste YouTube/Vimeo URL on its own line", type: :insert},
    %{id: "audio", icon: "♪", label: "Audio", syntax: "!audio[caption](url)", hint: "!audio[caption](audio-url)", type: :insert}
  ]

  def mount(socket) do
    {:ok,
     assign(socket,
       preview_html: "",
       theme_id: "minimal",
       themes: BlogThemes.all(),
       toolbar: @toolbar_items,
       active_tooltip: nil
     )}
  end

  def update(assigns, socket) do
    body = get_in(assigns, [:form]) && assigns.form[:body].value || ""

    preview_html =
      case Markdown.to_html(body) do
        {:safe, html} -> html
        _ -> ""
      end

    theme = BlogThemes.get(socket.assigns[:theme_id] || "minimal")
    theme_css = BlogThemes.to_scoped_css(theme)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       preview_html: preview_html,
       theme_css: theme_css,
       theme: theme
     )}
  end

  def handle_event("toolbar_click", %{"action" => action_json}, socket) do
    item = Enum.find(@toolbar_items, fn i -> i.id == action_json end)

    if item do
      payload =
        case item.type do
          :wrap ->
            {before, after_text} = item.syntax
            %{type: "wrap", before: before, after: after_text}

          :line_prefix ->
            %{type: "prefix", prefix: item.syntax}

          :block ->
            %{type: "block", syntax: item.syntax}

          :insert ->
            %{type: "insert", text: item.syntax}
        end

      {:noreply, push_event(socket, "blog:insert", payload)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("change_theme", %{"theme_id" => theme_id}, socket) do
    theme = BlogThemes.get(theme_id)
    theme_css = BlogThemes.to_scoped_css(theme)

    {:noreply,
     assign(socket,
       theme_id: theme_id,
       theme: theme,
       theme_css: theme_css
     )}
  end

  def handle_event("toggle_tooltip", %{"item" => item_id}, socket) do
    active =
      if socket.assigns.active_tooltip == item_id,
        do: nil,
        else: item_id

    {:noreply, assign(socket, active_tooltip: active)}
  end

  def handle_event("preview_update", %{"body" => body}, socket) do
    preview_html =
      case Markdown.to_html(body) do
        {:safe, html} -> html
        _ -> ""
      end

    {:noreply, assign(socket, preview_html: preview_html)}
  end

  def render(assigns) do
    ~H"""
    <div id="blog-editor" class="blog-editor-container" phx-hook="BlogEditor" phx-target={@myself}>
      <%!-- Toolbar --%>
      <div class="blog-toolbar">
        <div class="toolbar-group">
          <%= for item <- @toolbar do %>
            <div class="toolbar-btn-wrap">
              <button
                type="button"
                class="toolbar-btn"
                title={item.label}
                phx-click="toolbar_click"
                phx-value-action={item.id}
                phx-target={@myself}
              >
                <span class="toolbar-icon"><%= item.icon %></span>
              </button>
              <button
                type="button"
                class="toolbar-hint-btn"
                phx-click="toggle_tooltip"
                phx-value-item={item.id}
                phx-target={@myself}
                title="How to use"
              >
                ?
              </button>
              <%= if @active_tooltip == item.id do %>
                <div class="toolbar-tooltip">
                  <div class="tooltip-label"><%= item.label %></div>
                  <code class="tooltip-syntax"><%= item.hint %></code>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <div class="toolbar-right">
          <select
            class="theme-select"
            phx-change="change_theme"
            phx-target={@myself}
            name="theme_id"
          >
            <%= for theme <- @themes do %>
              <option value={theme.id} selected={theme.id == @theme_id}>
                {theme.name}
              </option>
            <% end %>
          </select>
        </div>
      </div>

      <%!-- Split Pane --%>
      <div class="editor-split">
        <%!-- Left: Markdown textarea --%>
        <div class="editor-pane">
          <div class="pane-header">
            <.icon name="hero-pencil-square" class="size-4" />
            <span>Markdown</span>
          </div>
          <textarea
            id="blog-textarea"
            name={@form[:body].name}
            class="editor-textarea"
            placeholder="Write your blog post in Markdown..."
            phx-debounce="300"
            phx-keyup="preview_update"
            phx-value-body=""
            phx-target={@myself}
          ><%= @form[:body].value %></textarea>
          <input type="hidden" name={@form[:theme_id].name} value={@theme_id} />
        </div>

        <%!-- Right: Live Preview --%>
        <div class="preview-pane">
          <div class="pane-header">
            <.icon name="hero-eye" class="size-4" />
            <span>Preview — {(@theme && @theme.name) || "Minimal"}</span>
          </div>
          <div class="preview-scroll">
            <%= Phoenix.HTML.raw(@theme_css) %>
            <div class="blog-content">
              <%= if @preview_html == "" do %>
                <p class="preview-empty">Your formatted blog post will appear here…</p>
              <% else %>
                <%= Phoenix.HTML.raw(@preview_html) %>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
