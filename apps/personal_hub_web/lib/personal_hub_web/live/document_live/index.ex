defmodule PersonalHubWeb.DocumentLive.Index do
  use PersonalHubWeb, :live_view

  alias PersonalHub.DocumentParser

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Document Viewer")
     |> assign(parsed: nil)
     |> assign(filename: nil)
     |> assign(error: nil)
     |> assign(active_sheet: 0)
     |> allow_upload(:document,
       accept: ~w(.pdf .xlsx .docx .pptx),
       max_entries: 1,
       max_file_size: 20_000_000
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("upload", _params, socket) do
    [result] =
      consume_uploaded_entries(socket, :document, fn %{path: path}, entry ->
        binary = File.read!(path)
        parsed = DocumentParser.parse(binary, entry.client_name)
        {:ok, {entry.client_name, parsed}}
      end)

    {filename, parsed_result} = result

    case parsed_result do
      {:ok, type, data} ->
        {:noreply,
         socket
         |> assign(parsed: {type, data})
         |> assign(filename: filename)
         |> assign(error: nil)
         |> assign(active_sheet: 0)}

      {:error, message} ->
        {:noreply,
         socket
         |> assign(error: message)
         |> assign(parsed: nil)
         |> assign(filename: nil)}
    end
  end

  @impl true
  def handle_event("switch_sheet", %{"index" => index}, socket) do
    {:noreply, assign(socket, active_sheet: String.to_integer(index))}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply,
     socket
     |> assign(parsed: nil)
     |> assign(filename: nil)
     |> assign(error: nil)
     |> assign(active_sheet: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-5xl mx-auto space-y-6">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Dashboard
        </.link>

        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-semibold text-gray-900">Document Viewer</h1>
          <%= if @parsed do %>
            <button
              phx-click="clear"
              class="px-4 py-2 rounded-xl text-sm font-medium text-gray-600 border border-gray-200 hover:bg-gray-50 transition-colors"
            >
              Upload New
            </button>
          <% end %>
        </div>

        <%= if @error do %>
          <div class="bg-red-50 border border-red-200 rounded-xl p-4 text-sm text-red-700">
            {@error}
          </div>
        <% end %>

        <%= if @parsed == nil do %>
          <div class="bg-white border border-gray-200 rounded-2xl p-8">
            <form id="upload-form" phx-submit="upload" phx-change="validate" class="space-y-6">
              <div class="border-2 border-dashed border-gray-300 rounded-2xl p-12 text-center hover:border-primary/50 transition-colors">
                <.live_file_input upload={@uploads.document} class="hidden" />
                <div class="space-y-3">
                  <div class="mx-auto w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center">
                    <.icon name="hero-document-arrow-up" class="size-8 text-gray-400" />
                  </div>
                  <div>
                    <label
                      for={@uploads.document.ref}
                      class="text-sm font-medium text-primary cursor-pointer hover:underline"
                    >
                      Choose a file
                    </label>
                    <p class="text-xs text-gray-400 mt-1">PDF, XLSX, DOCX, PPTX up to 20MB</p>
                  </div>
                </div>
              </div>

              <%= for entry <- @uploads.document.entries do %>
                <div class="flex items-center justify-between bg-gray-50 rounded-xl p-4">
                  <div class="flex items-center gap-3">
                    <.icon name="hero-document" class="size-5 text-gray-400" />
                    <span class="text-sm font-medium text-gray-700">{entry.client_name}</span>
                    <span class="text-xs text-gray-400">{format_size(entry.client_size)}</span>
                  </div>
                  <div class="w-32 bg-gray-200 rounded-full h-1.5">
                    <div
                      class="bg-primary h-1.5 rounded-full transition-all"
                      style={"width: #{entry.progress}%"}
                    >
                    </div>
                  </div>
                </div>
                <%= for err <- upload_errors(@uploads.document, entry) do %>
                  <p class="text-sm text-red-600">{upload_error_to_string(err)}</p>
                <% end %>
              <% end %>

              <button
                type="submit"
                disabled={@uploads.document.entries == []}
                class={[
                  "w-full px-4 py-3 rounded-xl text-sm font-medium transition-colors",
                  if(@uploads.document.entries == [],
                    do: "bg-gray-100 text-gray-400 cursor-not-allowed",
                    else: "bg-primary text-white hover:bg-primary/90"
                  )
                ]}
              >
                View Document
              </button>
            </form>
          </div>
        <% end %>

        <%= if @parsed do %>
          <div class="bg-white border border-gray-200 rounded-2xl overflow-hidden">
            <div class="flex items-center gap-3 px-6 py-4 border-b border-gray-100 bg-gray-50">
              <.icon name="hero-document" class="size-5 text-gray-400" />
              <span class="text-sm font-semibold text-gray-900">{@filename}</span>
              <span class={[
                "rounded-full px-2.5 py-0.5 text-xs font-medium",
                file_type_badge(@parsed)
              ]}>
                {file_type_label(@parsed)}
              </span>
            </div>

            <div class="p-6">
              {render_document(assigns)}
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp render_document(%{parsed: {:pdf, base64_data}} = assigns) do
    assigns = assign(assigns, :base64_data, base64_data)

    ~H"""
    <iframe
      id="pdf-viewer"
      src={"data:application/pdf;base64,#{@base64_data}"}
      class="w-full rounded-lg border border-gray-200"
      style="height: 80vh;"
      phx-update="ignore"
    >
    </iframe>
    """
  end

  defp render_document(%{parsed: {:xlsx, sheets}, active_sheet: active_sheet} = assigns) do
    sheet = Enum.at(sheets, active_sheet) || List.first(sheets)
    assigns = assign(assigns, :sheets, sheets) |> assign(:sheet, sheet)

    ~H"""
    <div class="space-y-4">
      <%= if length(@sheets) > 1 do %>
        <div class="flex gap-1 border-b border-gray-200">
          <%= for {s, idx} <- Enum.with_index(@sheets) do %>
            <button
              phx-click="switch_sheet"
              phx-value-index={idx}
              class={[
                "px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors",
                if(idx == @active_sheet,
                  do: "border-primary text-primary",
                  else: "border-transparent text-gray-500 hover:text-gray-700"
                )
              ]}
            >
              {s.name}
            </button>
          <% end %>
        </div>
      <% end %>

      <%= if @sheet do %>
        <div class="overflow-x-auto max-h-[70vh] overflow-y-auto">
          <table class="w-full text-sm">
            <tbody>
              <%= for {row, row_idx} <- Enum.with_index(@sheet.rows) do %>
                <tr class={
                  if(row_idx == 0,
                    do: "bg-gray-50 font-semibold",
                    else: "border-b border-gray-50 hover:bg-gray-50"
                  )
                }>
                  <td class="px-2 py-1.5 text-xs text-gray-400 w-8">{row_idx + 1}</td>
                  <%= for cell <- row do %>
                    <td class="px-3 py-1.5 text-gray-700 border-r border-gray-100 whitespace-nowrap">
                      {cell}
                    </td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_document(%{parsed: {:docx, paragraphs}} = assigns) do
    assigns = assign(assigns, :paragraphs, paragraphs)

    ~H"""
    <div class="prose max-w-none">
      <%= for paragraph <- @paragraphs do %>
        <p class="text-gray-700 leading-relaxed mb-3">{paragraph}</p>
      <% end %>
    </div>
    """
  end

  defp render_document(%{parsed: {:pptx, slides}} = assigns) do
    assigns = assign(assigns, :slides, slides)

    ~H"""
    <div class="space-y-4">
      <%= for slide <- @slides do %>
        <div class="bg-gray-50 rounded-xl p-6 border border-gray-100">
          <div class="flex items-center gap-2 mb-3">
            <span class="rounded-full bg-primary/10 text-primary px-2.5 py-0.5 text-xs font-semibold">
              Slide {slide.number}
            </span>
          </div>
          <div class="text-gray-700 whitespace-pre-wrap">{slide.text}</div>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_document(assigns) do
    ~H"""
    <p class="text-gray-500">Unable to render this document</p>
    """
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  defp file_type_badge({:pdf, _}), do: "bg-red-50 text-red-700"
  defp file_type_badge({:xlsx, _}), do: "bg-green-50 text-green-700"
  defp file_type_badge({:docx, _}), do: "bg-blue-50 text-blue-700"
  defp file_type_badge({:pptx, _}), do: "bg-orange-50 text-orange-700"
  defp file_type_badge(_), do: "bg-gray-100 text-gray-600"

  defp file_type_label({:pdf, _}), do: "PDF"
  defp file_type_label({:xlsx, _}), do: "XLSX"
  defp file_type_label({:docx, _}), do: "DOCX"
  defp file_type_label({:pptx, _}), do: "PPTX"
  defp file_type_label(_), do: "Unknown"

  defp upload_error_to_string(:too_large), do: "File is too large (max 20MB)"
  defp upload_error_to_string(:too_many_files), do: "Only one file at a time"
  defp upload_error_to_string(:not_accepted), do: "Unsupported file type"
  defp upload_error_to_string(err), do: "Error: #{inspect(err)}"
end
