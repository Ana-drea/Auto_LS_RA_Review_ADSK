@rem = '--*-Perl-*--
@echo off
REM ###################################################################
REM 
REM    #DESCRIPTION:     Wrapper script for DiffLpuLs.bat - to perform diffs on bundles 
REM    #				     stored in folders
REM
REM    #AUTHOR:            Abhishek Deshmukh updated by antonio.renna@autodesk.com
REM 
REM    #REVISION  :        Version 1.1
REM
REM    #DATE:                Dec 10
REM 
REM    #UPDATE 1.0:	First Draft
REM
REM    # REQMTS : 	Passolo,Excel,DiffLpuLS.bat in same folder as this script or in the path
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
use File::Basename;
use Cwd;

#
#
#UPDATE 1.1 - 15th of December 2010        - Added Passolo versions parameter to cmd line (default 2011), supported, 2007, 2009 and 2011
#
#############################################################################

our($old_dir,$new_dir,$lang,$PassoloVersionInput);

$old_dir = shift;
$new_dir = shift;
$lang = shift;

if (scalar @ARGV != 0) {
	$PassoloVersionInput = shift;
} else {
	$PassoloVersionInput = "2018";
}

if( !-d $old_dir || ! -d $new_dir){

	$0 = basename($0);
	print qq[

	-------------------------------------------------------
	-------------------------------------------------------
	USAGE: $0 <old_dir> <new_dir> <lang> [<PassoloVersion>]
	-------------------------------------------------------
	-------------------------------------------------------
	where:

	<old_dir> : directory containing all LPUs of previous build

	<new_dir> : directory containing all LPUs of current build

	<lang>    : standard 3 letter language code
	
	<PassoloVersion>    : Passolo release as 2007, 2009 or 2018 (default)
	
	eg:
        $0 "c:\\temp\\lpus_build_x" "c:\\temp\\lpus_build_y" jpn 2009
	------------------------------------------------------------

	The tool diffs all LPUs found in 'old_dir' with corresponding
	LPUs found in 'new_dir'. Review bundles and XLS
	are created in 'new_dir' with naming 	convention
	<current lpuname>_LS_REVIEW.XLS(or lpu/tbulic
	as case may be)

	Note: Tool assumes that the name of the LPUs of previous
	and current build are the same (in order to perform the
	diff of correspnding LPUs). If not - please rename accord-
	-ingly before running this script

	For APAC languages - complete dump is needed in 
	review xls output hence the process will take some time. 
	Excel has a limit of 65536 lines - hence in case LPU
	contains more  than 65536 strings, multiple excel review
	sheets will be created
		
	------------------------------------------------------------
	
		];
		
		exit;

}

our %lpu_hash;
#recurse old dir
find(
	{ wanted => sub {

	
		if(/\.lpu$/i){
			my $lpupath = $File::Find::name;
			$lpupath =~ s%\\%/%g;
			my $lpuname = basename($lpupath);
			$lpu_hash{lc($lpuname)} = $lpupath;
		}
	
	} , no_chdir => 1 } , $old_dir
);


#recurse new dir to match and compare
find(

	{ wanted => sub{
	
		
		if(/(?<!_ForLSReview)\.lpu$/i){
			my $lpupath = $File::Find::name;
			$lpupath =~ s%\\%/%g;
			my $lpuname = basename($lpupath);
			
			if( exists ($lpu_hash{lc($lpuname)})	){

				my $prevlpu = $lpu_hash{lc($lpuname)} ;
				my $currlpu = $lpupath;
				
#				print qq[
#
# Doing DiffLpuLs.bat "$prevlpu" "$currlpu" $lang ...
#				
#				];
			#	print(getcwd. "\n");
				print ("\nDiffLpuLS.bat \"$prevlpu\" \"$currlpu\" $lang $PassoloVersionInput\n");
				system qq[DiffLpuLS.bat "$prevlpu" "$currlpu" $lang $PassoloVersionInput];
			
			}else{
				
				print "\n  ### WARNING ### : No corresponding LPU found in old directory to comapre with $lpupath\n";
			}
		}
	
	} , no_chdir => 1 } , $new_dir

);




__END__
:endofperl
