require_relative 'lib/scripts/start'
require_all 'lib/classes'

# Modes:
# :menu, :edit, :delete, :list
mode = :menu
prompt = DEFAULT_PROMPT
command = ''
table = :payments
record_id = nil

puts PayLog::Content.title

loop do
  case mode

  # Main menu
  when :menu
    record_id = nil
    command = PayLog::Console.get_input prompt

    # Main menu: general commands, pick table
    case command
    when 'q'
      puts PayLog::Content.exit
      break
    when '?'
      puts
      puts PayLog::Content.help
      next
    when ''
      next
    when /^a/
      table = :accounts
    when /^p/
      table = :payments
    else
      puts PayLog::Content.error_unknown_command
      next
    end

    command = command.scan(/^[ap]\s*([edl].*)/).flatten[0].to_s

    # table commands
    case command
    # Main menu - table: edit
    when /^e/
      command = command.scan(/^e\s*(.*)/).flatten[0].to_s

      mode = :edit
      record_id = Integer(command) rescue nil
      if command.empty? || record_id.nil?
        prompt = "#{table}|new> "
      else
        prompt = "#{table}|edit|#{record_id}> "
      end

    # Main menu - table: delete
    when /^d/
      command = command.scan(/^d\s*(.*)/).flatten[0].to_s

      record_id = Integer(command) rescue nil
      if command.empty? || record_id.nil?
        puts PayLog::Content.error_unknown_command
        next
      else
        mode = :delete
        prompt = "#{table}|delete|#{record_id}> "
      end

    # Main menu - table: list
    when /^l/
      command = command.scan(/^l\s*(.*)/).flatten[0].to_s

      mode = :list
      prompt = "#{table}|list> "

    # Main menu - table: -
    else
      puts PayLog::Content.error_unknown_command
      next
    end

  # Edit record
  when :edit
    record = {}
    old_record = {}
    if record_id.nil?
      case table
      when :accounts
        record = %i(name balance currency).map{|x| [x, nil]}.to_h
      when :payments
        record = %i(from_name to_name description amount currency).map{|x| [x, nil]}.to_h
      end
      puts
    else
      old_record = PayLog::DbTable.get_by_id(table, record_id)
      if old_record.nil?
        puts PayLog::Content.error_record_missing(table, record_id)
        mode = :menu
        prompt = DEFAULT_PROMPT
        next
      end
      puts
      puts PayLog::DbTable.record_to_string(table, old_record)
    end
    puts PayLog::Content.mode_edit_help(table)

    loop do
      field = nil
      command = PayLog::Console.get_input prompt

      case table
      when :accounts
        case command
        when /^n/
          field = :name
          tmp = command.scan(/^n\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts PayLog::Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts PayLog::DbTable.field_to_string(field, record[field])
          end
          next
        when /^b/
          field = :balance
          tmp = BigDecimal(command.scan(/^b\s*(.*)/).flatten[0].to_s) rescue nil
          if tmp.nil?
            puts PayLog::Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts PayLog::DbTable.field_to_string(field, record[field])
          end
          next
        end
      when :payments
        case command
        when /^[ft]/
          field = command.match?(/^f/) ? :from_name : :to_name
          tmp = command.scan(/^#{field[0]}\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts PayLog::Content.error_invalid_value(field)
          else
            matching_accounts = PayLog::DbTable.get_all(:accounts, search_word: tmp)
            matching_accounts = matching_accounts.map{|a| a[:name]}.uniq
            matching_count = matching_accounts.size

            if matching_count == 0
              record[field] = tmp

            elsif matching_count == 1
              record[field] = matching_accounts[0]

            elsif matching_count <= MAX_CHOICES
              puts 'Matching accounts:'
              matching_accounts.each_with_index { |a, i| puts("  [#{i+1}] #{a}") }
              puts
              print 'Pick one (by typing the number in []) '
              command = gets.strip

              account_pick = Integer(command) rescue nil
              if account_pick.nil? || account_pick < 1 || account_pick > matching_count
                puts 'Invalid input. No account picked.'
                next
              else
                record[field] = matching_accounts[account_pick - 1]
              end

            else
              puts 'Too many accounts matching. Try to be more specific.'
              next
              
            end
            puts PayLog::DbTable.field_to_string(field, record[field])
          end
          next
        when /^d/
          field = :description
          tmp = command.scan(/^d\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts PayLog::Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts PayLog::DbTable.field_to_string(field, record[field])
          end
          next
        when /^a/
          field = :amount
          tmp = BigDecimal(command.scan(/^a\s*(.*)/).flatten[0].to_s) rescue nil
          if tmp.nil?
            puts PayLog::Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts PayLog::DbTable.field_to_string(field, record[field])
          end
          next
        end
      end

      case command
      when /^c/
        field = :currency
        tmp = command.scan(/^c\s*(.*)/).flatten[0].to_s.strip.upcase
        if tmp.empty? || !CURRENCIES.include?(tmp)
          puts PayLog::Content.error_invalid_value(field)
        else
          record[field] = tmp
          puts PayLog::DbTable.field_to_string(field, record[field])
        end
        next
      when '?'
        puts PayLog::Content.mode_edit_help(table)
        next
      when ''
        next
      when 'q'
        mode = :menu
        prompt = DEFAULT_PROMPT
        break
      when 's'
        # Save changes
        new_record_id = nil
        begin
          if record_id.nil?
            new_record_id = PayLog::DbTable.insert(table, record)
          else
            PayLog::DbTable.update(table, record_id, record)
            new_record_id = record_id
          end
          puts "\nRecord saved!\n\n"
          puts PayLog::DbTable.record_to_string(table, PayLog::DbTable.get_by_id(table, new_record_id))
        rescue ArgumentError => e
          puts e.message
        end
        next
      else
        puts PayLog::Content.error_unknown_command
        next
      end
    end

  # Delete record
  when :delete
    replacement_account = nil
    old_record = PayLog::DbTable.get_by_id(table, record_id)
    if old_record.nil?
      puts PayLog::Content.error_record_missing(table, record_id)
      mode = :menu
      prompt = DEFAULT_PROMPT
      next
    end
    puts
    puts PayLog::DbTable.record_to_string(table, old_record)
    puts PayLog::Content.mode_delete_help(table)

    loop do
      command = PayLog::Console.get_input prompt

      case table
      when :accounts
        case command
        when /^n/
          tmp = command.scan(/^n\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts PayLog::Content.error_invalid_value(:name)
          else
            replacement_account = tmp
            puts PayLog::DbTable.field_to_string(:name, replacement_account)
          end
          next
        end
      end

      case command
      when '?'
        puts PayLog::Content.mode_delete_help(table)
        next
      when ''
        next
      when 'q'
        mode = :menu
        prompt = DEFAULT_PROMPT
        break
      when 's'
        # Start deletion
        print 'Delete this record? [y/n]  '
        command = gets.strip.downcase

        if command == 'y'
          begin
            PayLog::DbTable.delete(table, record_id, replacement_account)
          rescue ArgumentError => e
            puts e.message
          else
            puts "Record deleted.\n\n"
          ensure
            mode = :menu
            prompt = DEFAULT_PROMPT
            break
          end
        else
          puts "Deletion cancelled.\n\n"
        end
        next
      else
        puts PayLog::Content.error_unknown_command
        next
      end
    end

  # Display records
  when :list
    filters = {
      search_word: nil,
      limit: DEFAULT_PAGE_SIZE,
      offset: nil
    }
    puts
    puts PayLog::Content.mode_list_help

    loop do
      command = PayLog::Console.get_input prompt

      case command
      when /^w/
        name = :search_word
        tmp = command.scan(/^w\s*(.*)/).flatten[0].to_s.strip
        if tmp.empty?
          puts PayLog::Content.error_invalid_value(name)
        else
          filters[name] = tmp
          puts PayLog::DbTable.field_to_string(name, filters[name])
        end
        next
      when /^l/
        name = :limit
        tmp = Integer(command.scan(/^l\s*(\d*)/).flatten[0].to_s) rescue nil
        if tmp.nil?
          puts PayLog::Content.error_invalid_value(name)
        else
          filters[name] = tmp
          puts PayLog::DbTable.field_to_string(name, filters[name])
        end
        next
      when /^o/
        name = :offset
        tmp = Integer(command.scan(/^o\s*(\d*)/).flatten[0].to_s) rescue nil
        if tmp.nil?
          puts PayLog::Content.error_invalid_value(name)
        else
          filters[name] = tmp
          puts PayLog::DbTable.field_to_string(name, filters[name])
        end
        next
      when '?'
        puts PayLog::Content.mode_delete_help(table)
        next
      when ''
        next
      when 'q'
        mode = :menu
        prompt = DEFAULT_PROMPT
        break
      when 's'
        # Search using given parameters
        records = PayLog::DbTable.get_all(table, filters)
        puts
        records.each { |r| puts PayLog::DbTable.record_to_string(table, r) }
        next
      when 'n'
        # Search next page
        filters[:offset] = filters[:offset].to_i + filters[:limit]
        records = PayLog::DbTable.get_all(table, filters)
        puts
        records.each { |r| puts PayLog::DbTable.record_to_string(table, r) }
        next
      else
        puts PayLog::Content.error_unknown_command
        next
      end
    end

  else
    puts PayLog::Content.error_unknown_mode
    puts PayLog::Content.exit
    break
  end
  
end


require_relative 'lib/scripts/end'
