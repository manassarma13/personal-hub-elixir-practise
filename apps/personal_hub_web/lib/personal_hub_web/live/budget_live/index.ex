defmodule PersonalHubWeb.BudgetLive.Index do
  use PersonalHubWeb, :live_view

  @categories ["Housing", "Food", "Transportation", "Utilities", "Insurance", "Medical", "Saving", "Personal"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Local Budget")
     |> assign(transactions: [])
     |> assign(new_amount: "")
     |> assign(new_desc: "")
     |> assign(new_cat: "Food")
     |> assign(categories: @categories)}
  end

  @impl true
  def handle_event("ls:loaded", data, socket) do
    transactions = data["budget_transactions"] || []
    
    {:noreply, 
     socket
     |> assign(transactions: transactions)
     |> update_chart(transactions)}
  end

  @impl true
  def handle_event("update_form", %{"amount" => amount, "desc" => desc, "cat" => cat}, socket) do
    {:noreply, assign(socket, new_amount: amount, new_desc: desc, new_cat: cat)}
  end

  @impl true
  def handle_event("add_tx", _params, socket) do
    amount = socket.assigns.new_amount
    desc = socket.assigns.new_desc
    cat = socket.assigns.new_cat

    if amount != "" and desc != "" do
      tx = %{
        "id" => System.unique_integer([:positive]) |> Integer.to_string(),
        "amount" => String.to_float(amount <> if(not String.contains?(amount, "."), do: ".0", else: "")),
        "desc" => desc,
        "category" => cat,
        "date" => Date.utc_today() |> Date.to_iso8601()
      }

      transactions = [tx | socket.assigns.transactions]
      
      {:noreply,
       socket
       |> assign(transactions: transactions, new_amount: "", new_desc: "")
       |> update_chart(transactions)
       |> push_event("ls:store", %{collection: "budget_transactions", data: transactions})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_tx", %{"id" => id}, socket) do
    transactions = Enum.reject(socket.assigns.transactions, fn t -> t["id"] == id end)
    
    {:noreply,
     socket
     |> assign(transactions: transactions)
     |> update_chart(transactions)
     |> push_event("ls:store", %{collection: "budget_transactions", data: transactions})}
  end

  defp update_chart(socket, transactions) do
    # Group by category and sum amounts
    grouped = Enum.reduce(transactions, %{}, fn tx, acc ->
      Map.update(acc, tx["category"], tx["amount"], &(&1 + tx["amount"]))
    end)

    labels = Map.keys(grouped)
    data = Map.values(grouped)

    chart_data = %{
      labels: labels,
      datasets: [
        %{
          data: data,
          backgroundColor: [
            "rgba(255, 99, 132, 0.7)",
            "rgba(54, 162, 235, 0.7)",
            "rgba(255, 206, 86, 0.7)",
            "rgba(75, 192, 192, 0.7)",
            "rgba(153, 102, 255, 0.7)",
            "rgba(255, 159, 64, 0.7)",
            "rgba(199, 199, 199, 0.7)",
            "rgba(83, 102, 255, 0.7)"
          ]
        }
      ]
    }

    push_event(socket, "render-chart", %{type: "doughnut", data: chart_data})
  end

  defp total_spend(transactions) do
    Enum.reduce(transactions, 0.0, fn tx, acc -> acc + tx["amount"] end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="budget-store" phx-hook="LocalStore" phx-update="ignore" data-collections="budget_transactions"></div>

      <div class="space-y-6 max-w-5xl mx-auto">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl sm:text-3xl font-bold text-gray-900 tracking-tight">Local Budget</h1>
            <p class="text-gray-500 mt-1">Track expenses privately in your browser.</p>
          </div>
          <div class="text-right">
            <p class="text-sm font-semibold text-gray-500 uppercase tracking-wider">Total Spend</p>
            <p class="text-3xl font-black text-gray-900">${:erlang.float_to_binary(total_spend(@transactions), decimals: 2)}</p>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="lg:col-span-1 space-y-6">
            <div class="bg-white border border-gray-200 rounded-2xl p-6">
              <h3 class="font-bold text-gray-900 mb-4">Add Expense</h3>
              <form phx-submit="add_tx" phx-change="update_form" class="space-y-4">
                <div>
                  <label class="block text-xs font-semibold text-gray-500 mb-1">Amount ($)</label>
                  <input type="number" step="0.01" name="amount" value={@new_amount} placeholder="42.50" class="w-full rounded-xl border border-gray-200 px-4 py-2 text-sm focus:ring-primary focus:border-primary" />
                </div>
                <div>
                  <label class="block text-xs font-semibold text-gray-500 mb-1">Description</label>
                  <input type="text" name="desc" value={@new_desc} placeholder="Groceries, Rent, Coffee..." class="w-full rounded-xl border border-gray-200 px-4 py-2 text-sm focus:ring-primary focus:border-primary" />
                </div>
                <div>
                  <label class="block text-xs font-semibold text-gray-500 mb-1">Category</label>
                  <select name="cat" class="w-full rounded-xl border border-gray-200 px-4 py-2 text-sm focus:ring-primary focus:border-primary">
                    <%= for cat <- @categories do %>
                      <option value={cat} selected={@new_cat == cat}>{cat}</option>
                    <% end %>
                  </select>
                </div>
                <button type="submit" disabled={@new_amount == "" or @new_desc == ""} class="w-full py-2 bg-gray-900 text-white rounded-xl text-sm font-medium hover:bg-gray-800 disabled:opacity-50 transition-colors cursor-pointer mt-2">
                  Add Transaction
                </button>
              </form>
            </div>
          </div>

          <div class="lg:col-span-2 space-y-6">
            <div class="bg-white border border-gray-200 rounded-2xl p-6 flex flex-col md:flex-row items-center gap-8">
              <div class="w-full md:w-1/2 aspect-square max-h-[300px]">
                <canvas id="budget-chart" phx-hook="ChartJS" phx-update="ignore"></canvas>
              </div>
              <div class="w-full md:w-1/2">
                <h3 class="font-bold text-gray-900 mb-4">Recent Transactions</h3>
                <div class="space-y-2 max-h-[250px] overflow-y-auto pr-2">
                  <%= for tx <- @transactions do %>
                    <div class="flex items-center justify-between p-3 rounded-xl border border-gray-100 hover:bg-gray-50 transition-colors">
                      <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 text-xs font-bold uppercase">
                          {String.slice(tx["category"], 0..1)}
                        </div>
                        <div>
                          <p class="text-sm font-semibold text-gray-900">{tx["desc"]}</p>
                          <p class="text-xs text-gray-500">{tx["category"]} • {tx["date"]}</p>
                        </div>
                      </div>
                      <div class="flex items-center gap-3">
                        <span class="text-sm font-bold text-gray-900">${:erlang.float_to_binary(tx["amount"] * 1.0, decimals: 2)}</span>
                        <button phx-click="delete_tx" phx-value-id={tx["id"]} class="text-gray-400 hover:text-red-500 cursor-pointer">
                          <.icon name="hero-trash" class="size-4" />
                        </button>
                      </div>
                    </div>
                  <% end %>
                  <%= if @transactions == [] do %>
                    <p class="text-sm text-gray-500 text-center py-4">No transactions recorded yet.</p>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
