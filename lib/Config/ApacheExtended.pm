package Config::ApacheExtended;

use Parse::RecDescent;
use Config::ApacheExtended::Grammar;
#use Config::ApacheExtended::ParseTree;
use IO::File;
use Scalar::Util qw(weaken);
use Text::Balanced qw(extract_variable);
use File::Spec::Functions qw(splitpath catpath abs2rel rel2abs file_name_is_absolute);
use Carp qw(croak cluck);

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

{
	my %_def_params = (
		_expand_vars	=> 0,
		_conf_root	=> undef,
		_root_directive	=> undef,
		_honor_include	=> 1,
		_inherit_vals	=> 0,
		_ignore_case	=> 1,
		_die_on_nokey	=> 0,
		_die_on_noblock	=> 0,
		_valid_keys		=> undef,
		_valid_blocks	=> undef,
		_source			=> undef,
	);

	sub _default_parameters { %_def_params; }
}
	
sub new
{
	my $cl = shift;
	my %args = @_;
	my $class = ref($cl) || $cl;

	my $self = {
		ref($cl) ? %$cl : $class->_default_parameters(),
		(map { ("_$_" => $args{$_}) } keys %args),
		_data	=> {},
	};

	bless($self,$class);		
	($self->{_source},$self->{_conf_root}) = _resolveSource($self->{_source}, $self->{_conf_root});
	return $self;
}

sub _resolveSource
{
	my $source = shift;
	my $root = shift;
	my $conf_root;

	return unless defined($source);

	if ( !file_name_is_absolute($source) )
	{
		$source = rel2abs($source, $root);
	}

	my @path_parts;
	@path_parts = splitpath($source);
	$path_parts[-1] = '';
	$conf_root = defined($root) ? $root : catpath(@path_parts);

	return ($source,$conf_root);
}

sub parse
{
	my $self = shift;
	my $source = shift;
	$self->{_current_block}		= $self->{_data};
	$self->{_previous_blocks}	= [];

	my $contents;

	if ( defined($source) && (ref($source) eq 'SCALAR' ) )
	{
		$contents = \$source;
	}
	elsif ( defined($source) && ref($source) =~ m/GLOB|IO::File/ )
	{
		$contents = join('', <$source>);
	}
	else
	{
		my $fh = IO::File->new($self->{_source}, "r") or croak "Could not open source [ " . $self->{_source} . " ] : $!\n";
		$contents = join('', <$fh>);
		$fh->close();
	}
	
#	my $parser = Parse::RecDescent->new(join('', <DATA>));
	my $parser = Config::ApacheExtended::Grammar->new();

	my $result = $parser->grammar($contents,1,$self);

	unless ( defined($result) )
	{
		return undef;
	}

	delete $self->{_current_block};
	delete $self->{_previous_blocks};

	$self->_substituteValues() if $self->{_expand_vars};
	return scalar(keys(%{$self->{_data}}));
}

sub include
{
	return $_[0]->{_honor_include};
}

sub _loadFile
{
	my $self = shift;
	my $file = shift;
	my $contents = "";
	$file = (_resolveSource($file,$self->{_conf_root}))[0];
	if ( -d $file )
	{
		opendir(INCD, $file) or cluck("Error opening include directory [ $file ] : $!\n");
		my @files = map { "$file/$_" } grep { -f "$file/$_" } readdir(INCD);
		closedir(INCD);
		$contents .= $self->_loadFile($_) for @files;
	}
	elsif ( -r $file )
	{
		my $fh = IO::File->new($file, "r");
		unless ( $fh )
		{
			cluck("Could not open [ $file ] for reading: $!\n");
			return '';
		}
		else
		{
			local $/ = undef;
			$contents = <$fh>;
		}
	}
	else
	{
		cluck("Could not find file [ $file ]\n");
		return '';
	}

#	open(TMP, '>/tmp/contents.txt');
#	print TMP $contents;
#	close(TMP);
	return $contents;
}

sub newDirective
{
	my $self = shift;
	my($dir,$vals) = @_;
	$dir = lc $dir if $self->{_ignore_case};
	$self->{_current_block}->{$dir} = $vals;
	if ( defined($self->{_root_directive}) && $self->{_root_directive} eq $dir )
	{
		$self->{_root_directive} = $vals->[0];
	}
}

sub beginBlock
{
	my $self = shift;
	my($block,$vals) = @_;
	$block = lc $block if $self->{_ignore_case};
	my $ident = $block;
	if ( defined($vals) && @$vals )
	{
		$ident = shift @$vals;
		$ident = lc $ident if $self->{_ignore_case};
	}
	my $new_block = {};
	$self->{_current_block}->{$block}->{$ident} = $new_block;
	push(@{$self->{_previous_blocks}}, $self->{_current_block});
	$self->{_current_block} = $new_block;
	return 1;
}

sub endBlock
{
	my $self = shift;
	if ( @{$self->{_previous_blocks}} )
	{
		$self->{_current_block} = pop @{$self->{_previous_blocks}};
	}

	return 1;
}

sub end
{
	$_[0]->{_current_block} = undef;
	return 1;
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
				$var = $self->{_ignore_case} ? lc $var : $var;
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

	$key = lc $key if $self->{_ignore_case};
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
	elsif ( $self->{_inherit_vals} && exists($self->{_parent}) )
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
	$block->{_parent} = $self->{_inherit_vals} ? $self : weaken($self);
	$block->_substituteValues() if $self->{_expand_vars};
	return $block;
}

1;
