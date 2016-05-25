module Elbas
  module Logger
    def info(message)
      $stdout.puts "** elbas: #{message}"
    end
  end
end
