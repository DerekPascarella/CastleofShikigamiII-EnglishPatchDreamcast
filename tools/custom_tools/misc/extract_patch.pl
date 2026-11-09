#!/usr/bin/perl

use utf8;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HAR;
use Imager;
use Encode qw(decode encode);
use File::Path qw(make_path);

binmode(STDOUT, "encoding(UTF-8)");

chdir($FindBin::Bin);

my $original_folder = "../../gdi_orig_extracted/";
my $patched_folder = "../../gdi_patched_extracted/";
my $dialogue_folder = "../text/dialogue/";
my $executable_layout = "../text/executable/executable_layout.txt";
my $executable_file = "../text/executable/executable.txt";
my $graphics_script = "../graphics/graphics_insert.pl";
my $graphics_folder = "../graphics/";
my $base_address = 0x8C010000;

my @dialogue_archives = ("DEMO1P", "DEMO2PD1", "DEMO2PD2", "DEMO2PF", "DEMO2PM", "DEMO_END");

my %speaker_names = (0 => "Together", 1 => "Fumiko", 2 => "Sayo", 3 => "Niigi", 4 => "Chibi Fumiko", 5 => "Kuga",
					 6 => "Hyuga", 7 => "Kim", 8 => "Roger", 9 => "Arala", 10 => "Anolegos", 11 => "Aja Brothers",
					 12 => "Aja Brothers", 13 => "Yukari", 14 => "Shintaro", 15 => "World Order", 16 => "Narration");

my %opcode_words = (0x02 => 3, 0x06 => 2, 0x15 => 2, 0x16 => 3);
my %texture_formats = (0x01 => "tw", 0x09 => "re", 0x0D => "twre");
my @twiddle = map { twiddle_bits($_) } (0 .. 1023);

print "\nExtracting dialogue...\n\n";

make_path($dialogue_folder);

foreach my $archive (@dialogue_archives)
{
	my $text_file = $dialogue_folder . $archive . ".txt";

	if(-e $text_file)
	{
		print "-> " . $archive . ".txt already exists, skipping.\n";
	}
	else
	{
		my $page_count = extract_dialogue($archive, $text_file);

		print "-> " . $archive . ".txt written (" . $page_count . " pages).\n";
	}
}

print "\nExtracting executable text...\n\n";

if(-e $executable_file)
{
	print "-> executable.txt already exists, skipping.\n";
}
else
{
	my $string_count = extract_executable_text();

	print "-> executable.txt written (" . $string_count . " strings).\n";
}

print "\nExtracting textures...\n\n";

make_path($graphics_folder . "textures/");

foreach my $texture (read_texture_list())
{
	my ($name, $archive, $index) = @{$texture};
	my $output_file = $graphics_folder . ($name =~ /\// ? $name : "textures/" . $name);
	(my $short_name = $output_file) =~ s/.*\///;

	if(-e $output_file)
	{
		print "-> " . $short_name . " already exists, skipping.\n";
		next;
	}

	my $har = read_har($patched_folder . $archive);
	my $data = $har->{'Entries'}->[$index]->{'Data'};

	if($name =~ /\.png$/i)
	{
		pvr_to_image($data)->write(file => $output_file, type => "png") or die "Failed to write " . $output_file . ": " . Imager->errstr();
	}
	else
	{
		write_file_raw($output_file, $data);
	}

	print "-> " . $short_name . " written.\n";
}

print "\nPatch extraction complete!\n\n";

sub extract_dialogue
{
	my $archive = $_[0];
	my $text_file = $_[1];

	my $original_har = read_har($original_folder . $archive . ".HAR");
	my $patched_har = read_har($patched_folder . $archive . ".HAR");
	my @entries = @{$original_har->{'Entries'}};
	my $page_count = 0;

	my $output = "";

	for(my $i = 0; $i < scalar(@entries); $i ++)
	{
		(my $name = $entries[$i]->{'Name'}) =~ s/[ \x00]//g;
		my $patched_index = har_entry_index($patched_har, $name);

		die "extract_dialogue() found no patched script for " . $name if($patched_index < 0);

		my @pages = japanese_pages($entries[$i]->{'Data'});
		my @english = english_pages($patched_har->{'Entries'}->[$patched_index]->{'Data'});

		die "extract_dialogue() found a page count mismatch in " . $name if(scalar(@pages) != scalar(@english));

		$output .= ($output eq "" ? "" : "\n") . "=== " . $name . " ===\n";

		for(my $j = 0; $j < scalar(@pages); $j ++)
		{
			my $speaker = defined($speaker_names{$pages[$j]->{'Speaker'}}) ? $speaker_names{$pages[$j]->{'Speaker'}} : "Speaker " . $pages[$j]->{'Speaker'};

			$output .= "\n[" . ($j + 1) . "] " . $speaker . "\n";
			$output .= "JP: " . $pages[$j]->{'Text'} . "\n";
			$output .= "EN: " . $english[$j] . "\n";
		}

		$page_count += scalar(@pages);
	}

	write_file_raw($text_file, encode("UTF-8", $output));

	return $page_count;
}

sub japanese_pages
{
	my $script = $_[0];

	my @pages;
	my @lines;
	my $speaker = -1;
	my $position = 0;

	while($position < length($script))
	{
		my $opcode = unpack("v", substr($script, $position, 2));

		if($opcode == 0x01)
		{
			my $length = unpack("v", substr($script, $position + 2, 2));
			my $text = decode("cp932", substr($script, $position + 4, $length));

			$text =~ s/\n//g;
			$text =~ s/^\s+|\s+$//g;
			push(@lines, $text) if($text ne "");

			$position += 4 + ($length & ~1);
		}
		else
		{
			$speaker = unpack("v", substr($script, $position + 2, 2)) if($opcode == 0x02);

			if($opcode == 0x07)
			{
				push(@pages, { 'Speaker' => $speaker, 'Text' => join(" / ", @lines) });
				@lines = ();
			}

			last if($opcode == 0x00);

			$position += 2 * (defined($opcode_words{$opcode}) ? $opcode_words{$opcode} : 1);
		}
	}

	return @pages;
}

sub english_pages
{
	my $script = $_[0];

	my @pages;
	my @lines;
	my $translated = 1;
	my $position = 0;

	while($position < length($script))
	{
		my $opcode = unpack("v", substr($script, $position, 2));

		if($opcode == 0x01)
		{
			my $length = unpack("v", substr($script, $position + 2, 2));
			my $line = "";

			for(my $i = 0; $i + 1 < $length; $i += 2)
			{
				my ($lead, $code) = unpack("C C", substr($script, $position + 4 + $i, 2));

				$translated = 0 if($lead != 0x86);
				$line .= ($code - 0x20 == 0x7F) ? "\x{2014}" : chr($code - 0x20);
			}

			push(@lines, $line);

			$position += 4 + ($length & ~1);
		}
		else
		{
			if($opcode == 0x07)
			{
				push(@pages, $translated ? join(" ", @lines) : "");
				@lines = ();
				$translated = 1;
			}

			last if($opcode == 0x00);

			$position += 2 * (defined($opcode_words{$opcode}) ? $opcode_words{$opcode} : 1);
		}
	}

	return @pages;
}

sub extract_executable_text
{
	my $original = read_file_raw($original_folder . "1ST_READ.BIN");
	my $patched = read_file_raw($patched_folder . "1ST_READ.BIN");
	my @layout;
	my %wanted;
	my %pointers;

	foreach my $line (split(/\r?\n/, read_file_raw($executable_layout)))
	{
		next if($line !~ /^\[([0-9A-F]{8}(?:,[0-9A-F]{8})*)\]\s+(\S+)(?:\s+(inplace|new))?\s*$/i);

		my @slots = map { hex($_) } split(/,/, $1);

		push(@layout, { 'Header' => $line, 'Address' => $slots[0], 'Group' => $2, 'Flag' => defined($3) ? lc($3) : "" });
		$wanted{$slots[0]} = 1;
	}

	for(my $offset = 0; $offset + 4 <= length($original); $offset += 4)
	{
		my $value = unpack("V", substr($original, $offset, 4));

		push(@{$pointers{$value}}, $offset) if($wanted{$value});
	}

	my $output = "";

	foreach my $entry (@layout)
	{
		my $address = $entry->{'Address'};
		my %strings;

		if($entry->{'Flag'} eq "inplace")
		{
			$strings{read_string($patched, $address)} = 1;
		}
		elsif($entry->{'Flag'} eq "new")
		{
			$strings{read_string($patched, unpack("V", substr($patched, $address - $base_address, 4)))} = 1;
		}
		else
		{
			foreach my $offset (@{$pointers{$address}})
			{
				my $target = unpack("V", substr($patched, $offset, 4));

				$strings{read_string($patched, $target)} = 1 if($target >= $base_address && $target < $base_address + length($patched));
			}
		}

		die "extract_executable_text() could not find a single string for " . sprintf("%08X", $address) if(scalar(keys %strings) != 1);

		my $english = (keys %strings)[0];
		$english =~ s/^\x81\x40// if($entry->{'Group'} eq "tutorial");

		$output .= $entry->{'Header'} . "\n";
		$output .= "JP: " . japanese_string($original, $address) . "\n" if($entry->{'Flag'} ne "new");
		$output .= "EN: " . english_string($english) . "\n\n";
	}

	write_file_raw($executable_file, encode("UTF-8", $output));

	return scalar(@layout);
}

sub read_string
{
	my $data = $_[0];
	my $offset = $_[1] - $base_address;

	return substr($data, $offset, index($data, "\x00", $offset) - $offset);
}

sub japanese_string
{
	(my $text = read_string($_[0], $_[1])) =~ s/\x0A/\\n/g;
	$text =~ s/([\x00-\x1F])/sprintf("<%02X>", ord($1))/ge;

	return decode("cp932", $text);
}

sub english_string
{
	my $bytes = $_[0];

	my $text = "";

	foreach my $byte (unpack("C*", $bytes))
	{
		if($byte == 0x0A)
		{
			$text .= "\\n";
		}
		elsif($byte >= 0x20 && $byte <= 0x7E)
		{
			$text .= chr($byte);
		}
		else
		{
			$text .= sprintf("<%02X>", $byte);
		}
	}

	return $text;
}

sub read_texture_list
{
	my $script = read_file_raw($graphics_script);
	my @list;

	while($script =~ /\["([^"]+)", \[\["([^"]+\.HAR)", (\d+)\]/g)
	{
		my ($name, $archive, $index) = ($1, $2, $3);

		push(@list, [$name, $archive, $index]) if($name =~ /\.png$/i || $name =~ /^textures\//);
	}

	return @list;
}

sub pvr_to_image
{
	my $data = $_[0];

	my $pvrt = hgpt_pvrt_offset($data);
	my ($pixel_format, $texture_format, $width, $height) = unpack("C C x2 v v", substr($data, $pvrt + 8, 8));

	die "pvr_to_image() found an unsupported texture format" if(!defined($texture_formats{$texture_format}) || $pixel_format > 2);

	my @pixels = unpack("v" . ($width * $height), substr($data, $pvrt + 16, $width * $height * 2));
	my $size = $width < $height ? $width : $height;
	my $image = Imager->new(xsize => $width, ysize => $height, channels => 4);

	for(my $y = 0; $y < $height; $y ++)
	{
		my $scanline = "";

		for(my $x = 0; $x < $width; $x ++)
		{
			my $index;

			if($texture_format == 0x09)
			{
				$index = $y * $width + $x;
			}
			else
			{
				my $block = $width >= $height ? int($x / $size) : int($y / $size);

				$index = $block * $size * $size + (($twiddle[$x % $size] << 1) | $twiddle[$y % $size]);
			}

			$scanline .= pixel_rgba($pixels[$index], $pixel_format);
		}

		$image->setscanline(y => $y, pixels => $scanline);
	}

	return $image;
}

sub pixel_rgba
{
	my $value = $_[0];
	my $pixel_format = $_[1];

	if($pixel_format == 0)
	{
		return pack("C4", int((($value >> 10) & 31) * 255 / 31), int((($value >> 5) & 31) * 255 / 31), int(($value & 31) * 255 / 31), ($value & 0x8000) ? 255 : 0);
	}
	elsif($pixel_format == 1)
	{
		return pack("C4", int((($value >> 11) & 31) * 255 / 31), int((($value >> 5) & 63) * 255 / 63), int(($value & 31) * 255 / 31), 255);
	}

	return pack("C4", (($value >> 8) & 15) * 17, (($value >> 4) & 15) * 17, ($value & 15) * 17, (($value >> 12) & 15) * 17);
}

sub twiddle_bits
{
	my $value = $_[0];

	my $result = 0;

	for(my $bit = 0; $bit < 10; $bit ++)
	{
		$result |= (($value >> $bit) & 1) << (2 * $bit);
	}

	return $result;
}
