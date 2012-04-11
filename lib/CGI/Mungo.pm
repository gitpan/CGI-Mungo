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

=cut

use strict;
use warnings;
use base qw(CGI::Mungo::Base CGI::Mungo::Utils CGI::Mungo::Log);
use CGI::Mungo::Response;
use CGI::Mungo::Session;	#for session management
use CGI::Mungo::Request;
use Carp;
our $VERSION = "1.6";
#########################################################

=head2 new(\%options)

	my $options = {
		'responsePlugin' => 'Some::Class',
		'checkReferer' => 0,
		'sessionClass' => 'Some::Class',
		'requestClass' => 'Some::Class'
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
		$self->{'_actions'} = {};
		$self->{'_options'} = $options;
		$self->{'_response'} = CGI::Mungo::Response->new($self, $self->_getOption('responsePlugin'));	
		my $sessionClass = $class . "::Session";
		if($self->_getOption('sessionClass')){
			$sessionClass = $self->_getOption('sessionClass');
		}
		$self->{'_session'} = $sessionClass->new();	
		my $requestClass = $class . "::Request";
		if($self->_getOption('requestClass')){
			$requestClass = $self->_getOption('requestClass');
		}
		$self->{'_request'} = $requestClass->new();
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

=head2 getResponse()

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

=head2 getSession()

	my $session = $m->getSession();

Returns an instance of the L<CGI::Mungo::Session> object.

=cut

###########################################################
sub getSession{
	my $self = shift;
	return $self->{'_session'};
}
#########################################################

=pod

=head2 getRequest()

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

=head2 setActions(\%actions)

	my %actions = (
		'default' => \&showMenu().
		'list' => \%showList() 
	)
	$m->setActions(\%actions);

Sets the actions of the web application using a hash reference. The names of the keys in the hash
reference will match the value of the given "action" form field from the current request. Hash reference values
can be references to subs or annoymous subs.

An action of 'default' can be used when a visitor does not request a specific action.

=cut

###########################################################
sub setActions{
	my($self, $actions) = @_;
	$self->{'_actions'} = $actions;
	return 1;
}
#########################################################

=pod

=head2 getAction()

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

=head2 run()

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
	#don't care about errors below
	if($session->read()){	#check for an existing session
		if($session->validate()){
			$existingSession = 1;
			$self->log("Existing session: " . $session->getId());
		}
	}
	if(!$existingSession){	#start a new session
		if($session->create({}, $response)){
			$self->log("Created new session: " . $session->getId());
		}
		else{
			$response->setError($session->getError());	#now care about errors
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
	my $value = undef;
	if(defined($self->{'_options'}->{$key})){	#this config option has been set
		$value = $self->{'_options'}->{$key};
	}
	return $value;
}
###########################################################

=pod

=head1 CONFIGURATION SUMMARY

The following list gives a summary of each Mungo 
configuration options. 

=head3 responsePlugin

A scalar string consisting of the response class to use.

See L<CGI::Mungo::Response::Base> for details on how to create your own response class, or
a list of response classes provided in this package.

=head3 checkReferer

Flag to indicate if referer checking should be performed. When enabled an
error will raised when the referer is not present or does not contain the server's
hostname.

This option is enabled by default.

=head3 sessionClass

A scalar string consisting of the session class to use. Useful if you want to change the way
session are stored.

Defaults to ref($self)::Session

=head3 requestClass

A scalar string consisting of the request class to use. Useful if you want to change the way
requests are handled.

Defaults to ref($self)::Request

=head1 Notes

To change the session prefix characters use the following code at the top of your script:

	$CGI::Mungo::Session::prefix = "ABC";
	
To change the session file save path use the following code at the top of your script:

	$CGI::Mungo::Session::path = "/var/tmp";

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2012 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

###########################################################
return 1;
