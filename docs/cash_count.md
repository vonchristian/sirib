<div data-controller="cash-count" 
     data-cash-count-expected-total-value="<%= @expected_total %>"
     data-cash-count-currency-value="PHP"
     data-cash-count-denominations-value="<%= @denominations.to_json %>"
     data-session-id="<%= @session.id %>">

  <!-- Header -->
  <div class="bg-gray-50 p-4 rounded-lg mb-6">
    <div class="flex justify-between">
      <div>
        <h1 class="text-2xl font-bold">Close Session #<%= @session.id %></h1>
        <p class="text-gray-600">Teller: <%= @session.teller.name %></p>
      </div>
      <div class="text-right">
        <p class="text-sm text-gray-600">Expected Total</p>
        <p class="text-xl font-bold"><%= number_to_currency(@expected_total) %></p>
      </div>
    </div>
  </div>

  <!-- Denomination Table -->
  <div class="bg-white rounded-lg shadow">
    <table class="min-w-full">
      <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left">Denomination</th>
          <th class="px-6 py-3 text-right">Count</th>
          <th class="px-6 py-3 text-right">Subtotal</th>
        </tr>
      </thead>
      <tbody>
        <% @denominations.each_with_index do |denom, index| %>
          <tr>
            <td class="px-6 py-3"><%= denom.label %></td>
            <td class="px-6 py-3">
              <input type="number" 
                     min="0" 
                     step="1"
                     data-cash-count-target="count"
                     data-action="input->cash-count#calculateTotals"
                     class="w-24 text-right rounded border-gray-300">
            </td>
            <td class="px-6 py-3 text-right" 
                data-cash-count-target="subtotal">₱0.00</td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>

  <!-- Summary -->
  <div class="mt-6 p-4 bg-gray-50 rounded-lg">
    <div class="flex justify-between items-center">
      <span class="font-semibold">Total Counted:</span>
      <span class="text-xl font-bold" data-cash-count-target="total">₱0.00</span>
    </div>
    <div class="flex justify-between items-center mt-2">
      <span class="font-semibold">Variance:</span>
      <span class="text-xl font-bold" data-cash-count-target="variance">₱0.00</span>
    </div>
  </div>

  <!-- Actions -->
  <div class="mt-6 flex justify-end gap-3">
    <%= link_to "Cancel", cash_sessions_path, class: "px-4 py-2 bg-gray-200 rounded" %>
    <button data-action="click->cash-count#validateAndSubmit"
            class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
      Confirm & Close Session
    </button>
  </div>
</div>