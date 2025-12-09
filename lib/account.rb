# An Account represents a category in the chart of accounts. Every transaction
# must be posted to an account. Accounts are organized by type: Assets, Liabilities,
# Equity, Income, and Expenses.

# Accounting Concepts:
# - Chart of Accounts: Organized list of all accounts
# - Account Types: The five fundamental categories
# - Normal Balance: Which side (debit/credit) increases the account
# - Account Numbering: Common numbering schemes

# AccountType is a simple value object using Struct
# I am using Struct because it creates a class with getter methods for each attribute.
# This is lighter than a full class for when I just need data
AccountType = Struct.new(:name, :normal_balance, :number_range) do
  def initialize(*args)
    super
    freeze
  end
end

class Account
  ACCOUNT_TYPES = {
    asset: AccountType.new(
      :asset,
      :debit,             # Assets increase with debits
      (1000..1999)
    ),
    liability: AccountType.new(
      :liability,
      :credit,            # Liabilities increase with credits
      (2000..2999)
    ),
    equity: AccountType.new(
      :equity,
      :credit,            # Equity increases with credits
      (3000..3999)
    ),
    income: AccountType.new(
      :income,
      :credit,            # Income increases with credits
      (4000..4999)
    ),
    expense: AccountType.new(
      :expense,
      :debit,             # Expenses increases with credits
      (5000..5999)
    ),
  }.freeze

  attr_reader :name, :type, :number, :description

  # Initialize creates a new Account
  #
  # @param name [String] Account name (e.g., "Cash", "Accounts Receivable")
  # @param type [Symbol] Account type (:asset, :liability, :equity, :income, :expense)
  # @param number [Integer] Optional account number (auto-assigned if nil)
  # @param description [String] Optional description
  #
  # Example:
  #   Account.new("Cash", :asset)
  def initialize(name, type, number = nil, description = nil)
    @name = name.to_s
    @type = type.to_sym

    unless ACCOUNT_TYPES.key?(@type)
      valid_types = ACCOUNT_TYPES.keys.join(", ")
      raise ArgumentError, "Invalid account type: #{type}. Must be one of: #{valid_types}"
    end

    @number = number || default_account_number(@type)

    @description = description.to_s if description

    freeze
  end

  # Get account type information
  #
  # Example:
  #   Account.type_info(:asset)  # => AccountType struct
  def self.type_info(type)
    ACCOUNT_TYPES[type.to_sym] || raise(ArgumentError, "Unknown account type #{type}")
  end

  # Get all account types
  # Returns an array of symbols
  #
  # Example:
  #   Account.types  # => [:asset, :liability, :equity, :income, :expense]
  def self.types
    ACCOUNT_TYPES.keys
  end

  # Get the normal balance for this account
  # Normal balance = which side (debit/credit) increases the account
  #
  # Example:
  #   cash = Account.new("Cash", :asset)
  #   cash.normal_balance  # => :debit
  def normal_balance
    ACCOUNT_TYPES[@type].normal_balance
  end

  # Check if account increases with debits
  #
  # Example:
  #   cash = Account.new("Cash", :asset)
  #   cash.debit_increases?  # => true
  def debit_increases?
    normal_balance == :debit
  end

  # Check if account increases with credits
  #
  # Example:
  #   cash = Account.new("Sales", :income)
  #   cash.credit_increases?  # => true
  def credit_increases?
    normal_balance == :credit
  end

  def type_info
    ACCOUNT_TYPES[@type]
  end

  def asset?
    @type == :asset
  end

  def liability?
    @type == :liability
  end

  def equity?
    @type == :equity
  end

  def income?
    @type == :income
  end

  def expense?
    @type == :expense
  end

  # Check the Equality: Two accounts are equal if they have the same number
  # In accounting, account numbers are unique identifiers
  #
  # Example:
  #   acc1 = Account.new("Cash", :asset, 1000)
  #   acc2 = Account.new("Cash", :asset, 1000)
  #   acc1 == acc2  # => true
  def ==(other)
    return false unless other.is_a?(Account)
    @number == other.number
  end

  def eql?(other)
    self == other
  end

  def hash
    @number.hash
  end

  def to_s
    "#{@name} (#{@number})"
  end

  def inspect
    "#<Account:#{@number} #{@name} (#{@type})>"
  end

  private

  # Calculate default account number
  def default_account_number(type)
    type_info = ACCOUNT_TYPES[type]
    # Use the start of the range as default
    type_info.number_range.first
  end
end

# Example usage (uncomment to test):
#
# # Create accounts
# cash = Account.new("Cash", :asset, 1000)
# accounts_receivable = Account.new("Accounts Receivable", :asset, 1100)
# accounts_payable = Account.new("Accounts Payable", :liability, 2000)
# sales_revenue = Account.new("Sales Revenue", :income, 4100)
# rent_expense = Account.new("Rent Expense", :expense, 5100)
#
# # Check account properties
# puts cash.normal_balance              # => :debit
# puts sales_revenue.normal_balance     # => :credit
# puts cash.debit_increases?            # => true
# puts sales_revenue.credit_increases?  # => true
#
# # Get type information
# puts Account.type_info(:asset).normal_balance  # => :debit
# puts Account.types                              # => [:asset, :liability, :equity, :income, :expense]
