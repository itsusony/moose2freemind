#! /usr/bin/perl

my $date = `date +%s`;
chomp $date;

my ($path,$output) = ($ARGV[0],$ARGV[1]);
if ( !defined $path || $path eq "" ) { 
    print "usage: perl map.pl PATH_INPUT PATH_OUTPUT\n";
    exit 1;
}
elsif ( !-d $path ) { 
    print "can't access folder\n";
    exit 1;
}

my $rst = '<map version="1.0.1"><node CREATED="' . $date . '" ID="ID_' . ( $id++ ) . '" MODIFIED="' . $date . '" TEXT="TOP">';
my $id = 1;

my @pm_attrnames = qw/with override around before after augment has sub/;

sub getpmfilename {
    my $path_input = shift;
    open my $fp, "<$path_input";
    my $info = { package => '', extends => '' };
    for (@pm_attrnames){
        $info->{$_}=[];
    }   
    my $package_cnt = 0;
    while ( my $line = <$fp> ) { 
        if ( $line =~ /^package ["']*([^"';]+)/ ) { 
            last if ($package_cnt++ > 0); 
            $info->{package} = $1; 
        }   
        elsif ( $line =~ /^extends ["']*([^"';]+)/ ) { 
            $info->{extends} = $1; 
        }   
        for (@pm_attrnames){
            if ( $line =~ /^$_[ ]+["']*([^ {='"]+)/ ) { 
                push $info->{$_}, $1; 
            }   
        }   
        last if ( $info->{package} && $info->{extensd} );
    }   
    close $fp;
    my $_filename = ""; 
    $_filename = $1 if ( $path_input =~ /\/([^\/]+)$/ );
    my $mixname = "$info->{package} ($_filename)";
    my $rtn_filename = $info->{extends} ? "$info->{extends} => $mixname" : $mixname;
    return wartarray ? ( $rtn_filename, $info ) : $rtn_filename;
}

sub scanfolder {
    my $path_input = shift;
    return [] if ( -f $path_input || !-d $path_input );
    my $cnt = `find '$path_input' -maxdepth 1`; 
    return [] if ( !$cnt );
    my @arr = split "\n", $cnt;
    my $rtn = []; 
    for (@arr) {
        next if (/\.swp$/);
        my $_path = $_; 
        my $_name = $_path;
        $_name = $1 if ( $_path =~ /\/([^\/]+)$/ );
        push @$rtn, [ $_path, $_name ];
    }   
    shift @$rtn if ( scalar @$rtn > 0 );
    return $rtn;
}

sub openfolder {
    my ( $path_input, $path_name ) = @_; 
    my $rtn = ''; 
    my $arr = scanfolder($path_input);

    if ( scalar @$arr == 0 ) { 
        my ( $fn, $info ) = &getpmfilename($path_input);
        $rtn .= '<node CREATED="' . $date . '" ID="' . ( $id++ ) . '" MODIFIED="' . $date . '" POSITION="right" TEXT="' . $fn . '" FOLDED="true">';
        for my $key (@pm_attrnames){
            for ( @{ $info->{$key} } ) { 
                $rtn .= '<node CREATED="' . $date . '" ID="' . ( $id++ ) . '" MODIFIED="' . $date . '" POSITION="right" TEXT="' . $key . ' ' . $_ . '"/>';
            }   
        }   
        $rtn .= '</node>';
    }   
    else {
        $rtn .= '<node CREATED="' . $date . '" ID="' . ( $id++ ) . '" MODIFIED="' . $date . '" POSITION="right" TEXT="' . $path_name . '"><icon BUILTIN="folder"/>';
        foreach my $obj (@$arr) {
            my $arr2 = scanfolder( $obj->[0] );
            if ( scalar @$arr2 > 0 ) {    # folder
                $rtn .= '<node CREATED="' . $date . '" ID="' . ( $id++ ) . '" MODIFIED="' . $date . '" POSITION="right" TEXT="' . $obj->[1] . '"><icon BUILTIN="folder"/>';
                foreach my $obj2 (@$arr2) {
                    $rtn .= &openfolder( $obj2->[0], $obj2->[1] );
                }   
                $rtn .= '</node>';
            }   
            else {                        # file or empty folder
                $rtn .= &openfolder( $obj->[0] );
            }   
        }   
        $rtn .= '</node>';
    }   
    return $rtn;
}

my $root_pathname = "ROOT";
$root_pathname = $1 if ( $path =~ /\/([^\/]+)$/ );

$rst .= &openfolder( $path, $root_pathname );
$rst .= '</node></map>';

open my $fp, ">$output/output.mm";
print $fp $rst;
close $fp;
