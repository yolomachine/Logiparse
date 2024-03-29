open STDIN, 'statements.txt' or die $!;
open STDOUT, '>truth_table.txt' or die $!;

my @regexs = (
	{
		find => qr/\|/,
		replace => sub { "||" }
	},
	{
		find => qr/[\^\&]/,
		replace => sub { "&&" }
	},
	{
		find => qr/\!\!/,
		replace => sub { "" }
	}
);

sub insert_parentheses {
	my ($s, $insert, $shift, $begin, $end, $inc) = @_;
	my $counter = 0;
	for (my $i = $begin; $inc > 0 ? $i <= $end : $i >= $end; $i += $inc) {
		++$counter if substr($$s, $i, 1) eq ')';
		--$counter if substr($$s, $i, 1) eq '(';
		do { $shift = 0 if $i == $end; substr($$s, $i + $shift, 0) = $insert; last } if ($counter == 0 or $i == $end);
	}
}

sub expand_operator {
	my ($s, $op, $new_op, $left_open, $left_close, $right_open, $right_close) = @_;
	$op =~ s/(.)/\\$1/g;
	$$s =~ s/$op/\*/g;

	while (index($$s, '*') != -1) {
		substr($$s, index($$s, '*') - 1, 0) = $left_close;
		substr($$s, index($$s, '*') + 2, 0) = $right_open;
		insert_parentheses($s, $left_open, 1, index($$s, $left_close .' *'), 0, -1);
		insert_parentheses($s, $right_close, 0, index($$s, '* ' . $right_open) + 2, $$s =~ y///c, 1);
		substr($$s, index($$s, '*'), 1) = $new_op;
	}
}

sub replace_operators {
	my $s = shift;
	$$s =~ s/$_->{find}/$_->{replace}->()/eg for @regexs;
	expand_operator($s, '=>', '||', '!(', ')', '(', ')');
	expand_operator($s, '=', '==', '(', ')', '(', ')');
}

sub truth_table {
	my ($s, %seen, @vars,, $counter) = shift;
	chomp $s;
	$seen{$_} //= do { push @vars, $_; 1 } for $s =~ /\w+/g;

	print 'x'.++$counter."\t =\t $_\n" for @vars;
	print "f\t =\t $s\n\n"; $counter = 0;
	print 'x'.++$counter."\t" for @vars;
	print "f\n"; 

	@vars = map("\$$_", @vars);
	$s =~ s/(\w+)/\$$1/g;
	replace_operators \$s;
	$s = "print(".join(',"\t",', map("($_ ? '1' : '0')", @vars, $s)).',"\n")';
	$s = "for my $_ (0, 1) { $s }" for reverse @vars;
	
	eval 'print \'====\' x scalar @vars; print "=\n";'.$s.'print \'====\' x scalar @vars; print "=\n\n";';
	
}

print "Perl $^V\n\n";
truth_table $_ for <>;