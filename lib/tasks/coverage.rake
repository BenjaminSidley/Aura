namespace :coverage do
  desc "Run RSpec and Cucumber with coverage and collate results into coverage/"
  task :all do
    puts "Running RSpec with coverage..."
    rspec_ok = system({ 'SPEC_COVERAGE' => 'true', 'RAILS_ENV' => 'test' }, 'bundle exec rspec')

    begin
      require 'fileutils'
      if File.exist?(File.join('coverage', 'index.html'))
        FileUtils.mkdir_p(File.join('coverage'))
        FileUtils.cp(File.join('coverage', 'index.html'), File.join('coverage', 'rspec_index.html'))
      end
    rescue StandardError => e
      puts "Warning: unable to save RSpec coverage HTML copy: #{e.message}"
    end

    puts "Running Cucumber with coverage..."
    cucumber_ok = system({ 'CUCUMBER_COVERAGE' => 'true', 'RAILS_ENV' => 'test' }, 'bundle exec cucumber --format progress')

    begin
      if File.exist?(File.join('coverage', 'index.html'))
        FileUtils.cp(File.join('coverage', 'index.html'), File.join('coverage', 'cucumber_index.html'))
      end
    rescue StandardError => e
      puts "Warning: unable to save Cucumber coverage HTML copy: #{e.message}"
    end

    begin
      require 'simplecov'
    
      resultsets = Dir.glob(File.join('coverage', '*resultset.json')) + Dir.glob(File.join('coverage', '.*resultset.json'))
      resultsets.uniq!
      if resultsets.empty?
        puts "No SimpleCov resultset files found in coverage/. Check that both runs produced coverage files."
        exit 1 unless rspec_ok && cucumber_ok
      else
        puts "Collating SimpleCov resultsets: \n  - #{resultsets.join("\n  - ")}"
        SimpleCov.collate resultsets, 'rails' do
          enable_coverage :branch
          add_filter '/spec/'
          add_filter '/features/'
          add_filter '/app/controllers/debug_controller.rb'
        end
        puts "Merged coverage report generated at coverage/index.html"
      end
    rescue LoadError => e
      puts "Unable to merge coverage reports: #{e.message}"
    end

    exit(1) unless rspec_ok && cucumber_ok
  end
end
