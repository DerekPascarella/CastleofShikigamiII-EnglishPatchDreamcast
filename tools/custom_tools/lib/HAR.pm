package HAR;

use strict;
use Compress::Raw::Zlib;

use Exporter 'import';
our @EXPORT = qw(read_file_raw write_file_raw read_har write_har har_entry_index har_replace_entry
				 hgpt_texture_offset hgpt_pvrt_offset hgpt_sprites inflate_raw deflate_raw
				 bin_open bin_read_sectors iso_list_files iso_read_file);

sub read_file_raw
{
	my $file = $_[0];

	open(my $handle, '<:raw', $file) or die "read_file_raw() failed to open $file: $!";
	local $/;
	my $data = <$handle>;
	close($handle);

	return $data;
}

sub write_file_raw
{
	my $file = $_[0];
	my $data = $_[1];

	open(my $handle, '>:raw', $file) or die "write_file_raw() failed to open $file: $!";
	print $handle $data;
	close($handle);
}

sub inflate_raw
{
	my $compressed = $_[0];

	my ($inflater, $status) = Compress::Raw::Zlib::Inflate->new(-WindowBits => -MAX_WBITS, -LimitOutput => 0);
	die "inflate_raw() failed to initialize: $status" if($status != Z_OK);

	my $output;
	$status = $inflater->inflate($compressed, $output);
	die "inflate_raw() failed: $status" if($status != Z_OK && $status != Z_STREAM_END);

	return $output;
}

sub deflate_raw
{
	my $data = $_[0];

	my ($deflater, $status) = Compress::Raw::Zlib::Deflate->new(-WindowBits => -MAX_WBITS, -Level => Z_BEST_COMPRESSION);
	die "deflate_raw() failed to initialize: $status" if($status != Z_OK);

	my ($output, $tail);
	$deflater->deflate($data, $output);
	$deflater->flush($tail);

	return deflate_dynamic(deflate_symbols($output . $tail));
}

my @length_extra = (0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0);
my @distance_extra = (0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13);
my @code_length_order = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

sub deflate_read
{
	return oct("0b" . scalar(reverse(substr($_[0], $_[1], $_[2]))));
}

sub deflate_bits
{
	return substr(unpack("b32", pack("V", $_[0])), 0, $_[1]);
}

sub deflate_table
{
	my @lengths = @_;

	my @codes = huffman_codes(@lengths);
	my %table = map { $lengths[$_] ? ($codes[$_] => $_) : () } 0 .. $#lengths;
	my @sizes = sort { $a <=> $b } grep { $_ } @lengths;

	return [\%table, $sizes[0], $sizes[-1]];
}

sub deflate_decode
{
	my ($table, $minimum, $maximum) = @{$_[0]};

	for(my $size = $minimum; $size <= $maximum; $size ++)
	{
		my $symbol = $table->{substr($_[1], $_[2], $size)};

		if(defined($symbol))
		{
			$_[2] += $size;
			return $symbol;
		}
	}

	die "deflate_decode() found an invalid code";
}

sub deflate_symbols
{
	my $bits = unpack("b*", $_[0]);
	my $position = 0;
	my $final = 0;
	my @symbols;

	while(!$final)
	{
		$final = substr($bits, $position, 1);
		my $type = deflate_read($bits, $position + 1, 2);
		$position += 3;

		if($type == 0)
		{
			$position = ($position + 7) & ~7;
			my $length = deflate_read($bits, $position, 16);
			push(@symbols, unpack("C*", pack("b*", substr($bits, $position + 32, $length * 8))), 256);
			$position += 32 + $length * 8;
			next;
		}

		my (@literal_lengths, @distance_lengths);

		if($type == 1)
		{
			@literal_lengths = ((8) x 144, (9) x 112, (7) x 24, (8) x 8);
			@distance_lengths = (5) x 30;
		}
		else
		{
			my $literal_count = deflate_read($bits, $position, 5) + 257;
			my $distance_count = deflate_read($bits, $position + 5, 5) + 1;
			my $code_length_count = deflate_read($bits, $position + 10, 4) + 4;
			my @code_length_lengths = (0) x 19;
			my @lengths;
			$position += 14;

			for(my $i = 0; $i < $code_length_count; $i ++)
			{
				$code_length_lengths[$code_length_order[$i]] = deflate_read($bits, $position, 3);
				$position += 3;
			}

			my $code_lengths = deflate_table(@code_length_lengths);

			while(scalar(@lengths) < $literal_count + $distance_count)
			{
				my $symbol = deflate_decode($code_lengths, $bits, $position);

				if($symbol < 16)
				{
					push(@lengths, $symbol);
				}
				elsif($symbol == 16)
				{
					push(@lengths, ($lengths[-1]) x (deflate_read($bits, $position, 2) + 3));
					$position += 2;
				}
				elsif($symbol == 17)
				{
					push(@lengths, (0) x (deflate_read($bits, $position, 3) + 3));
					$position += 3;
				}
				else
				{
					push(@lengths, (0) x (deflate_read($bits, $position, 7) + 11));
					$position += 7;
				}
			}

			@literal_lengths = @lengths[0 .. $literal_count - 1];
			@distance_lengths = @lengths[$literal_count .. $literal_count + $distance_count - 1];
		}

		my $literals = deflate_table(@literal_lengths);
		my $distances = deflate_table(@distance_lengths);

		while(1)
		{
			my $symbol = deflate_decode($literals, $bits, $position);
			push(@symbols, $symbol);

			last if($symbol == 256);
			next if($symbol < 256);

			my $length_bits = substr($bits, $position, $length_extra[$symbol - 257]);
			$position += $length_extra[$symbol - 257];
			my $distance = deflate_decode($distances, $bits, $position);
			my $distance_bits = substr($bits, $position, $distance_extra[$distance]);
			$position += $distance_extra[$distance];

			push(@symbols, $length_bits, $distance, $distance_bits);
		}
	}

	return \@symbols;
}

sub huffman_lengths
{
	my @frequencies = @{$_[0]};
	my $limit = $_[1];

	my @used = grep { $frequencies[$_] } 0 .. $#frequencies;

	for my $symbol (0, 1)
	{
		if(scalar(@used) < 2 && !$frequencies[$symbol])
		{
			$frequencies[$symbol] = 1;
			push(@used, $symbol);
		}
	}

	while(1)
	{
		my @order = sort { $frequencies[$a] <=> $frequencies[$b] || $a <=> $b } @used;
		my @weights = map { $frequencies[$_] } @order;
		my $count = scalar(@order);
		my ($leaf, $node) = (0, $count);
		my @parents;

		for(my $next = $count; $next < 2 * $count - 1; $next ++)
		{
			for(my $child = 0; $child < 2; $child ++)
			{
				my $pick = ($leaf < $count && ($node >= $next || $weights[$leaf] <= $weights[$node])) ? $leaf ++ : $node ++;
				$parents[$pick] = $next;
				$weights[$next] += $weights[$pick];
			}
		}

		my @depths = (0) x (2 * $count - 1);
		my @lengths = (0) x scalar(@frequencies);
		my $longest = 0;

		for(my $i = 2 * $count - 3; $i >= 0; $i --)
		{
			$depths[$i] = $depths[$parents[$i]] + 1;
		}

		for(my $i = 0; $i < $count; $i ++)
		{
			$lengths[$order[$i]] = $depths[$i];
			$longest = $depths[$i] if($depths[$i] > $longest);
		}

		return @lengths if($longest <= $limit);

		$frequencies[$_] = ($frequencies[$_] >> 1) | 1 for(@used);
	}
}

sub huffman_codes
{
	my @lengths = @_;

	my @counts = (0) x 16;
	my @next = (0) x 16;
	my $code = 0;

	$counts[$_] ++ for(grep { $_ } @lengths);

	for(my $size = 1; $size < 16; $size ++)
	{
		$code = ($code + $counts[$size - 1]) << 1;
		$next[$size] = $code;
	}

	return map { $_ ? sprintf("%0*b", $_, $next[$_] ++) : "" } @lengths;
}

sub huft_entries
{
	my $root = shift;
	my @lengths = @_;

	my @counts = (0) x 17;
	$counts[$_] ++ for(grep { $_ } @lengths);

	my @sizes = sort { $a <=> $b } grep { $_ } @lengths;
	my ($shortest, $longest) = ($sizes[0], $sizes[-1]);
	my $bits = $root < $shortest ? $shortest : $root > $longest ? $longest : $root;
	my ($code, $level, $decoded, $entries) = (0, -1, -$bits, 0);
	my @patterns = (0);

	for(my $size = $shortest; $size <= $longest; $size ++)
	{
		my $remaining = $counts[$size];

		while($remaining --)
		{
			while($size > $decoded + $bits)
			{
				$level ++;
				$decoded += $bits;

				my $limit = $longest - $decoded > $bits ? $bits : $longest - $decoded;
				my $table_bits = $size - $decoded;
				my $free = 1 << $table_bits;

				if($free > $remaining + 1)
				{
					$free -= $remaining + 1;
					my $next = $size;

					while(++ $table_bits < $limit)
					{
						$free <<= 1;
						last if($free <= $counts[++ $next]);
						$free -= $counts[$next];
					}
				}

				$entries += (1 << $table_bits) + 1;
				$patterns[$level] = $code;
			}

			my $bit = 1 << ($size - 1);

			while($code & $bit)
			{
				$code ^= $bit;
				$bit >>= 1;
			}

			$code ^= $bit;

			while(($code & ((1 << $decoded) - 1)) != $patterns[$level])
			{
				$level --;
				$decoded -= $bits;
			}
		}
	}

	return $entries;
}

sub deflate_dynamic
{
	my $symbols = $_[0];

	my $output = "";
	my $start = 0;

	while($start < scalar(@$symbols))
	{
		my @literal_frequencies = (0) x 286;
		my @distance_frequencies = (0) x 30;
		my $end = $start;

		while(1)
		{
			my $symbol = $symbols->[$end ++];
			$literal_frequencies[$symbol] ++;

			last if($symbol == 256);

			if($symbol > 256)
			{
				$distance_frequencies[$symbols->[$end + 1]] ++;
				$end += 3;
			}
		}

		my ($literal_limit, $distance_limit) = (15, 15);
		my (@literal_lengths, @distance_lengths);

		while(1)
		{
			@literal_lengths = huffman_lengths(\@literal_frequencies, $literal_limit);
			@distance_lengths = huffman_lengths(\@distance_frequencies, $distance_limit);

			my $literal_entries = huft_entries(9, @literal_lengths);
			my $distance_entries = huft_entries(6, @distance_lengths);

			last if($literal_entries + $distance_entries <= 1024);

			if($literal_entries - 513 >= $distance_entries - 65)
			{
				$literal_limit --;
			}
			else
			{
				$distance_limit --;
			}
		}

		my $literal_count = 286;
		my $distance_count = 30;
		$literal_count -- while($literal_lengths[$literal_count - 1] == 0);
		$distance_count -- while($distance_lengths[$distance_count - 1] == 0);

		my @lengths = (@literal_lengths[0 .. $literal_count - 1], @distance_lengths[0 .. $distance_count - 1]);
		my @runs;

		for(my $i = 0; $i < scalar(@lengths); )
		{
			my $length = $lengths[$i];
			my $run = 1;
			$run ++ while($i + $run < scalar(@lengths) && $lengths[$i + $run] == $length);
			$i += $run;

			if($length == 0)
			{
				while($run >= 11)
				{
					my $repeat = $run > 138 ? 138 : $run;
					push(@runs, [18, deflate_bits($repeat - 11, 7)]);
					$run -= $repeat;
				}

				if($run >= 3)
				{
					push(@runs, [17, deflate_bits($run - 3, 3)]);
					$run = 0;
				}
			}
			else
			{
				push(@runs, [$length, ""]);
				$run --;

				while($run >= 3)
				{
					my $repeat = $run > 6 ? 6 : $run;
					push(@runs, [16, deflate_bits($repeat - 3, 2)]);
					$run -= $repeat;
				}
			}

			push(@runs, [$length, ""]) for(1 .. $run);
		}

		my @code_length_frequencies = (0) x 19;
		$code_length_frequencies[$_->[0]] ++ for(@runs);

		my @code_length_lengths = huffman_lengths(\@code_length_frequencies, 7);
		my $code_length_count = 19;
		$code_length_count -- while($code_length_count > 4 && $code_length_lengths[$code_length_order[$code_length_count - 1]] == 0);

		my @code_length_codes = huffman_codes(@code_length_lengths);
		my @literal_codes = huffman_codes(@literal_lengths);
		my @distance_codes = huffman_codes(@distance_lengths);

		$output .= ($end == scalar(@$symbols) ? "1" : "0") . "01";
		$output .= deflate_bits($literal_count - 257, 5) . deflate_bits($distance_count - 1, 5) . deflate_bits($code_length_count - 4, 4);
		$output .= deflate_bits($code_length_lengths[$code_length_order[$_]], 3) for(0 .. $code_length_count - 1);
		$output .= $code_length_codes[$_->[0]] . $_->[1] for(@runs);

		for(my $i = $start; $i < $end; $i ++)
		{
			my $symbol = $symbols->[$i];
			$output .= $literal_codes[$symbol];

			if($symbol > 256)
			{
				$output .= $symbols->[$i + 1] . $distance_codes[$symbols->[$i + 2]] . $symbols->[$i + 3];
				$i += 3;
			}
		}

		$start = $end;
	}

	return pack("b*", $output);
}

sub read_har
{
	my $file = $_[0];

	my $har_data = read_file_raw($file);

	die "read_har() found no HGAR signature in $file" if(substr($har_data, 0, 4) ne "HGAR");

	my ($version, $count) = unpack("v v", substr($har_data, 4, 4));
	my @offsets = unpack("V" . $count, substr($har_data, 8, $count * 4));

	my %har;
	$har{'Version'} = $version;
	$har{'Header'} = substr($har_data, 0, $offsets[0]);
	$har{'Entries'} = [];

	for(my $i = 0; $i < $count; $i ++)
	{
		my $offset = $offsets[$i];
		my $name = substr($har_data, $offset, 12);
		my ($flags, $size) = unpack("V V", substr($har_data, $offset + 12, 8));
		my $payload = substr($har_data, $offset + 20, $size);
		my $data;

		if($flags & 0x80000000)
		{
			my $uncompressed_size = unpack("V", substr($payload, 0, 4));
			$data = inflate_raw(substr($payload, 4));

			die "read_har() size mismatch for entry " . $i . " in $file" if(length($data) != $uncompressed_size);
		}
		else
		{
			$data = $payload;
		}

		push(@{$har{'Entries'}}, { 'Name' => $name, 'Flags' => $flags, 'Payload' => $payload, 'Data' => $data, 'Modified' => 0 });
	}

	return \%har;
}

sub write_har
{
	my $file = $_[0];
	my %har = %{$_[1]};

	my @entries = @{$har{'Entries'}};
	my $header = $har{'Header'};
	my $body = "";
	my @offsets;

	for(my $i = 0; $i < scalar(@entries); $i ++)
	{
		my $entry = $entries[$i];
		my $payload = $entry->{'Payload'};

		if($entry->{'Modified'})
		{
			if($entry->{'Flags'} & 0x80000000)
			{
				$payload = pack("V", length($entry->{'Data'})) . deflate_raw($entry->{'Data'});
			}
			else
			{
				$payload = $entry->{'Data'};
			}

			$payload .= "\x00" x ((4 - length($payload) % 4) % 4);
		}

		push(@offsets, length($header) + length($body));
		$body .= $entry->{'Name'} . pack("V V", $entry->{'Flags'}, length($payload)) . $payload;
	}

	substr($header, 8, scalar(@offsets) * 4) = pack("V*", @offsets);

	write_file_raw($file, $header . $body);
}

sub har_entry_index
{
	my %har = %{$_[0]};
	my $name = lc($_[1]);

	my @entries = @{$har{'Entries'}};

	for(my $i = 0; $i < scalar(@entries); $i ++)
	{
		(my $entry_name = lc($entries[$i]->{'Name'})) =~ s/[ \x00]//g;

		return $i if($entry_name eq $name);
	}

	return -1;
}

sub har_replace_entry
{
	my $har = $_[0];
	my $index = $_[1];
	my $data = $_[2];

	$har->{'Entries'}->[$index]->{'Data'} = $data;
	$har->{'Entries'}->[$index]->{'Modified'} = 1;
}

sub hgpt_texture_offset
{
	my $hgpt = $_[0];

	die "hgpt_texture_offset() found no HGPT signature" if(substr($hgpt, 0, 4) ne "HGPT");

	my ($header_size, $has_sprites) = unpack("v v", substr($hgpt, 4, 4));

	return $has_sprites ? $header_size : $header_size + 8;
}

sub hgpt_pvrt_offset
{
	my $hgpt = $_[0];

	my $offset = index($hgpt, "PVRT", hgpt_texture_offset($hgpt));

	die "hgpt_pvrt_offset() found no PVRT chunk" if($offset < 0);

	return $offset;
}

sub hgpt_sprites
{
	my $hgpt = $_[0];

	my ($header_size, $has_sprites, $count) = unpack("v v V", substr($hgpt, 4, 8));
	my @sprites;

	return @sprites if(!$has_sprites);

	for(my $i = 0; $i < $count; $i ++)
	{
		push(@sprites, [unpack("v4", substr($hgpt, 0x1C + $i * 8, 8))]);
	}

	return @sprites;
}

sub bin_open
{
	my $file = $_[0];

	open(my $handle, '<:raw', $file) or die "bin_open() failed to open $file: $!";

	return $handle;
}

sub bin_read_sectors
{
	my $handle = $_[0];
	my $lba = $_[1];
	my $length = $_[2];

	my $data = "";
	my $sector = $lba;

	while(length($data) < $length)
	{
		my $raw;
		seek($handle, $sector * 2352, 0);
		read($handle, $raw, 2352) == 2352 or die "bin_read_sectors() failed to read sector $sector";
		$data .= substr($raw, 24, 2048);
		$sector ++;
	}

	return substr($data, 0, $length);
}

sub iso_list_files
{
	my $handle = $_[0];

	my $pvd = bin_read_sectors($handle, 16, 2048);

	die "iso_list_files() found no primary volume descriptor" if(substr($pvd, 1, 5) ne "CD001");

	my $root = substr($pvd, 156, 34);
	my @files;
	my @queue = (["", unpack("V", substr($root, 2, 4)), unpack("V", substr($root, 10, 4))]);

	while(scalar(@queue) > 0)
	{
		my ($path, $lba, $size) = @{shift(@queue)};
		my $directory = bin_read_sectors($handle, $lba, $size);
		my $position = 0;

		while($position < length($directory))
		{
			my $record_length = ord(substr($directory, $position, 1));

			if($record_length == 0)
			{
				$position = (int($position / 2048) + 1) * 2048;
				next;
			}

			my $entry_lba = unpack("V", substr($directory, $position + 2, 4));
			my $entry_size = unpack("V", substr($directory, $position + 10, 4));
			my $entry_flags = ord(substr($directory, $position + 25, 1));
			my $name_length = ord(substr($directory, $position + 32, 1));
			my $name = substr($directory, $position + 33, $name_length);

			if($name ne "\x00" && $name ne "\x01")
			{
				$name =~ s/;1$//;

				if($entry_flags & 2)
				{
					push(@queue, [$path . $name . "/", $entry_lba, $entry_size]);
				}
				else
				{
					push(@files, [$path . $name, $entry_lba, $entry_size]);
				}
			}

			$position += $record_length;
		}
	}

	return @files;
}

sub iso_read_file
{
	return bin_read_sectors($_[0], $_[1], $_[2]);
}

1;
