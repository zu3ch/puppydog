#!/usr/bin/env ruby
require 'pathname'
require 'json'
require 'set'

#TODO(matt): Delegate student handbook forking to Hemlock

module PhaseConfig
  extend self

  def challenges_as_hash(path)
    challenge_hash = Hash.new do |guide, week|
      guide[week] = Hash.new { |week, day| week[day] = [] }
    end
    find_challenges(path).each do |week, day, matches|
      challenge_hash[week][day] += matches
    end
    challenge_hash
  end

  def challenges_as_list(path)
    list = find_challenges(path).map{|challenge| challenge[2]}.flatten
    list.concat find_resources(path)
    list.sort.uniq
  end

  def challenges_as_portfolio(path)
    challenge_hash = challenges_as_hash(path)
    challenge_hash.keys.each_with_index do |week, index|
      new_key = "week#{index+1}"
      days_hash = challenge_hash[week]

      days_hash.keys.each_with_index do |day, index|
        if day == "weekend" || day == "pre-work"
          days_hash[day] = {core: days_hash[day]}
        else
          days_hash["day#{index+1}"] = {core: days_hash[day]}
          days_hash.delete(day)
        end
      end

      challenge_hash[new_key] = Hash[days_hash.sort]
      challenge_hash.delete(week)
    end
    challenge_hash
  end

  def find_challenges(path)
    repo = File.expand_path(path)
    config_dir = "#{repo}/config"
    glob_pattern = "#{repo}/**/week-*/{monday,tuesday,wednesday,thursday,friday,weekend,pre-work}.md"
    challenge_pattern = /([^\/]*-challenge)\)/
    challenges = []
    challenge_set = Set.new

    Dir.glob(glob_pattern).each do |file|
      path = Pathname.new(file)
      week = path.parent.basename
      day = path.basename(".md")
      matches = path
        .open {|f| f.read.scan(challenge_pattern).flatten }

      challenges << [week.to_s, day.to_s, matches]
      challenge_set.merge(matches)
    end

    challenges
  end

  def find_resources(path)
    repo = File.expand_path(path)
    file = File.read("#{repo}/config/resources.json")
    JSON.parse(file)
  end
end
