#response object
package CGI::Mungo::Response::TemplateToolkit;

=pod

=head1 NAME

Response TemplateToolkit - View plugin using template toolkit

=head1 SYNOPSIS

	my $response = $mungo->getResponse();
	$response->setTemplateVar("hello", $something);

=head1 DESCRIPTION

This view plugin allows you to read a template file and replace placholders with scalar variables.

With this class you can specify empty Mungo actions to just display a static page.

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use Template;
use base qw(CGI::Mungo::Response::Base CGI::Mungo::Log);
our $templateLoc = "../root/templates";	#where the templates are stored
#########################################################
sub new{
	my($class, $mungo) = @_;
	my $self = $class->SUPER::new($mungo);
	$self->{'_template'} = undef;	
	$self->{'_templateVars'} = {};
	bless $self, $class;
	$self->setTemplateVar("self", $ENV{'SCRIPT_NAME'});	#include this var by default
	return $self;
}
#########################################################

=item setTemplate($template)

	$response->setTemplate("login");

Manually set the template to display.

An file extension of '.html' will be automatically appended to this name.

The template will be fetched from the template directory, See the L<Notes>
section for more details.

=cut

#########################################################
sub setTemplate{
	my($self, $template) = @_;
	$self->{'_template'} = $template;
	return 1;
}
#########################################################
sub getTemplate{
	my $self = shift;
	return $self->{'_template'};
}
#########################################################

=pod

=item display()

	$response->display();

This method is called automatically at the end of an action.

A template is automatically chosen. An example demonstrates how this is done.

URL used: /foo/bar/app.cgi?action=login
Template chosen: app-login.html

=cut

#########################################################
sub display{	#this sub will display the page headers if needed
	my $self = shift;
	my $output;
	if(!$self->getTemplate()){	#if no template has been set in the action sub then we set a default
		my $tName = $self->_getTemplateNameForAction();
		$self->setTemplate($tName);	#set the template automatically
	}
	if(!$self->getError() && !$self->header("Location") && !$self->getTemplate()){	#we must have a template set if we dont have an error or a redirect
		$self->setError("No template defined");
	}
	if($self->_getDisplayedHeader()){	#just display more content
		$output = $self->_getContent();	#get the contents of the template
	}
	else{	#first output so display any headers
		if(!$self->header("Content-type")){	#set default content type
			$self->header("Content-type" => "text/html");
		}
		if(!$self->header("Location")){	#if we dont have a redirect
			my $content = $self->_getContent();	#get the contents of the template
			$self->content($content);
		}
		$output = $self->as_string();
		$output =~ s/^200 OK\n//i;	#remove code and message as cgi does not have control over these
	}
	print $output;
	$self->_setDisplayedHeader();	#we wont display the header again
	return 1;
}
#########################################################

=pod

=item setError($message)

	$response->setError("something has broken");

Set an error message for the response, which is accessible in the error template
as [% message %].

=cut

#########################################################
sub setError(){
	my($self, $message) = @_;
	$self->setTemplateVar("message", $message);	#so we can access the error message via smarty
	return $self->SUPER::setError($message);	#save the message for later in the instance
}
#########################################################
sub setTemplateVar{
	my($self, $name, $value) = @_;
	$self->{'_templateVars'}->{$name} = $value;
	return 1;
}
#########################################################
sub getTemplateVar{
	my($self, $name) = @_;
	return $self->{'_templateVars'}->{$name};
}
#########################################################
# private methods
########################################################
sub _getTemplateVars{
	my($self, $name) = @_;
	return $self->{'_templateVars'};
}
#########################################################
sub _getContent{
	my $self = shift;
	my $content;
	my $tt = Template->new(
		{
			INCLUDE_PATH => $self->_getTemplateLocation(),
			INTERPOLATE  => 1,
		}
	);
	if($tt){
		if(!$self->getError()){
			if(!$tt->process($self->getTemplate() . ".html", $self->_getTemplateVars(), \$content)){
				$self->setError($tt->error());
			}
		}
	}
	else{
		$self->setError($Template::ERROR);
	}
	if($self->getError()){	#_parseFile may have errored
		$self->setTemplateVar('message', $self->getError());
		$tt->process("genericerror.html", $self->_getTemplateVars(), $content);
		if(!$content){	#_parseFile may have errored again
			$self->log($self->getError());	#just log it so we have a record of this
		}
	}
	return $content;
}
###########################################################
sub _getTemplateNameForAction{
	my $self = shift;
	my $mungo = $self->getMungo();
	my $action = $mungo->getAction();
	my $script = $mungo->_getScriptName();
	$script =~ s/\.[^\.]+$//;	#remove the file extension
	$action =~ s/ /_/g;	#remove spaces in action if any
	my $name = $script . "-" . $action;
	return $name;
}
#########################################################
sub _getTemplateLocation{
	return $templateLoc;
}
##############################################################

=pod

=back

=head1 Notes

If an error occurs a template called "genericerror.html" will be used instead of the specified template.
Please make sure you have this file, there is an example of this in the "root/templates" directory of this module.

To change the template location use the following code at the top of your script:

	$CGI::Mungo::Response::SimpleTemplate::templateLoc = "../root";

=head1 Sess also

L<Template>

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2011 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

#########################################################
return 1;