#!/usr/bin/env perl

use 5.010.001;
use Function::Parameters;
use Types::Standard qw(Str Int ArrayRef RegexpRef);
use JSON -convert_blessed_universally;
use Image::ExifTool qw(:Public);
use Carp qw(croak carp);

my $configfile = "config.json";
my $config;    # configs read from json file.

sub main
{
    my $heicref = &findHeicFiles();
    &removeJpgWithSameFileNameAndDateTime($heicref);
}

fun findHeicFiles ()
{
    my @heicfiles;
    my $options = '-type f -iname "*.heic"';
    if ( -e $configfile ) {
        $config = &readConfigFile($configfile);
        my @src = @{ $config->{'folder'} };
        @heicfiles = `find @src $options`;
    } else {
        @heicfiles = `find . $options`;
    }
    chomp @heicfiles;

    return \@heicfiles;
}

fun removeJpgWithSameFileNameAndDateTime ( ArrayRef $filesref )
{
    for my $heic (@$filesref) {
        my $jpg = &getJpgFileName($heic);
        say "$heic =~ $jpg" if $config->{'debug'};
        if (    -e $jpg
            and &getDateTime($heic)
            and &getDateTime($heic) == &getDateTime($jpg) )
        {
            say $jpg;
            unlink $jpg if $config->{"delete"};
        }
    }
}

fun getJpgFileName (Str $heic)
{
    $jpg = $heic;
    $jpg =~ s/HEIC/JPG/;
    return $jpg;
}

fun getExifInfo ( $file )
{
    my $exifTool = new Image::ExifTool;
    $exifTool->Options( Unknown => 1 );
    return $exifTool->ImageInfo($file);
}

fun getDateTime ( $file )
{
    my $info = &getExifInfo($file);
    if ( $info->{'MIMEType'} =~ /image/i and $info->{'DateTimeOriginal'} ) {
        return $info->{'DateTimeOriginal'};
    }
}

fun getFileContent (Str $file)
{
    open my $fh, '<', $file or croak "$file $!";
    my @tmp = <$fh>;
    close($fh);
    return @tmp;
}

fun readConfigFile ( $filename )
{
    my @data        = &getFileContent($filename);
    my $onelinedata = join "\n", @data;
    return from_json($onelinedata);
}

&main();
