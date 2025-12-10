# A JournalEntry groups multiple ledger entries together as a single transaction.
# In double-entry accounting, a journal entry must have equal total debits and credits.
# This is rule that keeps the books balanced.
#
#
# Accounting Concepts:
# - Journal Entry: A group of related debits and credits
# - Double-Entry Rule: Total debits must equal total credits
# - Compound Entry: More than two accounts involved
# - Simple Entry: Only two accounts (one debit, one credit)

require "bigdecimal"
require "date"
require_relative "ledger"

class JournalEntry
  attr_reader :description, :date, :entries, :reference

  # Initialize creates a new JournalEntry
  #
  # @param description [String] Description of the transaction
  # @param date [Date] Transaction date
  # @param entries [Array<Hash>] Array of entry hashes with :account,
  #                       :debit or :credit, and :amount
  # @param reference [String] Optional reference number/ID
  #
  # Example:
  #   JournalEntry.new(
  #     description: "Customer payment",
  #     date: Date.today,
  #     entries: [
  #       { account: cash_account, debit: 100 },
  #       { account: revenue_account, credit: 100 }
  #     ]
  #   )
  def initialize(description, date: Date.today, entries: [], reference: nil)
    @description = description.to_s
    @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    @reference = reference.to_s if reference

    @entries = entries.map do |entry_hash|
      create_ledger_entry(entry_hash)
    end

    validate_balanced!

    freeze
  end

  def debit_entries
    @entries.select(&:debit?)
  end

  def credit_entries
    @entries.select(&:credit?)
  end

  def total_debits
    debit_entries.reduce(BigDecimal("0")) { |sum, entry| sum + entry.amount }
  end

  def total_credits
    credit_entries.reduce(BigDecimal("0")) { |sum, entry| sum + entry.amount }
  end

  def balanced?
    total_debits == total_credits
  end

  def imbalance
    total_debits - total_credits
  end

  def simple_entry?
    @entries.length == 2
  end

  def compound_entry?
    @entries.length > 2
  end

  def accounts
    @entries.map(&:account)
  end

  def entry_for(account)
    @entries.find { }
  end

  def entries_for(account)
    @entries.select { |entry| entry.account == account }
  end

  def to_s
    "#{@description} (#{@date}) - DR: #{total_debits}, CR: #{total_credits}"
  end

  def inspect
    "#<JournalEntry:#{@description} on #{@date} (#{@entries.length} entries)>"
  end

  private

  # Create a LedgerEntry from a hash
  # This handles the conversion from hash format to LedgerEntry object
  def create_ledger_entry(entry_hash)
    account = entry_hash[:account] || entry_hash["account"]
    debit = entry_hash[:debit] || entry_hash["debit"]
    credit = entry_hash[:credit] || entry_hash["credit"]
    amount = entry_hash[:amount] || entry_hash["amount"]
    description = entry_hash[:description] || entry_hash["description"]

    unless account.is_a?(Account)
      raise ArgumentError, "Entry must have an Account, but got #{account.class}"
    end

    if debit && !credit
      amount ||= BigDecimal(debit.to_s)
      LedgerEntry.debit(account, amount, @date, description, @reference)
    elsif credit && !debit
      amount ||= BigDecimal(credit.to_s)
      LedgerEntry.credit(account, amount, @date, description, @reference)
    elsif amount
      if account.debit_increases?
        LedgerEntry.debit(account, BigDecimal(amount.to_s), @date, description, @reference)
      else
        LedgerEntry.credit(account, BigDecimal(amount.to_s), @date, description, @reference)
      end
    else
      raise ArgumentError, "Entry must specify :debit, :credit or :amount"
    end
  end

  def validate_balanced!
    unless balanced?
      raise ArgumentError, "Journal entry is not balanced! Debits: #{total_debits}, Credits: #{total_credits}, Difference: #{imbalance}"
    end
  end
end

# Example usage (uncomment to test):
#
# # Create accounts
# cash = Account.new("Cash", :asset, 1000)
# revenue = Account.new("Sales Revenue", :income, 4100)
# rent_expense = Account.new("Rent Expense", :expense, 5100)
# accounts_payable = Account.new("Accounts Payable", :liability, 2000)
#
# # Simple entry: Customer pays $100
# simple = JournalEntry.new(
#   description: "Customer payment",
#   date: Date.today,
#   entries: [
#     { account: cash, debit: 100 },
#     { account: revenue, credit: 100 }
#   ]
# )
#
# # Compound entry: Pay rent of $500
# compound = JournalEntry.new(
#   description: "Monthly rent payment",
#   date: Date.today,
#   entries: [
#     { account: rent_expense, debit: 500 },
#     { account: cash, credit: 500 }
#   ]
# )
#
# # Check properties
# puts simple.balanced?           # => true
# puts simple.total_debits        # => 100
# puts simple.total_credits       # => 100
# puts compound.compound_entry?   # => false (only 2 entries, so simple)
# puts simple.simple_entry?      # => true