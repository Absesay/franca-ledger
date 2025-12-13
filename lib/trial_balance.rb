# A Trial Balance is a report that lists all accounts and their balances,
# with debits and credits separated. The fundamental rule: total debits must
# equal total credits. If they don't, there's an error in the books.
#
# Accounting Concepts:
# - Trial Balance: Proof that debits = credits
# - Account Balance: Current balance of each account
# - Debit Balance: Positive balance for assets/expenses
# - Credit Balance: Positive balance for liabilities/equity/income
# - Out of Balance: When debits ≠ credits (indicates error)

require "bigdecimal"
require "date"
require_relative "ledger"
require_relative "account"

# TrialBalanceRow represents a single row in the trial balance
TrialBalanceRow = Struct.new(:account, :debit_balance, :credit_balance) do
  def initialize(*args)
    super
    freeze
  end
end

class TrialBalance
  attr_reader :ledger, :date, :rows

  # Create a trial balance from a ledger
  #
  # @param ledger [Ledger] The ledger to create trial balance for
  # @param date [Date] Optional date for the trial balance (defaults to today)
  #
  # Example:
  #   trial_balance = TrialBalance.new(ledger)
  def initialize(ledger, date = Date.today)
    unless ledger.is_a?(Ledger)
      raise ArgumentError, "Must provide a ledger, got #{ledger.class}"
    end

    @ledger = ledger
    @date = date.is_a?(Date) ? date : Date.parse(date.to_s)

    @rows = build_rows
  end

  # Get total of all debit balances
  #
  # @return [BigDecimal] Total debits
  def total_debits
    @rows.reduce(BigDecimal("0")) do |sum, row|
      sum + (row.debit_balance || BigDecimal("0"))
    end
  end

  # Get total of all credit balances
  #
  # @return [BigDecimal] Total credits
  def total_credits
    @rows.reduce(BigDecimal("0")) do |sum, row|
      sum + (row.credit_balance || BigDecimal("0"))
    end
  end

  # Check if trial balance is balanced
  # This is the critical validation: debits must equal credits
  #
  # @return [Boolean] True if balanced
  def balanced?
    total_debits == total_credits
  end

  # Get the imbalance (difference between debits and credits)
  # Should be 0 if balanced
  #
  # @return [BigDecimal] The difference
  def imbalance
    total_debits - total_credits
  end

  # Get rows for a specific account type
  #
  # @param type [Symbol] Account type
  # @return [Array<TrialBalanceRow>] Rows for that account type
  def rows_for_type(type)
    @rows.select { |row| row.account.type == type.to_sym }
  end

  # Get row for a specific account
  #
  # @param account [Account] The account
  # @return [TrialBalanceRow, nil] The row or nil if not found
  def row_for(account)
    @rows.find { |row| row.account == account }
  end

  # Format trial balance as a string
  # Useful for printing or displaying
  #
  # @return [String] Formatted trial balance
  def to_s
    lines = []
    lines << "Trial Balance as of #{@date}"
    lines << "=" * 80
    lines << sprintf("%-30s %15s %15s", "Account", "Debit", "Credit")
    lines << "-" * 80

    @rows.each do |row|
      debit_str = row.debit_balance && row.debit_balance > 0 ? format_amount(row.debit_balance) : ""
      credit_str = row.credit_balance && row.credit_balance > 0 ? format_amount(row.credit_balance) : ""
      lines << sprintf("%-30s %15s %15s", row.account.name, debit_str, credit_str)
    end

    lines << "-" * 80
    lines << sprintf("%-30s %15s %15s", "TOTAL", format_amount(total_debits), format_amount(total_credits))

    if balanced?
      lines << "✓ BALANCED"
    else
      lines << "✗ OUT OF BALANCE by #{format_amount(imbalance.abs)}"
    end

    lines.join("\n")
  end

  def inspect
    status = balanced? ? "balanced" : "out of balance"
    "#<TrialBalance:#{@rows.length} accounts, #{status}>"
  end

  private

  # Build trial balance rows from ledger
  # This processes all accounts and calculates their balances
  def build_rows
    accounts = @ledger.accounts

    sorted_accounts = accounts.sort_by(&:number)

    sorted_accounts.map do |account|
      balance = @ledger.balance(account)

      if account.debit_increases?
        if balance >= 0
          TrialBalanceRow.new(account, balance, nil)
        else
          TrialBalanceRow.new(account, nil, balance.abs)
        end
      else
        if balance >= 0
          TrialBalanceRow.new(account, nil, balance)
        else
          TrialBalanceRow.new(account, balance.abs, nil)
        end
      end
    end
  end

  def format_amount(amount)
    return "" if amount.nil? || amount.zero?
    sprintf("%.2f", amount)
  end
end

# Example usage (uncomment to test):
#
# # Create accounts and ledger
# cash = Account.new("Cash", :asset, 1000)
# revenue = Account.new("Sales Revenue", :income, 4100)
# ledger = Ledger.new
#
# # Post some transactions
# journal = JournalEntry.new(
#   description: "Customer payment",
#   entries: [
#     { account: cash, debit: 100 },
#     { account: revenue, credit: 100 }
#   ]
# )
# ledger.post(journal)
#
# # Create trial balance
# trial_balance = TrialBalance.new(ledger)
#
# # Check properties
# puts trial_balance.balanced?      # => true
# puts trial_balance.total_debits   # => 100.00
# puts trial_balance.total_credits  # => 100.00
# puts trial_balance.to_s           # => Formatted report
