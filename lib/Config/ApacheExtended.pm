package Config::ApacheExtended;

use Parse::RecDescent;
use IO::File;

use strict;
BEGIN {
	use vars qw ($VERSION);
	$VERSION     = 0.5;
}


########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

Config::ApacheExtended - 

=head1 SYNOPSIS

  use Config::ApacheExtended
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

	A. U. Thor
	a.u.thor@a.galaxy.far.far.away
	http://a.galaxy.far.far.away/modules

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comments  : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   : 

=cut

################################################## subroutine header end ##
my $parser;
$::RD_HINT = 1;
$::RD_TRACE = 1;
{
	my %default_parameters = (
		expand_vars		=> 0,
		honor_include	=> 1,
		inherit_vals	=> 0,
		ignore_case		=> 1,
		die_on_nokey	=> 0,
		die_on_noblock	=> 1,
		valid_keys		=> [],
		valid_blocks	=> [],
		include_keys	=> [qr/include/i],
		source			=> undef,
		_prev_blocks	=> [],
		_data			=> {},
	);

	sub new
	{
		my $class = shift;

		my $self = bless ({%default_parameters,@_}, ref ($class) || $class);
		$self->{_current_block} = ["", $self->{_data}];
		$self->_normalize_source();
#		$self->{_parser} = Parse::RecDescent->new(join('', <DATA>));
		$parser = Parse::RecDescent->new(join('', <DATA>));
		return $self;
	}

}

sub _normalize_source
{
	my $self = shift;
	my $source = shift || $self->{source};
	return unless defined $source;

	if ( (ref($source) eq 'GLOB') || (ref($source) eq 'IO::File') )
	{
		$self->{_filename} = undef;
		$self->{_contents} = join('', <$source>);
	}
	elsif ( ref($source) eq 'SCALAR' )
	{
		$self->{_filename} = undef;
		$self->{_contents} = \$source;
	}
	else
	{
		$self->{_filename} = $source;
		my $content = IO::File->new("< $source");
		$self->{_contents} = join('', <$content>);
		$content->close();
	}
	$self->{source} = undef;
	
}

sub parse
{
	my $self = shift;
	my $source = shift;
	if ( defined($source) && (ref($source) eq 'SCALAR' ) )
	{
		$self->{_contents} = \$source;
	}
	elsif( defined($source) )
	{
		$self->normalize_source($source);
	}
	
#	my $result = $self->{_parser}->grammar($self->{_contents},1,$self);
	my $result = $parser->grammar($self->{_contents},1,$self);
	if ( defined($result) )
	{
		print "Parse Successful!\n";
		return 1;
	}
	else
	{
		print "Parse Unsuccessful!\n";
		return undef;
	}
}

#sub _getCurrentBlock
#{
#	return defined($_[0]->{_current_block}->[1])
#			? [$_[0]->{_current_block}->[0..1]]
#			: ["",$_[0]];
#}

#sub _setCurrentBlock
#{
#	my $self = shift;
#	my($blockname,$block) = @_;
#}

sub _newDirective
{
	my $self = shift;
	my($dir,$vals) = @_;
	$self->{_current_block}->[1]->{_data}->{$dir} = $vals;
	return 1;
}

sub _beginBlock
{
	my $self = shift;
	my($block,$vals) = @_;
	my $blname = defined($vals) ? $vals->[0] : $block;
	print STDERR "BLOCK: $blname, $vals\n";
	my $new_block = {};
	my($current_block_name,$current_block) = @{$self->{_current_block}};

	$current_block->{_data}->{$block}->{$blname} = $new_block;
	push(@{$self->{_prev_blocks}}, $self->{_current_block});
	$self->{_current_block} = [ $block, $new_block ];

	return 1;
}

sub _endBlock
{
	my $self = shift;
	my $current_block = $self->{_current_block};

	if ( $current_block->[0] eq "" )
	{
		warn "Unexpected End-of-Block found";
		return undef;
	}
	elsif ( $_[0] ne $current_block->[0] )
	{
		warn "Expected " . $current_block->[0] . "End-of-Block, but found $_[0] instead.";
		return undef;
	}

	if ( @{$self->{_prev_blocks}} )
	{
		$self->{_current_block} = pop @{$self->{_prev_blocks}};
		return 1;
	}
	else
	{
		warn "Unexpected End-of-Block found";
		return undef;
	}
}

sub end
{
	my $self = shift;
	if ( $self->{_current_block}->[0] ne "" )
	{
		warn "Expected End-of-Block for: " . $self->{_current_block}->[0];
		return undef;
	}
	else
	{
		return 1;
	}
}

1;

__DATA__

{ my $data; }

grammar: { $data = $arg[0]; } <reject> | statement(s?) eof { $data->end() }

statement: <skip: qr/[ \t]*/> (multiline_directive|hereto_directive|block_start|block_end|directive|skipline)

multiline_directive:
	/(.*?[\\][ \t]*\n)+.*/ eol
		{ $item[-2] =~ s/[\\][ \t]*\n//g; $return =
			$thisparser->directive($item[-2] . "\n",1, @arg) }

hereto_directive:
	key '<<' hereto_mark eol <skip: ''> hereto_line[$item[3]] eol
		{ $data->_newDirective($item[1], [$item[6]]) }

directive:	key val(s) <commit> eol { $data->_newDirective($item[1], $item[2]) }
			| key eol { $data->_newDirective($item[1], [1]) }

block_start:
	'<' key block_val(s?) '>' eol 
		{ $data->_beginBlock($item[2], $item[3]) }

block_end: '</' key '>' eol
		{ $data->_endBlock($item[2]) }

skipline: comment | eol { 0 }


hereto_mark: val
hereto_line: /(.*?)$arg[0]/sm { $1 }

comment: '#' /.*/ eol { 0 }
key: /\w+/
val: quote | no_space
block_val: quote | /[^\s>]+/
quote: <perl_quotelike> { $item[1][2] }
no_space: /\S+/
eol: /\n/
eof: /\z/

