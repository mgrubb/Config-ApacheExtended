package Config::ApacheExtended::ParseTree;
use strict;

BEGIN
{
	use vars qw($VERSION);
	$VERSION = q{$Revision$};
}

sub new
{
	my $class = shift;
	my $name = shift;
	my $self = {
		_name				=> $name || "",
		_data				=> {},
		_current_block		=> undef,
		_previous_blocks	=> [],
	};
	$self->{_current_block} = $self->{_data};
	return bless($self, ref($class) || $class);
}

sub newDirective
{
	my $self = shift;
	my($dir,$vals) = @_;
	$self->{_current_block}->{$dir} = $vals;
}

sub beginBlock
{
	my $self = shift;
	my($block,$vals) = @_;
	my $ident = $block;
	if ( defined($vals) && @$vals )
	{
		$ident = shift @$vals;
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
}

sub end
{
	$_[0]->{_current_block} = undef;
	return $_[0];
}

sub getData
{
	return $_[0]->{_data};
}

1;

