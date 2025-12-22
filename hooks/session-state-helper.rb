#!/usr/bin/env ruby
# Helper script to manage Claude session state files

require 'json'
require 'fileutils'

# Directory to store session state files
SESSIONS_DIR = File.expand_path('~/.claude-sessions')

# Ensure the sessions directory exists
FileUtils.mkdir_p(SESSIONS_DIR)

# Read hook input from STDIN
def read_hook_input
  begin
    input = STDIN.read
    return nil if input.nil? || input.empty?
    JSON.parse(input)
  rescue JSON::ParserError => e
    STDERR.puts "ERROR: Failed to parse JSON from STDIN: #{e.message}"
    exit 1
  end
end

# Get the session file path
def session_file(session_id)
  File.join(SESSIONS_DIR, "#{session_id}.json")
end

# Update session state
def update_session_state(hook_data, state, extra_metadata = {})
  session_id = hook_data['session_id']

  if session_id.nil? || session_id.empty?
    STDERR.puts "ERROR: session_id not found in hook input"
    exit 1
  end

  file_path = session_file(session_id)

  metadata = {
    cwd: hook_data['cwd'],
    transcript_path: hook_data['transcript_path'],
    permission_mode: hook_data['permission_mode'],
    project_dir: ENV['CLAUDE_PROJECT_DIR']
  }.merge(extra_metadata)

  data = {
    session_id: session_id,
    state: state,
    timestamp: Time.now.to_i,
    pwd: hook_data['cwd'] || ENV['PWD'] || Dir.pwd,
    metadata: metadata
  }

  File.write(file_path, JSON.pretty_generate(data))
end

# Remove session state file
def remove_session_state(hook_data)
  session_id = hook_data['session_id']

  if session_id.nil? || session_id.empty?
    STDERR.puts "ERROR: session_id not found in hook input"
    exit 1
  end

  file_path = session_file(session_id)
  File.delete(file_path) if File.exist?(file_path)
end

# Main execution
if __FILE__ == $0
  command = ARGV[0]
  hook_data = read_hook_input

  if hook_data.nil?
    STDERR.puts "ERROR: No input data received from STDIN"
    exit 1
  end

  case command
  when 'start'
    source = hook_data['source'] || 'unknown'
    update_session_state(hook_data, 'waiting', source: source)
  when 'stop'
    update_session_state(hook_data, 'ready')
  when 'waiting'
    notification_type = hook_data['notification_type']
    message = hook_data['message']
    update_session_state(hook_data, 'waiting', notification_type: notification_type, message: message)
  when 'working'
    prompt = hook_data['prompt']
    update_session_state(hook_data, 'working', prompt: prompt)
  when 'end'
    remove_session_state(hook_data)
  else
    STDERR.puts "Unknown command: #{command}"
    STDERR.puts "Usage: #{$0} {start|stop|waiting|working|end}"
    exit 1
  end
end
