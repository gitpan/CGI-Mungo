package CGI::Mungo::Base;
use strict;
use warnings;
###########################################################
sub new{
	my $class = shift;
	my $self = {
		'_error' => undef
	};
	bless $self, $class;
	return $self;
}
#########################################################
sub setError{
	my($self, $error) = @_;
	$self->{'_error'} = $error;
	return 1;
}
#########################################################
sub getError{
	my $self = shift;
	return $self->{'_error'};
}
##########################################################
return 1;
