package Config::ApacheExtended::ParseTree;
use strict;
use File::Spec::Functions qw(rel2abs);

BEGIN
{
	use vars qw($VERSION);
	$VERSION = q{$Revision$};
}

sub new
{
	my $class = shift;
#	my $name = shift;
	my %args = @_;
	my $self = {
		_name				=> "",
		_data				=> {},
		_ignore_case		=> 1,
		_current_block		=> undef,
		_previous_blocks	=> [],
		map { ("_$_" => $args{$_}) } keys %args,
	};
	$self->{_current_block} = $self->{_data};
	return bless($self, ref($class) || $class);
}

sub newDirective
{
	my $self = shift;
	my($dir,$vals) = @_;
	$dir = lc $dir if $self->{_ignore_case};
	$self->{_current_block}->{$dir} = $vals;
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

sub include
{
	return $_[0]->{_honor_include};
}

sub _loadInclude
{
	my $self = shift;
	my $file = shift;
	my $path;
	if ( $file =~ m|^/| )
	{
		$path = $file;
	}
	else
	{
		$path = rel2abs($file,$self->{_relative_path});
	}
	my $contents;	

	if ( -r $path )
	{
		open(FILE, "<$path") or warn "Could not open $path: $!\n";
		local $/ = undef;
		$contents = <FILE>;
		close(FILE);
	}
	else
	{
		warn "Could not read $path!\n";
	}

	return $contents;
}
	
1;

