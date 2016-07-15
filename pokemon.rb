require_relative 'lib/canvas'
require 'pry' rescue nil
require 'io/console'
class Pokemon
  def initialize
    char_image = Canvas::Image.new File.expand_path('images/chars.png', File.dirname(__FILE__))
    @chars = 128.times.map{|i|char_image.sub(i%16/16.0, i/16/8.0, 1/16.0, 1/8.0)}
  end

  def new_screen
    h, w = STDOUT.winsize
    Canvas::Screen.new w, 2*(h-1)
  end

  def show screen
    commands = screen.to_aa.each_with_index.map{|line, i|
      ["\e[#{i+1};1H", line]
    }
    STDOUT.write commands.join
  end

  def random_pokemon
    Canvas::Image.new File.expand_path("images/pokemon/#{rand(0..151)}.png", File.dirname(__FILE__))
  end

  def ls
    messages = Dir.foreach('.').map{|file|
      next if file =~ /^\./
      File.directory?(file) ? "#{file}/" : file
    }.compact
    messages.unshift ''

    pokemon = random_pokemon

    step = 100

    dst = [0.5, 0.5]
    d1 = [rand(-1..1), rand(-1..1)]
    d2 = [rand(-1..1), rand(-1..1)]
    time0 = Time.now
    loop do
      time = Time.now - time0
      screen = new_screen
      size = 96*(1-Math.exp(-time))
      x, y = dst.zip(d1, d2).map{|d, d1, d2|
        d+d1*Math.exp(-time)+d2*Math.exp(-time/2)
      }
      size *= 1+0.1*(Math.sin(1.4*time)+Math.sin(1.9*time))
      x += 0.1*(Math.sin(2.1*time)+Math.sin(1.7*time))
      y += 0.1*(Math.sin(2.5*time)+Math.sin(1.3*time))
      screen.draw pokemon, screen.width*x-size/2, screen.height*y-size/2, size, size
      messages.each_with_index do |message, index|
        message.chars.each_with_index{|c, i|
          sprite = @chars[c.ord]
          screen.draw sprite, i*8, index*16-20*time, 8, 16 if sprite
        }
      end
      show screen
      sleep 0.05
    end
  end
end

Pokemon.new.ls

#
# # screen.draw chars.sub(0..0.5, 0..0.5), 0, 0, 80, 80
# screen.draw chars[65], 0, 0, 40, 80
#
# puts screen.to_aa
# # binding.pry
#
# p 1
