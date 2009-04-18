#main framework object
package CGI::Mungo;

=pod

=head1 NAME

CGI::Mungo - Very simple CGI web framework

=head1 SYNOPSIS

	use CGI::Mungo;
	my $options = {
		'responsePlugin' => 'Some::Class'
	};
	my $m = CGI::Mungo->new($options);
	my $actions = {
		"default" => sub{},	#do nothing
		"list" => \&someSub(),	#use a named sub
		"add" => sub{my $var = 1;}	#use an anonymous sub
	};
	$m->setActions($actions);
	$m->run();	#do this thing!

=head1 DESCRIPTION

All action subs are passed a L<CGI::Mungo> object as the only parameter, from this you should be able to reach
everything you need.

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use base qw(CGI::Mungo::Base CGI::Mungo::Utils CGI::Mungo::Log);
use CGI::Mungo::Response;
use CGI::Mungo::Session;	#for session management
use CGI::Mungo::Request;
use Carp;
our $VERSION = "1.3";
#########################################################

=pod

=item new()

	my $options = {
		'responsePlugin' => 'Some::Class',
		'checkReferer' => 0
	};
	my $m = CGI::Mungo->new($options);

Constructor, requires a hash references to be passed as the only argument. This hash reference contains any general
options for the framework.

=cut

#########################################################
sub new{
	my($class, $options) = @_;
	if($options->{'responsePlugin'}){	#this option is mandatory
		my $self = $class->SUPER::new();
		$self->{'_session'} = CGI::Mungo::Session->new();	
		$self->{'_request'} = CGI::Mungo::Request->new();
		$self->{'_actions'} = {};
		$self->{'_options'} = $options;
		$self->{'_response'} = CGI::Mungo::Response->new($self, $self->_getOption('responsePlugin'));	
		$self->_init();	#perform initial setup
		return $self;
	}
	else{
		confess("No reponse plugin option provided");
	}
	return undef;
}
#########################################################

=pod

=item getResponse()

	my $response = $m->getResponse();

Returns an instance of the response plugin object, previously defined in the constructor options.
See L<CGI::Mungo::Response> for more details.

=cut

###########################################################
sub getResponse{
	my $self = shift;
	return $self->{'_response'};
}
#########################################################

=pod

=item getSession()

	my $session = $m->getSession();

Returns an instance of the <CGI::Mungo::Session> object.

=cut

###########################################################
sub getSession{
	my $self = shift;
	return $self->{'_session'};
}
#########################################################

=pod

=item getRequest()

	my $request = $m->getRequest();

Returns an instance of the L<CGI::Mungo::Request> object.

=cut

###########################################################
sub getRequest{
	my $self = shift;
	return $self->{'_request'};
}
#########################################################

=pod

=item setActions()

	my %actions = (
		'default' => \&showMenu().
		'list' => \%showList() 
	)
	$m->setActions(\%actions);

Sets the actions of the web application using a hash reference. The names of the keys in the hash
reference will match the value of the given "action" form field from the current request. Hash reference values
can be references to subs or annoymous subs.

=cut

###########################################################
sub setActions{
	my($self, $actions) = @_;
	$self->{'_actions'} = $actions;
	return 1;
}
#########################################################

=pod

=item getAction()

	my $action = $m->getAction();

Returns the curent action that the web application is performing. This is the current value of the "action"
request form field.

=cut

###########################################################
sub getAction{
	my $self = shift;
	my $request = $self->getRequest();
	my $params = $request->getParameters();
	my $action = "default";	
	if(defined($params->{'action'})){
		$action = $params->{'action'};
	}
	$self->log("Using action: '$action'");
	return $action;	
}
#########################################################

=pod

=item run()

	$m->run();

This methood is required for the web application to deal with the current request.
It should be called after any setup is done.

=cut

###########################################################
sub run{	#run the code for the given action
	my $self = shift;
	my $response = $self->getResponse();
	my $action = $self->getAction();	
	my $actions = $self->_getActions();
	my $actionSub = $actions->{$action};
	if($actionSub){	#got some code to execute
		eval{
			&$actionSub($self);
		};
		if($@){	#problem with sub
			$response->setError("<pre>" . $@ . "</pre>");
		}
	}
	else{	#no code to execute
		$response->setError("No action sub found for: $action");
	}
	$response->display();	#display the output to the browser
	return 1;
}
#########################################################

=pod

=item getThisUrl()

	my $url = $m->getThisUrl();

Returns the full URL for the current script.

=cut

###########################################################
sub getThisUrl{
	my $self = shift;
	my $url = $ENV{'SCRIPT_URI'};
	return $url;
}
###########################################################
# Private methods
###########################################################
sub _init{	#things to do when this object is created
	my $self = shift;
	if(!defined($self->_getOption('checkReferer')) || $self->_getOption('checkReferer')){	#check the referer by default
		$self->_checkReferer();	#check this first
	}
	my $response = $self->getResponse();
	my $session = $self->getSession();
	my $existingSession = 0;
	if($session->read()){	#check for an existing session
		if($session->validate()){
			$existingSession = 1;
			$self->log("we have an existing session");
		}
	}
	if($session->getError()){	#problem read existing session
		$response->setError($session->getError());
	}
	elsif(!$existingSession){	#start a new session
		$self->log("creating new session");
		if(!$session->create({}, $response)){
			$response->setError($session->getError());
		}
	}
	return 1;
}
###########################################################
sub _checkReferer{	#simple referer check for very basic security
	my $self = shift;
	my $result = 0;
	my $host = $ENV{'HTTP_HOST'};
	if($ENV{'HTTP_REFERER'} && $ENV{'HTTP_REFERER'} =~ m/^(http|https):\/\/$host/){	#simple check here
		$result = 1;
	}
	else{
		my $response = $self->getResponse();
		$response->setError("Details where not sent from the correct web page");
	}
	return $result;
}
##########################################################
sub _getActions{
	my $self = shift;
	return $self->{'_actions'};
}
##########################################################
sub _getOption{
	my($self, $key) = @_;
	return $self->{'_options'}->{$key};
}
###########################################################

=pod

=back

=head1 Notes

To change the session prefix characters use the following code at the top of your script:

	$CGI::Mungo::Session::prefix = "ABC";

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2009 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

###########################################################
return 1;
