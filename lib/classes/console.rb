module PayLog
  module Console
    def self.get_input(prompt = 'pay_log> ')
      command = Readline.readline(prompt, true).to_s.strip
      Readline::HISTORY.pop if command.empty?
      command
    end

    def self.format_money(amount, opts = {})
      decimal_sep = opts[:decimal_sep] || ','
      group_sep = opts[:group_sep] || '.'

      l, r = format('%.2f', amount).split('.')

      sgn = ''
      if l[0] == '-'
        l = l[1..]
        sgn = '-'
      end

      sgn + l.reverse.split('').each_slice(3).to_a.map(&:join).join(group_sep).reverse + decimal_sep + r
    end
  end
end
