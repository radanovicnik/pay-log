module DbTable
  def self.get_by_id(table, record_id)
    DB["v_#{table}".to_sym].first(id: record_id)
  end

  def self.record_to_string(table, record)
    record_str = ''
    columns = []
    return '' if record.to_h.empty?
    case table
    when :accounts
      record_str = <<~RECORD_STR
        ID: #{record[:id]}
        Name: #{record[:name]}
        Balance: #{record[:balance].round(2).to_s('F')} #{record[:currency]}
        Created at: #{record[:created_at]}
        Updated at: #{record[:updated_at]}

      RECORD_STR
    when :payments
      record_str = <<~RECORD_STR
        [#{record[:created_at]}] ID: #{record[:id]}
        From: #{record[:from_account]}
        To: #{record[:to_account]}
        Amount: #{record[:amount].round(2).to_s('F')} #{record[:currency]}
        Description: #{record[:description]}
        
      RECORD_STR
    end
    record_str
  end

  def self.insert(table, record)
    new_record = {}
    case table
    when :accounts
      DB[table].insert(
        {}
      )
    when :payments
    end
  end
end
