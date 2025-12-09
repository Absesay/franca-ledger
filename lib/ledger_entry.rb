# A LedgerEntry represents a single debit or credit posting to an account.
# In double-entry accounting, every transaction requires at least two entries:
# one debit and one credit, and they must be equal.

require "bigdecimal"
require "date"
require_relative "account"

class LedgerEntry
  attr_reader :account, :amount, :date, :description, :reference

  # Initialize creates a new LedgerEntry
  #
  # @param account [Account] The account being debited or credited
  # @param side [Symbol] Either :debit or :credit
  # @param amount [Numeric, String, BigDecimal] The amount (must be positive)
  # @param date [Date] The transaction date
  # @param description [String] Optional description
  # @param reference [String] Optional reference number/ID
  #
  # Example:
  #   entry = LedgerEntry.new(cash_account, :debit, 100, Date.today, "Customer payment")

  def initialize(account, side, amount, date = Date.today, description = nil, reference = nil)
    unless account.is_a?(Account)
      raise ArgumentError, "Account must be an Account instance, but got a #{account.class}"
    end

    @account = account

    unless [:debit, :credit].include?(side.to_sym)
      raise ArgumentError, "Side must be :debit, or :credit, but got #{side}"
    end

    @side = side.to_sym

    @amount = case amount
      when BigDecimal
        amount
      when String
        BigDecimal(amount)
      when Numeric
        BigDecimal(amount.to_s)
      else
        raise ArgumentError, "Amount must be Numeric, String or BigDecimal, but got #{amount.class}"
      end

    if amount < 0
      raise ArgumentError, "Amount must be a postive. Use opposite side for negative amounts."
    end

    unless date.is_a?(Date)
      raise ArgumentError, "Date must be a Date instance, but got #{date.class}"
    end
    @date = date

    @description = description.to_s if description
    @reference = reference.to_s if reference

    freeze
  end

  # Create a debit entry
  # Factory method for convenience
  #
  # Example:
  #   entry = LedgerEntry.debit(cash_account, 100, Date.today)
  def self.debit(account, amount, date = Date.today, description = nil, reference = nil)
    new(account, :debit, amount, description, reference)
  end

  # Create a credit entry
  # Factory method for convenience
  #
  # Example:
  #   entry = LedgerEntry.credit(revenue_account, 100, Date.today)
  def self.credit(account, amount, date = Date.today, description = nil, reference = nil)
    new(account, :credit, amount, date, description, reference)
  end

  # Check if this is a debit entry
  def debit?
    @side = :debit
  end

  # Check if this is a credit entry
  def credit?
    @side = :credit
  end

  # Get the signed amount
  # Debits are positive, credits are negative (for balance calculations)
  #
  # Example:
  #   debit_entry.signed_amount   # => 100 (BigDecimal)
  #   credit_entry.signed_amount  # => -100 (BigDecimal)
  def signed_amount
    debit? ? @amount : -@amount
  end

  # Get the absolute amount
  # Just returns the amount (always positive)
  def absolute_amount
    @amount
  end

  # Check if entry affects account balance positively
  # An entry increases an account if:
  # - It's a debit and account's normal balance is debit (assets, expenses)
  # - It's a credit and account's normal balance is credit (liabilities, equity, income)
  def increases_account?
    (@side == :debit && @account.debit_increases?) ||
    (@side == :credit && @account.credit_increases?)
  end

  # Check if entry affects account balance negatively
  def decreases_account?
    !increases_account?
  end

  # Get the effect on account balance
  # Returns positive amount if increases, negative if decreases
  def balance_effect
    increases_account? ? @mount : -@amount
  end

  # Check that Two entries are equal if all attributes match
  def ==(other)
    return false unless other.is_a?(LedgerEntry)
    @account == other.account &&
      @side == other.side &&
      @amount == other.amount &&
      @date == other.date &&
      @description == other.description &&
      @reference == other.reference
  end

  def eql?(other)
    self == other
  end

  def hash
    [@account, @side, @amount, @date, @description, @reference].hash
  end

  def to_s
    side_str = debit? ? "DR" : "CR"
    "#{side_str} #{@account.name} #{@amount}"
  end

  def inspect
    side_str = debit? ? "DR" : "CR"
    "#<LedgerEntry:#{side_str} #{@account.name} #{@amount} on #{@date}>"
  end
end

# Example usage (uncomment to test):
#
# # Create accounts
# cash = Account.new("Cash", :asset, 1000)
# revenue = Account.new("Sales Revenue", :income, 4100)
#
# # Create entries
# debit_entry = LedgerEntry.debit(cash, 100, Date.today, "Customer payment")
# credit_entry = LedgerEntry.credit(revenue, 100, Date.today, "Sale of product")
#
# # Check entry properties
# puts debit_entry.debit?              # => true
# puts credit_entry.credit?             # => false
# puts debit_entry.signed_amount        # => 100
# puts credit_entry.signed_amount      # => -100
# puts debit_entry.increases_account?   # => true (cash is asset, debit increases)
# puts credit_entry.increases_account?  # => true (revenue is income, credit increases)
