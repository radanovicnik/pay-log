module Console
  def self.get_input(prompt = 'pay_log> ')
    command = Readline.readline(prompt, true).to_s.strip
    Readline::HISTORY.pop if command.empty?
    command
  end
end