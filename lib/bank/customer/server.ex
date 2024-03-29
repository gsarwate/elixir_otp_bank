defmodule Bank.Customer.Server do
  use GenServer, restart: :temporary

  # Client

  @doc """
  Defines a function to start a server(GenServer). For every customer new server is created
  """
  def start_link(customer_id) do
    IO.puts("Start -> Bank Customer Server for #{customer_id}")
    GenServer.start_link(Bank.Customer.Server, customer_id, name: global_name(customer_id))
  end

  defp global_name(customer_id) do
    {:global, {__MODULE__, customer_id}}
  end

  def whereis(customer_id) do
    case :global.whereis_name({__MODULE__, customer_id}) do
      :undefined ->
        nil

      pid ->
        pid
    end
  end

  @doc """
  Defines a function to add customer account
  """
  def add_account(bank_server, new_account) do
    GenServer.cast(bank_server, {:add_account, new_account})
  end

  @doc """
  Defines a function to get all accounts for the customer
  """
  def accounts(bank_server) do
    GenServer.call(bank_server, {:accounts})
  end

  @doc """
  Defines a function to get customer account by account id
  """
  def account_by_id(bank_server, account_id) do
    GenServer.call(bank_server, {:account_by_id, account_id})
  end

  @doc """
  Defines a function to get customer account by account number
  """
  def account_by_number(bank_server, account_number) do
    GenServer.call(bank_server, {:account_by_number, account_number})
  end

  # Server (callbacks)

  @impl true
  def init(customer_id) do
    {
      :ok,
      {customer_id, Bank.Customer.Database.get(customer_id) || Bank.Customer.new(customer_id)},
      expiry_idle_timeout()
    }
  end

  @impl true
  def handle_cast({:add_account, new_account}, {customer_id, customer}) do
    updated_customer = Bank.Customer.add_account(customer, new_account)
    Bank.Customer.Database.store(customer_id, updated_customer)
    {:noreply, {customer_id, updated_customer}, expiry_idle_timeout()}
  end

  @impl true
  def handle_call({:accounts}, _from, {customer_id, customer}) do
    {
      :reply,
      Bank.Customer.get_accounts(customer),
      {customer_id, customer},
      expiry_idle_timeout()
    }
  end

  @impl true
  def handle_call({:account_by_id, account_id}, _from, {customer_id, customer}) do
    {
      :reply,
      Bank.Customer.get_account_by_id(customer, account_id),
      {customer_id, customer},
      expiry_idle_timeout()
    }
  end

  @impl true
  def handle_call({:account_by_number, account_number}, _from, {customer_id, customer}) do
    {
      :reply,
      Bank.Customer.get_account_by_number(customer, account_number),
      {customer_id, customer},
      expiry_idle_timeout()
    }
  end

  @impl true
  def handle_info(:timeout, {customer_id, customer}) do
    IO.puts(" Stop -> Bank Customer Server for #{customer_id}")
    {:stop, :normal, {customer_id, customer}}
  end

  defp expiry_idle_timeout(), do: Application.fetch_env!(:elixir_otp_bank, :todo_item_expiry)
end
