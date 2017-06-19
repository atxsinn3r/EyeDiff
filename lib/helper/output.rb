module Helper
  class Output
    def self.print_status(msg='')
      puts "[*] #{msg}"
    end

    def self.print_error(msg='')
      puts "[x] #{msg}"
    end
  end
end
