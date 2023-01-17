@rem = '--*-Perl-*--
@echo off
REM ###################################################################
REM 
REM    #DESCRIPTION:     Script to help LS perform LS review of any two bundles
REM
REM    #AUTHOR:            Abhishek Deshmukh updated by antonio.renna@autodesk.com
REM 
REM    #REVISION  :        Version 2.1
REM
REM    #DATE:                Dec 10
REM 
REM    #UPDATES :		[see below]
REM
REM    # REQMTS : 	Passolo,Excel
REM ###################################################################
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl
#line 29
use strict;
use File::Find;
use File::Spec;
use File::Copy;
use File::Path;
use File::Basename;
use Win32::OLE qw(CP_UTF8);
use Win32::OLE::Const;
use Cwd;

use Win32::TieRegistry( Delimiter=>"#", ArrayValues=>0 );
our $pound= $Registry->Delimiter("/");

#UPDATE 1.1	- Added code to have a new LS status for recovered strings (AUTOTRN)
#UPDATE 1.2	- Added code for splitting into XLS output
#UPDATE 1.3	- Handling interrrupts, clean exit , absolute path for all files
#UPDATE 1.4	- abs_path replaced by file spec rel2abs function to work with perl 5.6
#UPDATE 1.5	- added new EXTERNAL autotrans status, excel set to INVISIBLE mode of processing
#UPDATE 1.6	- added new AUTOTRN_REP status for APAC / Modularized code by adding WRITE_LS_INFO function
#UPDATE 1.7	- added code to check language code for LPUS that have multiple langs (eg Revit)
#UPDATE 1.8	- added code to remove dependency to run tool on regional settings; added XLSX option
#UPDATE 1.9	- added code to decide excel object library to create XLS or XLSX accordingly (so that old / new office users can still run the same script)
#UPDATE 2.0	- 15th of December 2010 - Added Passolo versions parameter to cmd line (default 2011), supported, 2007, 2009 and 2011
#UPDATE 2.1	- 14th of October 2011
#				- Fixed bug in xls report. $currsrc was being written inside "Previous Source" column instead of $prevsrc.
#				- Fixed bug in xls report. "N/A" is written in the previous source and translation for new strings
#				- Fixed status and comment for [MT] strings. The code edits the fields prior writing 
#				- [LS-STATUS=AUTOTRN-REP] removed (UNDO UPDATE 1.6)
#				This is a status that doesn't make sense anymore as it was introduce to track the strings set as [REPETITION] by the
#				ManageRepetitions macro. These were auto-translated from NEW strings and translation dispatched by ManageRepetitions macro.
#				As TLQM doesn't want such automatic process to happen, we stopped using ManageRepetitions macro and thus this STATUS is removed.
#				- TLQM doesn't want to review AUTOTRN anymore, so changed from for review to validated for AUTOTRN and AUTOTRN-EXT
#
#UPDATE 2.2	- 16th of January 2013
#				- Added "esn" in the list of accepted language parameter
#
######################################################  CLEAN EXIT FOR ALL INTERRUPTS  ##########################################################

$SIG{ 'HUP' } = 'clean_exit' ;
$SIG{ 'INT' } = 'clean_exit' ;
$SIG{ 'KILL' } = 'clean_exit' ;
$SIG{ 'TERM' } = 'clean_exit' ;

######################################################  INPUT VALIDATION ##########################################################

our($proj,$psl,$pslConst,$PassoloVersionInput);
my $prevlpu =  shift;
my $lpu = shift;
my $lang = shift;

if (scalar @ARGV != 0) {
	$PassoloVersionInput = shift;
} else {
	$PassoloVersionInput = "2018";
}

our ($start,$end);
$start = localtime;


sub TRUE{ return 1; }
sub FALSE{ return 0; }

### comment / uncomment as per your version of Passolo installed
#our $PassoloObject = 'Passolo.UnicodeApplication'; #Passolo 5
#our $PassoloObject = 'Passolo.Application'; #Passolo 6

our $PassoloObject;

if ($PassoloVersionInput eq "2007") {
	$PassoloObject = 'Passolo.Application.7'; #Passolo 2007
} elsif ($PassoloVersionInput eq "2009") {
	$PassoloObject = 'Passolo.Application.8'; #Passolo 2009
} elsif ($PassoloVersionInput eq "2018") {
	$PassoloObject = 'Passolo.Application.18'; #Passolo 2018
} else {
	$PassoloObject = 'Passolo.Application';
}

if ( IsPassoloInstalled($PassoloObject) ) {
	print "\nSDL Passolo $PassoloVersionInput will be used for opening LPUs.\n";
#	print "$PassoloObject\n";
} else {
	print "\nERROR: SDL Passolo $PassoloVersionInput is not installed on this machine.\n\n";
	exit;
}


### set to "TRUE" if you want to see PASSOLO  visible during the processing
our $Visible = FALSE;
### set to "TRUE" if you want to see EXCEL  visible during the processing
our $XlsVisible = FALSE;

our $langs_fulldump = "(jpn|chs|cht|kor)"; #add remove as confirmed by LS - currently APAC langs
our $xls_row_limit = 65536; # define the delimiter for split excels - max can be 65536
our $delimiter = "HOPE_THERE_IS_NO_DELIMITER_LIKE_ME";

if (! -e $prevlpu || !-e $lpu){
	
	$0 = basename($0);
	print qq[

	------------------------------------------------------------
	------------------------------------------------------------
	USAGE: $0 <prev_lpu_name> <curr_lpu_name> <lang> [<PassoloVersion>]
	------------------------------------------------------------
	------------------------------------------------------------
	where:
	
		<prev_lpu_name> : LPU of previous build
	
		<curr_lpu_name> : LPU of current build
	
		<lang>    : standard 3 letter language code
		
		<PassoloVersion>    : Passolo release as 2007, 2009 or 2018 (default)
		
		eg:
	        $0 "c:\\temp\\lpus_build_x" "c:\\temp\\lpus_build_y" jpn 2009
	------------------------------------------------------------
	
	The tool diffs <prev_lpu> with <curr_lpu>. The output
	Review bundles and XLS are created with naming
	convention <current lpuname>_LS_REVIEW.xlsx(or
	lpu/tbulic as case may be)
	
	For APAC languages - complete dump is needed in 
	------------------
	review xls output hence the process will take some time. 
	Excel has a limit of 65536 lines - hence in case LPU
	contains more  than 65536 strings, multiple excel review
	sheets will be created
	
	-----------------------------------------------------------
	
];
	exit;
	
}
 our $FLAG_OLD = 0;
 
 die "\nERROR: Invalid language code $lang: $0 takes a valid <lang> as last parameter\n" if $lang !~ /^(chs|cht|csy|dan|nld|esp|esn|fin|fra|deu|ell|hun|ita|jpn|kor|nor|plk|ptg|ptb|rus|sve|trk)$/i ;


###################################################### Passolo Code 1 ######################################################

$psl = Win32::OLE->new($PassoloObject, 'Quit');
$psl->SetProperty('Visible',$Visible); 
$pslConst = Win32::OLE::Const->Load($psl);
my $projs = $psl->Projects;

$prevlpu = File::Spec->rel2abs($prevlpu);
$proj = $projs->Open("$prevlpu") or die "\nCannot open $prevlpu. LPU could have been saved with a different version than SDL Passolo $PassoloVersionInput.\n";


###################################################### Excel Code ######################################################

 Win32::OLE->Option(CP=>CP_UTF8);
## GLOBALS ####
our ($ldxls); # xls name
our $sheetctr; # counter for different xls in case more than 65536 strings
our $exapp;# excel object
our ($wb,$ws,$row); # work book, work sheet objects , row counter
$lpu = File::Spec->rel2abs($lpu);
$prevlpu = File::Spec->rel2abs($prevlpu);
$ldxls = File::Spec->rel2abs($lpu);

# initialize excel and write header information
our $excelversion = &InitializeExcel();
our $excel_ext;

if($excelversion eq "12.0")
{
	$excel_ext = ".xlsx";
}
else
{
	$excel_ext = ".xls";	
}

&WriteExcelHeader();


if($lang =~ /$langs_fulldump/i){ # if langs need full dump -  we would need to split the output xls into several ones
		 $sheetctr = 1;
		$ldxls =~ s%\.lpu$%_LS_Review_${sheetctr}.$excel_ext%i;
		unlink $ldxls if -e $ldxls;
}else{
		$ldxls =~ s%\.lpu%\_LS_Review.$excel_ext%i;
		unlink $ldxls if -e $ldxls;
}

###################################################### Passolo Code 2 ######################################################

our %prevhash;
our %prev_lpu_src_hash;
print "\nReading $prevlpu to store in hash\n\n";

my $numtrnslists = $proj->TransLists->Count;
my $reverse_ctr = 0;
for my $this_translist(1..$numtrnslists){
	
	my $trnlist = $proj->TransLists($this_translist);
	
	my $trn_lang = $trnlist->Language->LangCode ;
	
	next if(lc($trn_lang) ne lc($lang)); #skip languages not matching the correct language code
	
	#target file base name - and convert to lowercase
	my $filename = lc (	basename($trnlist->TargetFile)	) ;
	printf "%3d: Scanning $filename..\n",$numtrnslists-$reverse_ctr++;
	for my $i(1 .. $trnlist->StringCount)
	{
		my $transstr = $trnlist->String($i);
		next  if ($transstr->ResType eq "Version");
		my $id = $transstr->ID;
		if ($transstr->ResType eq "StringTable"){
				$id = 16 * ( $transstr->Resource->ID - 1) + $id; #conversion for string table
		}
		my $num = $transstr->Number;
		my$compid = $num."*".$id;
		my $srctext = $transstr->SourceText;
		my $trntext = $transstr->Text;

		# strore in HASH
		
		if($srctext ne ""){
			#hash of filename and composite id 
			$prevhash{$filename}{$compid} = $srctext.$delimiter.$trntext;
			
			#hash of sourcetext for autotranslated strings
			$prev_lpu_src_hash{$srctext} = $trntext;
		}
	
	}
}

$proj->Close();
print "\n   ...Done!\n";
#make a copy of the new lpu
$lpu = File::Spec->rel2abs($lpu);
our $ls_lpu = $lpu;
$ls_lpu =~ s%\.lpu$%_ForLSReview.lpu%i;
#$ls_lpu =~ s%\.tbulic500$%_ForLSReview.tbulic500%i;
copy($lpu,$ls_lpu) or die"\nCannot replicate $lpu  -> $ls_lpu\n";;
$proj = $projs->Open("$ls_lpu") or die "\nCannot open $ls_lpu\n";

print "\nPerforming Diff of \n$lpu <-> $prevlpu ...\n\n";

#abhi added OCT 06 ---- UNDO UPDATE 1.6 - AUG 2011
#my %curr_lpu_src_hash; #needed for each translation list to catch repeated words 

$reverse_ctr = 0;
$numtrnslists = $proj->TransLists->Count;
for my $this_translist(1..$numtrnslists){
	
	my $trnlist = $proj->TransLists($this_translist);
	
	my $trn_lang = $trnlist->Language->LangCode ;
	next if(lc($trn_lang) ne lc($lang)); #skip languages not matching the correct language code

	#target file base name - and convert to lowercase
	my $filename = lc (	basename($trnlist->TargetFile)	) ;
	
	printf "%3d: Comparing $filename..\n",$numtrnslists-$reverse_ctr++;
	
	if(	! exists($prevhash{$filename})	){ # either the file is newly added to the current LPU OR the file name has changed between the two builds
	
		for my $i(1 .. $trnlist->StringCount)
		{
			$FLAG_OLD = 0;
			my $transstr = $trnlist->String($i);	
			# SKIP conditions block to speed up processing
			next  if ($transstr->ResType eq "Version");
			###next if ($transstr->ResType eq "Dialog" && $transstr->Type eq "DialogFont"); #skip all dialog fonts :::: ### reverted : apac wants to check if FONT info is correct - so cannot skip this !!
			next if ($transstr->State($pslConst->{'pslStateReadOnly'} == 1)); # SKIP all read only strings!
			my $currsrc = $transstr->SourceText;
			next if $currsrc eq ""; # SKIP all empty strings!
			# - - - - - - - - - - - - - - - - -- - -  -- - - - - - - -
			my $currtrans = $transstr->Text;
			
			my $id = $transstr->ID;
			if ($transstr->ResType eq "StringTable"){
					$id = 16 * ( $transstr->Resource->ID - 1) + $id; #conversion for string table
			}
			my $num = $transstr->Number;
			my$compid = $num."*".$id;

			my $srccomment = $transstr->Comment; # note we are accessing comment property of source string
			if($srccomment =~ /\[OLD\]/){ # if legacy string - set the COMMENT flag
				$FLAG_OLD = 1;
			}	
			
			my $translator_comment = $transstr->TransComment;
			my $curr_comment = $transstr->Comment;
			
			# Check if the string was recovered by autotranslation - if it exists in hash of source strings
		
			if (exists($prev_lpu_src_hash{$currsrc})){ 
			
				my $prevtrans = $prev_lpu_src_hash{$currsrc};
#				&Write_LS_Info("AUTOTRN",$transstr,1,$translator_comment,$filename,$compid,$currsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);
#	prev source and prev translation can only be N/A since we are in the case where the file is new (or renamed), thus the string doesn't have a prev source and a prev translation
# No need to review AUTORN anymore, so changed ,1, to ,0,
				&Write_LS_Info("AUTOTRN",$transstr,0,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);

# UNDO UPDATE 1.6 - AUG 2011 - Remove AUTOTRN-REP status				
#			}elsif(	exists($curr_lpu_src_hash{$currsrc})		){ #repeated string in curr lpu - status should be marked AUTOTRN
			
#				&Write_LS_Info("AUTOTRN-REP",$transstr,1,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);
				
			}else{
			
				#add string to current source hash
# UNDO UPDATE 1.6 - AUG 2011 - Remove AUTOTRN-REP status				
#				$curr_lpu_src_hash{$currsrc} = $currtrans;
				
				# Check if string was autotranslated from other files or project glosarries
				if(	($transstr->State($pslConst->{'pslStateBookmark'}) == 1)	){# unique NEW string
						&Write_LS_Info("NEW",$transstr,1,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);
				}else{
# No need to review AUTORN anymore, so changed ,1, to ,0,
						&Write_LS_Info("AUTOTRN-EXT",$transstr,0,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);
				}
				
			}
	
		}
		
	}else{ 			#YEAP - file name matches with previous LPU - LOGIC IS AS FOLLOWS
	
		for my $i(1 .. $trnlist->StringCount)
		{
			$FLAG_OLD = 0;
			my $transstr = $trnlist->String($i);	
			next  if ($transstr->ResType eq "Version");
			my $currsrc = $transstr->SourceText;
			next if $currsrc eq ""; # SKIP all empty strings!
			next if ($transstr->State($pslConst->{'pslStateReadOnly'} == 1)); # SKIP all read only strings!
			my $currtrans = $transstr->Text;
			my $id = $transstr->ID;
			
			if ($transstr->ResType eq "StringTable"){
					$id = 16 * ( $transstr->Resource->ID - 1) + $id; #conversion for string table
			}
			
			my $num = $transstr->Number;
			my$compid = $num."*".$id;

			my $srccomment = $transstr->Comment; # note w- we are accessing comment property of source string
			
			if($srccomment =~ /\[OLD\]/){ # if legacy string - set the COMMENT flag
				$FLAG_OLD = 1;
			}
			
			my $curr_comment = $transstr->Comment;
			my $translator_comment = $transstr->TransComment;
	
			# is same ID found in previous LPU ?
			if(	exists($prevhash{$filename}{$compid})	){

				my ($prevsrc,$prevtrans) = split /$delimiter/, $prevhash{$filename}{$compid};
				
				# source same - trans different
				if(	($prevsrc eq $currsrc)	&&	($prevtrans ne $currtrans)	){

					&Write_LS_Info("DIFF",$transstr,1,$translator_comment,$filename,$compid, $prevsrc , $prevtrans,$currsrc,$currtrans,$curr_comment);

				}elsif(	$prevsrc ne $currsrc	){  #source strings different at SAME ID - means string updated

# UNDO UPDATE 1.6 - AUG 2011 - Remove AUTOTRN-REP status	
#					if(	exists($curr_lpu_src_hash{$currsrc})		){ #repeated string in curr lpu - status should be marked AUTOTRN
#						&Write_LS_Info("AUTOTRN-REP",$transstr,1,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);								
#					}else{
# UNDO UPDATE 1.6 - AUG 2011 - Remove AUTOTRN-REP status						
#						$curr_lpu_src_hash{$currsrc} = $currtrans; #add to current source hash
						# Check if string was autotranslated from other files or project glosarries
						if(	($transstr->State($pslConst->{'pslStateBookmark'}) == 1)	){ # unique UPD string
								&Write_LS_Info("UPD",$transstr,1,$translator_comment,$filename,$compid,$prevsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);
						}else{
			#					&Write_LS_Info("AUTOTRN-EXT",$transstr,1,$translator_comment,$filename,$compid,$currsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);
# No need to review AUTORN anymore, so changed ,1, to ,0,
								&Write_LS_Info("AUTOTRN-EXT",$transstr,0,$translator_comment,$filename,$compid,$prevsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);
						}
# UNDO UPDATE 1.6 - AUG 2011 - Remove AUTOTRN-REP status	
#					}
					
				}else{ # unchanged string

						if($lang =~ /$langs_fulldump/i){ # dump unchanged strings -> XLS for APAC languages oinly

							&Write_LS_Info("UNC",$transstr,1,$translator_comment,$filename,$compid,$prevsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);

						}
				}


			}else{ # ID is not present in new LPU for same file - means the strings is to be treated as new string or recovered string
				
				# Check if the string was recovered by autotranslation - if it exists in hash of source strings

				if (exists($prev_lpu_src_hash{$currsrc})){
					
					my $prevtrans = $prev_lpu_src_hash{$currsrc};
#						&Write_LS_Info("AUTOTRN",$transstr,1,$translator_comment,$filename,$compid,$currsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);
#	prev source and prev translation can only be N/A since we are in the case where the file is new (or renamed), thus the string doesn't have a prev source and a prev translation
# No need to review AUTORN anymore, so changed ,1, to ,0,
					&Write_LS_Info("AUTOTRN",$transstr,0,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);
# UNDO UPDATE 1.6 - AUG 2011 - Remove AUTOTRN-REP status
#					}elsif(	exists($curr_lpu_src_hash{$currsrc})		){ #repeated string in curr lpu - status should be marked AUTOTRN-REP
				
#						&Write_LS_Info("AUTOTRN-REP",$transstr,1,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);							
					
				}else{
# UNDO UPDATE 1.6 - AUG 2011 - Remove AUTOTRN-REP status					
#						$curr_lpu_src_hash{$currsrc} = $currtrans; #add to current source hash
				
					# Check if string was autotranslated from other files or project glosarries

					if(	($transstr->State($pslConst->{'pslStateBookmark'}) == 1)	){ # unique NEW string
							&Write_LS_Info("NEW",$transstr,1,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);
					}else{
# No need to review AUTORN anymore, so changed ,1, to ,0,
					&Write_LS_Info("AUTOTRN-EXT",$transstr,0,$translator_comment,$filename,$compid,"N/A","N/A",$currsrc,$currtrans,$curr_comment);
					}

				}
			}

		} # end for each string in this trnlist

	} # end else of filename
	$trnlist->Save;
	
}# end iteration translists	
	
# format excel
&FormatXls();

# save and quit
if($sheetctr == 1){ # if excel limit not reached - we dont need split xls names
	$ldxls =~ s%_LS_Review_${sheetctr}\.${excel_ext}%_LS_Review.${excel_ext}%i;
}
unlink $ldxls if -e $ldxls;
$wb->SaveAs("$ldxls");
$wb->Close();

$exapp->Quit;

########### Export to Bundle ##############

my $bundle = $proj->PrepareTransBundle();
my $bundlename = $ls_lpu;
$bundlename =~ s#\.lpu$##i;
$numtrnslists = $proj->TransLists->Count;
for my $this_translist(1..$numtrnslists){
	my $trnlist = $proj->TransLists($this_translist);
	$bundle->AddTransList($trnlist);
}
$bundle->License("Exported");
$proj->ExportTransBundle($bundle,$bundlename);
$proj->Close();
printf "\n   DONE: LS Review XLS and Review bundle stored at %s\n\n",dirname($ls_lpu);
$end = localtime;
print "\nProcess Time:\nStart       :$start\nEnd         :$end\n\n";
&clean_exit();

###################################################### Write to XLS Code ######################################################

sub WriteToXls{

	my @args = @_;
	
	my ($status,$filename,$id,$prevsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);
	
	
	($status,$filename,$id,$prevsrc,$prevtrans,$currsrc,$currtrans,$curr_comment) = @args[0..7];
	
	$prevsrc = &EscapeChars("$prevsrc");
	$prevtrans = &EscapeChars("$prevtrans");
	$currsrc = &EscapeChars("$currsrc");
	$currtrans = &EscapeChars("$currtrans");
	
	#my $comment = "THIS IS A LEGACY STRING\nPLEASE ENTER A COMMENT IF YOU\nCHANGE THE TRANSLATION" if( $FLAG_OLD);
	my $note_to_reviewer = "This is a legacy string marked [OLD]. Please enter a comment if you change the translation" if( $FLAG_OLD);
	my @values;
	@values = ($status,$filename,$id,$prevsrc,$prevtrans,$currsrc,$currtrans,"",$curr_comment);
	
	#print "@values\n";
	# increment global counter
	$row ++;
	if($lang =~ /$langs_fulldump/i){ 
		
		if($row == $xls_row_limit){ # limit of excel
			
			# format excel
			&FormatXls();
			
			#save the xls - create a new one after deleting any old copy
			unlink $ldxls if -e $ldxls;
			$wb->SaveAs("$ldxls");
			$wb->Close();
			#increment sheet counter
			$sheetctr++;
			
			# create new xls
			$ldxls = File::Spec->rel2abs($lpu);
			$ldxls =~ s%\.lpu$%_LS_Review_${sheetctr}.${excel_ext}%i;
			
			&WriteExcelHeader();			
			
			#reinitialize row counter to 2
			$row++;

		}
	}
	
	for my $i (1..9){
		
		$ws->Cells($row,$i)->{Value} = $values[$i-1];
		
	}
	
	#write comment to excel if legacy string
	$ws->Cells($row,10)->{Value} = $note_to_reviewer if $FLAG_OLD;
}

sub EscapeChars{

			my $text = $_[0];
			$text=~s/\n/\\n/g;
			$text=~s/\r/\\r/g;
			$text=~s/\t/\\t/g;
			
			return $text;
}

sub clean_exit
{
	 
	 $exapp->Quit;
	 $psl->Quit;
	 Win32::OLE->Uninitialize();
	 exit(0);
	 
}

###################################################### EXCEL INITIALIZE CODE######################################################
sub InitializeExcel{
		## use existing instance if Excel is already running



			eval {$exapp = Win32::OLE->GetActiveObject('Excel.Application')};

			die "Excel not installed" if $@;

			unless (defined $exapp) {
			    $exapp = Win32::OLE->new('Excel.Application', sub {$_[0]->Quit;})
				    or die "Cannot start Excel";
			}
			
			return $exapp->{Version};

}

sub WriteExcelHeader {
		$wb = $exapp->WorkBooks->Add() or die "\nCannot create $ldxls\n";
		$exapp->SetProperty('Visible',$XlsVisible);

		 $ws = $wb->WorkSheets(1);
		$ws->SetProperty('Name',"LD SHEET");
		$ws->Cells(1,1)->{Value} = "STATUS";
		$ws->Cells(1,2)->{Value} = "FILENAME";
		$ws->Cells(1,3)->{Value} = "ID";
		$ws->Cells(1,4)->{Value} = "PREV SRC";
		$ws->Cells(1,5)->{Value} = "PREV TRANS";
		$ws->Cells(1,6)->{Value} = "CURR SRC";
		$ws->Cells(1,7)->{Value} = "CURR TRANS";
		$ws->Cells(1,8)->{Value} = "NEW TRANS";
		$ws->Cells(1,9)->{Value} = "COMMENT";
		$ws->Cells(1,10)->{Value} = "NOTE TO REVIEWER";

		#define global row  counters
		$row = 1;
	}


###################################################### Format  XLS Code ######################################################

sub FormatXls{
	$ws->Columns->Autofit;
	$ws->Range("A1:J${row}")->{ColumnWidth} = 25;
	$ws->Range("A1:A${row}")->{ColumnWidth} = 10;
	$ws->Range("B1:B${row}")->{ColumnWidth} = 12;
	$ws->Range("C1:C${row}")->{ColumnWidth} = 9;
	$ws->Range("A1:J${row}")->{WrapText} = 1;
	$ws->Range("A1:J${row}")->AutoFilter();

	#make heeader bold
	$ws->Range("A1:J1")->{Font}->{Bold} = 1;
}


sub Write_LS_Info{

	#arguments
	#- LSSTATUS, transstr object , ReviewState, TranslatorComment, $filename,$compid,$prevsrc,$prevtrans,$currsrc,$currtrans,$curr_comment
	my $ls_status = $_[0];
	my $transstr = $_[1];
	my $review = $_[2];
	my $translator_comment = $_[3];
	my $filename = $_[4];
	my $compid = $_[5];
	my $prevsrc = $_[6];
	my $prevtrans = $_[7];
	my $currsrc = $_[8];
	my $currtrans = $_[9];
	my $curr_comment = $_[10];

	# if OLD string - that was marked by SW engg specifically as OLD - then we should treat it as unchanged : except if it has DIFF status
	if(	($FLAG_OLD == 1)	&&	($ls_status =~ /(NEW|AUTOTRN|UPD)/)	){
		$ls_status = "UNC"; # change LS status to UNCHANGED
		$prevsrc = $currsrc;
		$prevtrans = $currtrans;
	}
	

	# set info in the LPU - as long as status is not UNC 
	if($ls_status ne "UNC"){
		my $lpu_ls_status;
		
		# Added code for processing [MT] strings as statuses like AUTOTRN, AUTOTRN-EXT, AUTOTRN-REP have no sense for MT strings
		if ($curr_comment =~ /\[MT\]/i) {
			$lpu_ls_status = "[LS-STATUS=POSTEDITED]";
			$curr_comment =~ s/\[LS-STATUS.*\]/\[LS-STATUS=POSTEDITED\]/;
			$ls_status = "POSTEDITED";
			# Force [MT] to be reviewed so set them to ForReview. A few could be marked as validated in the case they are found as being AUTOTRN-EXT
			$review = 1;
		} else {
			$lpu_ls_status = "[LS-STATUS=${ls_status}]";
		}
		
		$translator_comment = "$lpu_ls_status"."$translator_comment"; #append translator comment to LS status
		$transstr->SetProperty('TransComment',$translator_comment);	
		$transstr->SetProperty('State',$pslConst->{'pslStateReview'},$review);
		$transstr->SetProperty('State',$pslConst->{'pslStateTranslated'},1);
		$curr_comment .= $transstr->TransComment; #append the translators comment to existing comment
	}
	
	
	#XLS is to be written only for APAC LANGS with UNC status : or other langs with all other status
	if($lang =~ /$langs_fulldump/i){
			&WriteToXls($ls_status,$filename,$compid,$prevsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);
	}elsif($ls_status ne "UNC"){ # lang is NON APAC  -so we can pipe out all status except UNC
			&WriteToXls($ls_status,$filename,$compid,$prevsrc,$prevtrans,$currsrc,$currtrans,$curr_comment);
	}

}

###################################################### IS PASSOLO INSTALLED ######################################################

sub IsPassoloInstalled {
	my ($PassVersion) = @_;
	my $RegKeyCurVer = $Registry->{"Classes/$PassVersion/CLSID"};
	if (defined $RegKeyCurVer) {
		return 1;
	} else {
		return 0;
	}
}

#################################################################################################################################

###				# THE NEAR FUTURE AS I SEE IT : instead of checking bookmark - we should check if "M:AutoTranslated" is set to "Yes"

###				--- Logic for new autotranslate ----
###				
###				-NOTE:  - PslStateAutotranslated is 'readonly' property is Passolo 6 (and is only in Passolo 6)
###					- The property gets automatically 'reset' to FALSE when string will be se to translated
###				
###				hence we need to do the following
###				
###				: For each string during writing backups (to cover strings that are autotranslated using passolo inbuilt autotranslate feature)
###					:check if PslStateAutoTranslated = True
###					:If yes - > Property("M:Autotranslated") = Yes
###				
###				: if string is UNTRANSLATED 
###					: Check if the Property("M:Autotranslated") = Yes - > and Set it to "No" (this is needed for subsequent updates to make sure that UPDATED source strings which had this custom prop set in previous update are reset (since now there is no autotranslation for those strings)
###				
###				Modify the MACROS for recovering strings in this way:
###				
###				: Whenever AutoTranslateTsv or TsvManager.bas are run they
###					: Set String to translated and also Property("M:Autotranslated") = Yes

###				: Now in thie case we can just check that if a string has this property set to "yes" it is autotransalted else it is unique NEW or UPD as case may be :)


__END__
:endofperl

