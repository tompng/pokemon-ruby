require_relative 'lib/canvas'
require 'io/console'
require 'digest'
class Pokemon
  def initialize
    char_image = load_image 'images/chars.png'
    @chars = 128.times.map{|i|char_image.sub(i%16/16.0, i/16/8.0, 1/16.0, 1/8.0)}
  end

  def load_image file
    Canvas::Image.new File.expand_path(file, File.dirname(__FILE__))
  end

  def new_screen
    h, w = STDOUT.winsize
    Canvas::Screen.new w, 2*(h-1)
  end

  def show screen
    commands = screen.to_aa.each_with_index.map{|line, i|
      ["\n\e[#{i+1};1H", line]
    }
    STDOUT.write commands.join
  end

  def random_pokemon path
    hexdigest = ::Digest::SHA1.hexdigest path
    dir = Dir.new File.expand_path('images/pokemon', File.dirname(__FILE__))
    files = dir.each.to_a.grep(/.*\.png$/).sort
    file = files[hexdigest.to_i(16)%files.size]
    load_image "images/pokemon/#{file}"
  end

  def run
    messages = Dir.foreach('.').map{|file|
      next if file =~ /^\./
      File.directory?(file) ? "#{file}/" : file
    }.compact
    messages.unshift ''

    ball1 = load_image 'images/ball1.png'
    smoke = load_image 'images/smoke.png'
    ball2 = load_image 'images/ball2.png'
    ball3 = load_image 'images/ball3.png'

    pokemon = random_pokemon File.absolute_path '.'

    step = 100

    dst = [0.5, 0.5]
    d1 = [rand(-1..1), rand(-1..1)]
    d2 = [rand(-1..1), rand(-1..1)]
    time0 = Time.now
    gettime = 20
    exit_flag = false
    Thread.new{
      loop{
        ch = STDIN.noecho &:getch
        if ["\x03", "\x1C", 'q', 'Q'].include? ch
          exit_flag = true
        else
          gettime = [[gettime, Time.now - time0].min, 2].max
        end
      }
    }
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


      throwtime = 1
      if !gettime || time < gettime + throwtime
        screen.draw pokemon, screen.width*x-size/2, screen.height*y-size/2, size, size
      end
      messages.each_with_index do |message, index|
        message.chars.each_with_index{|c, i|
          sprite = @chars[c.ord]
          screen.draw sprite, i*8, index*16-20*time, 8, 16 if sprite
        }
      end
      if gettime && gettime < time
        phase = time - gettime
        yt = [phase*2, 0.5].max
        pos = 4*(yt%1)*(1-yt%1)*Math.exp(-yt.floor)
        if phase < throwtime
          screen.draw(
            smoke,
            size/4.0*(2*rand-1)+screen.width/2-size/2,
            size/4.0*(2*rand-1)+screen.height/2-size/2,
            size,size
          )
        end
        pos = 0 if phase > 2
        ball = phase > 5 ? ball3 : phase < 1 ? ball1 : phase%1 < 0.1 ? ball2 : ball1
        screen.draw ball, screen.width/2,(screen.height/2+20)*(1-pos)-20, 20, 20
        if phase > 5
          set_gotcha! screen
          show screen
          save pokemon
          exit
        end
      end
      show screen
      exit if exit_flag
      sleep 0.05
    end
  end

  def set_gotcha! screen
    msg = "Gotcha!"
    xsize = 80/msg.size
    ysize = 2*xsize
    r = 4
    (-r..xsize*msg.size+r).each{|x|(-r..ysize).each{|y|
      pos = screen.width/2-msg.size/2.0*xsize+x, screen.height-ysize+y
      r = 4
      dx = 1-[-x, x-xsize*msg.size, 0].max.fdiv(r)
      dy = 1-[-y, y-ysize, 0].max.fdiv(r)
      screen.plot *pos, 1, 0.8*dx*dy
    }}
    msg.chars.each_with_index{|c, i|
      screen.draw(
        @chars[c.ord],
        screen.width/2+(i-msg.size/2.0)*xsize,
        screen.height-ysize,
        xsize,
        2*xsize
      )
    }
  end

  def save pokemon
    screen = Canvas::Screen.new 80, 80
    screen.draw pokemon, 0, 0, 80, 80
    set_gotcha! screen
    File.write 'pokemon.txt', screen.to_aa.join("\n")+"\n"
  end
end

Pokemon.new.run
