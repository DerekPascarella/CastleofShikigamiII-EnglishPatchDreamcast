#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HAR;
use Imager;
use Encode qw(decode encode);
use File::Path qw(make_path remove_tree);

my $ps2_image = "../../ps2/Castle Shikigami 2.bin";
my $pc_folder = "../../pc/media/cdimg/";
my $pc_executable = "../../pc/Shikigami2_Demo.exe";
my $ps2_output_folder = "../../ps2_extracted/";
my $pc_output_folder = "../../pc_extracted/";
my $dc_folder = "../../gdi_orig_extracted/";
my $dialogue_folder = "../text/dialogue/";

my @dialogue_archives = (["DEMO1P", "demo1p"], ["DEMO2PD1", "demo2pd1"], ["DEMO2PD2", "demo2pd2"],
						 ["DEMO2PF", "demo2pf"], ["DEMO2PM", "demo2pm"], ["DEMO_END", "demo_end"]);

my %speaker_names = (0 => "Together", 1 => "Fumiko", 2 => "Sayo", 3 => "Niigi", 4 => "Chibi Fumiko", 5 => "Kuga",
					 6 => "Hyuga", 7 => "Kim", 8 => "Roger", 9 => "Arala", 10 => "Anolegos", 11 => "Aja Brothers",
					 12 => "Aja Brothers", 13 => "Yukari", 14 => "Shintaro", 15 => "World Order", 16 => "Narration");

my %ps2_skip_files = ("SND.BIN" => 1, "XS_LOGON.PSS" => 1);

my @pack_names = ("DEBUG", "ERRDISP", "FUM0", "FUM", "PACK_004", "PACK_005", "HYU", "JIKI", "KIM", "KUG",
				  "NII", "REPLAY", "ROG", "SAY", "SFU", "SYSTEM", "PACK_016", "PACK_017", "TITLE2", "TITLE3",
				  "PACK_020", "ZAKO", "PCMFUM", "PCMHYU", "PCMKIM", "PCMKUG", "PCMNII", "PCMROG", "PCMSAY", "PCMSFU",
				  "DEMO", "DEMO1P", "DEMO2PD1", "DEMO2PD2", "DEMO2PF", "DEMO2PM", "DEMO_END",
				  "D_COXX10", "D_COXX20", "D_FUNI11", "D_FUNI12", "D_FUNI21", "D_FUNI22", "D_HUNI11", "D_HUNI12",
				  "D_HUNI21", "D_HUNI22", "D_KMHU11", "D_KMHU12", "D_KMHU21", "D_KMHU22", "D_KMRO11", "D_KMRO12",
				  "D_KMRO21", "D_KMRO22", "D_KUKU11", "D_KUKU21", "D_KURO11", "D_KURO12", "D_KURO21", "D_KURO22",
				  "D_KUXX10", "D_SACO11", "D_SACO12", "D_SACO21", "D_SACO22", "D_SANI11", "D_SANI12", "D_SANI21",
				  "D_SANI22", "FACE_B3A", "FACE_B3B", "FACE_BS1", "FACE_BS2", "FACE_BS4", "FACE_BS5", "FACE_CO1",
				  "FACE_CO2", "FACE_FU1", "FACE_FU2", "FACE_HU1", "FACE_HU2", "FACE_KM1", "FACE_KM2", "FACE_KU1",
				  "FACE_KU2", "FACE_LO1", "FACE_LO2", "FACE_NI1", "FACE_NI2", "FACE_SA1", "FACE_SA2");

chdir($FindBin::Bin);

print "\nExtracting PlayStation 2 disc image...\n\n";

remove_tree($ps2_output_folder);
remove_tree($pc_output_folder);
make_path($ps2_output_folder . "disc/");

my $bin_handle = bin_open($ps2_image);
my @disc_files = iso_list_files($bin_handle);

for(my $i = 0; $i < scalar(@disc_files); $i ++)
{
	my ($path, $lba, $size) = @{$disc_files[$i]};
	(my $file_name = $path) =~ s/.*\///;

	next if($ps2_skip_files{$file_name} || $path =~ /^IOP\//);

	make_path($ps2_output_folder . "disc/" . ($path =~ /^(.*)\// ? $1 : ""));
	write_file_raw($ps2_output_folder . "disc/" . $path, iso_read_file($bin_handle, $lba, $size));

	print "-> " . $path . " (" . $size . " bytes)\n";

	if($file_name =~ /\.HAR$/i)
	{
		(my $archive_name = uc($file_name)) =~ s/\.HAR$//;
		extract_har_entries(read_har($ps2_output_folder . "disc/" . $path), $ps2_output_folder . "har/" . $archive_name . "/", $ps2_output_folder . "png/" . $archive_name . "/");
	}
}

close($bin_handle);

split_packed_archives($ps2_output_folder . "disc/PACK.BIN", "PACK", \@pack_names);
split_packed_archives($ps2_output_folder . "disc/GAL.BIN", "GAL", []);

print "\nExtracting PC demo archives...\n\n";

foreach my $set (["har_base", $pc_folder, ""], ["har_en", $pc_folder . "en/", "png_en"])
{
	my ($set_folder, $input_folder, $png_folder) = @{$set};

	opendir(DIR, $input_folder);
	my @input_files = sort grep /\.har$/i, readdir(DIR);
	closedir(DIR);

	for(my $i = 0; $i < scalar(@input_files); $i ++)
	{
		(my $archive_name = lc($input_files[$i])) =~ s/\.har$//;

		extract_har_entries(read_har($input_folder . $input_files[$i]), $pc_output_folder . $set_folder . "/" . $archive_name . "/",
							$png_folder ne "" ? $pc_output_folder . $png_folder . "/" . $archive_name . "/" : "");
	}

	print "-> " . $set_folder . ": " . scalar(@input_files) . " archive(s)\n";
}

dump_executable_strings($pc_executable, $pc_output_folder . "exe_strings.txt");

print "\nSeeding dialogue text files...\n\n";

for(my $i = 0; $i < scalar(@dialogue_archives); $i ++)
{
	my ($dc_name, $pc_name) = @{$dialogue_archives[$i]};
	my $text_file = $dialogue_folder . $dc_name . ".txt";

	if(-e $text_file)
	{
		print "-> " . $dc_name . ".txt already exists, skipping.\n";
	}
	else
	{
		my $todo_count = seed_dialogue_file($dc_name, $pc_name, $text_file);

		print "-> " . $dc_name . ".txt written (" . $todo_count . " page(s) need translation).\n";
	}
}

print "\nExtraction complete!\n\n";

sub split_packed_archives
{
	my $packed_file = $_[0];
	my $prefix = $_[1];
	my @names = @{$_[2]};

	my $packed_data = read_file_raw($packed_file);
	my $position = 0;
	my $index = 0;

	while($position >= 0 && $position < length($packed_data))
	{
		my ($version, $count) = unpack("v v", substr($packed_data, $position + 4, 4));
		my @offsets = unpack("V" . $count, substr($packed_data, $position + 8, $count * 4));
		my $last_size = unpack("V", substr($packed_data, $position + $offsets[-1] + 16, 4));
		my $end = $position + $offsets[-1] + 20 + $last_size;

		my $archive_name;

		if($prefix eq "GAL")
		{
			$archive_name = sprintf("BIG_%02d", $index + 1);
		}
		else
		{
			$archive_name = defined($names[$index]) ? $names[$index] : sprintf("%s_%03d", $prefix, $index);
		}

		my $archive_file = $ps2_output_folder . "har/" . $archive_name . ".HAR";
		make_path($ps2_output_folder . "har/");
		write_file_raw($archive_file, substr($packed_data, $position, $end - $position));
		extract_har_entries(read_har($archive_file), $ps2_output_folder . "har/" . $archive_name . "/", $prefix eq "GAL" ? "" : $ps2_output_folder . "png/" . $archive_name . "/");
		unlink($archive_file);

		print "-> " . $prefix . " archive " . $index . " = " . $archive_name . " (" . $count . " entries)\n";

		$position = index($packed_data, "HGAR", $end);
		$index ++;
	}
}

sub extract_har_entries
{
	my %har = %{$_[0]};
	my $entry_folder = $_[1];
	my $png_folder = $_[2];

	my @entries = @{$har{'Entries'}};

	make_path($entry_folder);
	make_path($png_folder) if($png_folder ne "");

	for(my $i = 0; $i < scalar(@entries); $i ++)
	{
		(my $name = $entries[$i]->{'Name'}) =~ s/[ \x00]//g;
		$name =~ s/[:\/]/_/g;
		my $file_name = sprintf("%02d_%s", $i, $name);

		write_file_raw($entry_folder . $file_name, $entries[$i]->{'Data'});

		if($png_folder ne "" && $name =~ /\.hpt$/i)
		{
			my $image = tga_to_image(substr($entries[$i]->{'Data'}, hgpt_texture_offset($entries[$i]->{'Data'})));

			$image->write(file => $png_folder . $file_name . ".png") if(defined($image));
		}
	}
}

sub tga_to_image
{
	my $tga = $_[0];

	my ($id_length, $map_type, $image_type, $map_first, $map_length, $map_bits, $x_origin, $y_origin,
		$width, $height, $bits, $descriptor) = unpack("C C C v v C v v v v C C", substr($tga, 0, 18));

	return undef if($image_type != 1 && $image_type != 2 && $image_type != 9 && $image_type != 10);

	my $position = 18 + $id_length;
	my @palette;

	if($map_type == 1)
	{
		my $entry_size = $map_bits / 8;

		for(my $i = 0; $i < $map_length; $i ++)
		{
			push(@palette, tga_pixel(substr($tga, $position + $i * $entry_size, $entry_size), $map_bits));
		}

		$position += $map_length * $entry_size;
	}

	my $bytes_per_pixel = $bits / 8;
	my $pixel_data;

	if($image_type == 9 || $image_type == 10)
	{
		my $needed = $width * $height * $bytes_per_pixel;

		while(length($pixel_data) < $needed)
		{
			my $packet = ord(substr($tga, $position, 1));
			$position ++;

			if($packet & 0x80)
			{
				$pixel_data .= substr($tga, $position, $bytes_per_pixel) x (($packet & 0x7F) + 1);
				$position += $bytes_per_pixel;
			}
			else
			{
				$pixel_data .= substr($tga, $position, ($packet + 1) * $bytes_per_pixel);
				$position += ($packet + 1) * $bytes_per_pixel;
			}
		}
	}
	else
	{
		$pixel_data = substr($tga, $position, $width * $height * $bytes_per_pixel);
	}

	my $image = Imager->new(xsize => $width, ysize => $height, channels => 4);

	for(my $y = 0; $y < $height; $y ++)
	{
		my $row = substr($pixel_data, $y * $width * $bytes_per_pixel, $width * $bytes_per_pixel);
		my $scanline = "";

		for(my $x = 0; $x < $width; $x ++)
		{
			if($map_type == 1)
			{
				$scanline .= $palette[ord(substr($row, $x, 1))];
			}
			else
			{
				$scanline .= tga_pixel(substr($row, $x * $bytes_per_pixel, $bytes_per_pixel), $bits);
			}
		}

		$image->setscanline(y => (($descriptor & 0x20) ? $y : $height - 1 - $y), pixels => $scanline);
	}

	return $image;
}

sub tga_pixel
{
	my $pixel = $_[0];
	my $bits = $_[1];

	if($bits == 32)
	{
		my ($b, $g, $r, $a) = unpack("C4", $pixel);

		return pack("C4", $r, $g, $b, $a);
	}
	elsif($bits == 24)
	{
		my ($b, $g, $r) = unpack("C3", $pixel);

		return pack("C4", $r, $g, $b, 255);
	}
	else
	{
		my $value = unpack("v", $pixel);

		return pack("C4", (($value >> 10) & 31) * 255 / 31, (($value >> 5) & 31) * 255 / 31, ($value & 31) * 255 / 31, ($value & 0x8000) ? 255 : 0);
	}
}

sub seed_dialogue_file
{
	my $dc_name = $_[0];
	my $pc_name = $_[1];
	my $text_file = $_[2];

	my $dc_har = read_har($dc_folder . $dc_name . ".HAR");
	my $pc_har = read_har($pc_folder . "en/" . $pc_name . ".har");
	my @dc_entries = @{$dc_har->{'Entries'}};
	my $todo_count = 0;

	my $output = "";

	for(my $i = 0; $i < scalar(@dc_entries); $i ++)
	{
		(my $name = $dc_entries[$i]->{'Name'}) =~ s/[ \x00]//g;
		my $pc_index = har_entry_index($pc_har, $name);

		die "seed_dialogue_file() found no PC script for " . $name if($pc_index < 0);

		my @dc_pages = mes_pages($dc_entries[$i]->{'Data'}, 0);
		my @pc_pages = mes_pages($pc_har->{'Entries'}->[$pc_index]->{'Data'}, 1);

		$output .= ($output eq "" ? "" : "\n") . "=== " . $name . " ===\n";

		my $pc_page = 0;

		for(my $j = 0; $j < scalar(@dc_pages); $j ++)
		{
			my $english = "";

			if($pc_page < scalar(@pc_pages) && $pc_pages[$pc_page]->{'Speaker'} == $dc_pages[$j]->{'Speaker'})
			{
				$english = $pc_pages[$pc_page]->{'Text'};
				$pc_page ++;
			}

			my $speaker = defined($speaker_names{$dc_pages[$j]->{'Speaker'}}) ? $speaker_names{$dc_pages[$j]->{'Speaker'}} : "Speaker " . $dc_pages[$j]->{'Speaker'};

			$output .= "\n[" . ($j + 1) . "] " . $speaker . "\n";
			$output .= "JP: " . $dc_pages[$j]->{'Text'} . "\n";

			$todo_count ++ if($english eq "");

			$output .= "EN: " . $english . "\n";
		}
	}

	write_file_raw($text_file, encode("UTF-8", $output));

	return $todo_count;
}

sub mes_pages
{
	my $script = $_[0];
	my $is_pc = $_[1];

	my %opcode_words = (0x02 => 3, 0x06 => 2, 0x15 => 2, 0x16 => 3);
	my @pages;
	my @lines;
	my $speaker = -1;
	my $voice = -1;
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

			$position += 4 + ($is_pc ? $length : $length & ~1);
		}
		else
		{
			$speaker = unpack("v", substr($script, $position + 2, 2)) if($opcode == 0x02);
			$voice = unpack("v", substr($script, $position + 2, 2)) if($opcode == 0x06);

			if($opcode == 0x07)
			{
				my $text = join($is_pc ? " " : " / ", @lines);

				if($is_pc)
				{
					$text =~ s/\x{FF0D}/\x{2014}/g;
					$text =~ s/[\x{2018}\x{2019}]/'/g;
					$text =~ s/[\x{201C}\x{201D}]/"/g;
					$text =~ s/ +/ /g;
				}

				push(@pages, { 'Speaker' => $speaker, 'Voice' => $voice, 'Text' => $text });
				@lines = ();
			}

			last if($opcode == 0x00);

			$position += 2 * (defined($opcode_words{$opcode}) ? $opcode_words{$opcode} : 1);
		}
	}

	return @pages;
}

sub dump_executable_strings
{
	my $executable = read_file_raw($_[0]);
	my $output_file = $_[1];

	open(my $handle, '>:raw', $output_file) or die "dump_executable_strings() failed to open $output_file: $!";

	while($executable =~ /((?:[\x20-\x7e\x0a]|[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc]){8,})\x00/g)
	{
		my $text = $1;
		my $offset = $-[0];

		$text =~ s/\x0a/\\n/g;

		print $handle sprintf("%08X", $offset) . "|" . $text . "\r\n";
	}

	close($handle);
}
