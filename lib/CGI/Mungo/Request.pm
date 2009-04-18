#request object
package CGI::Mungo::Request;

=pod

=head1 NAME

CGI::Mungo::Request - Form request class

=head1 SYNOPSIS

=head1 DESCRIPTION

All action subs are passed a L<CGI::Mungo> object as the only parameter, from this you should be able to reach
everything you need.

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use CGI;
use Carp;
#########################################################

=pod

=item new()

	my $r = CGI::Mungo::Request->new();

Constructor, gets all the GET/POST information from the browser request.

=cut

##########################################
sub new{
	my $class = shift;
	my $self = {};
	$self->{'_parameters'} = {};	
	bless $self, $class;
	$self->_setParameters();
	return $self;
}
#########################################################

=pod

=item getParameters()

=cut

##########################################
sub getParameters{	#get POST or GET data
	my $self = shift;
	return $self->{'_parameters'};
}
#########################################################

=pod

=item validate()

	my $rules = {
		'age' => {
			'rule' => '^\d+$',
			'friendly' => 'Your Age'
		}
	};	#the form validation rules
	my($result, $errors) = $r->validate($rules);

Validates all the current form fields against the provided hash reference.

The hash reference contains akey for every field you are concerned about,
which is a reference to another hash containing two elements. The first is the 
actaul matching rule. The second is the friendly name for the field used
in the error message, if a problem with the field is found.

The method returns two values, first being a 0 or a 1 indicating the success of the form.
The second is a reference to a list of errors if any.

=cut

##########################################
sub validate{	#checks %form againist the hash rules
	my($self, $rules) = @_;
	my %params = %{$self->getParameters()};
	my @errors;	#fields that have a problem
	my $result = 0;
	if($rules){
		foreach my $key (keys %{$rules}){	#check each field
			if(!$params{$key} || $params{$key} !~ m/$rules->{$key}->{'rule'}/){	#found an error
				push(@errors, $rules->{$key}->{'friendly'});
			}
		}
		if($#errors == -1){	#no errors
			$result = 1;
		}
	}
	else{
		confess("No rules to validate form");
	}
	return($result, \@errors);
}
#########################################
sub _setParameters{
	my $self = shift;
	my $cgi = CGI::new();   #create a new cgi object
	foreach my $param ($cgi->param()){
      my $value = $cgi->param($param);
      $self->{'_parameters'}->{$param} = $value;  #save
   }
	return 1;
}
###########################################################

=pod

=back

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2009 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

##########################################
return 1;