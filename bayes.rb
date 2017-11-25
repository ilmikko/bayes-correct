#!env ruby
# 
# Bayesian reasoning and 'smart' error correction
#
# I was an idiot.
#
# This program has two functionalities:
#
# -> Correcting typos
# -> Suggesting words (not really that interesting)

require('json');
require('io/console');

def levDist(str1,str2)
	d = [];
	m = str1.length;
	n = str2.length;

	for i in 0..m
		d[i]=[];
		for j in 0..n
			d[i][j]=0;
		end
	end

	for i in 0..m
		d[i][0]=i+1;
	end

	for j in 0..n
		d[0][j]=j+1;
	end

	for i in 0...m
		for j in 0...n
			if str1[i+1]==str2[j+1]
				cost=0;
			else
				cost=1;
			end

			d[i+1][j+1]=[
				d[i][j+1]+1,
				d[i+1][j]+1,
				d[i][j]+cost
			].min
		end
	end

	return d[m][n];
end

$log=[];
def log(str)
	$log.push(str);
end

require_relative('./inputlistener.rb');

# TODO: ruby input stream

# unix input stream (keylogger)
keys=JSON.parse(File.read('./keys.json'));

ri=0;
bytearr=[];

listener=InputListener.new;

class RubyListener
	@@keymap=JSON.parse(File.read('./keymap.json'));
	def convert(char)
		if @@keymap.key? char
			char=@@keymap[char];
		else
			char=char.upcase;
		end
	end
	def initialize(listener)
		# read standard ruby input events
		STDIN.raw!;
		STDIN.each_char{|char|
			exit if char=="\u0003"; # ^C
			if char=="\e"
				# Watch out for more characters
				char+=STDIN.getch+STDIN.getch;
			end
			listener.down(convert(char));
			listener.status;
		}
	end
end

class LinuxListener
	def initialize(listener)
		# read piped linux kernel input events
		# Usage: cat /dev/input/event0 | ruby bayes.rb
		ARGF.each_byte{|byte|
			ri=(ri+1)%72;

			bytearr.push(byte);

			if (ri==0)
				# Full byte array received
				#puts(bytearr.map{|x| x.to_s(16)}.join(' '));
				eventType=bytearr[44];
				key=bytearr[42];

				if (eventType==1)
					# We're really only interested in keydown events, aren't we?
					#puts("Key: #{keys[key-1]}");
					if keys[key-1]
						listener.down(keys[key-1]);
						listener.status;
					end
				elsif (eventType==2)
					#puts("Hld: #{keys[key-1]}");
					#listener.say(keys[key-1]);
					if keys[key-1]
						listener.hold(keys[key-1]);
						listener.status;
					end
				elsif (eventType==0)
					if keys[key-1]
						listener.up(keys[key-1]);
						listener.status;
					end
				end
				bytearr.clear;
			end
		}
	end
end

# We cannot have both listeners on STDIN.
# Hence the command line parameter '-'.

if ARGV[0]=='-'
	log('Using ruby listener (stdin)');
	RubyListener.new(listener);
else
	log('Using piped input events from kernel (stdin)');
	LinuxListener.new(listener);
end
