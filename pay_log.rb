require_relative 'lib/initializers/start'
require_all 'lib/helpers'

mode = Mode.change 'menu'
prompt = DEFAULT_PROMPT
command = ''
table = :payments
record_id = nil
limit = 5
offset = 0

loop do
  case mode

  # Main menu
  when 'menu'
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

    pp 'Table picked'
    pp command

    # table commands
    case command

    # Main menu - table: edit
    when /^e/
      command = command.scan(/^e\s*(.*)/).flatten[0].to_s
      pp command

      mode = Mode.change 'edit'
      record_id = Integer(command) rescue nil
      if command.empty? || record_id.nil?
        prompt = "#{table}|new> "
      else
        prompt = "#{table}|edit|#{record_id}> "
      end

    # Main menu - table: delete
    when /^d/
      command = command.scan(/^d\s*(.*)/).flatten[0].to_s
      pp command

      record_id = Integer(command) rescue nil
      if command.empty? || record_id.nil?
        puts Content.error_unknown_command
        next
      else
        mode = Mode.change 'delete'
        prompt = "#{table}|delete|#{record_id}> "
      end

    # Main menu - table: list
    when /^l/
      command = command.scan(/^l\s*(.*)/).flatten[0].to_s
      pp command

      mode = Mode.change 'list'
      prompt = "#{table}|list> "

    # Main menu - table: -
    else
      puts Content.error_unknown_command
      next
    end

  # Edit record
  when 'edit'
    record = {}
    if record_id.nil?
      case table
      when :accounts
        record = %i(name balance currency).map{|x| [x, nil]}.to_h
      when :payments
        record = %i(from_name to_name description amount currency).map{|x| [x, nil]}.to_h
      end
    else
      record = DbTable.get_by_id(table, record_id)
      puts DbTable.record_to_string(table, record)
    end
    puts Content.mode_edit_help(table)

    loop do
      command = Console.get_input prompt

      case table
      when :accounts
        case command
        when /^n/
          tmp = command.scan(/^n\s*(.*)/).flatten[0].to_s
          if tmp.empty?
            puts Content.error_invalid_value('name')
          else
            record[:name] = tmp
          end
          next
        when /^b/
          tmp = BigDecimal(command.scan(/^b\s*(.*)/).flatten[0].to_s) rescue nil
          if tmp.nil?
            puts Content.error_invalid_value('balance')
          else
            record[:balance] = tmp
          end
          next
        end
      when :payments
        case command
        when /^f/
          tmp = command.scan(/^f\s*(.*)/).flatten[0].to_s
          if tmp.empty?
            puts Content.error_invalid_value('from_name')
          else
            record[:from_name] = tmp
          end
          next
        when /^t/
          tmp = command.scan(/^t\s*(.*)/).flatten[0].to_s
          if tmp.empty?
            puts Content.error_invalid_value('to_name')
          else
            record[:to_name] = tmp
          end
          next
        when /^d/
          tmp = command.scan(/^d\s*(.*)/).flatten[0].to_s
          if tmp.empty?
            puts Content.error_invalid_value('description')
          else
            record[:description] = tmp
          end
          next
        when /^a/
          tmp = BigDecimal(command.scan(/^a\s*(.*)/).flatten[0].to_s) rescue nil
          if tmp.nil?
            puts Content.error_invalid_value('amount')
          else
            record[:amount] = tmp
          end
          next
        end
      end

      case command
      when /^c/
        tmp = command.scan(/^c\s*(.*)/).flatten[0].to_s.upcase
        if tmp.empty? || !CURRENCIES.include?(tmp)
          puts Content.error_invalid_value('currency')
        else
          record[:currency] = tmp
        end
        next
      when '?'
        puts Content.mode_edit_help(table)
        next
      when ''
        next
      when 'q'
        prompt = DEFAULT_PROMPT
        break
      when 's'
        # Save changes
        if record_id.nil?
          DB[table].insert(record)
        else
          old_record = DbTable.get_by_id(table, record_id)
          record_changes = record.filter { |k, v| v != old_record[k] }
          unless record_changes.empty?
            DB[table].update(record_changes)
          end
        end
      end
    end
  when 'delete'
  when 'list'
  else
    puts Content.error_unknown_mode
    puts Content.exit
    break
  end
  
end


require_relative 'lib/initializers/end'
