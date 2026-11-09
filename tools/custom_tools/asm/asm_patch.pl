#!/usr/bin/perl

use strict;
use FindBin;
use CamelROM;

chdir($FindBin::Bin);

my $executable = "../../gdi_extracted/1ST_READ.BIN";
my $original_executable = "../../gdi_orig_extracted/1ST_READ.BIN";

my @patches = (
	[0x4D20, "01e3", "video_60hz.asm"],
	[0xA9BA4, "224fe65211b093670c32264f0b002c3a224f0ed10b410900062f06b0c167ec700c3af660264f0b0009007c610c900031078f14e019477c67c07705d17c3110600c600b000900090086000900b4e6098cf89b0b8c", "vwf_dialogue.asm"],
	[0x110838, "01d02b4009000900a49b0b8c", "vwf_dialogue.asm"],
	[0x110912, "91bfe45309000900", "vwf_dialogue.asm"],
	[0x110A70, "b49b0b8c", "vwf_dialogue.asm"],
	[0x11174E, "30e6", "vwf_dialogue.asm"],
	[0x1117CE, "30e6", "vwf_dialogue.asm"],
	[0x1118DC, "30e6", "vwf_dialogue.asm"],
	[0x110E94, "30e3", "vwf_dialogue.asm"],
	[0x110F7A, "0009", "vwf_dialogue.asm"],
	[0x110744, "40eb", "exe_text.asm"],
	[0x112A8E, "01d02b400900589c0b8c", "exe_text.asm"],
	[0xA9C58, "e62fd62f224f48241e89436d536e00e6e460082006890a8804891140f88d0276f6af017e2eb0d4540900e365ffe0ec000a88eb890fd442622822058b0ed201e00ed1226332210224264ff66d0b00f66e94601140048f0c602070184004a086cb94611c6118411b20921f036904d12b4103640900ec84308cf484308cf084308c0605128cd1500d911030068bd2600a911030099000890890022401d32b4309005c08128c5e01b800ac008800", "exe_text.asm"],
	[0x1108D2, "0900090009000900", "exe_text.asm"],
	[0x1108DC, "0900", "exe_text.asm"],
	[0x110984, "a89c0b8c", "exe_text.asm"],
	[0x104268, "21b00900", "exe_text.asm"],
	[0x10416A, "91b00900090003e0031d0900", "exe_text.asm"],
	[0x104290, "c0601140068f0c632070184086cb03630b00ff7cc1840c6018400b000b23d15714e07c6286e44c644032058b19477c6703d27c3220600c600c330b0032110900b89b0b8c", "exe_text.asm"],
	[0x9F154, "fc00", "ui_layout.asm"],
	[0x9F8C4, "fc00", "ui_layout.asm"],
	[0x10A318, "1ce4", "ui_layout.asm"],
	[0x10A3A0, "1ce2", "ui_layout.asm"],
	[0x10F96A, "55e5", "ui_layout.asm"],
	[0x10FC6C, "9800", "ui_layout.asm"],
	[0x10D910, "f36437d5327438d10b4120e610e635d51ca0f3640900090009000900090009000900090009000900090009000900090009000900090009000900090009000900090009000900090009000900", "vmu_header.asm"],
	[0x5EFE2, "0b410900", "invincible.asm"],
	[0x5F078, "827b118c", "invincible.asm"],
	[0xA9000, "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004c910b8c030000000000000058910b8c030000001dd568e600465c361cd442600820058b68500224695001146a50021418d15e52235002212260031116d0026002265d500116121614d0031614d0026014d715d108200c8d107610e0022713164260022641500116425002160fd102a010760fe00227131601e218425c32226002262150011622500b000216fc5f1a8c88900b8c94900b8c48910b8c0200250020041f8ce8832f8c0100280001002a00", "invincible.asm"],
	[0x107984, "08900b8c", "invincible.asm"],
	[0x107AF4, "08900b8c", "invincible.asm"],
	[0x107B54, "0fd02b4009000fd1126001110f117c710dd22b4202210bd11f5002217c710bd22b42022107d1115009d22b42022109d1126040c903d112611b200b0008200900ac900b8c00900b8c086f118ca879118cde80118c000b158c09000900", "invincible.asm"],
	[0x107C78, "08900b8c", "invincible.asm"],
	[0x10804C, "08900b8c", "invincible.asm"],
	[0x108078, "48900b8c", "invincible.asm"],
	[0x10809C, "5a7b118c", "invincible.asm"],
	[0x1082E8, "48900b8c", "invincible.asm"],
	[0x109610, "08900b8c", "invincible.asm"],
	[0x10994C, "0e88", "invincible.asm"],
	[0x109996, "0f88", "invincible.asm"],
	[0x1099A8, "0e88", "invincible.asm"],
	[0x1099F4, "6a7b118c", "invincible.asm"],
	[0x109CD0, "787b118c", "invincible.asm"],
	[0x109CE0, "48900b8c", "invincible.asm"],
	[0x11174A, "03e7", "dialogue_box.asm"],
	[0x1117CA, "03e7", "dialogue_box.asm"],
	[0x1118D8, "03e7", "dialogue_box.asm"],
	[0x19737E, "5402", "dialogue_box.asm"],
	[0x1973AA, "5402e0015802", "dialogue_box.asm"],
	[0x1973DA, "5802e0015902", "dialogue_box.asm"],
	[0x1973F6, "5402", "dialogue_box.asm"],
	[0x197422, "5402e0015802", "dialogue_box.asm"],
	[0x197452, "5802e0015902", "dialogue_box.asm"],
	[0x197482, "2c02e0012c02", "dialogue_box.asm"],
	[0x19749A, "2c02e0012c02", "dialogue_box.asm"],
	[0x111840, "0b02", "text_vcenter.asm"],
	[0x111958, "0b02", "text_vcenter.asm"],
	[0x1064D8, "f974", "text_vcenter.asm"],
	[0x10662E, "5e95", "text_vcenter.asm"],
	[0x1066E6, "9101", "text_vcenter.asm"],
	[0x1066EA, "a701", "text_vcenter.asm"],
	[0x1066EE, "9001", "text_vcenter.asm"],
	[0x10A28E, "ad01", "text_vcenter.asm"],
	[0x10E9EC, "d301", "text_vcenter.asm"],
	[0x11250E, "f97d", "text_vcenter.asm"],
	[0x7F308, "287b0b8c", "analog_stick.asm"],
	[0xA7A5A, "1da00900", "analog_stick.asm"],
	[0xA7A98, "862f962f28d629d802e726d110600820449403898260018800893e945ce06e0158e06e031365114500895b653369114900899b6900e2473501894739188b2f9007091a04536018404730058b114110e2018901a0090020e2229007051a04936018404730048b40e01143008b00400b2254e06e012b21160640e00c380f901047c38f0c3607d100e22021f6690b00f66804d101e006d22b4200210002000878016a0009004c7b0b8c40bc2b8c3c69248cccea068c00000000", "analog_stick.asm"],
	[0x8862A, "08ec", "chibi_select.asm"],
	[0x88946, "ff88", "chibi_select.asm"],
	[0x88974, "ff88", "chibi_select.asm"],
	[0x889C2, "ff88", "chibi_select.asm"],
	[0x889CC, "07e9", "chibi_select.asm"],
	[0x889EC, "ff88", "chibi_select.asm"],
	[0x88A0C, "ff88", "chibi_select.asm"],
	[0x88A16, "08e9", "chibi_select.asm"],
	[0x88A36, "ff88", "chibi_select.asm"],
	[0xA97E8, "00000000010000000200000003000000040000000500000006000000070000000000000001000000020000000300000004000000050000000600000007000000224f19d00b40090018d00b40090018d1022103643291162f3191162f15d50fe651e715d00b400900087f264f0b00090063505c301140008907e008e11330008b00e00316415118210b89435207e33032008b03e203613031008b03e12031e88909000b000900090046ff068c366f0c8cb8b42e8c0b000d80047d108ca301cf00", "chibi_select.asm"],
	[0xFA110, "20e3", "chibi_select.asm"],
	[0xFA12E, "20e3", "chibi_select.asm"],
	[0xFA1AC, "e8970b8c", "chibi_select.asm"],
	[0xFA3E2, "20ea", "chibi_select.asm"],
	[0xFA3FC, "02d0ffe50b40e3663aa0090058980b8c09000900090009000900090009000900090009000900090009000900", "chibi_select.asm"],
	[0xFA450, "02d001e50b40e36610a0090058980b8c09000900090009000900090009000900090009000900090009000900", "chibi_select.asm"],
	[0xFA4F6, "1800", "chibi_select.asm"],
	[0xFA530, "e8970b8c", "chibi_select.asm"],
	[0xFA760, "e8970b8c", "chibi_select.asm"],
	[0xFA940, "28980b8c", "chibi_select.asm"],
	[0xFA9F0, "2077", "chibi_select.asm"],
	[0xFAA74, "e8970b8c", "chibi_select.asm"],
	[0xFAB6C, "e8970b8c", "chibi_select.asm"],
	[0xFAC98, "5855", "chibi_select.asm"],
	[0xFAE00, "3ae2270401e349233b63eee22923311f4e911c331a04de74", "chibi_select.asm"],
	[0xFB0BC, "44ded36830780de900eaa36001c8048fcfe4e1e44c6402a0cc344c64c834866693650b4e3a79017aa3600788018bd36854780888e98b0900090009000900090009000900090009000900", "chibi_select.asm"],
	[0xFC05A, "20e3", "chibi_select.asm"],
	[0xFC084, "e8970b8c", "chibi_select.asm"],
	[0xFC0CE, "20e0", "chibi_select.asm"],
	[0xFC1B8, "e8970b8c", "chibi_select.asm"],
	[0xFC21A, "3b14", "chibi_select.asm"],
	[0xFC2F0, "e8970b8c", "chibi_select.asm"]
);

my $error_count = 0;

print "\nApplying " . scalar(@patches) . " patch(es) to 1ST_READ.BIN...\n\n";

for(my $i = 0; $i < scalar(@patches); $i ++)
{
	my ($offset, $patch_hex, $source) = @{$patches[$i]};
	my $length = length($patch_hex) / 2;
	my $original_hex = read_bytes_at_offset($original_executable, $length, $offset);
	my $current_hex = read_bytes_at_offset($executable, $length, $offset);

	if(lc($current_hex) eq lc($patch_hex))
	{
		print "-> " . $source . " at 0x" . decimal_to_hex($offset) . " already applied.\n";
	}
	elsif(lc($current_hex) eq lc($original_hex))
	{
		patch_bytes($executable, $patch_hex, $offset);

		print "-> " . $source . " at 0x" . decimal_to_hex($offset) . " applied (" . $length . " bytes).\n";
	}
	else
	{
		print "-> " . $source . " at 0x" . decimal_to_hex($offset) . " ERROR: unexpected bytes, skipping!\n";

		$error_count ++;
	}
}

print "\nTotal errors: " . $error_count . "\n" if($error_count > 0);
print "\nPatching complete!\n\n";
