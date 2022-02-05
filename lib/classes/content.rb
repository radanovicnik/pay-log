module PayLog
  module Content
    def self.n
      Module.nesting
    end

    def self.title
      title_text = <<~TITLE_TEXT

        ###############
        ##  PAY LOG  ##
        ###############
      TITLE_TEXT
      title_text.gsub("\n", "\n  ")
    end

    def self.help
      help_message = <<~MESSAGE_TEXT
        Program for keeping track of payments and current money amount.
        Type first letters to use any of the available commands.
        Simple commands:
          [q]uit, [?] help
        For viewing or editing records, first pick a type (again using first letter):
          [a]ccounts, [p]ayments
        Then choose what you want to do:
          [e]dit (an existing record, or create a new one),
          [d]elete (an existing record),
          [l]ist (records)
        Some command examples:
          ae 3 -- edit an account with the ID 3
          pl -- list payments
          pe -- create a new payment
          q -- quit program

      MESSAGE_TEXT
      help_message
    end

    def self.exit
      if $db_modified
        "Saving changes...\n\n"
      else
        "Exiting...\n\n"
      end
    end

    def self.error_unknown_command
      "Unknown command. Type '?' to see what's available."
    end

    def self.error_unknown_mode
      'Program reached an unknown mode.'
    end

    def self.error_invalid_value(arg)
      "Invalid value for \"#{arg}\". Please check your input."
    end

    def self.error_record_missing(table, record_id)
      "No record in table \"#{table}\" with ID = #{record_id.inspect}"
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
end
