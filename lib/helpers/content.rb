module Content
  def self.help
    help_message = <<~MESSAGE_TEXT
      Program for keeping track of payments and current money amount.
      Available commands:
       'n' - Write new transaction
       'e' - Edit an existing transaction
       'd' - Delete a transaction
       'q' - Quit program
       '?' - Show this help message

    MESSAGE_TEXT
    help_message
  end

  def self.exit
    exit_message = <<~EXIT_MESSAGE
      Exiting...

    EXIT_MESSAGE
    exit_message
  end

  def self.error_unknown_command
    "Unkown command. Type '?' to see what's available."
  end

  def self.error_unknown_mode
    'Program reached an unknown mode.'
  end

  def self.error_invalid_value(arg)
    "Invalid value for \"#{arg}\". Please check your input."
  end

  def self.mode_edit_help(table)
    help_message = ''
    case table
    when :accounts
      help_message << <<~MESSAGE_TEXT
        Type first letters to fill out these fields:
          [n]ame, [b]alance, [c]urrency
      MESSAGE_TEXT
    when :payments
      help_message << <<~MESSAGE_TEXT
        Type first letters to fill out these fields:
          [f]rom_name, [t]o_name, [d]escription, [a]mount, [c]urrency
      MESSAGE_TEXT
    end
    help_message << <<~MESSAGE_TEXT
      Actions:
        [s]ave, [q]uit (back to menu), [?] help
    MESSAGE_TEXT
    help_message
  end

  def self.mode_delete_help(table)
    help_message = ''
    case table
    when :accounts
      help_message << <<~MESSAGE_TEXT
        You are about to delete this account.
        Fill out the name with which to replace it in past payments:
        (Optional - if not filled, will be replaced by "#{DEFAULT_UNKNOWN_ACCOUNT}")
          [n]ame
      MESSAGE_TEXT
    when :payments
      help_message << <<~MESSAGE_TEXT
        You are about to delete this payment record.
        Money will be returned to respective accounts.
      MESSAGE_TEXT
    end
    help_message << <<~MESSAGE_TEXT
      Actions:
        [s]tart (deletion), [q]uit (back to menu), [?] help
    MESSAGE_TEXT
    help_message
  end

  def self.mode_list_help
    help_message = <<~MESSAGE_TEXT
      Listing records from database...
      Type first letters to fill out search filters:
        [w]ord (for searching), [l]imit, [o]ffset
      Actions:
        [s]earch, [q]uit (back to menu), [?] help
    MESSAGE_TEXT
    help_message
  end
end