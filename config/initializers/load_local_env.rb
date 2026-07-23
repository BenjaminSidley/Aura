# Load `.local.env` or `.env.local` into ENV in development to make it easier to run OAuth locally.
# This is development-only and will not run in production.
if Rails.env.development?
  # Try .local.env first (backward compatibility), then .env.local
  local_env = Rails.root.join('.local.env')
  local_env = Rails.root.join('.env.local') unless File.exist?(local_env)
  
  if File.exist?(local_env)
    Rails.logger.info "[local_env] loading environment variables from #{local_env}"
    File.readlines(local_env).each do |line|
      next if line.strip.empty? || line.strip.start_with?('#')
      if line =~ /\A\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)\s*\z/
        key = $1
        raw = $2 || ''
        # remove surrounding quotes if present
        val = raw.gsub(/\A\s*"|"\s*\z/, '').gsub(/\A\s*'|'\s*\z/, '')
        ENV[key] ||= val
        Rails.logger.debug "[local_env] set #{key}=#{ENV[key].inspect}"
      end
    end
  else
    Rails.logger.debug "[local_env] no .local.env or .env.local file found"
  end
end
