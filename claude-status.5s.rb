#!/usr/bin/env ruby

require 'json'

# Claude Session Status Monitor for Kargos
# Refresh interval: 5 seconds (indicated by .5s. in filename)

# Icons for different states
ICON_WAITING = "⏸️"
ICON_WORKING = "⚙️"
ICON_IDLE = "💤"
ICON_CLAUDE = "🤖"

# Colors (in Pango markup format)
COLOR_WAITING = "#FFA500"  # Orange
COLOR_WORKING = "#00FF00"  # Green
COLOR_IDLE = "#808080"     # Gray

# Directory where session state files are stored
SESSIONS_DIR = File.expand_path('~/.claude-sessions')

# Read all session files and return status
def get_sessions
  return [] unless Dir.exist?(SESSIONS_DIR)

  sessions = []
  Dir.glob(File.join(SESSIONS_DIR, '*.json')).each do |file|
    begin
      data = JSON.parse(File.read(file))
      sessions << data
    rescue => e
      # Skip invalid files
    end
  end

  sessions
end

# Get icon for session state
def state_icon(state)
  case state
  when "waiting" then ICON_WAITING
  when "working" then ICON_WORKING
  when "ready" then "✓"
  else "?"
  end
end

# Main display logic
sessions = get_sessions

if sessions.empty?
  # No active sessions
  puts "#{ICON_CLAUDE} #{ICON_IDLE} | color=#{COLOR_IDLE} size=20"
  puts "---"
  puts "No active sessions"
else
  # Display one icon per session (in natural order)
  icons = sessions.map { |s| state_icon(s["state"]) }.join(" ")

  # Color based on most urgent state
  color = if sessions.any? { |s| s["state"] == "waiting" }
    COLOR_WAITING
  elsif sessions.any? { |s| s["state"] == "working" }
    COLOR_WORKING
  else
    COLOR_WORKING
  end

  puts "#{icons} | color=#{color} size=20"
  puts "---"

  # Summary message
  waiting_count = sessions.count { |s| s["state"] == "waiting" }
  working_count = sessions.count { |s| s["state"] == "working" }

  if waiting_count > 0
    puts "#{waiting_count} session#{'s' if waiting_count != 1} waiting for input!"
  elsif working_count > 0
    puts "#{working_count} session#{'s' if working_count != 1} working"
  else
    puts "All sessions ready"
  end

  # Show active sessions in dropdown
  puts "---"
  puts "Active Sessions (#{sessions.size}):"
  sessions.each do |session|
    icon = state_icon(session["state"])
    project = session.dig("metadata", "project") || session["pwd"] || "Unknown"
    project_name = File.basename(project)

    puts "#{icon} #{project_name} (#{session['state']})"
  end
end

# Dropdown menu items
puts "---"
puts "Refresh | refresh=true terminal=false"
puts "Open Claude Code | bash='cd #{ENV['HOME']} && claude' terminal=true"
