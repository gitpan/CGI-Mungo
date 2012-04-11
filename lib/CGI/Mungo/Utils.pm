package CGI::Mungo::Utils;
=pod

=head1 NAME

CGI::Mungo::Utils - Helper methods

=head1 SYNOPSIS

=head1 DESCRIPTION

Various methods used by several of the Mungo classes.

=head1 METHODS

=cut
use strict;
use warnings;
use File::Basename;
use Carp;
#########################################################

=pod

=head2 getThisUrl()

	my $url = $m->getThisUrl();

Returns the full URL for the current script.

=cut

###########################################################
sub getThisUrl{
	my $self = shift;
	my $url = "";
	if(exists($ENV{'HTTPS'})){	#are we running on ssl?
		$url .= "https://";
	}       
	else{	#on plain
		$url .= "http://";
	}
	$url .= $ENV{'HTTP_HOST'};
	if(exists($ENV{'SERVER_PORT'})){	#will ahve to assume port 80 if we don't have this
		if(exists($ENV{'HTTPS'}) && $ENV{'SERVER_PORT'} != 443){        #add non default ssl port
			$url .= ":" . $ENV{'SERVER_PORT'};
		}       
		elsif(!exists($ENV{'HTTPS'}) && $ENV{'SERVER_PORT'} != 80){     #add non default plain port     
			$url .= ":" . $ENV{'SERVER_PORT'};
		}
	}
	$url .= $ENV{'REQUEST_URI'};
	return $url;
}
##########################################################
sub _getScriptName{	#returns the basename of the running script
	my $scriptName = $ENV{'SCRIPT_NAME'};
	if($scriptName){
		return basename($scriptName);
	}
	else {
		confess("Cant find scriptname, are you running a CGI");
	}
	return undef;
}

#############################################################################################################

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2012 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

###########################################################
return 1;
