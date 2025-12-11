# The Ledger is the central repository for all accounting transactions.
# It maintains a record of all journal entries and can calculate account balances.
# The ledger enforces double-entry rules and provides posting functionality.
#
#
# Accounting Concepts:
# - General Ledger: Master record of all transactions
# - Posting: Recording transactions to the ledger
# - Account Balance: Current balance of an account
# - Ledger History: Complete audit trail

require "bigdecimal"
require "date"
require_relative "journal_entry"
require_relative "account"

class Ledger
  attr_reader :entries, :journal_entries

  # Initialize creates a new empty Ledger
  #
  # Example:
  #   ledger = Ledger.new
  def initialize
    @entries = []
    @journal_entries = []
  end

  # Post a journal entry to the ledger
  # This is the main way to record transactions
  #
  # @param journal_entry [JournalEntry] The journal entry to post
  # @return [Ledger] Returns self for method chaining
  #
  # Example:
  #   ledger.post(journal_entry)
  #   ledger.post(journal_entry1).post(journal_entry2)  # Method chaining
  def post(journal_entry)
    unless journal_entry.is_a?(JournalEntry)
      raise ArgumentError, "You must post a JournalEntry, but got #{journal_entry.class}"
    end

    @journal_entries << journal_entry

    @entries.concat(journal_entry.entries)

    self
  end

  # Post multiple journal entries at once
  # Convenience method for bulk posting
  #
  # @param journal_entries [Array<JournalEntry>] Array of journal entries
  # @return [Ledger] Returns self for method chaining
  #
  # Example:
  #   ledger.post_all([entry1, entry2, entry3])
  def post_all(journal_entries)
    journal_entries.each { |entry| post(entry) }
    self
  end

  # Get balance for a specific account
  # Balance = sum of all entries for that account
  # Debits increase asset/expense accounts, credits increase liability/equity/income accounts
  #
  # @param account [Account] The account to get balance for
  # @return [BigDecimal] The account balance
  #
  # Example:
  #   cash_balance = ledger.balance(cash_account)
  def balance(account)
    account_entries = @entries.select { |entry| entry.account == account }

    if account.debit_increases?
      debit = account_entries.select(&:debit).reduce(BigDecimal("0")) { |sum, entry| sum + entry.amount }
      credits = account_entries.select(&:credit).reduce(BigDecimal("0")) { |sum, entry| sum + entry.amount }
      debits - credits
    else
      debit = account_entries.select(&:debit).reduce(BigDecimal("0")) { |sum, entry| sum + entry.amount }
      credits = account_entries.select(&:credit).reduce(BigDecimal("0")) { |sum, entry| sum + entry.amount }
      credits - debits
    end
  end

  # Get balances for all accounts
  # Returns a hash mapping accounts to their balances
  #
  # @return [Hash<Account, BigDecimal>] Account balances
  #
  # Example:
  #   balances = ledger.all_balances
  #   balances[cash_account]  # => 1000.00
  def all_balances
    accounts = @entries.map(&:account).uniq
    accounts.map { |account| [account, balance(account)] }.to_h
  end

  # Get entries for a specific account
  #
  # @param account [Account] The account
  # @return [Array<LedgerEntry>] All entries for that account
  def entries_for(account)
    @entries.select { |entry| entry.account == account }
  end

  # Get entries within a date range
  #
  # @param start_date [Date] Start date (inclusive)
  # @param end_date [Date] End date (inclusive)
  # @return [Array<LedgerEntry>] Entries in date range
  def entries_between(start_date, end_date)
    @entries.select { |entry| entry.date >= start_date && entry.date <= end_date }
  end

  # Get journal entries within a date range
  #
  # @param start_date [Date] Start date (inclusive)
  # @param end_date [Date] End date (inclusive)
  # @return [Array<JournalEntry>] Journal entries in date range
  def journal_entries_between(start_date, end_date)
    @journal_entries.select { |entry| entry.date >= start_date && entry.date <= end_date }
  end

  # Get all accounts in the ledger
  #
  # @return [Array<Account>] All accounts that have entries
  def accounts
    @entries.map(&:account).uniq
  end

  # Get accounts by type
  #
  # @param type [Symbol] Account type (:asset, :liability, etc.)
  # @return [Array<Account>] Accounts of that type
  def accounts_by_type(type)
    account.select { |account| account.type == type.to_sym }
  end

  def empty?
    @entries.empty?
  end

  def entry_count
    @entries.length
  end

  def journal_entry_count
    @journal_entries.length
  end

  def clear!
    @entries.clear
    @journal_entries.clear
  end

  def total_debits
    @entries.select(&:debit?).reduce(BigDecimal("0")) { |sum, entry| sum + entry.amount }
  end

  def total_credits
    @entries.select(&:credit?).reduce(BigDecimal("0")) { |sum, entry| sum + entry.amount }
  end

  def balanced?
    total_debits == total_credits
  end

  def to_s
    "Ledger with #{@entries.length} entries across #{account.length} accounts"
  end

  def inspect
    "#<Ledger:#{@entries.length} entries, #{@journal_entries.length} journal entries>"
  end
end
