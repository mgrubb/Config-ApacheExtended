package Config::ApacheExtended;

use Parse::RecDescent;
use Config::ApacheExtended::ParseTree;
use IO::File;
use Scalar::Util qw(weaken);
use Text::Balanced qw(extract_variable);
use File::Spec qw(rel2abs);

use strict;
BEGIN {
	use vars qw ($VERSION $DEBUG);
	$VERSION	= sprintf("%d.%02d", q$Revision$ =~ /(\d+)/g);
	$DEBUG		= 0;
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
$::RD_HINT = 1 if $DEBUG;
$::RD_TRACE = 1 if $DEBUG;

sub new
{
	my $class = shift;
	my %default_parameters = (
		expand_vars		=> 0,
		relative_path	=> undef,
		honor_include	=> 1,
		inherit_vals	=> 0,
		ignore_case		=> 1,
		die_on_nokey	=> 0,
		die_on_noblock	=> 1,
		valid_keys		=> [],
		valid_blocks	=> [],
		source			=> undef,
		_prev_blocks	=> [],
		_data			=> {},
	);

	my $self = bless ({%default_parameters,@_}, ref ($class) || $class);
	$self->_normalize_source();
	return $self;
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
		require File::Basename;
		$self->{_filename} = $source;
		my $content = IO::File->new("< $source");
		$self->{_contents} = join('', <$content>);
		$content->close();
		$self->{relative_path} ||= File::Basename::dirname($source);
	}
	$self->{source} = undef;
	$self->{relative_path} ||= rel2abs($0);
	
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
	
	my $parser = Parse::RecDescent->new(join('', <DATA>));
#	my $result = $self->{_parser}->grammar($self->{_contents},1,$self);
	my $parse_tree = Config::ApacheExtended::ParseTree->new(ignore_case => $self->{ignore_case}, honor_include => $self->{honor_include});
	my $result = $parser->grammar($self->{_contents},1,$parse_tree);
	if ( defined($result) )
	{
#		print "Parse Successful!\n";
	}
	else
	{
#		print "Parse Unsuccessful!\n";
		return undef;
	}
	$self->{_data} = $parse_tree->getData();
	$self->_substituteValues() if $self->{expand_vars};
	return $parse_tree;
#	$self->_transliterateBlocks($result->getData);
}

sub _substituteValues
{
	my $self = shift;
	my $data = $self->{_data};

	foreach my $key ($self->get())
	{
		my @vals = $self->get($key); #@{$data->{$key}};
		for ( my $i = 0; $i < @vals; $i++ )
		{
			my $newval = $vals[$i];
			while( my $varspec = extract_variable($newval, qr/(?:.*?)(?=[\$\@])/) )
			{
				my($type,$var,$idx) = $varspec =~ m/^([\$\@])(.*?)(?:\[(\d+)\])?$/;
				$idx ||= 0;
				my $pattern;
				($pattern = $varspec) =~ s/([^\w\s])/\\$1/g;
				$var = $self->{ignore_case} ? lc $var : $var;
				my @lval = $self->get($var);
				if ( !@lval )
				{
					warn "No Value for $varspec found\n";
					last;
				}

				if ( $type eq '$' )
				{
					$data->{$key}->[$i] =~ s/$pattern/$lval[$idx]/g;
				}
				elsif( $type eq '@' )
				{
					$data->{$key}->[$i] =~ s/$pattern/join($", @lval)/eg;
				}
			}
		}
	}
}

sub get
{
	my $self = shift;
	my $key = shift;
	my $data = $self->{_data};
	return unless defined wantarray;

	unless(defined($key))
	{
#		return map { $_ if ref($data->{$_}) ne 'HASH' } keys(%$data);
		return grep { ref($data->{$_}) ne 'HASH' } keys(%$data);
	}

	$key = lc $key if $self->{ignore_case};
	return undef if ref($data->{$key}) eq 'HASH';

	if ( exists($data->{$key}) )
	{
		if( scalar(@{$data->{$key}}) == 1 ) 
		{
			return $data->{$key}->[0];
		}
		else
		{
			return wantarray ? @{$data->{$key}} : \@{$data->{$key}};
		}
	}
	elsif ( $self->{inherit_vals} && exists($self->{_parent}) )
	{
		return wantarray ? ($self->{_parent}->get($key)) : $self->{_parent}->get($key);
	}
	else
	{
		return wantarray ? () : undef;
	}
}

sub block
{
	my $self = shift;
	my ($type,$key) = @_;
	my $data = $self->{_data};

	unless (defined($type))
	{
		return grep { ref($data->{$_}) eq 'HASH' } keys(%$data);
	}

	$type = lc $type;
	return undef unless ref($data->{$type}) eq 'HASH';

	unless ( defined($key) )
	{
		return map { [$type, $_]  } keys(%{$data->{$type}});
	}

	$key = lc $key;
	return undef if !exists($data->{$type}->{$key});
	return $self->_createBlock( $data->{$type}->{$key} );
}

sub as_hash
{
	my $self = shift;
	return \%{$self->{_data}};
}

sub _createBlock
{
	my $self = shift;
	my $data = shift;
	my $block = bless { %{$self} }, ref($self);
	$block->{_data} = {%$data};
	$block->{_parent} = $self->{inherit_vals} ? $self : weaken($self);
	$block->_substituteValues() if $self->{expand_vars};
	return $block;
}

1;

__DATA__

{ my $data; }

grammar: { $data = $arg[0]; } <reject> | statement(s?) eof { $data->end() }

statement: <skip: qr/[ \t]*/> (include|multiline_directive|hereto_directive|block_start|block_end|directive|skipline)

multiline_directive:
	/(.*?[\\][ \t]*\n)+.*/ eol
		{ $item[-2] =~ s/[\\][ \t]*\n//g; $return =
			$thisparser->directive($item[-2] . "\n",1, @arg) }

hereto_directive:
	key '<<' hereto_mark eol <skip: ''> hereto_line[$item[3]] eol
		{ $data->newDirective($item[1], [$item[6]]) }

directive:	key val(s) <commit> eol { $data->newDirective($item[1], $item[2]) }
			| key eol { $data->newDirective($item[1], [1]) }

block_start:
	'<' key block_val(s?) '>' eol 
		{ $data->beginBlock($item[2], $item[3]) }

block_end: '</' key '>' eol
		{ $data->endBlock($item[2]) }

include: /\b(?i)include\b/ val eol { if ( $data->include ) { $text = $data->_loadFile($item[2]) . $text} else { $data->newDirective($item[1],$item[1])} }

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

