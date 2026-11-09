#!/usr/bin/perl

use strict;
use FindBin;
use CamelROM;

chdir($FindBin::Bin);

my $bootsector = "../../bootsector/IP.BIN";

my @patches = (
	[0x31, "2020", "5545"],
	[0x80, "5348494b4947414d49204e4f20534849524f2032202020202020202020202020", "434153544c45204f46205348494b4947414d492049492028454e474c49534829"],
	[0x3724, "20202020202020202020202020202020202020", "466f722055534120616e642043414e4144412e"],
	[0x3744, "2020202020202020202020", "466f72204555524f50452e"]
);

my $error_count = 0;

print "\nApplying " . scalar(@patches) . " patch(es) to IP.BIN...\n\n";

foreach my $patch (@patches)
{
	my ($offset, $original_hex, $patch_hex) = @{$patch};
	my $length = length($patch_hex) / 2;
	my $current_hex = read_bytes_at_offset($bootsector, $length, $offset);

	if(lc($current_hex) eq lc($patch_hex))
	{
		print "-> IP.BIN at 0x" . decimal_to_hex($offset) . " already applied.\n";
	}
	elsif(lc($current_hex) eq lc($original_hex))
	{
		patch_bytes($bootsector, $patch_hex, $offset);

		print "-> IP.BIN at 0x" . decimal_to_hex($offset) . " applied (" . $length . " bytes).\n";
	}
	else
	{
		print "-> IP.BIN at 0x" . decimal_to_hex($offset) . " ERROR: unexpected bytes, skipping!\n";

		$error_count ++;
	}
}

print "\nTotal errors: " . $error_count . "\n" if($error_count > 0);
print "\nPatching complete!\n\n";
