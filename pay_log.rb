require_relative 'lib/initializers/start'
require_all 'lib/helpers'

# Modes:
# :menu, :edit, :delete, :list
mode = :menu
prompt = DEFAULT_PROMPT
command = ''
table = :payments
record_id = nil

loop do
  case mode

  # Main menu
  when :menu
    record_id = nil
    command = Console.get_input prompt

    # Main menu: general commands, pick table
    case command
    when 'q'
      puts Content.exit
      break
    when '?'
      puts Content.help
      next
    when ''
      next
    when /^a/
      table = :accounts
    when /^p/
      table = :payments
    else
      puts Content.error_unknown_command
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
        puts Content.error_unknown_command
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
      puts Content.error_unknown_command
      next
    end

  # Edit record
  when :edit
    record = {}
    old_record = {}
    puts
    if record_id.nil?
      case table
      when :accounts
        record = %i(name balance currency).map{|x| [x, nil]}.to_h
      when :payments
        record = %i(from_name to_name description amount currency).map{|x| [x, nil]}.to_h
      end
    else
      old_record = DbTable.get_by_id(table, record_id)
      puts DbTable.record_to_string(table, old_record)
    end
    puts Content.mode_edit_help(table)

    loop do
      field = nil
      command = Console.get_input prompt

      case table
      when :accounts
        case command
        when /^n/
          field = :name
          tmp = command.scan(/^n\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts DbTable.field_to_string(field, record[field])
          end
          next
        when /^b/
          field = :balance
          tmp = BigDecimal(command.scan(/^b\s*(.*)/).flatten[0].to_s) rescue nil
          if tmp.nil?
            puts Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts DbTable.field_to_string(field, record[field])
          end
          next
        end
      when :payments
        case command
        when /^f/
          field = :from_name
          tmp = command.scan(/^f\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts DbTable.field_to_string(field, record[field])
          end
          next
        when /^t/
          field = :to_name
          tmp = command.scan(/^t\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts DbTable.field_to_string(field, record[field])
          end
          next
        when /^d/
          field = :description
          tmp = command.scan(/^d\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts DbTable.field_to_string(field, record[field])
          end
          next
        when /^a/
          field = :amount
          tmp = BigDecimal(command.scan(/^a\s*(.*)/).flatten[0].to_s) rescue nil
          if tmp.nil?
            puts Content.error_invalid_value(field)
          else
            record[field] = tmp
            puts DbTable.field_to_string(field, record[field])
          end
          next
        end
      end

      case command
      when /^c/
        field = :currency
        tmp = command.scan(/^c\s*(.*)/).flatten[0].to_s.strip.upcase
        if tmp.empty? || !CURRENCIES.include?(tmp)
          puts Content.error_invalid_value(field)
        else
          record[field] = tmp
          puts DbTable.field_to_string(field, record[field])
        end
        next
      when '?'
        puts Content.mode_edit_help(table)
        next
      when ''
        next
      when 'q'
        mode = :menu
        prompt = DEFAULT_PROMPT
        break
      when 's'
        # Save changes
        begin
          if record_id.nil?
            DbTable.insert(table, record)
          else
            DbTable.update(table, record_id, record)
          end
          puts "\nRecord saved!\n\n"
          puts DbTable.record_to_string(table, record)
        rescue ArgumentError => e
          puts e.message
        end
        next
      end
    end

  # Delete record
  when :delete
    replacement_account = nil
    old_record = DbTable.get_by_id(table, record_id)
    puts
    puts DbTable.record_to_string(table, old_record)
    puts Content.mode_delete_help(table)

    loop do
      command = Console.get_input prompt

      case table
      when :accounts
        case command
        when /^n/
          tmp = command.scan(/^n\s*(.*)/).flatten[0].to_s.strip
          if tmp.empty?
            puts Content.error_invalid_value(:name)
          else
            replacement_account = tmp
            puts DbTable.field_to_string(:name, replacement_account)
          end
          next
        end
      end

      case command
      when '?'
        puts Content.mode_delete_help(table)
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
            DbTable.delete(table, record_id, replacement_account)
          rescue ArgumentError => e
            puts e.message
          else
            puts "Record deleted.\n\n"
            prompt = DEFAULT_PROMPT
          ensure
            break
          end
        else
          puts "Deletion cancelled.\n\n"
        end
        next
      end
    end

  # Display records
  when :list
    filters = {
      search_word: '',
      limit: DEFAULT_PAGE_SIZE,
      offset: nil
    }
    puts
    puts Content.mode_list_help

    loop do
      command = Console.get_input prompt

      case command
      when /^w/
        name = :search_word
        tmp = command.scan(/^w\s*(.*)/).flatten[0].to_s.strip
        if tmp.empty?
          puts Content.error_invalid_value(name)
        else
          filters[name] = tmp
          puts DbTable.field_to_string(name, filters[name])
        end
        next
      when /^l/
        name = :limit
        tmp = Integer(command.scan(/^l\s*(\d*)/).flatten[0].to_s) rescue nil
        if tmp.nil?
          puts Content.error_invalid_value(name)
        else
          filters[name] = tmp
          puts DbTable.field_to_string(name, filters[name])
        end
        next
      when /^o/
        name = :offset
        tmp = Integer(command.scan(/^o\s*(\d*)/).flatten[0].to_s) rescue nil
        if tmp.nil?
          puts Content.error_invalid_value(name)
        else
          filters[name] = tmp
          puts DbTable.field_to_string(name, filters[name])
        end
        next
      when '?'
        puts Content.mode_delete_help(table)
        next
      when ''
        next
      when 'q'
        mode = :menu
        prompt = DEFAULT_PROMPT
        break
      when 's'
        # Search using given parameters
        records = DbTable.get_all(table, filters)
        puts
        records.each { |r| puts DbTable.record_to_string(table, r) }
        next
      when 'n'
        # Search next page
        filters[:offset] = filters[:offset].to_i + filters[:limit]
        records = DbTable.get_all(table, filters)
        puts
        records.each { |r| puts DbTable.record_to_string(table, r) }
        next
      end
    end

  else
    puts Content.error_unknown_mode
    puts Content.exit
    break
  end
  
end


require_relative 'lib/initializers/end'
