BEGIN { $| = 1; print "1..34\n"; }
END {print "not ok 1\n" unless $main::loaded;}

# There's actually a few tests here of the import routine.  I don't
# really know how to quantify them though.  If we fail to compile and
# there's an error from the Exception::Class::Base class then
# something here failed.
BEGIN
{
    package FooException;

    use vars qw[$VERSION];

    use Exception::Class;
    use base qw(Exception::Class::Base);

    $VERSION = 0.01;

    1;
}

use Exception::Class ( 'YAE' => { isa => 'SubTestException' },
		       'SubTestException' => { isa => 'TestException',
					       description => 'blah blah' },
		       'TestException',
		       'FooBarException' => { isa => 'FooException' },
		     );


$Exception::Class::BASE_EXC_CLASS = 'FooException';
Exception::Class->import( 'BlahBlah' );

use strict;

$^W = 1;
$main::loaded = 1;

result( $main::loaded, "Unable to load Exception::Class module\n" );

# 2-14: Accessors
{
    eval { Exception::Class::Base->throw( error => 'err' ); };

    result( $@->isa('Exception::Class::Base'),
	    "\$\@ is not an Exception::Class::Base\n" );

    result( $@->error eq 'err',
	    "Exception's error message should be 'err' but it's '", $@->error, "'\n" );

    result( $@->message eq 'err',
	    "Exception's message should be 'err' but it's '", $@->message, "'\n" );

    result( $@->description eq 'Generic exception',
	    "Description should be 'Generic exception' but it's '", $@->description, "'\n" );

    result( $@->package eq 'main',
	    "Package should be 'main' but it's '", $@->package, "'\n" );

    result( $@->file eq 't/basic.t',
	    "Package should be 't/basic.t' but it's '", $@->file, "'\n" );

    result( $@->line == 42,
	    "Line should be '42' but it's '", $@->line, "'\n" );

    result( $@->pid == $$,
	    "PID should be '$$' but it's '", $@->pid, "'\n" );

    result( $@->uid == $<,
	    "UID should be '$<' but it's '", $@->uid, "'\n" );

    result( $@->euid == $>,
	    "EUID should be '$>' but it's '", $@->euid, "'\n" );

    result( $@->gid == $(,
	    "GID should be '$(' but it's '", $@->gid, "'\n" );

    result( $@->egid == $),
	    "EGID should be '$)' but it's '", $@->egid, "'\n" );

    result( defined $@->trace,
	    "Exception object does not have a stacktrace but it should\n" );
}

# 15-23 : Test subclass creation
{
    eval { TestException->throw( error => 'err' ); };

    result( $@->isa( 'TestException' ),
	    "TestException was thrown in class ", ref $@, "\n" );

    result( $@->description eq 'Generic exception',
	    "Description should be 'Generic exception' but it's '", $@->description, "'\n" );

    eval { SubTestException->throw( error => 'err' ); };

    result( $@->isa( 'SubTestException' ),
	    "SubTestException was thrown in class ", ref $@, "\n" );

    result( $@->isa( 'TestException' ),
	    "SubTestException should be a subclass of TestException (triggers ->isa bug.  See README.)\n" );

    result( $@->isa( 'Exception::Class::Base' ),
	    "SubTestException should be a subclass of Exception::Class::Base (triggers ->isa bug.  See README.)\n" );

    result( $@->description eq 'blah blah',
	    "Description should be 'blah blah' but it's '", $@->description, "'\n" );

    eval { YAE->throw( error => 'err' ); };

    result( $@->isa( 'SubTestException' ),
	    "YAE should be a subclass of SubTestException (triggers ->isa bug.  See README.)\n" );

    eval { BlahBlah->throw( error => 'yadda yadda' ); };
    result( $@->isa('FooException'),
	    "BlahBlah should be a subclass of FooException\n" );
    result( $@->isa('Exception::Class::Base'),
	    "The BlahBlah class should be a subclass of Exception::Class::Base\n" );
}


# 24-29 : Trace related tests
{
    result( ! Exception::Class::Base->Trace,
	    "Exception::Class::Base class 'Trace' method should return false\n" );

    eval { Exception::Class::Base->throw( error => 'has stacktrace', show_trace => 1 ) };
    result( $@->as_string =~ /Trace begun/,
	    "Setting show_trace to true should override value of Trace" );

    Exception::Class::Base->Trace(1);

    result( Exception::Class::Base->Trace,
	    "Exception::Class::Base class 'Trace' method should return true\n" );

    eval { argh(); };

    result( $@->trace->as_string,
	    "Exception should have a stack trace\n" );

    eval { Exception::Class::Base->throw( error => 'has stacktrace', show_trace => 0 ) };
    result( $@->as_string !~ /Trace begun/,
	    "Setting show_trace to false should override value of Trace" );

    my @f;
    while ( my $f = $@->trace->next_frame ) { push @f, $f; }

    result( ( ! grep { $_->package eq 'Exception::Class::Base' } @f ),
	    "Trace contains frames from Exception::Class::Base package\n" );
}

# 29-30 : overloading
{
    Exception::Class::Base->Trace(0);
    eval { Exception::Class::Base->throw( error => 'overloaded' ); };

    result( "$@" eq 'overloaded', "Overloading is not working\n" );

    Exception::Class::Base->Trace(1);
    eval { Exception::Class::Base->throw( error => 'overloaded again' ); };

    my $re;
    if ($] == 5.006)
    {
	$re = qr/overloaded again.+eval {...}\((?:'Exception::Class::Base')?'error', 'overloaded again'\)/s;
    }
    else
    {
	$re = qr/overloaded again.+eval {...}\('Exception::Class::Base', 'error', 'overloaded again'\)/s
    }

    my $x = "$@" =~ /$re/;
    result( $x, "Overloaded stringification did not include the expected stack trace\n" );
}

# 32-33 - Test using message as hash key to constructor
{
    eval { Exception::Class::Base->throw( message => 'err' ); };

    result( $@->error eq 'err',
	    "Exception's error message should be 'err' but it's '", $@->error, "'\n" );

    result( $@->message eq 'err',
	    "Exception's message should be 'err' but it's '", $@->message, "'\n" );
}

# 34
{
    package X::Y;

    use Exception::Class ( __PACKAGE__ );

    sub xy_die () { __PACKAGE__->throw( error => 'dead' ); }

    eval { xy_die };

    main::result( $@->error, 'dead' );
}

sub argh
{
    Exception::Class::Base->throw( error => 'ARGH' );
}

sub result
{
    my $ok = !!shift;
    use vars qw($TESTNUM);
    $TESTNUM++;
    print "not "x!$ok, "ok $TESTNUM\n";
    print @_ if !$ok;
}