module Content
  def self.help
    help_message = <<~HELP_MESSAGE
      Program for keeping track of payments and current money amount.
      Available commands:
       'n' - Write new transaction
       'e' - Edit an existing transaction
       'd' - Delete a transaction
       'q' - Quit program
       '?' - Show this help message

    HELP_MESSAGE
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
      help_message = <<~HELP_MESSAGE
        Type first letters to fill out these fields:
          [n]ame, [b]alance, [c]urrency
      HELP_MESSAGE
    when :payments
      help_message = <<~HELP_MESSAGE
        Type first letters to fill out these fields:
          [f]rom_name, [t]o_name, [d]escription, [a]mount, [c]urrency
      HELP_MESSAGE
    end
    help_message << <<~HELP_MESSAGE
      Actions:
        [s]ave, [q]uit (back to menu), [?] help
    HELP_MESSAGE
    help_message
  end
end