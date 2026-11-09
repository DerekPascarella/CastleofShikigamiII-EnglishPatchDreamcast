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

my $input_file = "executable/executable.txt";
my $original_executable = "../../gdi_orig_extracted/1ST_READ.BIN";
my $output_executable = "../../gdi_extracted/1ST_READ.BIN";
my $font_widths = "../graphics/font/dialogue_font_widths.txt";
my $font_sheet = "../graphics/font/dialogue_font.png";
my $base_address = 0x8C010000;

my @text_runs = ([0x8C13B5C4, 0x8C13BEA3], [0x8C13BF60, 0x8C13C16B], [0x8C13C188, 0x8C13C577], [0x8C13C8E4, 0x8C13CAB3],
				 [0x8C13CCFC, 0x8C13CE57], [0x8C13CE5C, 0x8C13D0E3], [0x8C13D0F0, 0x8C13D36F]);

my @spare_runs = ([0x8C13B448, 0x8C13B597], [0x8C0B9D04, 0x8C0B9FB1], [0x8C0B9164, 0x8C0B92D7]);
my @dead_code_runs = ([0x8C114296, 0x8C114377]);

my $staff_table_original = 0x8C1A6DBC;
my @staff_table = (0x8C13D9F4, 0x8C13DE23);
my @staff_table_literals = ([0x8C11F9EC, 0], [0x8C11FB5C, 8]);

my %group_limits = ("options_help" => 296, "extra_help" => 368, "tutorial" => 440, "gallery" => 422,
					"vertical_warning" => 568, "confirm" => 448, "vmu" => 472, "button_name" => 20,
					"options_label" => 179, "options_value" => 240, "extra_value" => 164, "extra_header" => 411,
					"button_header" => "orig", "pause" => 220, "attract" => "orig", "results_label" => 202,
					"results_value" => "orig", "ranking" => 360, "ranking_name" => "orig", "practice_lg" => "orig",
					"practice_lw" => 440, "names" => 341, "staff" => 452, "vms_header" => "none",
					"invincible_label" => 179, "invincible_help" => 296);
my %box_groups = ("vertical_warning" => 1, "confirm" => 1);

my %fonts = ("ankfont" => [0x8C15AC60, "SYSTEM.HAR", "ankfont.hpt"], "font_lw" => [0x8C1A4F4C, "SYSTEM.HAR", "font_lw.hpt"],
			 "font_lg" => [0x8C1A4F5C, "SYSTEM.HAR", "font_lg.hpt"], "font_lwp" => [0x8C1A4F7C, "SYSTEM.HAR", "font_lwp.hpt"],
			 "font1" => [0x8C1A6678, "SYSTEM.HAR", "font1.hpt"], "gre04" => [0x8C1A4A50, "HISCORE.HAR", "gre04.hpt"],
			 "gre02" => [0x8C1A4A30, "HISCORE.HAR", "gre02.hpt"], "srfont" => [0x8C1A6DAC, "TITLE3.HAR", "srfont.hpt"]);

my %group_fonts = ("options_label" => "ankfont", "options_value" => "ankfont", "extra_value" => "font_lw",
				   "extra_header" => "font_lw", "button_header" => "font_lwp", "pause" => "font_lw", "attract" => "ankfont",
				   "results_label" => "gre04", "results_value" => "gre02", "ranking" => "ankfont", "ranking_name" => "ankfont",
				   "practice_lg" => "font_lg", "practice_lw" => "font_lw", "names" => "font1", "staff" => "srfont",
				   "invincible_label" => "ankfont");

my %widths = map { /^([0-9A-F]{2})\|(\d+)/i ? (hex($1) => $2) : () } split(/\r?\n/, read_file_raw($font_widths));
my %ink = read_ink($font_sheet);
my $executable = read_file_raw($original_executable);
my %new_entries;
my %entries = read_text_file($input_file);
my %font_metrics = map { $_ => read_font($fonts{$_}) } keys %fonts;
my %slot_sizes;
my $error_count = 0;

print "\nRead " . (scalar(keys %entries) + scalar(keys %new_entries)) . " string(s) from " . $input_file . ".\n\n";

foreach my $run (@text_runs, [@staff_table])
{
	my $position = $run->[0];

	while($position <= $run->[1])
	{
		my $byte = ord(substr($executable, $position - $base_address, 1));

		if($byte == 0)
		{
			$position ++;
			next;
		}

		if(!defined($entries{$position}))
		{
			print "-> ERROR: original string at " . sprintf("%08X", $position) . " has no English entry.\n";
			$error_count ++;
		}

		$position = index($executable, "\x00", $position - $base_address) + $base_address + 1;
	}
}

my %box_glyphs;

foreach my $address (sort { $a <=> $b } keys %entries)
{
	my $entry = $entries{$address};
	my $limit = $group_limits{$entry->{'Group'}};

	if(!defined($limit))
	{
		print "-> ERROR: " . sprintf("%08X", $address) . " has unknown group \"" . $entry->{'Group'} . "\".\n";
		$error_count ++;
		next;
	}

	my $font = $group_fonts{$entry->{'Group'}};

	if($limit eq "orig")
	{
		$limit = 0;

		foreach my $line (split(/\\n/, display_text(original_string($address))))
		{
			my $width = measure_line($font, $line, $address);
			$limit = $width if($width > $limit);
		}
	}

	my $display = display_text($entry->{'Text'});

	foreach my $line ($limit eq "none" ? () : split(/\\n/, $display))
	{
		my $width = measure_line($font, $line, $address);

		if($width > $limit)
		{
			print "-> ERROR: " . sprintf("%08X", $address) . " line is " . $width . " px (limit " . $limit . "): " . $line . "\n";
			$error_count ++;
		}
	}

	if(!in_runs($address))
	{
		my $fits = length(encode_text(($entry->{'Group'} eq "tutorial" ? "<81><40>" : "") . $entry->{'Text'})) <= slot_size($address);

		if($entry->{'InPlace'} && !$fits)
		{
			print "-> ERROR: in-place string " . sprintf("%08X", $address) . " is longer than its slot.\n";
			$error_count ++;
		}

		$entry->{'InPlace'} = 1 if($fits && !in_staff_table($address));
		$entry->{'Displaced'} = 1 if($fits && in_staff_table($address));
	}

	if($box_groups{$entry->{'Group'}})
	{
		(my $glyphs = $display) =~ s/\\n| //g;
		$box_glyphs{$entry->{'Group'}} += length($glyphs);
	}

	$entry->{'Bytes'} = encode_text(($entry->{'Group'} eq "tutorial" ? "<81><40>" : "") . $entry->{'Text'});
}

foreach my $address (sort { $a <=> $b } keys %new_entries)
{
	my $entry = $new_entries{$address};
	my $limit = $group_limits{$entry->{'Group'}};

	if(!defined($limit) || $limit eq "orig" || $box_groups{$entry->{'Group'}} || $entry->{'Group'} eq "tutorial")
	{
		print "-> ERROR: new string " . sprintf("%08X", $address) . " has unsupported group \"" . $entry->{'Group'} . "\".\n";
		$error_count ++;
		next;
	}

	foreach my $line ($limit eq "none" ? () : split(/\\n/, display_text($entry->{'Text'})))
	{
		my $width = measure_line($group_fonts{$entry->{'Group'}}, $line, $address);

		if($width > $limit)
		{
			print "-> ERROR: new string " . sprintf("%08X", $address) . " line is " . $width . " px (limit " . $limit . "): " . $line . "\n";
			$error_count ++;
		}
	}

	foreach my $slot (@{$entry->{'Slots'}})
	{
		if($slot % 4 || in_runs($slot))
		{
			print "-> ERROR: new string slot " . sprintf("%08X", $slot) . " is unaligned or inside a run.\n";
			$error_count ++;
		}
	}

	$entry->{'Bytes'} = encode_text($entry->{'Text'});
}

foreach my $group (sort keys %box_glyphs)
{
	if($box_glyphs{$group} > 256)
	{
		print "-> ERROR: message box group \"" . $group . "\" has " . $box_glyphs{$group} . " glyphs (limit 256).\n";
		$error_count ++;
	}
}

my %staff_roll_slots = map { $_ => 1 } grep { in_staff_table($_) } map { @{$_->{'Slots'}} } values %new_entries;
my $staff_source = $staff_table_original;
my $staff_end = -1;

for(my $slot = $staff_table[0]; $slot <= $staff_table[1]; $slot += 4)
{
	my $value = 0;

	if($staff_end < 0 && !$staff_roll_slots{$slot})
	{
		$value = unpack("V", substr($executable, $staff_source - $base_address, 4));
		$staff_source += 4;
		$staff_end = $slot if($value == 0);
	}

	substr($executable, $slot - $base_address, 4) = pack("V", $value);
}

if($staff_end < 0)
{
	print "-> ERROR: staff roll does not fit in " . sprintf("%08X-%08X", @staff_table) . ".\n";
	$error_count ++;
}

foreach my $slot (sort { $a <=> $b } grep { $_ > $staff_end } keys %staff_roll_slots)
{
	print "-> ERROR: new staff roll slot " . sprintf("%08X", $slot) . " is after the end of the roll.\n";
	$error_count ++;
}

foreach my $literal (@staff_table_literals)
{
	substr($executable, $literal->[0] - $base_address, 4) = pack("V", $staff_table[0] + $literal->[1]);
}

if($error_count > 0)
{
	print "\nTotal errors: " . $error_count . "\n1ST_READ.BIN was not modified.\n\n";
	exit;
}

my %pointer_locations;
my @owned_pointers;

for(my $offset = 0; $offset < length($executable); $offset += 4)
{
	my $value = unpack("V", substr($executable, $offset, 4));

	next if(in_runs($offset + $base_address) || grep { $_->[0] == $offset + $base_address } @staff_table_literals);

	push(@owned_pointers, $offset) if(defined($entries{$value}));

	if(defined($entries{$value}) && !$entries{$value}->{'InPlace'})
	{
		push(@{$pointer_locations{$value}}, $offset);
	}
	elsif(in_runs($value) && !in_dead_code($offset + $base_address))
	{
		print "-> ERROR: pointer at " . sprintf("%08X", $offset + $base_address) . " targets " . sprintf("%08X", $value) . " inside a run but not a string entry.\n";
		$error_count ++;
	}
}

my %owned_offsets = map { $_ => 1 } @owned_pointers;

foreach my $address (keys %new_entries)
{
	foreach my $slot (@{$new_entries{$address}->{'Slots'}})
	{
		if($owned_offsets{$slot - $base_address})
		{
			print "-> ERROR: new string slot " . sprintf("%08X", $slot) . " is an original string pointer.\n";
			$error_count ++;
		}
	}
}

my %padding_targets;

foreach my $address (grep { $entries{$_}->{'InPlace'} } keys %entries)
{
	my $string_end = $address + length(original_string_raw($address)) + 1;

	$padding_targets{$_} = $address foreach ($string_end .. $address + slot_size($address) - 1);
}

for(my $offset = 0; $offset < length($executable); $offset += 4)
{
	my $value = unpack("V", substr($executable, $offset, 4));

	if(defined($padding_targets{$value}) && !in_dead_code($offset + $base_address))
	{
		print "-> ERROR: pointer at " . sprintf("%08X", $offset + $base_address) . " targets the padding of " . sprintf("%08X", $padding_targets{$value}) . ".\n";
		$error_count ++;
	}
}

foreach my $address (sort { $a <=> $b } keys %entries)
{
	next if($entries{$address}->{'InPlace'} || in_runs($address) || defined($pointer_locations{$address}));

	print "-> ERROR: string " . sprintf("%08X", $address) . " is outside the runs and has no pointer to update.\n";
	$error_count ++;
}

if($error_count > 0)
{
	print "\nTotal errors: " . $error_count . "\n1ST_READ.BIN was not modified.\n\n";
	exit;
}

foreach my $address (grep { $entries{$_}->{'InPlace'} } keys %entries)
{
	my $bytes = encode_text($entries{$address}->{'Text'});

	substr($executable, $address - $base_address, slot_size($address)) = $bytes . ("\x00" x (slot_size($address) - length($bytes)));
}

my @free;

foreach my $run (@text_runs, @spare_runs)
{
	substr($executable, $run->[0] - $base_address, $run->[1] - $run->[0] + 1) = "\x00" x ($run->[1] - $run->[0] + 1);
	push(@free, [$run->[0], $run->[1]]);
}

my $pointer_count = 0;
my $spare_used = 0;

foreach my $phase (0, 1)
{
	foreach my $address (sort { length($entries{$b}->{'Bytes'}) <=> length($entries{$a}->{'Bytes'}) || $a <=> $b } grep { !$entries{$_}->{'InPlace'} && ($entries{$_}->{'Displaced'} // 0) == $phase } keys %entries)
	{
		my $bytes = $entries{$address}->{'Bytes'};
		my $new_address = place_string($bytes, "string " . sprintf("%08X", $address));

		next if($new_address < 0);

		foreach my $offset (@{$pointer_locations{$address}})
		{
			substr($executable, $offset, 4) = pack("V", $new_address);
			$pointer_count ++;
		}
	}

	foreach my $address (sort { length($new_entries{$b}->{'Bytes'}) <=> length($new_entries{$a}->{'Bytes'}) || $a <=> $b } grep { (grep { in_staff_table($_) } @{$new_entries{$_}->{'Slots'}}) ? $phase : !$phase } keys %new_entries)
	{
		my $bytes = $new_entries{$address}->{'Bytes'};
		my $new_address = place_string($bytes, "new string " . sprintf("%08X", $address));

		next if($new_address < 0);

		foreach my $slot (@{$new_entries{$address}->{'Slots'}})
		{
			substr($executable, $slot - $base_address, 4) = pack("V", $new_address);
			$pointer_count ++;
		}
	}
}

if($error_count > 0)
{
	print "\nTotal errors: " . $error_count . "\n1ST_READ.BIN was not modified.\n\n";
	exit;
}

my $output = read_file_raw($output_executable);

foreach my $run (@text_runs, @spare_runs)
{
	my $offset = $run->[0] - $base_address;
	my $length = $run->[1] - $run->[0] + 1;

	substr($output, $offset, $length) = substr($executable, $offset, $length);
}

foreach my $offset (@owned_pointers)
{
	substr($output, $offset, 4) = substr($executable, $offset, 4);
}

foreach my $address (grep { $entries{$_}->{'InPlace'} } keys %entries)
{
	my $offset = $address - $base_address;

	substr($output, $offset, slot_size($address)) = substr($executable, $offset, slot_size($address));
}

foreach my $address (keys %new_entries)
{
	foreach my $slot (@{$new_entries{$address}->{'Slots'}})
	{
		substr($output, $slot - $base_address, 4) = substr($executable, $slot - $base_address, 4);
	}
}

substr($output, $staff_table[0] - $base_address, $staff_table[1] - $staff_table[0] + 1) = substr($executable, $staff_table[0] - $base_address, $staff_table[1] - $staff_table[0] + 1);

foreach my $literal (@staff_table_literals)
{
	substr($output, $literal->[0] - $base_address, 4) = substr($executable, $literal->[0] - $base_address, 4);
}

write_file_raw($output_executable, $output);

print "-> " . (scalar(keys %entries) + scalar(keys %new_entries)) . " string(s) written, " . $pointer_count . " pointer(s) updated, " . $spare_used . " byte(s) of spare space used.\n";
print "\nExecutable text complete!\n\n";

sub read_text_file
{
	my $file = $_[0];

	my %result;
	my $address = -1;
	my $group = "";
	my $in_place = 0;
	my @slots;

	foreach my $line (split(/\r?\n/, decode("UTF-8", read_file_raw($file))))
	{
		if($line =~ /^\[([0-9A-F]{8}(?:,[0-9A-F]{8})*)\]\s+(\S+)\s+new\s*$/i)
		{
			@slots = map { hex($_) } split(/,/, $1);
			$address = $slots[0];
			$group = $2;
		}
		elsif($line =~ /^\[([0-9A-F]{8})\]\s+(\S+)(\s+inplace)?/i)
		{
			@slots = ();
			$address = hex($1);
			$group = $2;
			$in_place = defined($3) ? 1 : 0;
		}
		elsif($line =~ /^EN:\s?(.*)$/ && $address >= 0 && scalar(@slots))
		{
			$new_entries{$address} = { 'Group' => $group, 'Text' => $1, 'Slots' => [@slots] };
		}
		elsif($line =~ /^EN:\s?(.*)$/ && $address >= 0)
		{
			$result{$address} = { 'Group' => $group, 'Text' => $1, 'InPlace' => $in_place };
		}
	}

	return %result;
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

sub read_font
{
	my ($descriptor, $har_file, $entry_name) = @{$_[0]};

	my ($space, $line_height, $texture, $map_address) = unpack("V4", substr($executable, $descriptor - $base_address, 16));
	my $har = read_har("../../gdi_orig_extracted/" . $har_file);
	my @sprites = hgpt_sprites($har->{'Entries'}->[har_entry_index($har, $entry_name)]->{'Data'});
	my %advance = (0x20 => $space);

	for(my $i = 0; $i < 95; $i ++)
	{
		my $index = ord(substr($executable, $map_address - $base_address + $i, 1));

		$advance{0x20 + $i} = $sprites[$index]->[2] if($i > 0 && $index < 0x80);
	}

	return \%advance;
}

sub measure_line
{
	my ($font, $line, $address) = @_;

	my $pen = 0;
	my $width = 0;

	foreach my $character (split(//, $line))
	{
		my $advance = defined($font) ? $font_metrics{$font}->{ord($character)} : $widths{ord($character)};

		if(!defined($advance))
		{
			print "-> ERROR: " . sprintf("%08X", $address) . " has unsupported character \"" . $character . "\".\n";
			$error_count ++;
			next;
		}

		$width = $pen + $ink{ord($character)} if(!defined($font) && $pen + $ink{ord($character)} > $width);
		$pen += $advance;
	}

	return $pen > $width ? $pen : $width;
}

sub display_text
{
	my $text = $_[0];

	$text =~ s/%s/A/g;
	$text =~ s/%d/0/g;
	$text =~ s/<[0-9A-F]{2}>//gi;

	return $text;
}

sub original_string_raw
{
	my $offset = $_[0] - $base_address;

	return substr($executable, $offset, index($executable, "\x00", $offset) - $offset);
}

sub slot_size
{
	my $address = $_[0];

	return $slot_sizes{$address} if(defined($slot_sizes{$address}));

	my $end = $address + length(original_string_raw($address)) + 1;

	while($end % 4 && ord(substr($executable, $end - $base_address, 1)) == 0)
	{
		$end ++;
	}

	$slot_sizes{$address} = $end - $address;

	return $slot_sizes{$address};
}

sub original_string
{
	my $offset = $_[0] - $base_address;

	(my $text = substr($executable, $offset, index($executable, "\x00", $offset) - $offset)) =~ s/\x0A/\\n/g;

	return $text;
}

sub encode_text
{
	my $text = $_[0];

	$text =~ s/\\n/\x0A/g;
	$text =~ s/<([0-9A-F]{2})>/chr(hex($1))/gie;

	return $text . "\x00";
}

sub in_dead_code
{
	my $address = $_[0];

	foreach my $run (@dead_code_runs)
	{
		return 1 if($address >= $run->[0] && $address <= $run->[1]);
	}

	return 0;
}

sub place_string
{
	my ($bytes, $label) = @_;

	for(my $i = 0; $i < scalar(@free); $i ++)
	{
		my $start = ($free[$i]->[0] + 3) & ~3;

		next if($start + length($bytes) - 1 > $free[$i]->[1]);
		next if($i >= scalar(@text_runs) && (length($bytes) > 255 || $bytes =~ /%/));

		$free[$i]->[0] = $start + length($bytes);
		$spare_used += length($bytes) if($i >= scalar(@text_runs));
		substr($executable, $start - $base_address, length($bytes)) = $bytes;

		return $start;
	}

	print "-> ERROR: no space for " . $label . " (" . length($bytes) . " bytes).\n";
	$error_count ++;

	return -1;
}

sub in_staff_table
{
	my $address = $_[0];

	return ($address >= $staff_table[0] && $address <= $staff_table[1]) ? 1 : 0;
}

sub in_runs
{
	my $address = $_[0];

	foreach my $run (@text_runs, @spare_runs)
	{
		return 1 if($address >= $run->[0] && $address <= $run->[1]);
	}

	return 0;
}
