#!/bin/ruby

require "open3"
require 'nkf'

def get_ch(info)
  ch_video = ""; ch_audio = []
  info.each_line{|line|
    if /Stream\s+\#(\d+:\d+).+Video.*,\s+(\d+x1080)/i =~ line
      ch_video = $1
    elsif /stream\s+\#(\d+:\d+).+audio.*,\s+(\d+)\s+kb\/s/i =~ line
#      puts line
      #      p $2
      if $2.to_i > 100
        ch_audio << $1
      end
    end
  }
  return ch_video, ch_audio.uniq
end

ARGV.each{|ts|
  if /\.ts/ =~ ts then
    stdout, stderr, status = Open3.capture3("ffprobe #{ts}")
    ffmpegprog = "C\:\\cygwin64\\usr\\local\\bin\\ffmpeg\.exe"
    info = NKF.nkf("-w", stderr)
    v,a  = get_ch(info)

    map_v = " -map #{v}"
    map_a = ""
    a.each{|aa|
      map_a += " -map #{aa}"
    }
    
    outfile = ts.gsub(/\.ts/, '.mp4')
    command = "#{ffmpegprog} -y -i #{ts}  -threads 0 -f mp4"
    command += " -vcodec libx264 -b:v 2000k -vpre libx264 -r 30000/1001 -aspect 16:9 -s 1024x768"
    command += " -bufsize 20000k -maxrate 25000k -vsync 1 -async 1000 -crf 23.0 -level 30 -qmin 10"
    command += " -acodec libfdk_aac -strict experimental -b:a 192k -ac 2 -ar 48000 #{map_v} #{map_a}  #{outfile}"
    puts command
    system(command)

  end
}
