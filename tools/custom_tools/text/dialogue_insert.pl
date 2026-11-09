#!/usr/bin/perl

use utf8;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HAR;
use Encode qw(decode);
use Imager;

binmode(STDOUT, "encoding(UTF-8)");

chdir($FindBin::Bin);

my $input_folder = "dialogue/";
my $original_folder = "../../gdi_orig_extracted/";
my $output_folder = "../../gdi_extracted/";
my $font_widths = "../graphics/font/dialogue_font_widths.txt";
my $font_sheet = "../graphics/font/dialogue_font.png";

my $max_line_width = 412;
my $max_lines = 3;
my $max_script_size = 2048;

my @archives = ("DEMO1P", "DEMO2PD1", "DEMO2PD2", "DEMO2PF", "DEMO2PM", "DEMO_END");
my %opcode_words = (0x02 => 3, 0x06 => 2, 0x15 => 2, 0x16 => 3);

my %widths = map { /^([0-9A-F]{2})\|(\d+)/i ? (hex($1) => $2) : () } split(/\r?\n/, read_file_raw($font_widths));
my %ink = read_ink($font_sheet);
my $error_count = 0;
my $warning_count = 0;

print "\n";

foreach my $archive (@archives)
{
	my %english = read_dialogue_file($input_folder . $archive . ".txt");
	my $original_har = read_har($original_folder . $archive . ".HAR");
	my $har = read_har($output_folder . $archive . ".HAR");
	my @entries = @{$original_har->{'Entries'}};
	my $largest = 0;

	print "-> Processing " . $archive . " (" . scalar(@entries) . " scripts):\n";

	for(my $i = 0; $i < scalar(@entries); $i ++)
	{
		(my $name = $entries[$i]->{'Name'}) =~ s/[ \x00]//g;
		my $script = rebuild_script($name, $entries[$i]->{'Data'}, $english{$name});

		if(length($script) > $max_script_size)
		{
			print "   ERROR: " . $name . " is " . length($script) . " bytes (limit " . $max_script_size . "), skipping!\n";
			$error_count ++;
			next;
		}

		$largest = length($script) if(length($script) > $largest);
		har_replace_entry($har, har_entry_index($har, $name), $script);
	}

	write_har($output_folder . $archive . ".HAR", $har);

	print "   Largest script: " . $largest . " bytes\n\n";
}

print "Total warnings: " . $warning_count . "\n" if($warning_count > 0);
print "Total errors: " . $error_count . "\n" if($error_count > 0);
print "Dialogue complete!\n\n";

sub read_dialogue_file
{
	my $file = $_[0];

	my %pages;
	my $script = "";
	my $page = 0;

	foreach my $line (split(/\r?\n/, decode("UTF-8", read_file_raw($file))))
	{
		if($line =~ /^=== (.+?) ===$/)
		{
			$script = $1;
		}
		elsif($line =~ /^\[(\d+)\]/)
		{
			$page = $1;
		}
		elsif($line =~ /^EN:\s?(.*)$/)
		{
			$pages{$script}{$page} = $1;
		}
	}

	return %pages;
}

sub rebuild_script
{
	my $name = $_[0];
	my $data = $_[1];
	my %english = defined($_[2]) ? %{$_[2]} : ();

	my @ops = parse_script($data);
	my @page_lines;
	my $page_count = scalar(grep { $_->[0] == 0x07 } @ops);

	for(my $page = 1; $page <= $page_count; $page ++)
	{
		my $text = defined($english{$page}) ? $english{$page} : "";

		if($text eq "")
		{
			print "   WARNING: " . $name . " page " . $page . " has no English, keeping original.\n";
			$warning_count ++;
			$page_lines[$page] = undef;
			next;
		}

		my @lines = wrap_text($text);

		if(scalar(@lines) > $max_lines)
		{
			print "   ERROR: " . $name . " page " . $page . " needs " . scalar(@lines) . " lines (limit " . $max_lines . ").\n";
			$error_count ++;
		}

		$page_lines[$page] = \@lines;
	}

	my $output = "";
	my $page = 1;
	my $text_written = 0;

	for(my $i = 0; $i < scalar(@ops); $i ++)
	{
		my ($opcode, $raw) = @{$ops[$i]};

		if($opcode == 0x01)
		{
			if(!defined($page_lines[$page]))
			{
				$output .= $raw;
			}
			elsif(!$text_written)
			{
				foreach my $line (@{$page_lines[$page]})
				{
					my $encoded = encode_line($line, $name, $page);
					$output .= pack("v v", 0x01, length($encoded)) . $encoded;
				}

				$text_written = 1;
			}
		}
		elsif($opcode == 0x16)
		{
			my ($columns, $rows) = unpack("v v", substr($raw, 2, 4));
			my ($block_width, $block_lines) = caption_extent(\@ops, $i, $page, \@page_lines);

			$columns = int(($block_width + 19) / 20) if($block_width > 0);
			$rows = $block_lines if($block_lines > $rows);

			$output .= pack("v v v", 0x16, $columns, $rows);
		}
		else
		{
			$output .= $raw;

			if($opcode == 0x07)
			{
				$page ++;
				$text_written = 0;
			}
		}
	}

	return $output;
}

sub caption_extent
{
	my @ops = @{$_[0]};
	my $start = $_[1];
	my $page = $_[2];
	my @page_lines = @{$_[3]};

	my ($width, $lines) = (0, 0);

	for(my $i = $start + 1; $i < scalar(@ops) && $ops[$i]->[0] != 0x11 && $ops[$i]->[0] != 0x00; $i ++)
	{
		if($ops[$i]->[0] == 0x07)
		{
			if(defined($page_lines[$page]))
			{
				foreach my $line (@{$page_lines[$page]})
				{
					$width = line_width($line) if(line_width($line) > $width);
				}

				$lines = scalar(@{$page_lines[$page]}) if(scalar(@{$page_lines[$page]}) > $lines);
			}

			$page ++;
		}
	}

	return ($width, $lines);
}

sub parse_script
{
	my $data = $_[0];

	my @ops;
	my $position = 0;

	while($position < length($data))
	{
		my $opcode = unpack("v", substr($data, $position, 2));
		my $size = 2 * (defined($opcode_words{$opcode}) ? $opcode_words{$opcode} : 1);

		$size = 4 + (unpack("v", substr($data, $position + 2, 2)) & ~1) if($opcode == 0x01);

		push(@ops, [$opcode, substr($data, $position, $size)]);
		$position += $size;

		last if($opcode == 0x00);
	}

	return @ops;
}

sub wrap_text
{
	my $text = $_[0];

	my @lines;

	foreach my $segment (split(/\s*<NL>\s*/i, $text))
	{
		my $line = "";

		foreach my $word (split(/ +/, $segment))
		{
			my $candidate = $line eq "" ? $word : $line . " " . $word;

			if(line_width($candidate) <= $max_line_width || $line eq "")
			{
				$line = $candidate;
			}
			else
			{
				push(@lines, $line);
				$line = $word;
			}
		}

		push(@lines, $line);
	}

	return @lines;
}

sub line_width
{
	my $pen = 0;
	my $width = 0;

	foreach my $character (split(//, $_[0]))
	{
		my $code = character_code($character);

		$width = $pen + $ink{$code} if($pen + $ink{$code} > $width);
		$pen += $widths{$code};
	}

	$width = $pen if($pen > $width);

	return $width;
}

sub read_ink
{
	my $file = $_[0];

	my %result;
	my $sheet = Imager->new(file => $file) or die "Failed to read " . $file . ": " . Imager->errstr();

	for(my $i = 0; $i < 96; $i ++)
	{
		$result{0x20 + $i} = 0;

		for(my $x = 0; $x < 20; $x ++)
		{
			for(my $y = 0; $y < 20; $y ++)
			{
				my @color = $sheet->getpixel(x => ($i % 16) * 20 + $x, y => int($i / 16) * 20 + $y)->rgba();

				$result{0x20 + $i} = $x + 1 if($color[3] > 0);
			}
		}
	}

	return %result;
}

sub character_code
{
	my $character = $_[0];

	return 0x7F if($character eq "\x{2014}");
	return ord($character) if(ord($character) >= 0x20 && ord($character) <= 0x7E);
	return -1;
}

sub encode_line
{
	my $line = $_[0];
	my $name = $_[1];
	my $page = $_[2];

	my $encoded = "";

	foreach my $character (split(//, $line))
	{
		my $code = character_code($character);

		if($code < 0)
		{
			print "   ERROR: " . $name . " page " . $page . " has unsupported character \"" . $character . "\".\n";
			$error_count ++;
			next;
		}

		$encoded .= pack("C C", 0x86, $code + 0x20);
	}

	return $encoded;
}
