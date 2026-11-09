#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HAR;
use CamelROM;
use Imager;
use Cwd;
use File::Temp qw(tempdir);

chdir($FindBin::Bin);

my $original_folder = "../../gdi_orig_extracted/";
my $output_folder = "../../gdi_extracted/";
my $font_sheet = "font/dialogue_font.png";
my $font_widths = "font/dialogue_font_widths.txt";
my $font_palette = "font/dialogue_font_palette.bin";

my $first_glyph = 1392;
my $lead_index = (0x86 - 0x81) * 0xBD;
my $fallback_index = (0x87 - 0x81) * 0xBD + (0x81 - 0x40);
my $width_table_offset = 0xA9BF8;
my $message_box_space_offset = 0x103FF6;
my $font_palette_offset = 0x1971A8;
my $position_table_offset = 0x8C1A71E8 - 0x8C010000;
my $texture_folder = "textures/";
my $pvr_encoder = Cwd::abs_path("../tools/pypvr.exe");

my %pixel_formats = (0 => "1555", 1 => "565", 2 => "4444", 3 => "yuv422");
my %texture_formats = (0x01 => "tw", 0x09 => "re", 0x0D => "twre");

my @textures = (
	["CS_TITLE_07.png", [["CS_TITLE.HAR", 7]]],
	["CS_SR_02.png", [["CS_SR.HAR", 2]]],
	["TITLE_06.png", [["TITLE.HAR", 6]]],
	["DEMO_00.png", [["DEMO.HAR", 0]]],
	["TITLE3_00.png", [["TITLE3.HAR", 0]]],
	["HISCORE_07.png", [["HISCORE.HAR", 7]]],
	["GAME_RS_27.png", [["GAME_RS.HAR", 27], ["ST1_RS.HAR", 62], ["ST2_RS.HAR", 86], ["ST3_RS.HAR", 67], ["ST4_RS.HAR", 84], ["ST5_RS.HAR", 100]]],
	["GAME_RS_28.png", [["GAME_RS.HAR", 28], ["ST1_RS.HAR", 63], ["ST2_RS.HAR", 87], ["ST3_RS.HAR", 68], ["ST4_RS.HAR", 85], ["ST5_RS.HAR", 101]]],
	["GAME_RS_29.png", [["GAME_RS.HAR", 29], ["ST1_RS.HAR", 64], ["ST2_RS.HAR", 88], ["ST3_RS.HAR", 69], ["ST4_RS.HAR", 86], ["ST5_RS.HAR", 102]]],
	["GAME_RS_33.png", [["GAME_RS.HAR", 33], ["ST1_RS.HAR", 68], ["ST2_RS.HAR", 92], ["ST3_RS.HAR", 73], ["ST4_RS.HAR", 90], ["ST5_RS.HAR", 106]]],
	["GAME_VO_08.png", [["GAME_VO.HAR", 8], ["ST1_VO.HAR", 94], ["ST2_VO.HAR", 191], ["ST3_VO.HAR", 136], ["ST4_VO.HAR", 157], ["ST5_VO.HAR", 55]]],
	["GAME_VO_09.png", [["GAME_VO.HAR", 9], ["ST1_VO.HAR", 95], ["ST2_VO.HAR", 192], ["ST3_VO.HAR", 137], ["ST4_VO.HAR", 158], ["ST5_VO.HAR", 56]]],
	["TITLE_02.png", [["TITLE.HAR", 2], ["TITLE4.HAR", 1]]],
	["HISCORE_11.png", [["HISCORE.HAR", 11], ["GAME_RS.HAR", 31], ["ST1_RS.HAR", 66], ["ST2_RS.HAR", 90], ["ST3_RS.HAR", 71], ["ST4_RS.HAR", 88], ["ST5_RS.HAR", 104]]],
	["HISCORE_12.png", [["HISCORE.HAR", 12], ["GAME_RS.HAR", 32], ["ST1_RS.HAR", 67], ["ST2_RS.HAR", 91], ["ST3_RS.HAR", 72], ["ST4_RS.HAR", 89], ["ST5_RS.HAR", 105]]],
	["CS_GAL_61.png", [["CS_GAL.HAR", 61]]],
	["CS_GAL_62.png", [["CS_GAL.HAR", 62]]],
	["CS_OMAKE_08.png", [["CS_OMAKE.HAR", 8]]],
	["CS_OMAKE_09.png", [["CS_OMAKE.HAR", 9]]],
	["CS_SR_00.png", [["CS_SR.HAR", 0]]],
	["CS_TITLE_02.png", [["CS_TITLE.HAR", 2]]],
	["GAME_RS_25.png", [["GAME_RS.HAR", 25], ["ST1_RS.HAR", 60], ["ST2_RS.HAR", 84], ["ST3_RS.HAR", 65], ["ST4_RS.HAR", 82], ["ST5_RS.HAR", 98]]],
	["GAME_RS_26.png", [["GAME_RS.HAR", 26], ["ST1_RS.HAR", 61], ["ST2_RS.HAR", 85], ["ST3_RS.HAR", 66], ["ST4_RS.HAR", 83], ["ST5_RS.HAR", 99]]],
	["HISCORE_00.png", [["HISCORE.HAR", 0]]],
	["HISCORE_01.png", [["HISCORE.HAR", 1]]],
	["HISCORE_09.png", [["HISCORE.HAR", 9]]],
	["HISCORE_13.png", [["HISCORE.HAR", 13]]],
	["HISCORE_31.png", [["HISCORE.HAR", 31]]],
	["HISCORE_32.png", [["CS_TITLE.HAR", 6], ["HISCORE.HAR", 32]]],
	["TITLE_03.png", [["TITLE4.HAR", 2], ["TITLE.HAR", 3]]],
	["TITLE_07.png", [["TITLE.HAR", 7]]],
	["TITLE_08.png", [["TITLE.HAR", 8]]],
	["TITLE_09.png", [["TITLE.HAR", 9]]],
	["TITLE_10.png", [["TITLE.HAR", 10]]],
	["TITLE_11.png", [["TITLE.HAR", 11]]],
	["TITLE_28.png", [["TITLE.HAR", 28]]],
	["TITLE_29.png", [["TITLE.HAR", 29]]],
	["TITLE_30.png", [["TITLE.HAR", 30]]],
	["TITLE_31.png", [["TITLE.HAR", 31]]],
	["ST3_RS_85.png", [["ST3_RS.HAR", 85]]],
	["HISCORE_30.png", [["HISCORE.HAR", 30]]]
);

my @files = (
	["textures/CS_TITLE_03.hpt", [["CS_TITLE.HAR", 3]]],
	["textures/GAME_RS_07.hga", [["GAME_RS.HAR", 7], ["ST1_RS.HAR", 42], ["ST2_RS.HAR", 66], ["ST3_RS.HAR", 47], ["ST4_RS.HAR", 64], ["ST5_RS.HAR", 80]]],
	["vmu/icon.bmp", [["SYSTEM.HAR", 11]]],
	["vmu/no.bmp", [["SYSTEM.HAR", 15]]],
	["vmu/lcd.bmp", [["SYSTEM.HAR", 16]]]
);

my @sprites = (
	["TITLE.HAR", 28, 7, [108, 0, 35, 390], [144, 244, 35, 241]]
);

my @disc_files = (["disc/0GDTEX.PVR", "0GDTEX.PVR"]);

print "\nInserting dialogue font...\n\n";

my @positions = unpack("V36", substr(read_file_raw($original_folder . "1ST_READ.BIN"), $position_table_offset, 144));
my $original_har = read_har($original_folder . "DEMO.HAR");
my $font_data = $original_har->{'Entries'}->[har_entry_index($original_har, "fontdata.bin")]->{'Data'};
my $kanji_table = $original_har->{'Entries'}->[har_entry_index($original_har, "kanjitbl.bin")]->{'Data'};

my $sheet = Imager->new(file => $font_sheet) or die "Failed to read " . $font_sheet . ": " . Imager->errstr();
my %widths = map { /^([0-9A-F]{2})\|(\d+)/i ? (hex($1) => $2) : () } split(/\r?\n/, read_file_raw($font_widths));

for(my $i = 0; $i < 96; $i ++)
{
	my @pixels;

	for(my $y = 0; $y < 20; $y ++)
	{
		for(my $x = 0; $x < 20; $x ++)
		{
			my @color = $sheet->getpixel(x => ($i % 16) * 20 + $x, y => int($i / 16) * 20 + $y)->rgba();
			$pixels[$y][$x] = int($color[3] / 17 + 0.5);
		}
	}

	substr($font_data, ($first_glyph + $i) * 200, 200) = encode_glyph(\@pixels, \@positions);
	substr($kanji_table, ($lead_index + $i) * 2, 2) = pack("v", $first_glyph + $i);
}

substr($kanji_table, $fallback_index * 2, 2) = pack("v", 0);

my $har = read_har($output_folder . "DEMO.HAR");
har_replace_entry($har, har_entry_index($har, "fontdata.bin"), $font_data);
har_replace_entry($har, har_entry_index($har, "kanjitbl.bin"), $kanji_table);
write_har($output_folder . "DEMO.HAR", $har);

my $width_hex = "";

for(my $i = 0; $i < 96; $i ++)
{
	$width_hex .= decimal_to_hex(defined($widths{0x20 + $i}) ? $widths{0x20 + $i} : 20, 1);
}

patch_bytes($output_folder . "1ST_READ.BIN", $width_hex, $width_table_offset);
patch_bytes($output_folder . "1ST_READ.BIN", decimal_to_hex($widths{0x20}, 1), $message_box_space_offset);
patch_bytes($output_folder . "1ST_READ.BIN", unpack("H*", read_file_raw($font_palette)), $font_palette_offset);

print "-> 96 glyphs written to DEMO.HAR (glyphs " . $first_glyph . "-" . ($first_glyph + 95) . ").\n";
print "-> Width table written to 1ST_READ.BIN at 0x" . decimal_to_hex($width_table_offset) . ".\n";
print "\nInserting textures...\n\n";

my %replacements;

foreach my $texture (@textures)
{
	my ($png, $targets) = @{$texture};

	my $original = original_entry($targets);
	my $pvrt = hgpt_pvrt_offset($original);
	my ($pixel_format, $texture_format, $width, $height) = unpack("C C x2 v v", substr($original, $pvrt + 8, 8));

	die "Unsupported PVR format for " . $png . "." if(!defined($pixel_formats{$pixel_format}) || !defined($texture_formats{$texture_format}));

	my $encoded = encode_pvr($texture_folder . $png, $pixel_formats{$pixel_format}, $texture_formats{$texture_format});
	my $encoded_pvrt = index($encoded, "PVRT");

	die "Encoded " . $png . " does not match the original size or format." if(substr($encoded, $encoded_pvrt + 8, 8) ne substr($original, $pvrt + 8, 8) || length($encoded) - $encoded_pvrt != length($original) - $pvrt);

	my $data = $original;
	substr($data, $pvrt + 16) = substr($encoded, $encoded_pvrt + 16);

	push(@{$replacements{$_->[0]}}, [$_->[1], $data]) foreach (@{$targets});

	print "-> " . $png . " (" . $width . "x" . $height . " " . $pixel_formats{$pixel_format} . " " . $texture_formats{$texture_format} . ") for " . scalar(@{$targets}) . " entr" . (scalar(@{$targets}) == 1 ? "y" : "ies") . ".\n";
}

foreach my $file (@files)
{
	my ($name, $targets) = @{$file};

	my $original = original_entry($targets);
	my $data = read_file_raw($name);

	die $name . " does not match the original size." if(length($data) != length($original));

	push(@{$replacements{$_->[0]}}, [$_->[1], $data]) foreach (@{$targets});

	print "-> " . $name . " for " . scalar(@{$targets}) . " entr" . (scalar(@{$targets}) == 1 ? "y" : "ies") . ".\n";
}

foreach my $sprite (@sprites)
{
	my ($har_file, $entry, $index, $original_rect, $rect) = @{$sprite};

	my ($replacement) = grep { $_->[0] == $entry } @{$replacements{$har_file}};

	die $har_file . " entry " . $entry . " has no replacement texture for sprite " . $index . "." if(!defined($replacement));

	my @current = hgpt_sprites($replacement->[1]);

	die $har_file . " entry " . $entry . " sprite " . $index . " does not match the original rect." if($index >= scalar(@current) || join(",", @{$current[$index]}) ne join(",", @{$original_rect}));

	substr($replacement->[1], 0x1C + $index * 8, 8) = pack("v4", @{$rect});

	print "-> " . $har_file . " entry " . $entry . " sprite " . $index . " rect set to " . join(",", @{$rect}) . ".\n";
}

foreach my $har_file (sort keys %replacements)
{
	my $har = read_har($output_folder . $har_file);

	har_replace_entry($har, $_->[0], $_->[1]) foreach (@{$replacements{$har_file}});
	write_har($output_folder . $har_file, $har);
}

foreach my $disc_file (@disc_files)
{
	write_file_raw($output_folder . $disc_file->[1], read_file_raw($disc_file->[0]));

	print "-> " . $disc_file->[0] . " copied to disc root.\n";
}

print "\nGraphics complete!\n\n";

sub original_entry
{
	my @targets = @{$_[0]};

	my $data;

	foreach my $target (@targets)
	{
		my $har = read_har($original_folder . $target->[0]);
		my $entry = $har->{'Entries'}->[$target->[1]]->{'Data'};

		$data = $entry if(!defined($data));

		die $target->[0] . " entry " . $target->[1] . " is not a copy of " . $targets[0]->[0] . " entry " . $targets[0]->[1] . "." if($entry ne $data);
	}

	return $data;
}

sub encode_pvr
{
	my ($png, $pixel_format, $texture_format) = @_;

	my $folder = tempdir(CLEANUP => 1);
	my $current = getcwd();

	die "Temporary folder " . $folder . " contains a hyphen." if($folder =~ /-/);

	write_file_raw($folder . "/texture.png", read_file_raw($png));
	chdir($folder);
	system("\"" . $pvr_encoder . "\" texture.png -" . $pixel_format . " -" . $texture_format . " -silent");
	chdir($current);

	my $output = (glob($folder . "/texture.[pP][vV][rR]"))[0];

	die "PyPVR failed to encode " . $png . "." if(!defined($output));

	return read_file_raw($output);
}

sub encode_glyph
{
	my @pixels = @{$_[0]};
	my @positions = @{$_[1]};

	my @slot = (0) x 512;

	for(my $y = 0; $y < 20; $y ++)
	{
		for(my $x = 0; $x < 20; $x ++)
		{
			my $index = (twiddle($x) << 1) | twiddle($y);
			my $value = $pixels[$y][$x] & 15;

			$slot[$index >> 1] |= ($index & 1) ? ($value << 4) : $value;
		}
	}

	my $slot_data = pack("C*", @slot);
	my $glyph = substr($slot_data, 0, 128);

	foreach my $position (@positions)
	{
		$glyph .= substr($slot_data, $position * 2, 2);
	}

	return $glyph;
}

sub twiddle
{
	my $value = $_[0];
	my $result = 0;

	for(my $bit = 0; $bit < 5; $bit ++)
	{
		$result |= 1 << (2 * $bit) if($value & (1 << $bit));
	}

	return $result;
}
